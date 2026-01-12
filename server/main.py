#
# main.py
# Textory Server
#
# FastAPI server for video rendering
#

import os
import uuid
import asyncio
from datetime import datetime, timedelta
from typing import Optional
from fastapi import FastAPI, BackgroundTasks, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
import cloudinary
import cloudinary.uploader

from models import (
    RenderRequest, JobResponse, JobStatus,
    GenerateStoryRequest, GenerateStoryResponse, AIServiceStatus
)
from renderer import VideoRenderer
from ai_service import generate_chat_story, get_ai_service_status, AIServiceError

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


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
