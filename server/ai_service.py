"""
AI service for generating fictional dialogue story scenes using OpenAI GPT or Anthropic Claude.
"""

import os
import json
import re
from typing import Dict, Any, List, Optional
from dotenv import load_dotenv

# Load environment variables
load_dotenv()


class AIServiceError(Exception):
    """Custom exception for AI service errors."""
    pass


def _clean_json_response(text: str) -> str:
    """
    Clean AI response to extract valid JSON.
    Removes markdown code blocks and extra text.
    """
    # Remove markdown code blocks (```json ... ``` or ``` ... ```)
    text = re.sub(r'^```(?:json)?\s*', '', text.strip())
    text = re.sub(r'\s*```$', '', text.strip())

    # Try to find JSON object in the text
    start = text.find('{')
    end = text.rfind('}')

    if start != -1 and end != -1:
        text = text[start:end+1]

    return text.strip()


def _create_prompt(
    topic: str,
    num_messages: int,
    genre: str,
    mood: str,
    num_characters: int = 2,
    character_names: Optional[List[str]] = None
) -> str:
    """
    Create the AI prompt for generating chat story conversation.
    """
    # Define genre descriptions
    genre_descriptions = {
        "romance": "A romantic story with emotional connection, flirting, and relationship dynamics",
        "horror": "A scary, suspenseful story with tension, dread, and unexpected twists",
        "comedy": "A funny, light-hearted story with humor, jokes, and amusing situations",
        "drama": "An emotional, intense story with conflict, stakes, and character development",
        "mystery": "A puzzling story with secrets, clues, and revelations",
        "thriller": "A suspenseful, edge-of-your-seat story with danger and urgency",
        "friendship": "A heartwarming story about bonds between friends",
        "family": "A story about family relationships, dynamics, and connections"
    }

    # Define mood descriptions
    mood_descriptions = {
        "happy": "Upbeat, positive, and cheerful tone",
        "sad": "Melancholic, emotional, and touching tone",
        "tense": "Suspenseful, anxious, and on-edge tone",
        "funny": "Humorous, witty, and entertaining tone",
        "romantic": "Sweet, affectionate, and loving tone",
        "scary": "Creepy, unsettling, and frightening tone",
        "dramatic": "Intense, emotional, and impactful tone",
        "casual": "Relaxed, natural, and everyday tone"
    }

    # Handle "auto" - let AI decide based on the story topic
    if genre.lower() == "auto":
        genre_desc = "Choose the best genre that fits the story topic naturally"
        genre_line = "Genre: AUTO - You decide the best genre based on the topic"
    else:
        genre_desc = genre_descriptions.get(genre.lower(), f"A {genre} themed story")
        genre_line = f"Genre: {genre.upper()} - {genre_desc}"

    if mood.lower() == "auto":
        mood_desc = "Choose the best mood that fits the story naturally"
        mood_line = "Mood: AUTO - You decide the best mood based on the topic"
    else:
        mood_desc = mood_descriptions.get(mood.lower(), f"A {mood} tone")
        mood_line = f"Mood: {mood.upper()} - {mood_desc}"

    # Build character instructions
    is_group_chat = num_characters > 2
    if character_names and len(character_names) >= num_characters:
        char_names = character_names[:num_characters]
        char_instruction = f"Use these exact character names: {', '.join(char_names)}. The first character ({char_names[0]}) is 'Me' (the protagonist/sender)."
    else:
        if num_characters == 2:
            char_instruction = "Use exactly 2 characters: 'Me' (the protagonist) and one other person with a fitting name for the story."
        else:
            char_instruction = f"Use exactly {num_characters} characters: 'Me' (the protagonist) and {num_characters - 1} other people with fitting names for the story."

    # Group chat name instruction
    group_name_instruction = ""
    if is_group_chat:
        group_name_instruction = """
GROUP TITLE:
- Generate a playful, story-forward cast title for the scene
- Examples: "Moon Base Crew", "Portal Detention Club", "Dragon Study Hall", "Skyship Squad"
- Avoid titles that sound like real private friend groups or personal chat threads
- Can include 1 fitting emoji if it feels stylized"""

    scene_break_instruction = """
SCENE BREAKS:
- Also create 1-3 short scene break cards that help the video feel like a scripted episode
- Each scene break must be inserted BEFORE a message index where the next beat begins
- Great examples:
  - "3 Hours Later"
  - "After The Mall"
  - "Meanwhile"
  - "The Next Morning"
  - "Outside The Theater"
- Keep titles short, cinematic, and creator-friendly
- Optional subtitle can add a little context, but keep it brief
- Do not create a scene break before the first message
- Use 0-based indexes for "insert_before_message_index" and keep them within the message count
"""

    return f"""You are a creative writer specializing in fictional dialogue stories for short-form video content.

Generate a compelling scripted story scene about: {topic}

STORY REQUIREMENTS:
- {genre_line}
- {mood_line}
- Number of messages: Exactly {num_messages} messages
- {char_instruction}
{group_name_instruction}

SCENE WRITING REQUIREMENTS:
- Write this as a clearly fictional scripted scene, not as a believable real private conversation
- Use casual modern dialogue, but keep it polished enough for creator content
- Characters can sound natural, but the overall scene should feel authored and story-driven
- Use emojis sparingly (0-1 per message, not every message)
- Vary message lengths - some short ("ok", "wait what"), some longer
- Include strong reactions ("wait what", "no way", "that changes everything")
- Build clean conversational pacing for a video audience

STORY STRUCTURE:
1. Hook - Start with something attention-grabbing
2. Build-up - Develop tension/interest
3. Climax - The main reveal or peak moment
4. Resolution - Satisfying ending (can be cliffhanger for horror/thriller)
{scene_break_instruction}

IMPORTANT RULES:
- This must be fictional entertainment content for storytelling/video creation
- Do not write scenes that look like leaked real private arguments, cheating accusations, harassment, fraud, impersonation, stalking, blackmail, or deceptive proof-style conversations
- Prefer obviously fictional, heightened, or creator-style premises such as fantasy, sci-fi, mystery adventure, school drama, absurd comedy, or exaggerated ensemble chaos
- Build emotional engagement without making it feel like a real person's private messages
- Include unexpected twists or reveals
- End with impact - make viewers want to watch the next scene

Return response as ONLY valid JSON (no markdown, no backticks) with this structure:

{{
  "title": "Catchy story title for the video",
  "group_name": "story-forward cast title (only for group scenes with 3+ characters, null for 1-on-1)",
  "characters": [
    {{
      "id": "1",
      "name": "Me",
      "is_me": true,
      "suggested_color": "#007AFF"
    }},
    {{
      "id": "2",
      "name": "Character Name",
      "is_me": false,
      "suggested_color": "#34C759"
    }}
  ],
  "messages": [
    {{
      "id": "m1",
      "character_id": "1",
      "text": "message text here"
    }},
    {{
      "id": "m2",
      "character_id": "2",
      "text": "reply text here"
    }}
  ],
  "scene_breaks": [
    {{
      "title": "3 Hours Later",
      "subtitle": "The plan changes fast",
      "insert_before_message_index": 4
    }}
  ]
}}

IMPORTANT: Return ONLY the JSON object, no additional text or explanation."""


def _fallback_scene_breaks(num_messages: int) -> List[Dict[str, Any]]:
    """Generate simple scene-break defaults if the model omits them."""
    if num_messages < 8:
        return []
    if num_messages < 12:
        return [{"title": "Later That Day", "subtitle": None, "insert_before_message_index": max(3, num_messages // 2)}]
    if num_messages < 18:
        return [
            {"title": "A Little Later", "subtitle": None, "insert_before_message_index": max(3, num_messages // 3)},
            {"title": "That Night", "subtitle": None, "insert_before_message_index": max(6, (num_messages * 2) // 3)},
        ]
    return [
        {"title": "A Few Hours Later", "subtitle": None, "insert_before_message_index": max(4, num_messages // 4)},
        {"title": "Meanwhile", "subtitle": None, "insert_before_message_index": max(8, num_messages // 2)},
        {"title": "The Next Morning", "subtitle": None, "insert_before_message_index": max(12, (num_messages * 3) // 4)},
    ]


def _normalize_scene_breaks(scene_breaks: Any, message_count: int) -> List[Dict[str, Any]]:
    """Sanitize scene breaks so renderer/app can trust the structure."""
    if not isinstance(scene_breaks, list):
        scene_breaks = []

    normalized: List[Dict[str, Any]] = []
    seen_indexes = set()

    for item in scene_breaks:
        if not isinstance(item, dict):
            continue

        title = str(item.get("title", "")).strip()
        if not title:
            continue

        try:
            insert_index = int(item.get("insert_before_message_index"))
        except (TypeError, ValueError):
            continue

        if insert_index <= 0 or insert_index >= message_count or insert_index in seen_indexes:
            continue

        subtitle = item.get("subtitle")
        subtitle_text = str(subtitle).strip() if subtitle else None
        normalized.append(
            {
                "title": title[:40],
                "subtitle": subtitle_text[:60] if subtitle_text else None,
                "insert_before_message_index": insert_index,
            }
        )
        seen_indexes.add(insert_index)

    if not normalized:
        normalized = _fallback_scene_breaks(message_count)

    return sorted(normalized, key=lambda item: item["insert_before_message_index"])


def _generate_with_openai(
    topic: str,
    num_messages: int,
    genre: str,
    mood: str,
    num_characters: int,
    character_names: Optional[List[str]]
) -> Dict[str, Any]:
    """Generate chat story using OpenAI GPT."""
    try:
        import openai
    except ImportError:
        raise AIServiceError("OpenAI library not installed. Run: pip install openai")

    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise AIServiceError("OPENAI_API_KEY not found in environment variables")

    model = os.getenv("OPENAI_MODEL", "gpt-4o")

    try:
        client = openai.OpenAI(api_key=api_key)

        response = client.chat.completions.create(
            model=model,
            messages=[
                {
                    "role": "system",
                    "content": "You write fictional dialogue story scenes for short-form video creators. Your scenes should feel clearly authored, story-forward, and suitable for entertainment content. Never frame output like believable leaked private messages. Always return valid JSON without markdown formatting."
                },
                {
                    "role": "user",
                    "content": _create_prompt(topic, num_messages, genre, mood, num_characters, character_names)
                }
            ],
            temperature=0.8,
            max_tokens=4000
        )

        content = response.choices[0].message.content
        cleaned_content = _clean_json_response(content)

        try:
            result = json.loads(cleaned_content)
        except json.JSONDecodeError as e:
            raise AIServiceError(
                f"Failed to parse AI response as JSON: {e}\n"
                f"Response: {cleaned_content[:200]}..."
            )

        return result

    except openai.APIError as e:
        raise AIServiceError(f"OpenAI API error: {str(e)}")
    except Exception as e:
        raise AIServiceError(f"Unexpected error with OpenAI: {str(e)}")


def _generate_with_anthropic(
    topic: str,
    num_messages: int,
    genre: str,
    mood: str,
    num_characters: int,
    character_names: Optional[List[str]]
) -> Dict[str, Any]:
    """Generate chat story using Anthropic Claude."""
    try:
        import anthropic
    except ImportError:
        raise AIServiceError("Anthropic library not installed. Run: pip install anthropic")

    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        raise AIServiceError("ANTHROPIC_API_KEY not found in environment variables")

    model = os.getenv("ANTHROPIC_MODEL", "claude-sonnet-4-20250514")

    try:
        client = anthropic.Anthropic(api_key=api_key)

        message = client.messages.create(
            model=model,
            max_tokens=4000,
            temperature=0.8,
            system="You write fictional dialogue story scenes for short-form video creators. Your scenes should feel clearly authored, story-forward, and suitable for entertainment content. Never frame output like believable leaked private messages. Always return valid JSON without markdown formatting.",
            messages=[
                {
                    "role": "user",
                    "content": _create_prompt(topic, num_messages, genre, mood, num_characters, character_names)
                }
            ]
        )

        content = message.content[0].text
        cleaned_content = _clean_json_response(content)

        try:
            result = json.loads(cleaned_content)
        except json.JSONDecodeError as e:
            raise AIServiceError(
                f"Failed to parse AI response as JSON: {e}\n"
                f"Response: {cleaned_content[:200]}..."
            )

        return result

    except anthropic.APIError as e:
        raise AIServiceError(f"Anthropic API error: {str(e)}")
    except Exception as e:
        raise AIServiceError(f"Unexpected error with Anthropic: {str(e)}")


def generate_chat_story(
    topic: str,
    num_messages: int = 15,
    genre: str = "drama",
    mood: str = "dramatic",
    num_characters: int = 2,
    character_names: Optional[List[str]] = None,
    content_intent: str = "fictional_story",
) -> Dict[str, Any]:
    """
    Generate a fictional dialogue story scene using AI.

    Args:
        topic: The fictional story topic/premise
        num_messages: Number of messages to generate (8-30)
        genre: Story genre (romance, horror, comedy, drama, mystery, thriller, friendship, family)
        mood: Story mood (happy, sad, tense, funny, romantic, scary, dramatic, casual)
        num_characters: Number of characters (2-5)
        character_names: Optional list of character names to use
        content_intent: Must remain fictional_story for App Store-safe story generation

    Returns:
        Dictionary containing:
        - title: Story title
        - characters: List of character objects
        - messages: List of message objects

    Raises:
        AIServiceError: If generation fails
        ValueError: If inputs are invalid
    """
    # Validate inputs
    if not topic or not topic.strip():
        raise ValueError("Topic cannot be empty")

    if content_intent != "fictional_story":
        raise ValueError("Only fictional_story content is supported")

    if not isinstance(num_messages, int) or num_messages < 5 or num_messages > 50:
        raise ValueError("Number of messages must be between 5 and 50")

    if not isinstance(num_characters, int) or num_characters < 2 or num_characters > 10:
        raise ValueError("Number of characters must be between 2 and 10")

    # Determine which AI service to use
    ai_service = os.getenv("AI_SERVICE", "anthropic").lower()

    if ai_service == "anthropic":
        result = _generate_with_anthropic(topic, num_messages, genre, mood, num_characters, character_names)
    elif ai_service == "openai":
        result = _generate_with_openai(topic, num_messages, genre, mood, num_characters, character_names)
    else:
        raise AIServiceError(
            f"Invalid AI_SERVICE '{ai_service}'. Must be 'openai' or 'anthropic'"
        )

    # Validate result structure
    if "title" not in result or "characters" not in result or "messages" not in result:
        raise AIServiceError("AI response missing required fields (title, characters, messages)")

    if not isinstance(result["messages"], list):
        raise AIServiceError("AI response 'messages' must be a list")

    if len(result["messages"]) < 5:
        raise AIServiceError(f"AI generated too few messages: {len(result['messages'])}")

    result["scene_breaks"] = _normalize_scene_breaks(result.get("scene_breaks"), len(result["messages"]))

    return result


def get_ai_service_status() -> Dict[str, Any]:
    """Get the current AI service configuration status."""
    ai_service = os.getenv("AI_SERVICE", "anthropic").lower()

    status = {
        "configured_service": ai_service,
        "openai_configured": bool(os.getenv("OPENAI_API_KEY")),
        "anthropic_configured": bool(os.getenv("ANTHROPIC_API_KEY")),
        "openai_model": os.getenv("OPENAI_MODEL", "gpt-4o"),
        "anthropic_model": os.getenv("ANTHROPIC_MODEL", "claude-sonnet-4-20250514")
    }

    return status


if __name__ == "__main__":
    # Test the AI service
    print("Testing AI service...")
    print(f"Status: {get_ai_service_status()}")

    try:
        story = generate_chat_story(
            topic="My best friend just told me they're moving to another country",
            num_messages=10,
            genre="drama",
            mood="sad"
        )
        print(f"\nGenerated story: {story['title']}")
        print(f"Characters: {[c['name'] for c in story['characters']]}")
        print(f"Number of messages: {len(story['messages'])}")
        print("\nMessages:")
        for msg in story['messages']:
            char = next((c for c in story['characters'] if c['id'] == msg['character_id']), None)
            char_name = char['name'] if char else 'Unknown'
            print(f"  {char_name}: {msg['text']}")

        print("\n✓ AI service test passed!")
    except Exception as e:
        print(f"\n✗ AI service test failed: {str(e)}")
