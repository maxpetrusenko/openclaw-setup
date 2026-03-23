#!/usr/bin/env python3
"""
Publish or schedule a multi-platform campaign post via GetLate.

Features:
- Resolves active/inactive/missing accounts by platform
- Uploads media via /v1/media/presign
- Supports Instagram Story posting (vertical image)
- Returns OAuth connect URLs for missing/inactive platforms
- Writes detailed run logs for success/failure analysis
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import mimetypes
import os
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

BASE_URL = "https://getlate.dev/api/v1"

PLATFORM_ALIASES = {
    "x": "twitter",
    "twitter": "twitter",
    "ig": "instagram",
    "instagram": "instagram",
    "fb": "facebook",
    "facebook": "facebook",
    "linkedin": "linkedin",
    "tiktok": "tiktok",
    "tt": "tiktok",
    "youtube": "youtube",
    "yt": "youtube",
}


def load_env_file(path: Path) -> None:
    if not path.exists():
        return
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip())


def api_request(
    method: str,
    path: str,
    token: str,
    query: Optional[Dict[str, Any]] = None,
    body: Optional[Dict[str, Any]] = None,
    headers: Optional[Dict[str, str]] = None,
) -> Tuple[int, Dict[str, Any], str]:
    params = ""
    if query:
        params = "?" + urllib.parse.urlencode({k: v for k, v in query.items() if v is not None})
    url = f"{BASE_URL}{path}{params}"
    req_headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    if headers:
        req_headers.update(headers)
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, headers=req_headers, method=method.upper())
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            text = resp.read().decode("utf-8")
            parsed = {}
            if text:
                try:
                    parsed = json.loads(text)
                except json.JSONDecodeError:
                    parsed = {"raw": text}
            return resp.status, parsed, text
    except urllib.error.HTTPError as e:
        text = e.read().decode("utf-8")
        parsed = {}
        if text:
            try:
                parsed = json.loads(text)
            except json.JSONDecodeError:
                parsed = {"raw": text}
        return e.code, parsed, text


def upload_media(token: str, file_path: Path) -> str:
    if not file_path.exists():
        raise FileNotFoundError(f"Media file not found: {file_path}")
    mime = mimetypes.guess_type(str(file_path))[0] or "application/octet-stream"
    size = file_path.stat().st_size
    presign_body = {"filename": file_path.name, "contentType": mime, "size": size}
    status, data, _ = api_request("POST", "/media/presign", token, body=presign_body)
    if status != 200:
        raise RuntimeError(f"Failed to get presigned URL ({status}): {data}")
    upload_url = data.get("uploadUrl")
    public_url = data.get("publicUrl")
    if not upload_url or not public_url:
        raise RuntimeError(f"Missing upload/public URL in presign response: {data}")

    blob = file_path.read_bytes()
    put_req = urllib.request.Request(upload_url, data=blob, method="PUT", headers={"Content-Type": mime})
    try:
        with urllib.request.urlopen(put_req, timeout=120) as resp:
            if resp.status < 200 or resp.status >= 300:
                raise RuntimeError(f"Upload failed with status {resp.status}")
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"Upload failed ({e.code}): {e.read().decode('utf-8', errors='ignore')}") from e
    return str(public_url)


def normalize_platforms(raw: str) -> List[str]:
    out = []
    for part in raw.split(","):
        p = part.strip().lower()
        if not p:
            continue
        mapped = PLATFORM_ALIASES.get(p, p)
        if mapped not in out:
            out.append(mapped)
    return out


def get_profile_id(accounts: List[Dict[str, Any]], token: str) -> Optional[str]:
    for acc in accounts:
        profile = acc.get("profileId")
        if isinstance(profile, dict) and profile.get("_id"):
            return str(profile["_id"])
        if isinstance(profile, str) and profile:
            return profile
    status, data, _ = api_request("GET", "/profiles", token)
    if status == 200:
        profiles = data.get("profiles") or []
        if profiles and isinstance(profiles[0], dict):
            return profiles[0].get("_id")
    return None


def find_account(accounts: List[Dict[str, Any]], platform: str, include_inactive: bool) -> Tuple[Optional[Dict[str, Any]], str]:
    same = [a for a in accounts if str(a.get("platform", "")).lower() == platform]
    active = [a for a in same if a.get("isActive") is True]
    inactive = [a for a in same if a.get("isActive") is False]
    if active:
        return active[0], "active"
    if include_inactive and inactive:
        return inactive[0], "inactive"
    if inactive:
        return None, "inactive_unselected"
    return None, "missing"


def trim_text(text: str, n: int) -> str:
    clean = " ".join(text.split())
    return clean if len(clean) <= n else clean[: max(0, n - 1)] + "…"


def main() -> int:
    parser = argparse.ArgumentParser(description="Publish campaign posts to GetLate platforms.")
    parser.add_argument("--topic", required=True, help="Campaign topic")
    parser.add_argument("--platforms", default="linkedin,facebook,instagram,x,tiktok,youtube", help="Comma-separated platforms")
    parser.add_argument("--assets-manifest", help="Path to manifest.json from generate_social_assets.py")
    parser.add_argument("--feed-image", help="Feed image path (landscape/square)")
    parser.add_argument("--story-image", help="Story vertical image path")
    parser.add_argument("--youtube-video", help="YouTube video file path (optional)")
    parser.add_argument("--caption", help="Override post caption")
    parser.add_argument("--publish-now", action="store_true", help="Publish immediately")
    parser.add_argument("--scheduled-for", help="ISO datetime for schedule (if not publish-now)")
    parser.add_argument("--timezone", default="America/New_York")
    parser.add_argument("--api-key-env", default="GETLATE_API_KEY")
    parser.add_argument("--api-key", help="GetLate API key override")
    parser.add_argument("--attempt-inactive", action="store_true", help="Try posting on inactive connected accounts too")
    parser.add_argument("--tiktok-privacy-level", default="PUBLIC_TO_EVERYONE")
    parser.add_argument("--poll-attempts", type=int, default=8)
    parser.add_argument("--poll-interval", type=int, default=6)
    parser.add_argument("--log-dir", default="", help="Directory for run logs (auto: ./clawdbot/tmp or ./tmp)")
    args = parser.parse_args()

    load_env_file(Path(".env"))

    token = args.api_key or os.getenv(args.api_key_env) or os.getenv("GETLATE_DEV_API_KEY_LIFETIME")
    if not token:
        raise SystemExit("Missing GetLate API key. Set GETLATE_API_KEY or pass --api-key.")

    requested = normalize_platforms(args.platforms)
    status, account_data, _ = api_request("GET", "/accounts", token, query={"includeOverLimit": "true"})
    if status != 200:
        raise SystemExit(f"Failed to list accounts: HTTP {status} {account_data}")
    accounts = account_data.get("accounts", [])

    profile_id = get_profile_id(accounts, token)

    manifest: Dict[str, Any] = {}
    if args.assets_manifest:
        manifest_path = Path(args.assets_manifest).expanduser().resolve()
        if not manifest_path.exists():
            raise SystemExit(f"Manifest not found: {manifest_path}")
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

    manifest_assets = manifest.get("assets", {}) if isinstance(manifest, dict) else {}
    feed_image_path = Path(args.feed_image).expanduser().resolve() if args.feed_image else None
    story_image_path = Path(args.story_image).expanduser().resolve() if args.story_image else None
    youtube_video_path = Path(args.youtube_video).expanduser().resolve() if args.youtube_video else None

    if feed_image_path is None and isinstance(manifest_assets, dict):
        if manifest_assets.get("feed_square"):
            feed_image_path = Path(str(manifest_assets["feed_square"])).expanduser().resolve()
        elif manifest_assets.get("feed_landscape"):
            feed_image_path = Path(str(manifest_assets["feed_landscape"])).expanduser().resolve()
    if story_image_path is None and isinstance(manifest_assets, dict) and manifest_assets.get("story_vertical"):
        story_image_path = Path(str(manifest_assets["story_vertical"])).expanduser().resolve()

    copy = manifest.get("copy", {}) if isinstance(manifest, dict) else {}
    caption_long = args.caption or str(copy.get("caption_long") or copy.get("caption_short") or args.topic)
    hashtags = copy.get("hashtags") if isinstance(copy, dict) else []
    if isinstance(hashtags, list) and hashtags:
        caption_long = f"{caption_long} {' '.join(str(h).strip() for h in hashtags if str(h).strip())}".strip()
    caption_twitter = trim_text(str(copy.get("caption_short") or caption_long), 260)

    if args.log_dir:
        log_dir = Path(args.log_dir).expanduser().resolve()
    else:
        if Path("./clawdbot/AGENTS.md").exists():
            log_dir = Path("./clawdbot/tmp").resolve()
        else:
            log_dir = Path("./tmp").resolve()
    log_dir.mkdir(parents=True, exist_ok=True)
    stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    log_path = log_dir / f"getlate-campaign-{stamp}-{os.getpid()}.json"

    uploads: Dict[str, str] = {}
    upload_errors: Dict[str, str] = {}

    if feed_image_path:
        try:
            uploads["feed_image_url"] = upload_media(token, feed_image_path)
        except Exception as e:
            upload_errors["feed"] = str(e)
    if story_image_path:
        try:
            uploads["story_image_url"] = upload_media(token, story_image_path)
        except Exception as e:
            upload_errors["story"] = str(e)
    if youtube_video_path:
        try:
            uploads["youtube_video_url"] = upload_media(token, youtube_video_path)
        except Exception as e:
            upload_errors["youtube_video"] = str(e)

    connect_urls: Dict[str, Any] = {}
    selected_targets: List[Dict[str, Any]] = []
    skipped: List[Dict[str, str]] = []
    payload_platforms: List[Dict[str, Any]] = []

    for platform in requested:
        account, account_state = find_account(accounts, platform, include_inactive=args.attempt_inactive)
        if not account:
            if account_state in {"missing", "inactive_unselected"} and profile_id:
                c_status, c_data, _ = api_request(
                    "GET",
                    f"/connect/{platform}",
                    token,
                    query={"profileId": profile_id, "redirect_url": "https://getlate.dev/dashboard"},
                )
                connect_urls[platform] = {"http": c_status, "response": c_data}
            skipped.append({"platform": platform, "reason": account_state})
            continue

        account_id = str(account.get("_id"))
        target: Dict[str, Any] = {"platform": platform, "accountId": account_id}
        reason = ""

        if platform == "instagram":
            media_url = uploads.get("story_image_url") or uploads.get("feed_image_url")
            if not media_url:
                reason = "no_story_or_feed_image"
            else:
                target["customMedia"] = [{"type": "image", "url": media_url}]
                target["customContent"] = ""
                target["platformSpecificData"] = {"contentType": "story"}
        elif platform == "youtube":
            media_url = uploads.get("youtube_video_url")
            if not media_url:
                reason = "youtube_requires_video"
            else:
                target["customMedia"] = [{"type": "video", "url": media_url}]
                target["platformSpecificData"] = {
                    "title": trim_text(args.topic, 90),
                    "visibility": "public",
                    "madeForKids": False,
                }
        elif platform == "tiktok":
            media_url = uploads.get("feed_image_url") or uploads.get("story_image_url")
            if not media_url:
                reason = "no_media_for_tiktok"
            else:
                target["customMedia"] = [{"type": "image", "url": media_url}]
                target["customContent"] = trim_text(caption_twitter, 90)
                target["platformSpecificData"] = {
                    "mediaType": "photo",
                    "privacyLevel": args.tiktok_privacy_level,
                    "allowComment": True,
                    "contentPreviewConfirmed": True,
                    "expressConsentGiven": True,
                }
        else:
            media_url = uploads.get("feed_image_url")
            if media_url:
                target["customMedia"] = [{"type": "image", "url": media_url}]
            if platform == "twitter":
                target["customContent"] = caption_twitter

        if reason:
            skipped.append({"platform": platform, "reason": reason})
            continue

        payload_platforms.append(target)
        selected_targets.append(
            {
                "platform": platform,
                "accountId": account_id,
                "accountState": account_state,
                "displayName": account.get("displayName"),
                "username": account.get("username"),
            }
        )

    summary: Dict[str, Any] = {
        "timestampUtc": dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "topic": args.topic,
        "requestedPlatforms": requested,
        "selectedTargets": selected_targets,
        "skipped": skipped,
        "connectUrls": connect_urls,
        "uploadErrors": upload_errors,
        "uploads": uploads,
        "logPath": str(log_path),
    }

    if not payload_platforms:
        summary["result"] = "no_publishable_targets"
        log_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")
        print(json.dumps(summary, indent=2))
        return 0

    post_payload: Dict[str, Any] = {
        "content": caption_long,
        "platforms": payload_platforms,
        "publishNow": bool(args.publish_now),
        "timezone": args.timezone,
        "crosspostingEnabled": False,
    }
    if uploads.get("feed_image_url"):
        post_payload["mediaItems"] = [{"type": "image", "url": uploads["feed_image_url"]}]
    if not args.publish_now:
        if args.scheduled_for:
            post_payload["scheduledFor"] = args.scheduled_for
        else:
            post_payload["scheduledFor"] = (
                dt.datetime.now(dt.timezone.utc) + dt.timedelta(minutes=30)
            ).strftime("%Y-%m-%dT%H:%M:%SZ")

    create_status, create_data, create_raw = api_request("POST", "/posts", token, body=post_payload)
    summary["createPostHttp"] = create_status
    summary["createPostResponse"] = create_data if create_data else {"raw": create_raw[:1500]}

    post_id = None
    if isinstance(create_data, dict):
        post_id = (create_data.get("post") or {}).get("_id")
    if not post_id:
        summary["result"] = "create_failed"
        log_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")
        print(json.dumps(summary, indent=2))
        return 0

    summary["postId"] = post_id
    final_post = None
    for _ in range(max(1, args.poll_attempts)):
        get_status, get_data, _ = api_request("GET", f"/posts/{post_id}", token)
        if get_status != 200:
            time.sleep(max(1, args.poll_interval))
            continue
        post = get_data.get("post", {})
        platforms = post.get("platforms", [])
        terminal = True
        for item in platforms:
            st = str(item.get("status", "")).lower()
            if st in {"pending", "publishing"}:
                terminal = False
                break
        final_post = post
        if terminal:
            break
        time.sleep(max(1, args.poll_interval))

    summary["finalPost"] = final_post
    summary["result"] = "ok"
    if final_post:
        summary["platformStatus"] = [
            {
                "platform": p.get("platform"),
                "status": p.get("status"),
                "errorMessage": p.get("errorMessage"),
                "platformPostUrl": p.get("platformPostUrl"),
            }
            for p in final_post.get("platforms", [])
        ]

    log_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
