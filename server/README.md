# ChatStoryMaker Server

Python video rendering server for ChatStoryMaker iOS app.

## Local Development

### 1. Install dependencies

```bash
cd server
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Install FFmpeg (required for video encoding)

**macOS:**
```bash
brew install ffmpeg
```

**Ubuntu/Debian:**
```bash
sudo apt install ffmpeg
```

**Windows:**
Download from https://ffmpeg.org/download.html

### 3. Run the server

```bash
python main.py
```

Or with uvicorn:
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Server runs at: http://localhost:8000

### 4. Test the API

**Health check:**
```bash
curl http://localhost:8000/health
```

**Start a render job:**
```bash
curl -X POST http://localhost:8000/render \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"id": "1", "text": "Hey!", "character_id": "me"},
      {"id": "2", "text": "Hi there!", "character_id": "other"}
    ],
    "characters": [
      {"id": "me", "name": "Me", "is_me": true, "color_hex": "#007AFF"},
      {"id": "other", "name": "John", "is_me": false, "color_hex": "#34C759", "avatar_emoji": "😊"}
    ],
    "conversation_title": "Chat with John"
  }'
```

**Check status:**
```bash
curl http://localhost:8000/status/{job_id}
```

**Download video (local dev):**
```bash
curl http://localhost:8000/download/{job_id} --output video.mp4
```

## Deploy to Render

### 1. Create Render account
Sign up at https://render.com

### 2. Create Web Service
- Connect your GitHub repo
- Select the `server` directory
- Build Command: `pip install -r requirements.txt`
- Start Command: `uvicorn main:app --host 0.0.0.0 --port $PORT`

### 3. Add Environment Variables (optional)
For Cloudinary video storage:
- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_API_KEY`
- `CLOUDINARY_API_SECRET`

### 4. Deploy
Render will auto-deploy on push to main branch.

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Service info |
| GET | `/health` | Health check |
| POST | `/render` | Start render job |
| GET | `/status/{job_id}` | Get job status |
| GET | `/download/{job_id}` | Download video (local) |

## Architecture

```
iOS App
    │
    ├─► POST /render (conversation data)
    │   └─► Returns job_id immediately
    │
    ├─► GET /status/{job_id} (poll every 2-3s)
    │   └─► Returns progress (0.0 - 1.0)
    │
    └─► GET video_url (when complete)
        └─► Downloads MP4 video
```

## Cost Estimate

For ~50 users/day:
- **Render Starter**: $7/month
- **Cloudinary Free**: $0 (25GB storage)
- **Total**: ~$7/month
