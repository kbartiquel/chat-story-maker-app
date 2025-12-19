#
# renderer.py
# ChatStoryMaker Server
#
# Video rendering engine - Authentic iMessage style
#

import os
import uuid
import base64
import io
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from pilmoji import Pilmoji
from moviepy.editor import ImageSequenceClip, AudioFileClip, CompositeAudioClip
from moviepy.audio.AudioClip import AudioArrayClip
import tempfile
from typing import Optional, Callable
from models import (
    RenderRequest, Message, Character, ChatTheme,
    ExportFormat, TypingSpeed, ExportSettings
)


# Theme colors (matching iOS Theme.swift)
THEMES = {
    "imessage": {
        "sender_bubble": "#007AFF",
        "receiver_bubble": "#E5E5EA",
        "background": "#FFFFFF",
        "sender_text": "#FFFFFF",
        "receiver_text": "#000000",
    },
    "whatsapp": {
        "sender_bubble": "#DCF8C6",
        "receiver_bubble": "#FFFFFF",
        "background": "#ECE5DD",
        "sender_text": "#000000",
        "receiver_text": "#000000",
    },
    "messenger": {
        "sender_bubble": "#0084FF",
        "receiver_bubble": "#E4E6EB",
        "background": "#FFFFFF",
        "sender_text": "#FFFFFF",
        "receiver_text": "#000000",
    },
    "discord": {
        "sender_bubble": "#5865F2",
        "receiver_bubble": "#2F3136",
        "background": "#36393F",
        "sender_text": "#FFFFFF",
        "receiver_text": "#DCDDDE",
    },
}

# Format resolutions (matching iOS ExportSettings.swift)
RESOLUTIONS = {
    "tiktok": (1080, 1920),    # 9:16
    "instagram": (1080, 1080), # 1:1
    "youtube": (1920, 1080),   # 16:9
    "iphone": (1284, 2778),    # iPhone 12 Pro Max native (no letterboxing)
}

# Phone aspect ratio - use TikTok 9:16 as the standard phone look
PHONE_ASPECT_RATIO = 9 / 16  # width / height = 0.5625

# Typing speeds in seconds per character (matching iOS)
TYPING_SPEEDS = {
    "slow": 0.20,
    "normal": 0.12,
    "fast": 0.06,
}

FPS = 30
SUPERSAMPLE_SCALE = 2  # Render at 2x resolution for anti-aliasing

# iMessage specific colors
IMESSAGE_GRAY = "#8E8E93"
IMESSAGE_SEPARATOR = "#C6C6C8"


def hex_to_rgb(hex_color: str) -> tuple:
    """Convert hex color to RGB tuple."""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))


def get_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    """Get a font - uses system font or falls back to default."""
    try:
        # Try to use SF Pro or similar fonts
        font_paths = [
            "/System/Library/Fonts/SFNS.ttf",
            "/System/Library/Fonts/SFNSText.ttf",
            "/Library/Fonts/SF-Pro-Text-Regular.otf",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
            "/usr/share/fonts/TTF/DejaVuSans.ttf",
        ]
        if bold:
            font_paths = [
                "/System/Library/Fonts/SFNS.ttf",
                "/Library/Fonts/SF-Pro-Text-Semibold.otf",
                "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
                "/usr/share/fonts/TTF/DejaVuSans-Bold.ttf",
            ] + font_paths

        for path in font_paths:
            if os.path.exists(path):
                return ImageFont.truetype(path, size)

        # Fallback to default
        return ImageFont.load_default()
    except Exception:
        return ImageFont.load_default()


class VideoRenderer:
    """Renders chat conversations to video - Authentic iMessage style."""

    def __init__(self, request: RenderRequest):
        self.request = request
        self.messages = request.messages
        self.characters = {c.id: c for c in request.characters}
        self.theme = THEMES.get(request.theme.value, THEMES["imessage"])
        self.settings = request.settings
        self.resolution = RESOLUTIONS.get(request.settings.format.value, RESOLUTIONS["tiktok"])
        self.width, self.height = self.resolution

        # Apply supersample scale for anti-aliasing
        self.render_width = self.width * SUPERSAMPLE_SCALE
        self.render_height = self.height * SUPERSAMPLE_SCALE

        # Calculate phone frame that fits within the export format
        # Using TikTok 9:16 as the standard phone look
        frame_aspect = self.render_width / self.render_height

        if frame_aspect <= PHONE_ASPECT_RATIO:
            # Frame is taller or equal to phone (e.g., TikTok 9:16) - fit to width
            self.phone_width = self.render_width
            self.phone_height = int(self.render_width / PHONE_ASPECT_RATIO)
        else:
            # Frame is wider than phone (e.g., Instagram 1:1, YouTube 16:9) - fit to height
            self.phone_height = self.render_height
            self.phone_width = int(self.render_height * PHONE_ASPECT_RATIO)

        # Center offset for the phone frame
        self.phone_x = (self.render_width - self.phone_width) // 2
        self.phone_y = (self.render_height - self.phone_height) // 2

        # Scale factor based on phone width (iPhone 14 = 390 points)
        self.scale = self.phone_width / 390.0

        # Determine if group chat (3+ characters OR explicitly set)
        self._is_group_chat = request.is_group_chat or len(request.characters) > 2

        # Layout constants - iMessage style (no status bar)
        self.keyboard_height = int(216 * self.scale)
        self.input_bar_height = int(52 * self.scale)
        # 1:1 chat has taller header with avatar, name, and timestamp
        self.header_height = int(120 * self.scale) if not self._is_group_chat else int(50 * self.scale)
        self.bubble_padding = int(16 * self.scale)
        self.avatar_size = int(28 * self.scale)
        self.avatar_margin = int(6 * self.scale)
        self.max_bubble_width = int(self.phone_width * 0.70)
        self.bubble_radius = int(18 * self.scale)
        self.tail_size = int(8 * self.scale)

        # Fonts
        self.font_size = int(17 * self.scale)
        self.small_font_size = int(13 * self.scale)
        self.name_font_size = int(12 * self.scale)

        # Timing
        self.typing_speed = TYPING_SPEEDS.get(self.settings.typing_speed.value, 0.12)
        self.frames_per_char = max(1, int(self.typing_speed * FPS))

        # Message timings for audio sync
        self.message_timings = []

        # Cache for loaded sounds
        self._send_sound_cache = None
        self._receive_sound_cache = None

    def get_character(self, character_id: str) -> Optional[Character]:
        """Get character by ID."""
        return self.characters.get(character_id)

    def get_main_contact(self) -> Optional[Character]:
        """Get the main contact (first non-me character)."""
        for char in self.request.characters:
            if not char.is_me:
                return char
        return None

    def draw_avatar(
        self,
        img: Image.Image,
        draw: ImageDraw.Draw,
        character: Character,
        x: int,
        y: int,
        size: int
    ):
        """Draw a circular avatar for a character."""
        avatar_color = hex_to_rgb(character.color_hex)

        # Try to draw base64 image avatar
        if character.avatar_image_base64:
            try:
                image_data = base64.b64decode(character.avatar_image_base64)
                avatar_img = Image.open(io.BytesIO(image_data))

                if avatar_img.mode != 'RGBA':
                    avatar_img = avatar_img.convert('RGBA')

                avatar_img = avatar_img.resize((size, size), Image.Resampling.LANCZOS)

                # Create circular mask
                mask = Image.new('L', (size, size), 0)
                mask_draw = ImageDraw.Draw(mask)
                mask_draw.ellipse([(0, 0), (size, size)], fill=255)

                avatar_img.putalpha(mask)
                img.paste(avatar_img, (x, y), avatar_img)
                return
            except Exception as e:
                print(f"Failed to decode avatar image: {e}")

        # Draw colored circle background
        draw.ellipse([(x, y), (x + size, y + size)], fill=avatar_color)

        # Try to draw emoji avatar
        if character.avatar_emoji:
            emoji_font = get_font(int(size * 0.55), bold=False)
            with Pilmoji(img) as pilmoji:
                bbox = draw.textbbox((0, 0), character.avatar_emoji, font=emoji_font)
                emoji_width = bbox[2] - bbox[0]
                emoji_height = bbox[3] - bbox[1]
                emoji_x = x + (size - emoji_width) // 2
                emoji_y = y + (size - emoji_height) // 2 - int(2 * self.scale)
                pilmoji.text((emoji_x, emoji_y), character.avatar_emoji, font=emoji_font)
            return

        # Fallback: draw initial letter
        initial = character.name[0].upper() if character.name else "?"
        initial_font = get_font(int(size * 0.45), bold=True)
        bbox = draw.textbbox((0, 0), initial, font=initial_font)
        initial_width = bbox[2] - bbox[0]
        initial_height = bbox[3] - bbox[1]
        initial_x = x + (size - initial_width) // 2
        initial_y = y + (size - initial_height) // 2 - int(2 * self.scale)
        draw.text((initial_x, initial_y), initial, fill=(255, 255, 255), font=initial_font)

    def draw_bubble_with_tail(
        self,
        draw: ImageDraw.Draw,
        x: int,
        y: int,
        width: int,
        height: int,
        color: tuple,
        is_sender: bool
    ):
        """Draw a message bubble with an iMessage-style tail."""
        radius = self.bubble_radius
        tail_size = self.tail_size

        # Draw main rounded rectangle
        draw.rounded_rectangle([(x, y), (x + width, y + height)], radius=radius, fill=color)

        # Draw tail
        if is_sender:
            # Tail points RIGHT (bottom-right of bubble)
            tail_x = x + width - int(2 * self.scale)
            tail_y = y + height - radius
            points = [
                (tail_x, tail_y),
                (tail_x + tail_size, tail_y + tail_size + int(4 * self.scale)),
                (tail_x, tail_y + tail_size)
            ]
            draw.polygon(points, fill=color)
        else:
            # Tail points LEFT (bottom-left of bubble)
            tail_x = x + int(2 * self.scale)
            tail_y = y + height - radius
            points = [
                (tail_x, tail_y),
                (tail_x - tail_size, tail_y + tail_size + int(4 * self.scale)),
                (tail_x, tail_y + tail_size)
            ]
            draw.polygon(points, fill=color)

    def render(self, progress_callback: Optional[Callable[[float], None]] = None) -> str:
        """Render the video and return the file path."""
        if progress_callback:
            progress_callback(0.02)

        frames = []
        visible_messages = []
        frame_count = 0
        total_messages = len(self.messages)

        if progress_callback:
            progress_callback(0.05)

        for index, message in enumerate(self.messages):
            character = self.get_character(message.character_id)
            is_me = character.is_me if character else True

            message_base_progress = 0.05 + (index / total_messages * 0.75)
            message_progress_range = 0.75 / total_messages

            if is_me:
                total_chars = len(message.text)

                for char_index in range(1, total_chars + 1):
                    partial_text = message.text[:char_index]
                    current_char = message.text[char_index - 1].lower()

                    frame = self.render_frame(
                        visible_messages=visible_messages,
                        show_typing_indicator=False,
                        typing_character=None,
                        keyboard_typing_text=partial_text,
                        highlighted_key=current_char
                    )

                    for _ in range(self.frames_per_char):
                        frames.append(frame)
                        frame_count += 1

                    if progress_callback and char_index % 3 == 0:
                        typing_progress = char_index / total_chars * 0.6
                        progress_callback(message_base_progress + typing_progress * message_progress_range)

                frame = self.render_frame(
                    visible_messages=visible_messages,
                    show_typing_indicator=False,
                    typing_character=None,
                    keyboard_typing_text=message.text
                )
                for _ in range(10):
                    frames.append(frame)
                    frame_count += 1

                message_time = frame_count / FPS
                self.message_timings.append({
                    "message_id": message.id,
                    "time": message_time,
                    "is_me": is_me
                })

                visible_messages.append((message, message.text, character))

                if progress_callback:
                    progress_callback(message_base_progress + 0.8 * message_progress_range)

            else:
                typing_duration = min(max(len(message.text) / 20.0, 1.5), 2.5)
                typing_frames = int(typing_duration * FPS)

                frame = self.render_frame(
                    visible_messages=visible_messages,
                    show_typing_indicator=True,
                    typing_character=character,
                    keyboard_typing_text=None
                )
                for _ in range(typing_frames):
                    frames.append(frame)
                    frame_count += 1

                message_time = frame_count / FPS
                self.message_timings.append({
                    "message_id": message.id,
                    "time": message_time,
                    "is_me": is_me
                })

                visible_messages.append((message, message.text, character))

                if progress_callback:
                    progress_callback(message_base_progress + 0.8 * message_progress_range)

            reading_time = min(max(len(message.text) / 25.0, 1.5), 3.0)
            pause_frames = int(reading_time * FPS)

            frame = self.render_frame(
                visible_messages=visible_messages,
                show_typing_indicator=False,
                typing_character=None,
                keyboard_typing_text=None
            )
            for _ in range(pause_frames):
                frames.append(frame)
                frame_count += 1

            if progress_callback:
                progress_callback(message_base_progress + message_progress_range)

        if progress_callback:
            progress_callback(0.82)

        frame = self.render_frame(
            visible_messages=visible_messages,
            show_typing_indicator=False,
            typing_character=None,
            keyboard_typing_text=None
        )
        for _ in range(60):
            frames.append(frame)
            frame_count += 1

        if progress_callback:
            progress_callback(0.85)

        frame_arrays = [np.array(f) for f in frames]
        clip = ImageSequenceClip(frame_arrays, fps=FPS)

        if progress_callback:
            progress_callback(0.88)

        if self.settings.enable_sounds:
            audio = self.create_audio(frame_count / FPS)
            if audio:
                clip = clip.set_audio(audio)
            if progress_callback:
                progress_callback(0.95)

        output_path = os.path.join(tempfile.gettempdir(), f"{uuid.uuid4()}.mp4")
        clip.write_videofile(
            output_path,
            fps=FPS,
            codec='libx264',
            audio_codec='aac',
            bitrate="12M",
            preset="slow",
            ffmpeg_params=["-crf", "18"],
            verbose=False,
            logger=None
        )

        if progress_callback:
            progress_callback(1.0)

        return output_path

    def render_frame(
        self,
        visible_messages: list,
        show_typing_indicator: bool,
        typing_character: Optional[Character],
        keyboard_typing_text: Optional[str] = None,
        highlighted_key: Optional[str] = None
    ) -> Image.Image:
        """Render a single frame at high resolution, then downscale for anti-aliasing."""
        dark_mode = self.settings.dark_mode
        bg_color = "#000000" if dark_mode else "#FFFFFF"

        # Create main frame with black background for letterboxing
        frame = Image.new("RGB", (self.render_width, self.render_height), (0, 0, 0))

        # Create phone image at iPhone aspect ratio
        img = Image.new("RGB", (self.phone_width, self.phone_height), hex_to_rgb(bg_color))
        draw = ImageDraw.Draw(img)

        # Draw simplified iMessage header (centered timestamp)
        self.draw_header(draw, img, dark_mode)

        # Draw keyboard if enabled
        if self.settings.show_keyboard:
            self.draw_keyboard(draw, img, dark_mode, keyboard_typing_text, highlighted_key)

        # Calculate message area (relative to phone frame)
        message_area_top = self.header_height + int(10 * self.scale)
        if self.settings.show_keyboard:
            keyboard_y = self.phone_height - self.keyboard_height
            input_bar_y = keyboard_y - self.input_bar_height
            message_area_bottom = input_bar_y - int(10 * self.scale)
        else:
            message_area_bottom = self.phone_height - int(20 * self.scale)

        # Calculate message heights
        message_heights = []
        for message, text, character in visible_messages:
            is_me = character.is_me if character else True
            height = self.calculate_bubble_height(text, is_me, character)
            message_heights.append(height)

        # Auto-scroll logic - messages start from TOP
        available_height = message_area_bottom - message_area_top
        typing_indicator_height = int(50 * self.scale) if show_typing_indicator else 0

        # Calculate total height of all messages
        total_all_messages = sum(message_heights) + typing_indicator_height

        if total_all_messages <= available_height:
            # FEW MESSAGES: Start from TOP
            start_index = 0
            y_offset = message_area_top
        else:
            # MANY MESSAGES: Show most recent, fill from top
            start_index = 0
            total_height = typing_indicator_height

            for i in range(len(visible_messages) - 1, -1, -1):
                if total_height + message_heights[i] <= available_height:
                    total_height += message_heights[i]
                    start_index = i
                else:
                    break

            y_offset = message_area_top

        # Draw messages
        for i in range(start_index, len(visible_messages)):
            message, text, character = visible_messages[i]
            is_me = character.is_me if character else True
            y_offset = self.draw_bubble(draw, img, text, is_me, character, y_offset, dark_mode)

        # Draw typing indicator
        if show_typing_indicator and typing_character:
            self.draw_typing_indicator(draw, img, typing_character, y_offset, dark_mode)

        # Paste phone image onto main frame (centered)
        frame.paste(img, (self.phone_x, self.phone_y))

        # Downscale for anti-aliasing (supersampling)
        if SUPERSAMPLE_SCALE > 1:
            frame = frame.resize((self.width, self.height), Image.Resampling.LANCZOS)

        return frame

    def draw_header(self, draw: ImageDraw.Draw, img: Image.Image, dark_mode: bool):
        """Draw header - 1:1 has avatar/name/video icon, group chat has timestamp."""
        header_bg = "#000000" if dark_mode else "#FFFFFF"
        blue_color = hex_to_rgb("#007AFF")
        gray_color = hex_to_rgb(IMESSAGE_GRAY)
        text_color = (255, 255, 255) if dark_mode else (0, 0, 0)

        # Header background
        draw.rectangle([(0, 0), (self.phone_width, self.header_height)], fill=hex_to_rgb(header_bg))

        if not self._is_group_chat:
            # === 1:1 CHAT HEADER ===
            # Layout: [Back] [Avatar + Name] [Video] | separator | iMessage + Time

            contact = self.get_main_contact()
            contact_avatar_size = int(40 * self.scale)

            # Avatar centered at top
            avatar_x = (self.phone_width - contact_avatar_size) // 2
            avatar_y = int(8 * self.scale)

            if contact:
                self.draw_avatar(img, draw, contact, avatar_x, avatar_y, contact_avatar_size)
                contact_name = contact.name
            else:
                draw.ellipse(
                    [(avatar_x, avatar_y), (avatar_x + contact_avatar_size, avatar_y + contact_avatar_size)],
                    fill=hex_to_rgb("#C7C7CC")
                )
                contact_name = self.request.conversation_title

            # Back arrow and video icon on the same row, aligned with avatar center
            icon_row_y = avatar_y + contact_avatar_size // 2  # Center of avatar

            # Debug line at avatar center
            debug_line_y = icon_row_y

            # Back arrow - centered on debug line (adjust for font baseline)
            arrow_font_size = int(38 * self.scale)
            arrow_font = get_font(arrow_font_size)
            arrow_x = int(10 * self.scale)
            arrow_y = debug_line_y - arrow_font_size // 2 - int(8 * self.scale)  # Move up to center
            draw.text((arrow_x, arrow_y), "‹", fill=blue_color, font=arrow_font)

            # Video icon - same vertical center as back arrow
            assets_dir = os.path.join(os.path.dirname(__file__), "assets")
            video_icon_path = os.path.join(assets_dir, "video_icon.png")

            if os.path.exists(video_icon_path):
                try:
                    video_icon = Image.open(video_icon_path)
                    if video_icon.mode != 'RGBA':
                        video_icon = video_icon.convert('RGBA')

                    # Scale to match back arrow height
                    target_height = int(18 * self.scale)
                    aspect_ratio = video_icon.width / video_icon.height
                    target_width = int(target_height * aspect_ratio)
                    video_icon = video_icon.resize((target_width, target_height), Image.Resampling.LANCZOS)

                    video_x = self.phone_width - target_width - int(16 * self.scale)
                    video_y = debug_line_y - target_height // 2  # Centered on debug line
                    img.paste(video_icon, (video_x, video_y), video_icon)
                except Exception as e:
                    print(f"Failed to load video icon: {e}")

            # Name with chevron below avatar
            name_font = get_font(int(13 * self.scale))
            name_text = f"{contact_name} ›"
            bbox = draw.textbbox((0, 0), name_text, font=name_font)
            name_width = bbox[2] - bbox[0]
            name_x = (self.phone_width - name_width) // 2
            name_y = avatar_y + contact_avatar_size + int(2 * self.scale)
            draw.text((name_x, name_y), name_text, fill=text_color, font=name_font)

            # Separator line - below name
            separator_y = name_y + int(20 * self.scale)
            draw.line(
                [(0, separator_y), (self.phone_width, separator_y)],
                fill=hex_to_rgb(IMESSAGE_SEPARATOR),
                width=1
            )

            # "iMessage" BELOW separator
            label_font = get_font(int(11 * self.scale))
            label_text = "iMessage"
            bbox = draw.textbbox((0, 0), label_text, font=label_font)
            label_width = bbox[2] - bbox[0]
            label_x = (self.phone_width - label_width) // 2
            label_y = separator_y + int(8 * self.scale)
            draw.text((label_x, label_y), label_text, fill=gray_color, font=label_font)

            # Time below iMessage
            time_font = get_font(int(11 * self.scale))
            time_text = "Today 9:41 AM"
            bbox = draw.textbbox((0, 0), time_text, font=time_font)
            time_width = bbox[2] - bbox[0]
            time_x = (self.phone_width - time_width) // 2
            time_y = label_y + int(14 * self.scale)
            draw.text((time_x, time_y), time_text, fill=gray_color, font=time_font)

        else:
            # === GROUP CHAT HEADER ===
            # "iMessage" label centered
            label_font = get_font(int(11 * self.scale))
            label_text = "iMessage"
            bbox = draw.textbbox((0, 0), label_text, font=label_font)
            label_width = bbox[2] - bbox[0]
            label_x = (self.phone_width - label_width) // 2
            label_y = int(8 * self.scale)
            draw.text((label_x, label_y), label_text, fill=gray_color, font=label_font)

            # Timestamp centered below "iMessage"
            time_font = get_font(int(11 * self.scale))
            time_text = "Today 9:40 PM"
            bbox = draw.textbbox((0, 0), time_text, font=time_font)
            time_width = bbox[2] - bbox[0]
            time_x = (self.phone_width - time_width) // 2
            time_y = label_y + int(16 * self.scale)
            draw.text((time_x, time_y), time_text, fill=gray_color, font=time_font)

            # Separator line
            draw.line(
                [(0, self.header_height - 1), (self.phone_width, self.header_height - 1)],
                fill=hex_to_rgb(IMESSAGE_SEPARATOR),
                width=1
            )

    def calculate_bubble_height(self, text: str, is_me: bool, character: Optional[Character]) -> int:
        """Calculate the height of a message bubble."""
        font = get_font(self.font_size)
        max_text_width = self.max_bubble_width - int(24 * self.scale)

        words = text.split()
        lines = []
        current_line = ""

        temp_img = Image.new("RGB", (1, 1))
        temp_draw = ImageDraw.Draw(temp_img)

        for word in words:
            test_line = f"{current_line} {word}".strip()
            bbox = temp_draw.textbbox((0, 0), test_line, font=font)
            if bbox[2] - bbox[0] <= max_text_width:
                current_line = test_line
            else:
                if current_line:
                    lines.append(current_line)
                current_line = word
        if current_line:
            lines.append(current_line)

        line_height = int(22 * self.scale)
        text_height = max(len(lines), 1) * line_height

        height = text_height + int(16 * self.scale)  # Bubble padding
        height += int(8 * self.scale)  # Spacing between messages

        # Add space for character name (received messages in GROUP CHAT only)
        if self._is_group_chat and not is_me and character:
            height += int(18 * self.scale)

        return height

    def draw_bubble(
        self,
        draw: ImageDraw.Draw,
        img: Image.Image,
        text: str,
        is_me: bool,
        character: Optional[Character],
        y_offset: int,
        dark_mode: bool
    ) -> int:
        """Draw a message bubble with tail and return new y_offset."""
        font = get_font(self.font_size)

        # Colors
        if is_me:
            bubble_color = hex_to_rgb(self.theme["sender_bubble"])
            text_color = hex_to_rgb(self.theme["sender_text"])
        else:
            if dark_mode:
                bubble_color = hex_to_rgb("#3A3A3C")
            else:
                bubble_color = hex_to_rgb(self.theme["receiver_bubble"])
            text_color = hex_to_rgb(self.theme["receiver_text"]) if not dark_mode else (255, 255, 255)

        # Calculate text wrapping
        max_text_width = self.max_bubble_width - int(24 * self.scale)
        words = text.split()
        lines = []
        current_line = ""

        for word in words:
            test_line = f"{current_line} {word}".strip()
            bbox = draw.textbbox((0, 0), test_line, font=font)
            if bbox[2] - bbox[0] <= max_text_width:
                current_line = test_line
            else:
                if current_line:
                    lines.append(current_line)
                current_line = word
        if current_line:
            lines.append(current_line)

        if not lines:
            lines = [text]

        # Calculate bubble dimensions
        line_height = int(22 * self.scale)
        text_height = len(lines) * line_height

        max_line_width = 0
        for line in lines:
            bbox = draw.textbbox((0, 0), line, font=font)
            max_line_width = max(max_line_width, bbox[2] - bbox[0])

        bubble_width = max_line_width + int(24 * self.scale)
        bubble_height = text_height + int(14 * self.scale)

        actual_y = y_offset

        # For GROUP CHAT received messages: draw character name and avatar
        if self._is_group_chat and not is_me and character:
            # Character name (gray, above bubble)
            name_font = get_font(self.name_font_size)
            name_color = hex_to_rgb(IMESSAGE_GRAY)
            name_x = self.bubble_padding + self.avatar_size + self.avatar_margin
            with Pilmoji(img) as pilmoji:
                pilmoji.text((name_x, actual_y), character.name, fill=name_color, font=name_font)
            actual_y += int(18 * self.scale)

            # Avatar (left of bubble, aligned with bubble bottom)
            avatar_x = self.bubble_padding
            avatar_y = actual_y + bubble_height - self.avatar_size
            self.draw_avatar(img, draw, character, avatar_x, avatar_y, self.avatar_size)

            # Bubble position (right of avatar)
            bubble_x = self.bubble_padding + self.avatar_size + self.avatar_margin
        elif not is_me:
            # 1:1 CHAT received message: left-aligned, no avatar
            bubble_x = self.bubble_padding
        else:
            # Sent message: right-aligned, no avatar
            bubble_x = self.phone_width - bubble_width - self.bubble_padding

        # Draw bubble with tail
        self.draw_bubble_with_tail(draw, bubble_x, actual_y, bubble_width, bubble_height, bubble_color, is_me)

        # Draw text with emoji support
        text_x = bubble_x + int(12 * self.scale)
        text_y = actual_y + int(7 * self.scale)

        with Pilmoji(img) as pilmoji:
            for line in lines:
                pilmoji.text((text_x, text_y), line, fill=text_color, font=font)
                text_y += line_height

        return actual_y + bubble_height + int(6 * self.scale)

    def draw_typing_indicator(
        self,
        draw: ImageDraw.Draw,
        img: Image.Image,
        character: Character,
        y_offset: int,
        dark_mode: bool
    ):
        """Draw typing indicator - with avatar for group chat, without for 1:1."""
        if dark_mode:
            bubble_color = hex_to_rgb("#3A3A3C")
            dot_color = (155, 155, 155)
        else:
            bubble_color = hex_to_rgb(self.theme["receiver_bubble"])
            dot_color = (128, 128, 128)

        bubble_width = int(60 * self.scale)
        bubble_height = int(36 * self.scale)

        if self._is_group_chat:
            # GROUP CHAT: Show avatar
            avatar_x = self.bubble_padding
            avatar_y = y_offset + bubble_height - self.avatar_size
            self.draw_avatar(img, draw, character, avatar_x, avatar_y, self.avatar_size)
            bubble_x = self.bubble_padding + self.avatar_size + self.avatar_margin
        else:
            # 1:1 CHAT: No avatar
            bubble_x = self.bubble_padding

        # Draw bubble with tail
        self.draw_bubble_with_tail(draw, bubble_x, y_offset, bubble_width, bubble_height, bubble_color, False)

        # Draw dots
        dot_size = int(8 * self.scale)
        for i in range(3):
            dot_x = bubble_x + int(15 * self.scale) + i * int(12 * self.scale)
            dot_y = y_offset + bubble_height // 2
            draw.ellipse(
                [(dot_x - dot_size // 2, dot_y - dot_size // 2),
                 (dot_x + dot_size // 2, dot_y + dot_size // 2)],
                fill=dot_color
            )

    def draw_keyboard(
        self,
        draw: ImageDraw.Draw,
        img: Image.Image,
        dark_mode: bool,
        typing_text: Optional[str],
        highlighted_key: Optional[str]
    ):
        """Draw the iOS keyboard."""
        keyboard_y = self.phone_height - self.keyboard_height

        row1 = list("qwertyuiop")
        row2 = list("asdfghjkl")
        row3 = list("zxcvbnm")

        if dark_mode:
            kb_bg = (30, 30, 30)
            key_color = (89, 89, 89)
            special_key_color = (64, 64, 64)
            text_color = (255, 255, 255)
            input_bg = (51, 51, 51)
            input_border = (100, 100, 100)
        else:
            kb_bg = (209, 213, 219)
            key_color = (255, 255, 255)
            special_key_color = (173, 176, 182)
            text_color = (0, 0, 0)
            input_bg = (255, 255, 255)
            input_border = (200, 200, 200)  # Light gray border

        highlight_color = (128, 128, 128)

        # Draw input field with border
        input_height = int(32 * self.scale)
        input_margin = int(8 * self.scale)
        input_y = keyboard_y - input_height - int(10 * self.scale)
        input_width = self.phone_width - int(54 * self.scale)

        # Fill background
        draw.rounded_rectangle(
            [(input_margin, input_y), (input_margin + input_width, input_y + input_height)],
            radius=int(16 * self.scale),
            fill=input_bg
        )
        # Draw border outline
        draw.rounded_rectangle(
            [(input_margin, input_y), (input_margin + input_width, input_y + input_height)],
            radius=int(16 * self.scale),
            outline=input_border,
            width=1
        )

        input_font = get_font(int(15 * self.scale))
        text_y_pos = input_y + (input_height - int(15 * self.scale)) // 2

        if typing_text:
            display_text = typing_text + "|"
            with Pilmoji(img) as pilmoji:
                pilmoji.text(
                    (input_margin + int(12 * self.scale), text_y_pos),
                    display_text,
                    fill=text_color,
                    font=input_font
                )
        else:
            draw.text(
                (input_margin + int(12 * self.scale), text_y_pos),
                "iMessage",
                fill=(128, 128, 128),
                font=input_font
            )

        # Send button
        send_size = int(28 * self.scale)
        send_x = self.phone_width - send_size - int(12 * self.scale)
        send_y = input_y + (input_height - send_size) // 2
        draw.ellipse(
            [(send_x, send_y), (send_x + send_size, send_y + send_size)],
            fill=(0, 122, 255)
        )
        arrow_font = get_font(int(16 * self.scale), bold=True)
        draw.text(
            (send_x + int(8 * self.scale), send_y + int(4 * self.scale)),
            "↑",
            fill=(255, 255, 255),
            font=arrow_font
        )

        # Keyboard background
        draw.rectangle([(0, keyboard_y), (self.phone_width, self.phone_height)], fill=kb_bg)

        key_height = int(38 * self.scale)
        key_spacing = int(5 * self.scale)
        row_spacing = int(8 * self.scale)
        side_margin = int(3 * self.scale)

        keyboard_width = self.phone_width - side_margin * 2
        row1_key_width = (keyboard_width - (len(row1) - 1) * key_spacing) // len(row1)

        current_y = keyboard_y + int(8 * self.scale)
        key_font = get_font(int(16 * self.scale))
        small_font = get_font(int(11 * self.scale))

        # Row 1
        x = side_margin
        for char in row1:
            is_highlighted = highlighted_key and highlighted_key.lower() == char
            color = highlight_color if is_highlighted else key_color
            draw.rounded_rectangle(
                [(x, current_y), (x + row1_key_width, current_y + key_height)],
                radius=int(5 * self.scale),
                fill=color
            )
            bbox = draw.textbbox((0, 0), char, font=key_font)
            char_width = bbox[2] - bbox[0]
            char_x = x + (row1_key_width - char_width) // 2
            char_y = current_y + (key_height - int(16 * self.scale)) // 2
            draw.text((char_x, char_y), char, fill=text_color, font=key_font)
            x += row1_key_width + key_spacing

        current_y += key_height + row_spacing

        # Row 2
        row2_indent = int(16 * self.scale)
        row2_key_width = (keyboard_width - (len(row2) - 1) * key_spacing - row2_indent) // len(row2)
        x = side_margin + row2_indent // 2

        for char in row2:
            is_highlighted = highlighted_key and highlighted_key.lower() == char
            color = highlight_color if is_highlighted else key_color
            draw.rounded_rectangle(
                [(x, current_y), (x + row2_key_width, current_y + key_height)],
                radius=int(5 * self.scale),
                fill=color
            )
            bbox = draw.textbbox((0, 0), char, font=key_font)
            char_width = bbox[2] - bbox[0]
            char_x = x + (row2_key_width - char_width) // 2
            char_y = current_y + (key_height - int(16 * self.scale)) // 2
            draw.text((char_x, char_y), char, fill=text_color, font=key_font)
            x += row2_key_width + key_spacing

        current_y += key_height + row_spacing

        # Row 3
        special_key_width = int(38 * self.scale)
        row3_key_width = (keyboard_width - (len(row3) - 1) * key_spacing - special_key_width * 2 - key_spacing * 2) // len(row3)

        x = side_margin
        draw.rounded_rectangle(
            [(x, current_y), (x + special_key_width, current_y + key_height)],
            radius=int(5 * self.scale),
            fill=special_key_color
        )
        draw.text((x + int(10 * self.scale), current_y + int(10 * self.scale)), "⇧", fill=text_color, font=small_font)
        x += special_key_width + key_spacing

        for char in row3:
            is_highlighted = highlighted_key and highlighted_key.lower() == char
            color = highlight_color if is_highlighted else key_color
            draw.rounded_rectangle(
                [(x, current_y), (x + row3_key_width, current_y + key_height)],
                radius=int(5 * self.scale),
                fill=color
            )
            bbox = draw.textbbox((0, 0), char, font=key_font)
            char_width = bbox[2] - bbox[0]
            char_x = x + (row3_key_width - char_width) // 2
            char_y = current_y + (key_height - int(16 * self.scale)) // 2
            draw.text((char_x, char_y), char, fill=text_color, font=key_font)
            x += row3_key_width + key_spacing

        draw.rounded_rectangle(
            [(self.phone_width - side_margin - special_key_width, current_y),
             (self.phone_width - side_margin, current_y + key_height)],
            radius=int(5 * self.scale),
            fill=special_key_color
        )
        draw.text(
            (self.phone_width - side_margin - special_key_width + int(10 * self.scale), current_y + int(10 * self.scale)),
            "⌫", fill=text_color, font=small_font
        )

        current_y += key_height + row_spacing

        # Row 4
        bottom_key_height = int(38 * self.scale)
        num_key_width = int(38 * self.scale)
        emoji_key_width = int(36 * self.scale)
        return_key_width = int(60 * self.scale)
        space_width = self.phone_width - num_key_width - emoji_key_width - return_key_width - key_spacing * 4 - side_margin * 2

        x = side_margin

        draw.rounded_rectangle(
            [(x, current_y), (x + num_key_width, current_y + bottom_key_height)],
            radius=int(5 * self.scale),
            fill=special_key_color
        )
        draw.text((x + int(8 * self.scale), current_y + int(12 * self.scale)), "123", fill=text_color, font=small_font)
        x += num_key_width + key_spacing

        draw.rounded_rectangle(
            [(x, current_y), (x + emoji_key_width, current_y + bottom_key_height)],
            radius=int(5 * self.scale),
            fill=special_key_color
        )
        x += emoji_key_width + key_spacing

        is_space_highlighted = highlighted_key == " "
        space_color = highlight_color if is_space_highlighted else key_color
        draw.rounded_rectangle(
            [(x, current_y), (x + space_width, current_y + bottom_key_height)],
            radius=int(5 * self.scale),
            fill=space_color
        )
        bbox = draw.textbbox((0, 0), "space", font=small_font)
        space_text_width = bbox[2] - bbox[0]
        draw.text(
            (x + (space_width - space_text_width) // 2, current_y + int(12 * self.scale)),
            "space", fill=text_color, font=small_font
        )
        x += space_width + key_spacing

        draw.rounded_rectangle(
            [(x, current_y), (self.phone_width - side_margin, current_y + bottom_key_height)],
            radius=int(5 * self.scale),
            fill=special_key_color
        )
        draw.text((x + int(8 * self.scale), current_y + int(12 * self.scale)), "return", fill=text_color, font=small_font)

    def create_audio(self, total_duration: float):
        """Create audio with send/receive sounds using moviepy."""
        if not self.message_timings:
            return None

        from moviepy.editor import AudioFileClip, CompositeAudioClip, concatenate_audioclips

        assets_dir = os.path.join(os.path.dirname(__file__), "assets")
        send_path = os.path.join(assets_dir, "send.mp3")
        receive_path = os.path.join(assets_dir, "receive.mp3")

        clips = []
        for timing in self.message_timings:
            is_me = timing["is_me"]
            # send.mp3 for sent messages, receive.mp3 for received messages
            sound_path = send_path if is_me else receive_path

            if os.path.exists(sound_path):
                try:
                    clip = AudioFileClip(sound_path)
                    clip = clip.set_start(timing["time"])
                    clips.append(clip)
                    print(f"Sound at {timing['time']:.2f}s: {sound_path}")
                except Exception as e:
                    print(f"Failed: {e}")

        if not clips:
            return None

        return CompositeAudioClip(clips).set_duration(total_duration)

    def load_sound_file(self, filename: str) -> Optional[np.ndarray]:
        """Try to load a sound file from assets folder using moviepy."""
        assets_dir = os.path.join(os.path.dirname(__file__), "assets")
        for ext in [".mp3", ".wav", ".m4a"]:
            filepath = os.path.join(assets_dir, filename + ext)
            if os.path.exists(filepath):
                try:
                    from moviepy.editor import AudioFileClip
                    audio_clip = AudioFileClip(filepath)
                    # Get samples at 44100Hz (standard rate)
                    samples = audio_clip.to_soundarray(fps=44100)
                    # Convert to mono if stereo
                    if len(samples.shape) > 1 and samples.shape[1] > 1:
                        samples = samples.mean(axis=1)
                    samples = samples.flatten().astype(np.float32)
                    duration = len(samples) / 44100
                    audio_clip.close()
                    print(f"Loaded sound: {filepath}, duration: {duration:.3f}s, samples: {len(samples)}")
                    return samples
                except Exception as e:
                    print(f"Failed to load {filepath}: {e}")
        return None

    def generate_send_sound(self) -> np.ndarray:
        """Load or generate iMessage send sound (swoosh)."""
        # Use cache if available
        if self._send_sound_cache is not None:
            return self._send_sound_cache

        # Try to load from file first
        sound = self.load_sound_file("send")
        if sound is not None:
            self._send_sound_cache = sound
            return sound

        # Fallback: generate synthetic sound
        sample_rate = 44100
        duration = 0.15
        t = np.linspace(0, duration, int(sample_rate * duration))
        freq = 800 + 400 * t / duration
        sound = 0.3 * np.sin(2 * np.pi * freq * t)
        envelope = np.exp(-3 * t / duration)
        sound *= envelope
        self._send_sound_cache = sound.astype(np.float32)
        return self._send_sound_cache

    def generate_receive_sound(self) -> np.ndarray:
        """Load or generate iMessage receive sound (ding)."""
        # Use cache if available
        if self._receive_sound_cache is not None:
            return self._receive_sound_cache

        # Try to load from file first
        sound = self.load_sound_file("receive")
        if sound is not None:
            self._receive_sound_cache = sound
            return sound

        # Fallback: generate synthetic sound
        sample_rate = 44100
        duration = 0.2
        t = np.linspace(0, duration, int(sample_rate * duration))
        sound = 0.2 * np.sin(2 * np.pi * 1200 * t) + 0.15 * np.sin(2 * np.pi * 1500 * t)
        envelope = np.exp(-5 * t / duration)
        sound *= envelope
        self._receive_sound_cache = sound.astype(np.float32)
        return self._receive_sound_cache
