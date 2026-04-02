#
# tracking_manager.py
# Textery Server
#
# File-backed analytics, RevenueCat webhook, and admin dashboard helpers.
#

import json
import os
from collections import Counter
from datetime import datetime, timezone
from threading import Lock
from typing import Any

_lock = Lock()
TRACKING_FILE = os.path.join(os.path.dirname(__file__), "tracking_data.json")
MAX_EVENTS = 10000
MAX_REQUEST_LOGS = 5000
MAX_USER_EVENTS = 120
USERS_LIMIT = 250

REVENUE_EVENTS = {
    "subscription_purchased",
    "trial_converted",
    "subscription_renewed",
    "lifetime_purchased",
}


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _parse_iso(value: str | None) -> datetime:
    if not value:
        return datetime.min.replace(tzinfo=timezone.utc)
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return datetime.min.replace(tzinfo=timezone.utc)


def _default_store() -> dict[str, Any]:
    return {
        "events": [],
        "users": {},
        "processed_webhooks": {},
        "request_logs": [],
    }


def _load_store() -> dict[str, Any]:
    if not os.path.exists(TRACKING_FILE):
        return _default_store()

    try:
        with open(TRACKING_FILE, "r") as f:
            data = json.load(f)
    except (json.JSONDecodeError, IOError):
        return _default_store()

    merged = _default_store()
    merged.update(data)
    if not isinstance(merged.get("events"), list):
        merged["events"] = []
    if not isinstance(merged.get("users"), dict):
        merged["users"] = {}
    if not isinstance(merged.get("processed_webhooks"), dict):
        merged["processed_webhooks"] = {}
    if not isinstance(merged.get("request_logs"), list):
        merged["request_logs"] = []
    return merged


def _save_store(store: dict[str, Any]) -> None:
    with open(TRACKING_FILE, "w") as f:
        json.dump(store, f, indent=2)


def _default_user(user_id: str, platform: str, app_version: str | None, timestamp: str) -> dict[str, Any]:
    return {
        "user_id": user_id,
        "platform": platform,
        "app_version": app_version,
        "first_seen": timestamp,
        "last_seen": timestamp,
        "event_count": 0,
        "event_counts": {},
        "last_event": None,
        "last_properties": {},
        "subscription_status": "free",
        "purchase_count": 0,
        "current_plan": None,
        "plan_type": "free",
        "country": None,
        "total_revenue": 0.0,
        "total_revenue_usd": 0.0,
        "revenue_currency": "USD",
        "events": [],
    }


def _derive_plan_type(product_id: str | None) -> str:
    if not product_id:
        return "free"
    lowered = product_id.lower()
    if "week" in lowered:
        return "weekly"
    if "month" in lowered:
        return "monthly"
    if "year" in lowered or "annual" in lowered:
        return "yearly"
    if "life" in lowered or "forever" in lowered:
        return "lifetime"
    return "one_time"


def _rc_event_name(event_type: str, period_type: str | None, is_trial_conversion: bool = False) -> str:
    is_trial = (period_type or "").upper() == "TRIAL"
    mapping = {
        "INITIAL_PURCHASE": "trial_started" if is_trial else "subscription_purchased",
        "NON_RENEWING_PURCHASE": "lifetime_purchased",
        "RENEWAL": "trial_converted" if is_trial_conversion else "subscription_renewed",
        "CANCELLATION": "trial_cancelled" if is_trial else "subscription_cancelled",
        "UNCANCELLATION": "trial_reactivated" if is_trial else "subscription_reactivated",
        "EXPIRATION": "trial_expired" if is_trial else "subscription_expired",
        "BILLING_ISSUE": "billing_issue",
        "PRODUCT_CHANGE": "plan_changed",
        "SUBSCRIPTION_PAUSED": "subscription_paused",
        "REFUND_REVERSED": "refund_reversed",
    }
    return mapping.get(event_type, f"rc_{event_type.lower()}")


def _rc_status(event_type: str, period_type: str | None) -> str | None:
    is_trial = (period_type or "").upper() == "TRIAL"
    mapping = {
        "INITIAL_PURCHASE": "trial" if is_trial else "subscribed",
        "NON_RENEWING_PURCHASE": "lifetime",
        "RENEWAL": "subscribed",
        "CANCELLATION": "trial_cancelled" if is_trial else "cancelled",
        "UNCANCELLATION": "trial" if is_trial else "subscribed",
        "EXPIRATION": "expired",
        "BILLING_ISSUE": "billing_issue",
    }
    return mapping.get(event_type)


def _append_event(store: dict[str, Any], event_item: dict[str, Any]) -> None:
    store["events"].append(event_item)
    store["events"] = store["events"][-MAX_EVENTS:]


def _append_user_event(user: dict[str, Any], event_item: dict[str, Any]) -> None:
    user_events = user.get("events", [])
    user_events.append(
        {
            "event": event_item["event"],
            "properties": event_item.get("properties", {}),
            "ts": event_item["timestamp"],
        }
    )
    user["events"] = user_events[-MAX_USER_EVENTS:]


def _update_user_from_event(
    user: dict[str, Any],
    event_item: dict[str, Any],
    *,
    country: str | None = None,
) -> None:
    event = event_item["event"]
    props = event_item.get("properties", {}) or {}

    user["platform"] = event_item.get("platform") or user.get("platform", "ios")
    user["app_version"] = event_item.get("app_version") or user.get("app_version")
    user["last_seen"] = event_item["timestamp"]
    user["last_event"] = event
    user["last_properties"] = props
    user["event_count"] = int(user.get("event_count", 0)) + 1
    if country:
        user["country"] = country

    counts = user.get("event_counts", {})
    counts[event] = int(counts.get(event, 0)) + 1
    user["event_counts"] = counts

    if event == "first_install" and not user.get("first_seen"):
        user["first_seen"] = event_item["timestamp"]

    if event == "paywall_shown" and user.get("subscription_status") in {None, "unknown"}:
        user["subscription_status"] = "free"

    if event in {"purchase_completed", "subscription_purchased", "trial_converted", "subscription_renewed"}:
        user["subscription_status"] = "subscribed"
        user["purchase_count"] = int(user.get("purchase_count", 0)) + 1
        plan = props.get("plan")
        if plan:
            user["current_plan"] = plan
            user["plan_type"] = _derive_plan_type(plan)

    if event == "lifetime_purchased":
        user["subscription_status"] = "lifetime"
        user["purchase_count"] = int(user.get("purchase_count", 0)) + 1
        plan = props.get("plan")
        if plan:
            user["current_plan"] = plan
        user["plan_type"] = "lifetime"

    if event in {"trial_started", "trial_reactivated"}:
        user["subscription_status"] = "trial"
    elif event == "trial_cancelled":
        user["subscription_status"] = "trial_cancelled"
    elif event == "subscription_cancelled":
        user["subscription_status"] = "cancelled"
    elif event in {"trial_expired", "subscription_expired"}:
        user["subscription_status"] = "expired"
    elif event == "billing_issue":
        user["subscription_status"] = "billing_issue"

    revenue = float(props.get("price", 0) or 0)
    revenue_usd = float(props.get("price_usd", 0) or 0)
    if revenue > 0 and event in REVENUE_EVENTS:
        user["total_revenue"] = round(float(user.get("total_revenue", 0.0)) + revenue, 6)
        if props.get("currency"):
            user["revenue_currency"] = props["currency"]
    if revenue_usd > 0 and event in REVENUE_EVENTS:
        user["total_revenue_usd"] = round(float(user.get("total_revenue_usd", 0.0)) + revenue_usd, 6)

    _append_user_event(user, event_item)


def record_event(
    user_id: str,
    event: str,
    properties: dict[str, Any] | None = None,
    platform: str = "ios",
    app_version: str | None = None,
    country: str | None = None,
) -> dict[str, Any]:
    properties = properties or {}
    timestamp = _now_iso()
    event_item = {
        "user_id": user_id,
        "event": event,
        "properties": properties,
        "platform": platform,
        "app_version": app_version,
        "timestamp": timestamp,
    }

    with _lock:
        store = _load_store()
        _append_event(store, event_item)
        user = store["users"].get(user_id) or _default_user(user_id, platform, app_version, timestamp)
        _update_user_from_event(user, event_item, country=country)
        store["users"][user_id] = user
        _save_store(store)
    return event_item


def record_request(
    user_id: str,
    endpoint: str,
    properties: dict[str, Any] | None = None,
    platform: str = "ios",
    app_version: str | None = None,
    country: str | None = None,
) -> dict[str, Any]:
    properties = properties or {}
    timestamp = _now_iso()
    log_item = {
        "user_id": user_id,
        "endpoint": endpoint,
        "properties": properties,
        "platform": platform,
        "app_version": app_version,
        "country": country,
        "timestamp": timestamp,
    }
    synthetic_event = {
        "user_id": user_id,
        "event": f"request_{endpoint}",
        "properties": {"endpoint": endpoint, **properties},
        "platform": platform,
        "app_version": app_version,
        "timestamp": timestamp,
    }

    with _lock:
        store = _load_store()
        store["request_logs"].append(log_item)
        store["request_logs"] = store["request_logs"][-MAX_REQUEST_LOGS:]
        _append_event(store, synthetic_event)
        user = store["users"].get(user_id) or _default_user(user_id, platform, app_version, timestamp)
        _update_user_from_event(user, synthetic_event, country=country)
        store["users"][user_id] = user
        _save_store(store)
    return log_item


def record_revenuecat_webhook(payload: dict[str, Any]) -> dict[str, Any]:
    event = payload.get("event") or payload
    if not isinstance(event, dict) or not event.get("type"):
        raise ValueError("Invalid RevenueCat webhook payload")

    event_type = event["type"]
    if event_type == "TEST":
        return {"success": True, "skipped": True, "reason": "test_event"}

    user_id = event.get("app_user_id")
    if not user_id:
        return {"success": True, "skipped": True, "reason": "missing_user_id"}

    event_id = event.get("id")
    period_type = event.get("period_type")
    mapped_event = _rc_event_name(event_type, period_type, bool(event.get("is_trial_conversion")))
    price = float(event.get("price_in_purchased_currency") or 0)
    price_usd = float(event.get("price") or 0)
    currency = event.get("currency") or "USD"
    properties = {
        "plan": event.get("product_id") or "",
        "period": period_type or "",
        "currency": currency,
        "cancel_reason": event.get("cancel_reason"),
        "expiration_reason": event.get("expiration_reason"),
        "trial_conversion": bool(event.get("is_trial_conversion")),
    }
    if price > 0:
        properties["price"] = price
    if price_usd > 0:
        properties["price_usd"] = price_usd

    timestamp = _now_iso()
    event_item = {
        "user_id": user_id,
        "event": mapped_event,
        "properties": properties,
        "platform": "revenuecat",
        "app_version": None,
        "timestamp": timestamp,
    }

    with _lock:
        store = _load_store()
        if event_id and event_id in store["processed_webhooks"]:
            return {"success": True, "duplicate": True, "event": mapped_event}
        if event_id:
            store["processed_webhooks"][event_id] = {"timestamp": timestamp, "type": event_type, "user_id": user_id}

        _append_event(store, event_item)
        user = store["users"].get(user_id) or _default_user(user_id, "ios", None, timestamp)
        status = _rc_status(event_type, period_type)
        if status:
            user["subscription_status"] = status
        if properties.get("plan"):
            user["current_plan"] = properties["plan"]
            user["plan_type"] = _derive_plan_type(properties["plan"])
        _update_user_from_event(user, event_item)
        store["users"][user_id] = user
        _save_store(store)
    return {"success": True, "event": mapped_event, "user_id": user_id}


def _event_in_range(item: dict[str, Any], start: datetime | None, end: datetime | None) -> bool:
    ts = _parse_iso(item.get("timestamp") or item.get("ts"))
    if start and ts < start:
        return False
    if end and ts > end:
        return False
    return True


def _user_has_range_activity(user: dict[str, Any], start: datetime | None, end: datetime | None) -> bool:
    if not start and not end:
        return True
    return any(_event_in_range(event, start, end) for event in user.get("events", []))


def _feature_key_for_event(event: dict[str, Any]) -> str | None:
    name = event.get("event")
    props = event.get("properties") or {}
    if name == "ai_generation_completed":
        return "AI Stories"
    if name == "export_completed":
        return f"Export {str(props.get('format', 'video')).title()}"
    if name == "paywall_shown":
        return f"Paywall {str(props.get('source', 'unknown')).replace('_', ' ').title()}"
    if name == "conversation_created":
        return "Group Stories" if props.get("is_group_chat") == "true" else "1-on-1 Stories"
    if name == "tab_selected" and props.get("tab"):
        return f"Tab {str(props['tab']).title()}"
    if name and name.startswith("request_"):
        return str(props.get("endpoint", name.replace("request_", ""))).replace("_", " ").title()
    return None


def get_admin_stats(
    start_date: datetime | None = None,
    end_date: datetime | None = None,
    limit: int = USERS_LIMIT,
) -> dict[str, Any]:
    with _lock:
        store = _load_store()

    all_events = [event for event in store["events"] if _event_in_range(event, start_date, end_date)]
    request_logs = [log for log in store.get("request_logs", []) if _event_in_range(log, start_date, end_date)]
    users = list(store["users"].values())

    filtered_users = [user for user in users if _user_has_range_activity(user, start_date, end_date)]
    filtered_users.sort(key=lambda item: item.get("last_seen", ""), reverse=True)
    filtered_users = filtered_users[: max(1, min(limit, USERS_LIMIT))]

    by_endpoint: Counter[str] = Counter()
    for log in request_logs:
        by_endpoint[log.get("endpoint", "unknown")] += 1

    by_event: Counter[str] = Counter()
    by_feature: Counter[str] = Counter()
    active_users = 0
    new_users = 0
    total_revenue = 0.0
    for user in filtered_users:
        if user.get("last_seen"):
            active_users += 1

    for event in all_events:
        event_name = event.get("event")
        if not event_name:
            continue
        by_event[event_name] += 1
        feature_key = _feature_key_for_event(event)
        if feature_key:
            by_feature[feature_key] += 1
        if event_name == "first_install":
            new_users += 1
        if event_name in REVENUE_EVENTS:
            props = event.get("properties") or {}
            amount = float(props.get("price_usd") or 0)
            if amount <= 0 and (props.get("currency") in {None, "", "USD"}):
                amount = float(props.get("price") or 0)
            total_revenue += amount

    result_users = []
    for user in filtered_users:
        user_events = [event for event in user.get("events", []) if _event_in_range(event, start_date, end_date)]
        result_users.append(
            {
                "userId": user.get("user_id"),
                "firstSeen": user.get("first_seen"),
                "lastSeen": user.get("last_seen"),
                "lastEvent": user.get("last_event"),
                "subscriptionStatus": user.get("subscription_status", "free"),
                "country": user.get("country"),
                "planType": user.get("plan_type", "free"),
                "currentPlan": user.get("current_plan"),
                "totalRevenue": round(float(user.get("total_revenue", 0.0)), 2),
                "totalRevenueUsd": round(float(user.get("total_revenue_usd", 0.0)), 2),
                "revenueCurrency": user.get("revenue_currency", "USD"),
                "eventCount": user.get("event_count", 0),
                "purchaseCount": user.get("purchase_count", 0),
                "events": list(reversed(user_events[-50:])),
            }
        )

    return {
        "success": True,
        "summary": {
            "activeUsers": active_users,
            "newUsers": new_users,
            "periodRequests": len(request_logs),
            "totalRevenue": round(total_revenue, 2),
        },
        "byEndpoint": dict(by_endpoint),
        "featureBreakdown": [
            {"feature": feature, "count": count}
            for feature, count in sorted(by_feature.items(), key=lambda item: item[1], reverse=True)
        ],
        "eventBreakdown": [
            {"event": event, "count": count}
            for event, count in sorted(by_event.items(), key=lambda item: item[1], reverse=True)
        ],
        "users": result_users,
    }


def get_dashboard_summary() -> dict[str, Any]:
    return get_admin_stats()


def get_users(limit: int = USERS_LIMIT) -> list[dict[str, Any]]:
    with _lock:
        store = _load_store()
    users = list(store["users"].values())
    users.sort(key=lambda item: item.get("last_seen", ""), reverse=True)
    return users[:limit]


def delete_user(user_id: str) -> dict[str, Any]:
    with _lock:
        store = _load_store()
        if user_id in store["users"]:
            del store["users"][user_id]
        store["events"] = [event for event in store["events"] if event.get("user_id") != user_id]
        store["request_logs"] = [log for log in store.get("request_logs", []) if log.get("user_id") != user_id]
        _save_store(store)
    return {"success": True, "deleted": user_id}
