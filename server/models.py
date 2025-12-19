#
# models.py
# ChatStoryMaker Server
#
# Pydantic models for API request/response
#

from pydantic import BaseModel
from typing import Optional
from enum import Enum


class ExportType(str, Enum):
    video = "video"
    screenshot = "screenshot"


class ExportFormat(str, Enum):
    tiktok = "tiktok"      # 9:16 (1080x1920)
    instagram = "instagram" # 1:1 (1080x1080)
    youtube = "youtube"     # 16:9 (1920x1080)


class TypingSpeed(str, Enum):
    slow = "slow"       # 0.20s per char
    normal = "normal"   # 0.12s per char
    fast = "fast"       # 0.06s per char


class ChatTheme(str, Enum):
    imessage = "imessage"
    whatsapp = "whatsapp"
    messenger = "messenger"
    discord = "discord"


class Character(BaseModel):
    id: str
    name: str
    is_me: bool
    color_hex: str
    avatar_emoji: Optional[str] = None
    avatar_image_base64: Optional[str] = None  # Base64-encoded avatar image


class Message(BaseModel):
    id: str
    text: str
    character_id: str


class ExportSettings(BaseModel):
    export_type: ExportType = ExportType.video
    format: ExportFormat = ExportFormat.tiktok
    typing_speed: TypingSpeed = TypingSpeed.normal
    show_keyboard: bool = True
    show_typing_indicator: bool = True
    enable_sounds: bool = True
    dark_mode: bool = False


class RenderRequest(BaseModel):
    messages: list[Message]
    characters: list[Character]
    theme: ChatTheme = ChatTheme.imessage
    settings: ExportSettings = ExportSettings()
    conversation_title: str = "Chat"
    is_group_chat: bool = False


class JobStatus(str, Enum):
    queued = "queued"
    processing = "processing"
    completed = "completed"
    failed = "failed"


class JobResponse(BaseModel):
    job_id: str
    status: JobStatus
    progress: float = 0.0
    video_url: Optional[str] = None
    error: Optional[str] = None
