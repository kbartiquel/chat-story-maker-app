#
# settings_manager.py
# Textery Server
#
# Manages paywall and app settings stored in JSON file
#

import json
import os
from threading import Lock
from typing import Any

# Thread lock for file operations
_lock = Lock()

# Default settings for Textery
DEFAULT_SETTINGS = {
    "videoExportLimit": 3,
    "aiGenerationLimit": 5,
    "hardPaywall": False,
    "paywallCloseButtonDelay": 3,
    "paywallCloseButtonDelayOnLimit": 5,
    "paywallShowLoadingIndicator": True,
    "showPaywallOnStart": True,
    "paywallMonthly": False,
    "paywallWeekly": True,
    "paywallLifetime": False,
    "paywallYearly": True,
}

SETTINGS_FILE = os.path.join(os.path.dirname(__file__), "settings.json")


def load_settings() -> dict[str, Any]:
    """Load settings from JSON file, falling back to defaults if needed."""
    with _lock:
        try:
            if os.path.exists(SETTINGS_FILE):
                with open(SETTINGS_FILE, "r") as f:
                    raw_settings = json.load(f)
                    settings = DEFAULT_SETTINGS.copy()
                    for key in DEFAULT_SETTINGS:
                        if key in raw_settings:
                            settings[key] = raw_settings[key]
                    return settings
        except (json.JSONDecodeError, IOError) as e:
            print(f"Error loading settings: {e}")

        return DEFAULT_SETTINGS.copy()


def save_settings(settings: dict[str, Any]) -> dict[str, Any]:
    """Save settings to JSON file."""
    with _lock:
        try:
            sanitized_settings = DEFAULT_SETTINGS.copy()
            for key in DEFAULT_SETTINGS:
                if key in settings:
                    sanitized_settings[key] = settings[key]

            with open(SETTINGS_FILE, "w") as f:
                json.dump(sanitized_settings, f, indent=2)

            return sanitized_settings
        except IOError as e:
            print(f"Error saving settings: {e}")
            raise


def reset_settings() -> dict[str, Any]:
    """Reset settings to defaults."""
    return save_settings(DEFAULT_SETTINGS.copy())


def get_default_settings() -> dict[str, Any]:
    """Get a copy of the default settings."""
    return DEFAULT_SETTINGS.copy()
