#
# main.py
# Textory Server
#
# FastAPI server for video rendering
#

import os
import uuid
import asyncio
import base64
import io
from datetime import datetime, timedelta
from typing import Optional
from fastapi import FastAPI, BackgroundTasks, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, HTMLResponse
import cloudinary
import cloudinary.uploader

from models import (
    RenderRequest, JobResponse, JobStatus,
    GenerateStoryRequest, GenerateStoryResponse, AIServiceStatus,
    ScreenshotRequest, ScreenshotResponse
)
from renderer import VideoRenderer, ScreenshotRenderer
from ai_service import generate_chat_story, get_ai_service_status, AIServiceError
from settings_manager import load_settings, save_settings, reset_settings, get_default_settings

# Initialize FastAPI
app = FastAPI(
    title="Textory API",
    description="Video rendering API for chat story videos",
    version="1.0.0"
)

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
        "service": "Textory Video Renderer",
        "version": "1.0.0"
    }


@app.get("/health")
async def health():
    """Health check for uptime monitoring."""
    return {"status": "healthy"}


# ===========================================
# AI Story Generation Endpoints
# ===========================================

@app.get("/ai-status", response_model=AIServiceStatus)
async def ai_status():
    """Get AI service configuration status."""
    return get_ai_service_status()


@app.post("/generate", response_model=GenerateStoryResponse)
async def generate_story(request: GenerateStoryRequest):
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

        return GenerateStoryResponse(
            title=result["title"],
            group_name=result.get("group_name"),
            characters=result["characters"],
            messages=result["messages"]
        )
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
async def start_render(request: RenderRequest, background_tasks: BackgroundTasks):
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
        "request": request
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


# ===========================================
# Screenshot Rendering Endpoints
# ===========================================

@app.post("/render-screenshot", response_model=ScreenshotResponse)
async def render_screenshot(request: ScreenshotRequest):
    """
    Render a chat conversation as a screenshot image.

    Supports two modes:
    - "long": All messages in one tall image (for scrolling/panning in video edits)
    - "paginated": Split into multiple screen-sized images

    Returns base64-encoded PNG image(s).
    """
    from models import ScreenshotMode

    try:
        renderer = ScreenshotRenderer(request)

        if request.mode == ScreenshotMode.paginated:
            # Paginated mode - return multiple images (already HD at 3x scale)
            images_base64 = renderer.render_paginated_to_base64()
            screen_height = int(renderer.width * 16 / 9)  # 9:16 aspect ratio
            return ScreenshotResponse(
                success=True,
                images_base64=images_base64,
                width=renderer.width,
                height=screen_height,
                page_count=len(images_base64)
            )
        else:
            # Long mode - return single tall image (already HD at 3x scale)
            image = renderer.render()

            # Convert to base64
            buffer = io.BytesIO()
            image.save(buffer, format="PNG", optimize=True)
            buffer.seek(0)
            image_base64 = base64.b64encode(buffer.read()).decode('utf-8')

            return ScreenshotResponse(
                success=True,
                image_base64=image_base64,
                width=image.width,
                height=image.height,
                page_count=1
            )

    except Exception as e:
        return ScreenshotResponse(
            success=False,
            error=str(e)
        )


async def render_video(job_id: str, request: RenderRequest):
    """Background task to render the video."""
    try:
        jobs[job_id]["status"] = JobStatus.processing

        # Progress callback
        def update_progress(progress: float):
            jobs[job_id]["progress"] = progress

        # Create renderer and render video
        renderer = VideoRenderer(request)

        # Run rendering in thread pool to not block event loop
        loop = asyncio.get_event_loop()
        video_path = await loop.run_in_executor(
            None,
            lambda: renderer.render(progress_callback=update_progress)
        )

        jobs[job_id]["local_path"] = video_path

        # Upload to Cloudinary if configured
        if CLOUDINARY_CONFIGURED:
            try:
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
            except Exception as e:
                # If Cloudinary fails, keep local file
                print(f"Cloudinary upload failed: {e}")
                jobs[job_id]["video_url"] = f"/download/{job_id}"
        else:
            # Local development - use download endpoint
            jobs[job_id]["video_url"] = f"/download/{job_id}"

        jobs[job_id]["status"] = JobStatus.completed
        jobs[job_id]["progress"] = 1.0

    except Exception as e:
        jobs[job_id]["status"] = JobStatus.failed
        jobs[job_id]["error"] = str(e)
        print(f"Rendering failed for job {job_id}: {e}")


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
async def get_admin_settings():
    """Get current settings for admin panel."""
    return load_settings()


@app.post("/admin/settings")
async def update_admin_settings(request: Request):
    """Update settings (requires admin password in Authorization header)."""
    password = request.headers.get("Authorization", "")

    if not check_admin_password(password):
        raise HTTPException(
            status_code=401,
            detail={"success": False, "message": "Unauthorized"}
        )

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
    password = request.headers.get("Authorization", "")

    if not check_admin_password(password):
        raise HTTPException(
            status_code=401,
            detail={"success": False, "message": "Unauthorized"}
        )

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
