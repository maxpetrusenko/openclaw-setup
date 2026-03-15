#!/usr/bin/env python3
"""
Generate social images with short text overlays.

Outputs:
- feed_landscape.png (1200x675)
- feed_square.png (1080x1080)
- story_vertical.png (1080x1920) for Instagram Story
- manifest.json
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import re
import shutil
import textwrap
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Dict, Tuple

from PIL import Image, ImageDraw, ImageFont


def load_env_file(path: Path) -> None:
    if not path.exists():
        return
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip())


def pick_palette(topic: str) -> Tuple[Tuple[int, int, int], Tuple[int, int, int]]:
    digest = hashlib.sha256(topic.encode("utf-8")).hexdigest()
    a = int(digest[0:6], 16)
    b = int(digest[6:12], 16)
    c1 = (50 + (a >> 16) % 150, 40 + (a >> 8) % 150, 50 + a % 120)
    c2 = (40 + (b >> 16) % 160, 60 + (b >> 8) % 130, 70 + b % 140)
    return c1, c2


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = []
    if bold:
        candidates.extend(
            [
                "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
                "/System/Library/Fonts/Supplemental/Helvetica.ttc",
                "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
            ]
        )
    candidates.extend(
        [
            "/System/Library/Fonts/Supplemental/Arial.ttf",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        ]
    )
    for path in candidates:
        p = Path(path)
        if p.exists():
            try:
                return ImageFont.truetype(str(p), size=size)
            except Exception:
                continue
    return ImageFont.load_default()


def wrap_text(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.ImageFont, max_width: int) -> str:
    words = text.split()
    if not words:
        return ""
    lines = []
    current = words[0]
    for word in words[1:]:
        probe = f"{current} {word}"
        left, top, right, bottom = draw.textbbox((0, 0), probe, font=font)
        if (right - left) <= max_width:
            current = probe
        else:
            lines.append(current)
            current = word
    lines.append(current)
    return "\n".join(lines)


def draw_gradient(width: int, height: int, c1: Tuple[int, int, int], c2: Tuple[int, int, int]) -> Image.Image:
    img = Image.new("RGB", (width, height), c1)
    draw = ImageDraw.Draw(img)
    for y in range(height):
        t = y / max(height - 1, 1)
        col = (
            int(c1[0] * (1 - t) + c2[0] * t),
            int(c1[1] * (1 - t) + c2[1] * t),
            int(c1[2] * (1 - t) + c2[2] * t),
        )
        draw.line([(0, y), (width, y)], fill=col)
    return img


def draw_card(img: Image.Image, title: str, subtitle: str, compact: bool = False) -> None:
    draw = ImageDraw.Draw(img, "RGBA")
    w, h = img.size
    pad = int(min(w, h) * 0.06)

    # translucent content panel
    panel_h = int(h * (0.42 if compact else 0.36))
    panel_top = h - panel_h - pad
    draw.rounded_rectangle(
        [pad, panel_top, w - pad, h - pad],
        radius=int(min(w, h) * 0.025),
        fill=(8, 10, 18, 145),
    )

    title_font = load_font(int(h * (0.07 if compact else 0.06)), bold=True)
    sub_font = load_font(int(h * (0.034 if compact else 0.028)), bold=False)

    max_text_width = w - (pad * 3)
    wrapped_title = wrap_text(draw, title.strip(), title_font, max_text_width)
    wrapped_sub = wrap_text(draw, subtitle.strip(), sub_font, max_text_width)

    x = pad * 2
    y = panel_top + int(pad * 0.8)
    draw.multiline_text((x, y), wrapped_title, font=title_font, fill=(245, 248, 255, 255), spacing=6)
    title_box = draw.multiline_textbbox((x, y), wrapped_title, font=title_font, spacing=6)
    y = title_box[3] + int(pad * 0.5)
    draw.multiline_text((x, y), wrapped_sub, font=sub_font, fill=(225, 231, 240, 240), spacing=4)


def parse_json_object(raw: str) -> Dict[str, object] | None:
    raw = raw.strip()
    try:
        parsed = json.loads(raw)
        if isinstance(parsed, dict):
            return parsed
    except Exception:
        pass
    m = re.search(r"\{.*\}", raw, re.DOTALL)
    if not m:
        return None
    try:
        parsed = json.loads(m.group(0))
    except Exception:
        return None
    return parsed if isinstance(parsed, dict) else None


def gemini_copy(topic: str, model: str, key: str) -> Dict[str, object] | None:
    prompt = (
        "Create social copy for a post topic.\n"
        "Return strict JSON only with keys:\n"
        "- headline (<= 9 words)\n"
        "- story_overlay (<= 4 words)\n"
        "- caption_short (<= 220 chars)\n"
        "- caption_long (<= 600 chars)\n"
        "- hashtags (array of up to 5 tags, include #)\n\n"
        f"Topic: {topic}"
    )
    body = json.dumps({"contents": [{"parts": [{"text": prompt}]}]}).encode("utf-8")
    url = (
        f"https://generativelanguage.googleapis.com/v1beta/models/"
        f"{urllib.parse.quote(model, safe='')}:generateContent?key={urllib.parse.quote(key)}"
    )
    req = urllib.request.Request(
        url,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=35) as resp:
            data = json.loads(resp.read().decode("utf-8"))
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError):
        return None

    text = ""
    try:
        text = data["candidates"][0]["content"]["parts"][0]["text"]
    except Exception:
        return None
    return parse_json_object(text)


def fallback_copy(topic: str) -> Dict[str, object]:
    return {
        "headline": f"{topic} in Practice",
        "story_overlay": topic.split()[0][:16] if topic.split() else "Update",
        "caption_short": f"{topic}: practical gains from multimodal reasoning are now shipping into daily workflows.",
        "caption_long": (
            f"{topic} is becoming practical for real product work. "
            "Teams can iterate faster across text, vision, and reasoning in a single loop. "
            "The advantage now is execution speed and tighter feedback cycles."
        ),
        "hashtags": ["#AI", "#Gemini", "#Product", "#Automation"],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate social assets for campaign posts.")
    parser.add_argument("--topic", required=True, help="Campaign topic")
    parser.add_argument("--output-dir", default="./clawdbot/tmp/social-assets", help="Output root directory")
    parser.add_argument("--model", default="gemini-2.5-flash", help="Gemini model for copy generation")
    parser.add_argument("--gemini-env", default="Gemini_token_max", help="Primary Gemini key env var")
    parser.add_argument("--gemini-fallback-env", default="gemini_token_turkey", help="Fallback Gemini key env var")
    parser.add_argument("--skip-gemini", action="store_true", help="Disable Gemini copy generation")
    args = parser.parse_args()

    load_env_file(Path(".env"))

    out_root = Path(args.output_dir).expanduser().resolve()
    stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    run_dir = out_root / stamp
    run_dir.mkdir(parents=True, exist_ok=True)

    copy = None
    if not args.skip_gemini:
        key = os.getenv(args.gemini_env) or os.getenv(args.gemini_fallback_env)
        if key:
            copy = gemini_copy(args.topic, args.model, key)
    if not copy:
        copy = fallback_copy(args.topic)

    headline = str(copy.get("headline", args.topic)).strip()
    story_overlay = str(copy.get("story_overlay", headline)).strip()
    caption_short = str(copy.get("caption_short", "")).strip()
    caption_long = str(copy.get("caption_long", caption_short)).strip()
    hashtags = copy.get("hashtags", [])
    if not isinstance(hashtags, list):
        hashtags = []
    hashtags = [str(tag).strip() for tag in hashtags if str(tag).strip()]

    c1, c2 = pick_palette(args.topic)
    assets = {
        "feed_landscape": ("feed_landscape.png", (1200, 675), headline, caption_short),
        "feed_square": ("feed_square.png", (1080, 1080), headline, caption_short),
        "story_vertical": ("story_vertical.png", (1080, 1920), story_overlay, "Swipe for details"),
    }

    file_map: Dict[str, str] = {}
    for key, (filename, size, title, subtitle) in assets.items():
        img = draw_gradient(size[0], size[1], c1, c2)
        draw_card(img, title, subtitle, compact=(key == "story_vertical"))
        out_path = run_dir / filename
        img.save(out_path, format="PNG")
        file_map[key] = str(out_path)

    manifest = {
        "topic": args.topic,
        "generatedAt": dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "copy": {
            "headline": headline,
            "story_overlay": story_overlay,
            "caption_short": caption_short,
            "caption_long": caption_long,
            "hashtags": hashtags,
        },
        "assets": file_map,
    }
    manifest_path = run_dir / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    latest_dir = out_root / "latest"
    if latest_dir.exists():
        shutil.rmtree(latest_dir)
    latest_dir.mkdir(parents=True, exist_ok=True)
    for file_name in ["feed_landscape.png", "feed_square.png", "story_vertical.png", "manifest.json"]:
        shutil.copy2(run_dir / file_name, latest_dir / file_name)

    print(json.dumps({"runDir": str(run_dir), "latestDir": str(latest_dir), "manifest": str(manifest_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
