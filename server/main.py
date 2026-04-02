#
# main.py
# Textery Server
#
# FastAPI server for video rendering
#

import os
import uuid
import asyncio
from datetime import datetime, timedelta, timezone
from typing import Optional
from fastapi import FastAPI, BackgroundTasks, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, HTMLResponse
import cloudinary
import cloudinary.uploader

from models import (
    RenderRequest, JobResponse, JobStatus,
    GenerateStoryRequest, GenerateStoryResponse, AIServiceStatus,
    TrackingEventRequest
)
from renderer import VideoRenderer
from ai_service import generate_chat_story, get_ai_service_status, AIServiceError
from settings_manager import load_settings, save_settings, reset_settings, get_default_settings
from tracking_manager import (
    record_event,
    record_request,
    record_revenuecat_webhook,
    get_dashboard_summary,
    get_users,
    get_admin_stats,
    delete_user,
)

# Initialize FastAPI
app = FastAPI(
    title="Textery API",
    description="Video rendering API for chat story videos",
    version="1.0.0"
)

# Render queue limiter - max 2 concurrent renders to prevent OOM on 2GB RAM
MAX_CONCURRENT_RENDERS = 2
render_semaphore = asyncio.Semaphore(MAX_CONCURRENT_RENDERS)
render_queue_count = 0  # Track how many jobs are waiting

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory job storage (for 50 users/day this is fine)
# In production, use Redis or a database
jobs: dict[str, dict] = {}

# Configure Cloudinary (optional - for cloud storage)
CLOUDINARY_CONFIGURED = False
if os.getenv("CLOUDINARY_CLOUD_NAME"):
    cloudinary.config(
        cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
        api_key=os.getenv("CLOUDINARY_API_KEY"),
        api_secret=os.getenv("CLOUDINARY_API_SECRET")
    )
    CLOUDINARY_CONFIGURED = True

# Cleanup old jobs periodically
def cleanup_old_jobs():
    """Remove jobs older than 1 hour."""
    cutoff = datetime.now() - timedelta(hours=1)
    to_remove = [
        job_id for job_id, job in jobs.items()
        if job.get("created_at", datetime.now()) < cutoff
    ]
    for job_id in to_remove:
        # Delete local file if exists
        if jobs[job_id].get("local_path"):
            try:
                os.remove(jobs[job_id]["local_path"])
            except:
                pass
        del jobs[job_id]


@app.get("/")
async def root():
    """Health check endpoint."""
    return {
        "status": "ok",
        "service": "Textery Video Renderer",
        "version": "1.0.0"
    }


@app.get("/health")
async def health():
    """Health check for uptime monitoring."""
    return {"status": "healthy"}


@app.get("/privacy", response_class=HTMLResponse)
async def privacy_policy():
    """Serve the privacy policy page."""
    privacy_html_path = os.path.join(os.path.dirname(__file__), "privacy.html")
    try:
        with open(privacy_html_path, "r") as f:
            return HTMLResponse(content=f.read())
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="Privacy policy not found")


@app.get("/terms", response_class=HTMLResponse)
async def terms_of_service():
    """Serve the terms of service page."""
    terms_html_path = os.path.join(os.path.dirname(__file__), "terms.html")
    try:
        with open(terms_html_path, "r") as f:
            return HTMLResponse(content=f.read())
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="Terms of service not found")


@app.get("/queue-status")
async def queue_status():
    """Get current render queue status."""
    active_renders = MAX_CONCURRENT_RENDERS - render_semaphore._value
    return {
        "max_concurrent": MAX_CONCURRENT_RENDERS,
        "active_renders": active_renders,
        "queue_waiting": render_queue_count,
        "available_slots": render_semaphore._value
    }


@app.post("/track")
async def track_event(request: TrackingEventRequest, http_request: Request):
    """Receive lightweight analytics events for admin dashboard visibility."""
    try:
        event = record_event(
            user_id=request.user_id,
            event=request.event,
            properties=request.properties,
            platform=request.platform,
            app_version=request.app_version,
            country=http_request.headers.get("cf-ipcountry"),
        )
        return {"success": True, "event": event}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Tracking failed: {str(e)}")


@app.post("/webhooks/revenuecat")
@app.post("/revenuecat/webhook")
async def revenuecat_webhook(http_request: Request):
    """Process RevenueCat webhook events for revenue reporting."""
    try:
        payload = await http_request.json()
        return record_revenuecat_webhook(payload)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Webhook failed: {str(e)}")


# ===========================================
# AI Story Generation Endpoints
# ===========================================

@app.get("/ai-status", response_model=AIServiceStatus)
async def ai_status():
    """Get AI service configuration status."""
    return get_ai_service_status()


@app.post("/generate", response_model=GenerateStoryResponse)
async def generate_story(request: GenerateStoryRequest, http_request: Request):
    """
    Generate a chat story conversation using AI.

    Uses either OpenAI GPT or Anthropic Claude based on AI_SERVICE env var.
    """
    try:
        result = generate_chat_story(
            topic=request.topic,
            num_messages=request.num_messages,
            genre=request.genre,
            mood=request.mood,
            num_characters=request.num_characters,
            character_names=request.character_names
        )

        response = GenerateStoryResponse(
            title=result["title"],
            group_name=result.get("group_name"),
            characters=result["characters"],
            messages=result["messages"]
        )
        user_id = http_request.headers.get("X-User-ID")
        if user_id:
            record_request(
                user_id=user_id,
                endpoint="generate",
                properties={
                    "message_count": len(result["messages"]),
                    "genre": request.genre,
                    "mood": request.mood,
                },
                country=http_request.headers.get("cf-ipcountry"),
                app_version=http_request.headers.get("X-App-Version"),
            )
        return response
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except AIServiceError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Generation failed: {str(e)}")


# ===========================================
# Video Rendering Endpoints
# ===========================================

@app.post("/render", response_model=JobResponse)
async def start_render(request: RenderRequest, background_tasks: BackgroundTasks, http_request: Request):
    """
    Start a video rendering job.
    Returns immediately with a job_id for polling.
    """
    job_id = str(uuid.uuid4())

    # Create job entry
    jobs[job_id] = {
        "status": JobStatus.queued,
        "progress": 0.0,
        "video_url": None,
        "local_path": None,
        "error": None,
        "created_at": datetime.now(),
        "request": request,
        "user_id": http_request.headers.get("X-User-ID"),
        "app_version": http_request.headers.get("X-App-Version"),
        "country": http_request.headers.get("cf-ipcountry"),
    }

    # Start rendering in background
    background_tasks.add_task(render_video, job_id, request)

    return JobResponse(
        job_id=job_id,
        status=JobStatus.queued,
        progress=0.0
    )


@app.get("/status/{job_id}", response_model=JobResponse)
async def get_status(job_id: str):
    """Get the status of a rendering job."""
    if job_id not in jobs:
        raise HTTPException(status_code=404, detail="Job not found")

    job = jobs[job_id]

    return JobResponse(
        job_id=job_id,
        status=job["status"],
        progress=job["progress"],
        video_url=job.get("video_url"),
        error=job.get("error")
    )


@app.get("/download/{job_id}")
async def download_video(job_id: str):
    """Download the rendered video (for local development)."""
    if job_id not in jobs:
        raise HTTPException(status_code=404, detail="Job not found")

    job = jobs[job_id]

    if job["status"] != JobStatus.completed:
        raise HTTPException(status_code=400, detail="Video not ready")

    if job.get("local_path") and os.path.exists(job["local_path"]):
        return FileResponse(
            job["local_path"],
            media_type="video/mp4",
            filename=f"chat_video_{job_id}.mp4"
        )

    raise HTTPException(status_code=404, detail="Video file not found")


async def render_video(job_id: str, request: RenderRequest):
    """Background task to render the video with queue limiting."""
    import traceback
    import sys
    global render_queue_count

    render_queue_count += 1
    queue_position = render_queue_count
    print(f"[RENDER] Job {job_id} queued (position ~{queue_position}, waiting for semaphore)", flush=True)

    # Wait for semaphore - limits concurrent renders to MAX_CONCURRENT_RENDERS
    async with render_semaphore:
        render_queue_count -= 1
        print(f"[RENDER] Job {job_id} acquired semaphore, starting render", flush=True)

        try:
            jobs[job_id]["status"] = JobStatus.processing
            print(f"[RENDER] Job {job_id} status set to processing", flush=True)

            # Progress callback
            def update_progress(progress: float):
                jobs[job_id]["progress"] = progress
                if int(progress * 100) % 10 == 0:
                    print(f"[RENDER] Job {job_id} progress: {progress:.1%}", flush=True)

            # Create renderer and render video
            print(f"[RENDER] Creating VideoRenderer for job {job_id}", flush=True)
            renderer = VideoRenderer(request)
            print(f"[RENDER] VideoRenderer created, starting render", flush=True)

            # Run rendering in thread pool to not block event loop
            loop = asyncio.get_event_loop()
            video_path = await loop.run_in_executor(
                None,
                lambda: renderer.render(progress_callback=update_progress)
            )

            print(f"[RENDER] Job {job_id} render complete, video at: {video_path}", flush=True)

            jobs[job_id]["local_path"] = video_path

            # Upload to Cloudinary if configured
            if CLOUDINARY_CONFIGURED:
                try:
                    print(f"[RENDER] Uploading to Cloudinary", flush=True)
                    result = cloudinary.uploader.upload(
                        video_path,
                        resource_type="video",
                        folder="chatstorymaker",
                        public_id=job_id
                    )
                    jobs[job_id]["video_url"] = result["secure_url"]

                    # Clean up local file after upload
                    os.remove(video_path)
                    jobs[job_id]["local_path"] = None
                    print(f"[RENDER] Cloudinary upload complete", flush=True)
                except Exception as e:
                    # If Cloudinary fails, keep local file
                    print(f"[RENDER] Cloudinary upload failed: {e}", flush=True)
                    jobs[job_id]["video_url"] = f"/download/{job_id}"
            else:
                # Local development - use download endpoint
                jobs[job_id]["video_url"] = f"/download/{job_id}"

            jobs[job_id]["status"] = JobStatus.completed
            jobs[job_id]["progress"] = 1.0
            if jobs[job_id].get("user_id"):
                record_request(
                    user_id=jobs[job_id]["user_id"],
                    endpoint="render",
                    properties={
                        "format": request.settings.format.value,
                        "export_type": request.settings.export_type.value,
                        "is_group_chat": request.is_group_chat,
                    },
                    app_version=jobs[job_id].get("app_version"),
                    country=jobs[job_id].get("country"),
                )
            print(f"[RENDER] Job {job_id} completed successfully", flush=True)

        except Exception as e:
            error_trace = traceback.format_exc()
            print(f"[RENDER ERROR] Job {job_id} failed: {e}", flush=True)
            print(f"[RENDER ERROR] Traceback:\n{error_trace}", flush=True)
            sys.stdout.flush()
            sys.stderr.flush()
            jobs[job_id]["status"] = JobStatus.failed
            jobs[job_id]["error"] = str(e)


# Cleanup task
@app.on_event("startup")
async def startup_event():
    """Run cleanup on startup."""
    cleanup_old_jobs()


# ===========================================
# Admin Panel & Settings Endpoints
# ===========================================

def check_admin_password(password: str) -> bool:
    """Check if the provided password matches the admin password."""
    admin_password = os.getenv("ADMIN_PASSWORD")
    return admin_password and password == admin_password


def require_admin_password(request: Request) -> None:
    """Require a valid admin password in Authorization header."""
    password = request.headers.get("Authorization", "")
    if not check_admin_password(password):
        raise HTTPException(
            status_code=401,
            detail={"success": False, "message": "Unauthorized"}
        )


@app.get("/settings")
async def get_public_settings():
    """Get current paywall settings (public endpoint for iOS app)."""
    return load_settings()


@app.get("/admin", response_class=HTMLResponse)
async def admin_panel():
    """Serve the admin panel HTML."""
    admin_html_path = os.path.join(os.path.dirname(__file__), "admin.html")
    try:
        with open(admin_html_path, "r") as f:
            return HTMLResponse(content=f.read())
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="Admin panel not found")


@app.post("/admin/auth")
async def admin_auth(request: Request):
    """Authenticate admin user."""
    try:
        body = await request.json()
        password = body.get("password", "")
    except:
        raise HTTPException(status_code=400, detail="Invalid request body")

    if check_admin_password(password):
        return {"success": True, "message": "Authentication successful"}
    else:
        raise HTTPException(
            status_code=401,
            detail={"success": False, "message": "Invalid password"}
        )


@app.get("/admin/settings")
async def get_admin_settings(request: Request):
    """Get current settings for admin panel."""
    require_admin_password(request)
    return load_settings()


@app.get("/admin/dashboard")
async def get_admin_dashboard(request: Request):
    """Get summary analytics for the admin dashboard."""
    require_admin_password(request)
    return get_dashboard_summary()


@app.get("/admin/stats")
async def get_admin_stats_endpoint(
    request: Request,
    limit: int = 200,
    startDate: Optional[str] = None,
    endDate: Optional[str] = None,
):
    """Get detailed dashboard stats with optional date filters."""
    require_admin_password(request)
    start = datetime.fromisoformat(startDate).replace(tzinfo=timezone.utc) if startDate else None
    end = datetime.fromisoformat(endDate).replace(tzinfo=timezone.utc) if endDate else None
    return get_admin_stats(start_date=start, end_date=end, limit=limit)


@app.get("/admin/users")
async def get_admin_users(request: Request, limit: int = 100):
    """Get recent users for the admin dashboard."""
    require_admin_password(request)
    return {"users": get_users(limit=max(1, min(limit, 250)))}


@app.delete("/admin/user/{user_id}")
async def delete_admin_user(user_id: str, request: Request):
    """Delete a user and their analytics records."""
    require_admin_password(request)
    return delete_user(user_id)


@app.post("/admin/settings")
async def update_admin_settings(request: Request):
    """Update settings (requires admin password in Authorization header)."""
    require_admin_password(request)

    try:
        new_settings = await request.json()
        saved_settings = save_settings(new_settings)
        return {"success": True, "settings": saved_settings}
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={"success": False, "message": str(e)}
        )


@app.post("/admin/settings/reset")
async def reset_admin_settings(request: Request):
    """Reset settings to defaults (requires admin password)."""
    require_admin_password(request)

    try:
        default_settings = reset_settings()
        return {"success": True, "settings": default_settings}
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={"success": False, "message": str(e)}
        )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
