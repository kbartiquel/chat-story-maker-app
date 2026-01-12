"""
AI service for generating chat story conversations using OpenAI GPT or Anthropic Claude.
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

    genre_desc = genre_descriptions.get(genre.lower(), f"A {genre} themed story")
    mood_desc = mood_descriptions.get(mood.lower(), f"A {mood} tone")

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
GROUP CHAT NAME:
- Generate a realistic group chat name that friends would actually use
- Examples: "birthday squad 🎂", "fam", "work besties", "girls night", "the boys", "roommates", "book club"
- Keep it casual and authentic - how real friend groups name their chats
- Can include 1 emoji if fitting"""

    return f"""You are a creative writer specializing in viral chat story content for TikTok, Instagram, and YouTube.

Generate a compelling text message conversation about: {topic}

STORY REQUIREMENTS:
- Genre: {genre.upper()} - {genre_desc}
- Mood: {mood.upper()} - {mood_desc}
- Number of messages: Exactly {num_messages} messages
- {char_instruction}
{group_name_instruction}

TEXTING STYLE REQUIREMENTS:
- Make it feel like REAL text messages, not formal writing
- Use natural texting patterns: "u" for "you", "rn" for "right now", "omg", "lol", etc.
- Include occasional typos that feel authentic (but not too many)
- Use emojis naturally (1-2 per message max, not every message)
- Vary message lengths - some short ("ok", "wait what"), some longer
- Include realistic reactions ("???", "omg", "no way")
- Add natural pauses in conversation flow

STORY STRUCTURE:
1. Hook - Start with something attention-grabbing
2. Build-up - Develop tension/interest
3. Climax - The main reveal or peak moment
4. Resolution - Satisfying ending (can be cliffhanger for horror/thriller)

IMPORTANT RULES:
- Each message should feel authentic to how people actually text
- Build emotional engagement - make readers invested
- Include unexpected twists or reveals
- End with impact - make people want to share/comment

Return response as ONLY valid JSON (no markdown, no backticks) with this structure:

{{
  "title": "Catchy story title for the video",
  "group_name": "realistic group chat name (only for group chats with 3+ characters, null for 1-on-1)",
  "characters": [
    {{
      "id": "1",
      "name": "Me",
      "is_me": true,
      "suggested_color": "#007AFF",
      "suggested_emoji": "emoji that fits character"
    }},
    {{
      "id": "2",
      "name": "Character Name",
      "is_me": false,
      "suggested_color": "#34C759",
      "suggested_emoji": "emoji that fits character"
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
  ]
}}

IMPORTANT: Return ONLY the JSON object, no additional text or explanation."""


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
                    "content": "You are a viral content creator who writes engaging chat story conversations. Your stories get millions of views because they feel authentic and emotionally engaging. You always return valid JSON without markdown formatting."
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
            system="You are a viral content creator who writes engaging chat story conversations. Your stories get millions of views because they feel authentic and emotionally engaging. You always return valid JSON without markdown formatting.",
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
    character_names: Optional[List[str]] = None
) -> Dict[str, Any]:
    """
    Generate a chat story conversation using AI.

    Args:
        topic: The story topic/premise
        num_messages: Number of messages to generate (8-30)
        genre: Story genre (romance, horror, comedy, drama, mystery, thriller, friendship, family)
        mood: Story mood (happy, sad, tense, funny, romantic, scary, dramatic, casual)
        num_characters: Number of characters (2-5)
        character_names: Optional list of character names to use

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
