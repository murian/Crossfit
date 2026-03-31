#!/usr/bin/env python3
"""
Polaroid Photo Formatter
========================
Transforms photos into classic Polaroid format (10cm x 15cm at 300 DPI)
with location and date text extracted from EXIF metadata.

Supports batch processing of entire folders.
Cross-platform: Windows and macOS.
"""

import os
import sys
import argparse
import platform
import time
import json
from pathlib import Path
from datetime import datetime

try:
    from PIL import Image, ImageDraw, ImageFont, ImageOps
    from PIL.ExifTags import TAGS, GPSTAGS
except ImportError:
    print("Error: Pillow is required. Install with: pip install Pillow")
    sys.exit(1)

try:
    from geopy.geocoders import Nominatim
    from geopy.exc import GeocoderTimedOut, GeocoderServiceError
    GEOPY_AVAILABLE = True
except ImportError:
    GEOPY_AVAILABLE = False
    print("Warning: geopy not installed. Location will show GPS coordinates only.")
    print("Install with: pip install geopy\n")

try:
    from tqdm import tqdm
    TQDM_AVAILABLE = True
except ImportError:
    TQDM_AVAILABLE = False

try:
    from staticmap import StaticMap, CircleMarker
    STATICMAP_AVAILABLE = True
except ImportError:
    STATICMAP_AVAILABLE = False


# =============================================================================
# Constants
# =============================================================================

DPI = 300
CM_TO_INCH = 1 / 2.54

# Polaroid dimensions in pixels at 300 DPI
PORTRAIT_WIDTH = round(10 * CM_TO_INCH * DPI)    # 1181px
PORTRAIT_HEIGHT = round(15 * CM_TO_INCH * DPI)   # 1772px
LANDSCAPE_WIDTH = round(15 * CM_TO_INCH * DPI)   # 1772px
LANDSCAPE_HEIGHT = round(10 * CM_TO_INCH * DPI)  # 1181px

# Classic Polaroid borders in pixels at 300 DPI
BORDER_TOP = round(0.5 * CM_TO_INCH * DPI)       # ~59px
BORDER_SIDE = round(0.5 * CM_TO_INCH * DPI)      # ~59px
BORDER_BOTTOM = round(3.2 * CM_TO_INCH * DPI)    # ~378px (room for mini-map)

# Mini-map settings
MAP_W = 220
MAP_H = 165
MAP_ZOOM = 11
MAP_PADDING = round(0.2 * CM_TO_INCH * DPI)      # padding inside bottom border
MAP_BORDER_PX = 2
MAP_BORDER_COLOR = (210, 210, 210)

# Supported image extensions
SUPPORTED_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.tiff', '.tif', '.bmp',
                        '.heic', '.heif', '.webp'}

# Text styling
TEXT_COLOR = (60, 60, 60)
BG_COLOR = (255, 255, 255)
SEPARATOR = " \u00b7 "  # middle dot


# =============================================================================
# Font Configuration
# =============================================================================

FONT_OPTIONS = [
    {
        "name": "Handwritten Elegant",
        "description": "Flowing script, perfect for travel or romantic photos",
        "example": "Lisbon, Portugal  \u00b7  24 Dec 2024",
        "fonts": {
            "windows": ["Segoe Script", "Palace Script MT", "Lucida Handwriting"],
            "darwin": ["Bradley Hand", "Snell Roundhand", "Apple Chancery"],
            "linux": ["URW Chancery L", "DejaVu Sans"],
        },
    },
    {
        "name": "Casual Handwriting",
        "description": "Relaxed, informal handwritten style",
        "example": "Lisbon, Portugal  \u00b7  24 Dec 2024",
        "fonts": {
            "windows": ["Ink Free", "Comic Sans MS", "Segoe Print"],
            "darwin": ["Marker Felt", "Chalkboard", "Noteworthy"],
            "linux": ["Comic Neue", "DejaVu Sans"],
        },
    },
    {
        "name": "Classic Serif",
        "description": "Timeless, elegant serif font for a refined look",
        "example": "Lisbon, Portugal  \u00b7  24 Dec 2024",
        "fonts": {
            "windows": ["Georgia", "Palatino Linotype", "Book Antiqua",
                        "Times New Roman"],
            "darwin": ["Georgia", "Palatino", "Didot", "Times New Roman"],
            "linux": ["DejaVu Serif", "Liberation Serif", "Nimbus Roman"],
        },
    },
    {
        "name": "Modern Sans-Serif",
        "description": "Clean, contemporary look for a minimalist feel",
        "example": "Lisbon, Portugal  \u00b7  24 Dec 2024",
        "fonts": {
            "windows": ["Segoe UI", "Calibri", "Trebuchet MS", "Arial"],
            "darwin": ["Helvetica Neue", "Avenir", "Futura",
                       "SF Pro Display"],
            "linux": ["DejaVu Sans", "Liberation Sans", "Nimbus Sans"],
        },
    },
    {
        "name": "Typewriter",
        "description": "Vintage typewriter style for a nostalgic, retro feel",
        "example": "Lisbon, Portugal  \u00b7  24 Dec 2024",
        "fonts": {
            "windows": ["Courier New", "Consolas", "Lucida Console"],
            "darwin": ["American Typewriter", "Courier New", "Andale Mono"],
            "linux": ["DejaVu Sans Mono", "Liberation Mono", "Courier New"],
        },
    },
]


# =============================================================================
# EXIF & GPS Helpers
# =============================================================================

def get_exif_data(image):
    """Extract EXIF data from a PIL Image using the modern public API."""
    exif_data = {}
    try:
        exif = image.getexif()
        if not exif:
            return exif_data

        for tag_id, value in exif.items():
            tag = TAGS.get(tag_id, tag_id)
            exif_data[tag] = value

        # GPS lives in a sub-IFD (tag 0x8825) and must be fetched separately
        gps_ifd = exif.get_ifd(0x8825)
        if gps_ifd:
            gps_data = {}
            for tag_id, value in gps_ifd.items():
                tag = GPSTAGS.get(tag_id, tag_id)
                gps_data[tag] = value
            exif_data["GPSInfo"] = gps_data
    except Exception:
        pass
    return exif_data


def _to_float(val):
    """Convert an EXIF value (IFDRational, tuple, int, float) to float."""
    try:
        return float(val)
    except (TypeError, ValueError):
        pass
    # Handle (numerator, denominator) tuples
    try:
        if hasattr(val, "numerator") and hasattr(val, "denominator"):
            return float(val.numerator) / float(val.denominator)
    except (TypeError, ZeroDivisionError):
        pass
    try:
        if isinstance(val, (tuple, list)) and len(val) == 2:
            return float(val[0]) / float(val[1])
    except (TypeError, ZeroDivisionError):
        pass
    return None


def _dms_to_decimal(dms_value):
    """Convert GPS DMS (degrees, minutes, seconds) to decimal degrees."""
    try:
        d = _to_float(dms_value[0])
        m = _to_float(dms_value[1])
        s = _to_float(dms_value[2])
        if d is None or m is None or s is None:
            return None
        return d + (m / 60.0) + (s / 3600.0)
    except (TypeError, IndexError):
        return None


def get_gps_coordinates(exif_data):
    """Extract GPS latitude/longitude from EXIF data as decimal degrees."""
    gps_info = exif_data.get("GPSInfo")
    if not gps_info:
        return None, None

    lat = _dms_to_decimal(gps_info.get("GPSLatitude"))
    lon = _dms_to_decimal(gps_info.get("GPSLongitude"))

    if lat is None or lon is None:
        return None, None

    if gps_info.get("GPSLatitudeRef", "N") == "S":
        lat = -lat
    if gps_info.get("GPSLongitudeRef", "E") == "W":
        lon = -lon

    return lat, lon


def get_date_taken(exif_data):
    """Extract the date the photo was taken from EXIF data."""
    date_str = exif_data.get("DateTimeOriginal") or exif_data.get("DateTime")
    if date_str:
        try:
            dt = datetime.strptime(str(date_str), "%Y:%m:%d %H:%M:%S")
            return dt.strftime("%d %b %Y")
        except (ValueError, TypeError):
            pass
    return None


# =============================================================================
# Geocoding with Cache
# =============================================================================

class GeocodingCache:
    """Disk-backed cache for reverse geocoding to minimize API calls."""

    def __init__(self, cache_file="geocoding_cache.json"):
        self.cache_file = cache_file
        self.cache = {}
        self._load_cache()
        if GEOPY_AVAILABLE:
            self.geolocator = Nominatim(
                user_agent="polaroid_photo_formatter/1.0"
            )
        self.last_request_time = 0

    def _load_cache(self):
        try:
            if os.path.exists(self.cache_file):
                with open(self.cache_file, "r", encoding="utf-8") as f:
                    self.cache = json.load(f)
        except (json.JSONDecodeError, IOError):
            self.cache = {}

    def _save_cache(self):
        try:
            with open(self.cache_file, "w", encoding="utf-8") as f:
                json.dump(self.cache, f, ensure_ascii=False, indent=2)
        except IOError:
            pass

    @staticmethod
    def _round_coords(lat, lon):
        """Round to ~100m precision for cache grouping."""
        return f"{lat:.3f},{lon:.3f}"

    def get_location(self, lat, lon):
        """Reverse-geocode coordinates to 'City, Country'."""
        if not GEOPY_AVAILABLE:
            return f"{lat:.4f}, {lon:.4f}"

        cache_key = self._round_coords(lat, lon)
        if cache_key in self.cache:
            return self.cache[cache_key]

        # Rate limit: max 1 request/second for Nominatim fair-use policy
        elapsed = time.time() - self.last_request_time
        if elapsed < 1.0:
            time.sleep(1.0 - elapsed)

        try:
            self.last_request_time = time.time()
            location = self.geolocator.reverse(
                f"{lat}, {lon}", language="en", timeout=10
            )
            if location and location.raw.get("address"):
                addr = location.raw["address"]
                city = (
                    addr.get("city")
                    or addr.get("town")
                    or addr.get("village")
                    or addr.get("municipality")
                    or addr.get("county")
                    or ""
                )
                country = addr.get("country", "")

                if city and country:
                    result = f"{city}, {country}"
                elif city:
                    result = city
                elif country:
                    result = country
                else:
                    result = f"{lat:.4f}, {lon:.4f}"
            else:
                result = f"{lat:.4f}, {lon:.4f}"
        except (GeocoderTimedOut, GeocoderServiceError, Exception):
            result = f"{lat:.4f}, {lon:.4f}"

        self.cache[cache_key] = result
        self._save_cache()
        return result


# =============================================================================
# Mini-Map Generation
# =============================================================================

# In-memory cache: rounded coords -> PIL Image
_map_cache = {}


def _generate_map(lat, lon):
    """Return a small PIL Image with a map centered on (lat, lon), or None."""
    if not STATICMAP_AVAILABLE:
        return None

    cache_key = f"{lat:.2f},{lon:.2f}"
    if cache_key in _map_cache:
        return _map_cache[cache_key].copy()

    try:
        m = StaticMap(MAP_W, MAP_H)
        marker = CircleMarker((lon, lat), "#e74c3c", 8)
        m.add_marker(marker)
        map_img = m.render(zoom=MAP_ZOOM)
        map_img = map_img.convert("RGB")
        _map_cache[cache_key] = map_img
        return map_img.copy()
    except Exception:
        return None


def _add_map_border(map_img):
    """Return a new image with a thin border drawn around *map_img*."""
    w, h = map_img.size
    bordered = Image.new("RGB", (w + 2 * MAP_BORDER_PX, h + 2 * MAP_BORDER_PX),
                         MAP_BORDER_COLOR)
    bordered.paste(map_img, (MAP_BORDER_PX, MAP_BORDER_PX))
    return bordered


# =============================================================================
# Font Resolution
# =============================================================================

def _get_system_font_dirs():
    """Return font directories for the current platform."""
    system = platform.system().lower()
    if system == "windows":
        windir = os.environ.get("WINDIR", r"C:\Windows")
        localappdata = os.environ.get("LOCALAPPDATA", "")
        dirs = [os.path.join(windir, "Fonts")]
        if localappdata:
            dirs.append(
                os.path.join(localappdata, "Microsoft", "Windows", "Fonts")
            )
        return dirs
    elif system == "darwin":
        return [
            "/System/Library/Fonts",
            "/System/Library/Fonts/Supplemental",
            "/Library/Fonts",
            os.path.expanduser("~/Library/Fonts"),
        ]
    else:  # Linux
        return [
            "/usr/share/fonts",
            "/usr/local/share/fonts",
            os.path.expanduser("~/.fonts"),
            os.path.expanduser("~/.local/share/fonts"),
        ]


def _find_font_file(font_name):
    """Walk system font directories looking for a font matching *font_name*."""
    search = font_name.lower().replace(" ", "")
    for font_dir in _get_system_font_dirs():
        if not os.path.isdir(font_dir):
            continue
        for root, _dirs, files in os.walk(font_dir):
            for fname in files:
                if fname.lower().endswith((".ttf", ".otf", ".ttc")):
                    base = (
                        fname.lower()
                        .replace(" ", "")
                        .replace("-", "")
                        .replace("_", "")
                    )
                    if search in base:
                        return os.path.join(root, fname)
    return None


def resolve_font(font_option_index):
    """Return the path to the best available font for the chosen style."""
    system = platform.system().lower()
    option = FONT_OPTIONS[font_option_index]
    names = option["fonts"].get(system, option["fonts"].get("linux", []))

    for name in names:
        path = _find_font_file(name)
        if path:
            return path

    # Fallback: try every font in every option until one works
    for opt in FONT_OPTIONS:
        for name in opt["fonts"].get(system, opt["fonts"].get("linux", [])):
            path = _find_font_file(name)
            if path:
                return path
    return None


# =============================================================================
# Polaroid Creator
# =============================================================================

def _fit_text_font(draw, text, font_path, max_width, max_height):
    """Return an ImageFont that fits *text* within the given bounds."""
    font_size = int(max_height)
    font = None

    if font_path:
        while font_size > 8:
            try:
                candidate = ImageFont.truetype(font_path, font_size)
                bbox = draw.textbbox((0, 0), text, font=candidate)
                tw = bbox[2] - bbox[0]
                th = bbox[3] - bbox[1]
                if tw <= max_width and th <= max_height:
                    font = candidate
                    break
                font_size -= 1
            except Exception:
                font_size -= 1

    if font is None:
        # Last-resort fallback: try common system fonts at a visible size
        fallback_size = max(36, int(max_height * 0.5))
        fallback_names = [
            "arial.ttf", "Arial.ttf",
            "DejaVuSans.ttf", "LiberationSans-Regular.ttf",
            "Helvetica.ttc", "Times New Roman.ttf",
        ]
        for fb_name in fallback_names:
            try:
                font = ImageFont.truetype(fb_name, fallback_size)
                break
            except OSError:
                continue
        if font is None:
            # Pillow 10.1+ supports size parameter on load_default
            try:
                font = ImageFont.load_default(size=fallback_size)
            except TypeError:
                font = ImageFont.load_default()

    return font


def create_polaroid(image_path, output_path, font_path, geocoding_cache,
                    quality=95, verbose=False):
    """Create a single Polaroid-style image.

    Returns (success: bool, info: str).
    """
    try:
        img = Image.open(image_path)
    except Exception as e:
        return False, f"Cannot open: {e}"

    # --- Extract EXIF metadata BEFORE transpose (which strips EXIF) ------
    exif_data = get_exif_data(img)

    if verbose:
        name = os.path.basename(image_path)
        has_gps = "GPSInfo" in exif_data
        has_date = ("DateTimeOriginal" in exif_data or "DateTime" in exif_data)
        print(f"  [{name}] EXIF keys: {list(exif_data.keys())}")
        print(f"  [{name}] GPS found: {has_gps}, Date found: {has_date}")
        if has_gps:
            print(f"  [{name}] GPSInfo: {exif_data['GPSInfo']}")

    # Honour EXIF orientation
    try:
        img = ImageOps.exif_transpose(img)
    except Exception:
        pass

    # Convert to RGB (handles RGBA, palette, etc.)
    if img.mode != "RGB":
        img = img.convert("RGB")

    lat, lon = get_gps_coordinates(exif_data)
    location = (
        geocoding_cache.get_location(lat, lon)
        if lat is not None
        else None
    )
    date_taken = get_date_taken(exif_data)

    if verbose:
        print(f"  [{name}] GPS coords: {lat}, {lon}")
        print(f"  [{name}] Location: {location}")
        print(f"  [{name}] Date: {date_taken}")

    text_parts = []
    if location:
        text_parts.append(location)
    if date_taken:
        text_parts.append(date_taken)
    text = SEPARATOR.join(text_parts) if text_parts else ""

    # --- Determine orientation -------------------------------------------
    is_landscape = img.width > img.height

    if is_landscape:
        canvas_w, canvas_h = LANDSCAPE_WIDTH, LANDSCAPE_HEIGHT
    else:
        canvas_w, canvas_h = PORTRAIT_WIDTH, PORTRAIT_HEIGHT

    # Photo area inside the borders
    photo_w = canvas_w - 2 * BORDER_SIDE
    photo_h = canvas_h - BORDER_TOP - BORDER_BOTTOM

    # --- Resize + center-crop to fill photo area -------------------------
    img_ratio = img.width / img.height
    area_ratio = photo_w / photo_h

    if img_ratio > area_ratio:
        # Image wider than area -> fit height, crop width
        new_h = photo_h
        new_w = round(img.width * (photo_h / img.height))
    else:
        # Image taller -> fit width, crop height
        new_w = photo_w
        new_h = round(img.height * (photo_w / img.width))

    img = img.resize((new_w, new_h), Image.LANCZOS)

    left = (new_w - photo_w) // 2
    top = (new_h - photo_h) // 2
    img = img.crop((left, top, left + photo_w, top + photo_h))

    # --- Compose Polaroid canvas -----------------------------------------
    canvas = Image.new("RGB", (canvas_w, canvas_h), BG_COLOR)
    canvas.paste(img, (BORDER_SIDE, BORDER_TOP))

    # --- Draw bottom area: map + text ------------------------------------
    map_img = None
    if lat is not None and lon is not None:
        map_img = _generate_map(lat, lon)
        if map_img is not None:
            map_img = _add_map_border(map_img)

    draw = ImageDraw.Draw(canvas)
    bottom_top = canvas_h - BORDER_BOTTOM  # y where bottom border starts

    if map_img is not None and text:
        # Layout: map on the left, text (location line + date line) on right
        mw, mh = map_img.size
        map_x = BORDER_SIDE + MAP_PADDING
        map_y = bottom_top + (BORDER_BOTTOM - mh) // 2
        canvas.paste(map_img, (map_x, map_y))

        # Text area is to the right of the map
        text_area_left = map_x + mw + MAP_PADDING
        text_area_right = canvas_w - BORDER_SIDE - MAP_PADDING
        text_area_w = text_area_right - text_area_left

        # Draw location and date as separate lines
        loc_str = location or ""
        date_str = date_taken or ""

        # Fit location font
        max_line_h = int(BORDER_BOTTOM * 0.22)
        loc_font = _fit_text_font(draw, loc_str, font_path,
                                  text_area_w, max_line_h) if loc_str else None
        date_font = _fit_text_font(draw, date_str, font_path,
                                   text_area_w, max_line_h) if date_str else None

        # Measure
        lines = []
        if loc_str and loc_font:
            bb = draw.textbbox((0, 0), loc_str, font=loc_font)
            lines.append((loc_str, loc_font, bb[2] - bb[0], bb[3] - bb[1]))
        if date_str and date_font:
            bb = draw.textbbox((0, 0), date_str, font=date_font)
            lines.append((date_str, date_font, bb[2] - bb[0], bb[3] - bb[1]))

        line_gap = 10
        total_text_h = sum(l[3] for l in lines) + line_gap * (len(lines) - 1)
        cur_y = bottom_top + (BORDER_BOTTOM - total_text_h) // 2

        for txt, fnt, tw, th in lines:
            tx = text_area_left + (text_area_w - tw) // 2
            draw.text((tx, cur_y), txt, fill=TEXT_COLOR, font=fnt)
            cur_y += th + line_gap

    elif map_img is not None:
        # Map only, no text - center the map
        mw, mh = map_img.size
        map_x = (canvas_w - mw) // 2
        map_y = bottom_top + (BORDER_BOTTOM - mh) // 2
        canvas.paste(map_img, (map_x, map_y))

    elif text:
        # Text only, no map - center text
        max_text_h = int(BORDER_BOTTOM * 0.35)
        max_text_w = int(photo_w * 0.95)
        font = _fit_text_font(draw, text, font_path, max_text_w, max_text_h)
        bbox = draw.textbbox((0, 0), text, font=font)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        text_x = (canvas_w - tw) // 2
        text_y = bottom_top + (BORDER_BOTTOM - th) // 2
        draw.text((text_x, text_y), text, fill=TEXT_COLOR, font=font)

    # --- Save ------------------------------------------------------------
    canvas.save(output_path, "JPEG", quality=quality, dpi=(DPI, DPI))
    return True, text or "(no metadata)"


# =============================================================================
# Interactive Font Menu
# =============================================================================

def display_font_menu():
    """Show available font styles and return the chosen index (0-based)."""
    print()
    print("+----------------------------------------------------------+")
    print("|             Choose a Font Style                          |")
    print("+----------------------------------------------------------+")

    for i, option in enumerate(FONT_OPTIONS):
        print(f"|                                                          |")
        print(f"|  [{i + 1}] {option['name']:<52}|")
        print(f"|      {option['description']:<52}|")
        print(f"|      Example: {option['example']:<43}|")

    print("|                                                          |")
    print("+----------------------------------------------------------+")

    while True:
        try:
            raw = input(f"\nSelect font style (1-{len(FONT_OPTIONS)}): ").strip()
            choice = int(raw)
            if 1 <= choice <= len(FONT_OPTIONS):
                return choice - 1
        except (ValueError, EOFError):
            pass
        print(f"Please enter a number between 1 and {len(FONT_OPTIONS)}.")


# =============================================================================
# Main
# =============================================================================

def main():
    parser = argparse.ArgumentParser(
        description=(
            "Transform photos into classic Polaroid format (10x15 cm) "
            "with location and date text from EXIF metadata."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
examples:
  %(prog)s /path/to/photos
  %(prog)s /path/to/photos -o /path/to/output
  %(prog)s /path/to/photos --font 1
  %(prog)s /path/to/photos --font 3 --recursive
        """,
    )
    parser.add_argument(
        "input_dir", help="Directory containing photos to process"
    )
    parser.add_argument(
        "-o", "--output",
        help="Output directory (default: <input_dir>/polaroids)",
    )
    parser.add_argument(
        "--font",
        type=int,
        choices=range(1, len(FONT_OPTIONS) + 1),
        metavar=f"1-{len(FONT_OPTIONS)}",
        help="Font style number. Omit to see the interactive menu.",
    )
    parser.add_argument(
        "-r", "--recursive",
        action="store_true",
        help="Also process images in subdirectories",
    )
    parser.add_argument(
        "--quality",
        type=int,
        default=95,
        help="JPEG output quality 1-100 (default: 95)",
    )
    parser.add_argument(
        "--preview",
        action="store_true",
        help="Process only the first image (quick preview)",
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Show detailed EXIF/metadata info for each image (debug)",
    )

    args = parser.parse_args()

    # --- Validate input --------------------------------------------------
    input_dir = Path(args.input_dir)
    if not input_dir.is_dir():
        print(f"Error: '{input_dir}' is not a valid directory.")
        sys.exit(1)

    output_dir = Path(args.output) if args.output else input_dir / "polaroids"
    output_dir.mkdir(parents=True, exist_ok=True)

    # --- Font selection --------------------------------------------------
    if args.font:
        font_index = args.font - 1
    else:
        font_index = display_font_menu()

    font_path = resolve_font(font_index)
    font_name = FONT_OPTIONS[font_index]["name"]

    if font_path:
        print(f"\nFont style : {font_name}")
        print(f"Font file  : {font_path}")
    else:
        print(f"\nCould not find fonts for '{font_name}'. Using system default.")

    # --- Collect image files ---------------------------------------------
    print(f"\nScanning '{input_dir}' for images...")

    if args.recursive:
        image_files = sorted(
            f for f in input_dir.rglob("*")
            if f.is_file() and f.suffix.lower() in SUPPORTED_EXTENSIONS
        )
    else:
        image_files = sorted(
            f for f in input_dir.iterdir()
            if f.is_file() and f.suffix.lower() in SUPPORTED_EXTENSIONS
        )

    if not image_files:
        print("No supported image files found.")
        sys.exit(0)

    if args.preview:
        image_files = image_files[:1]
        print(f"Preview mode: processing 1 of {len(image_files)} image(s)")
    else:
        print(f"Found {len(image_files)} image(s)")

    # --- Geocoding cache -------------------------------------------------
    cache_file = str(output_dir / ".geocoding_cache.json")
    geocoding_cache = GeocodingCache(cache_file)

    # --- Process ---------------------------------------------------------
    print(f"\nProcessing photos into Polaroid format...")
    print(f"Output: {output_dir}\n")

    success = 0
    errors = 0
    no_meta = 0

    iterator = (
        tqdm(image_files, desc="Processing", unit="photo")
        if TQDM_AVAILABLE
        else image_files
    )

    for idx, image_path in enumerate(iterator):
        # Determine output path (preserve subdirectory structure)
        if args.recursive:
            relative = image_path.relative_to(input_dir)
        else:
            relative = Path(image_path.name)

        out_stem = relative.stem
        out_path = output_dir / relative.parent / (out_stem + ".jpg")
        out_path.parent.mkdir(parents=True, exist_ok=True)

        # Prevent overwriting the original
        if out_path.resolve() == image_path.resolve():
            out_path = (
                output_dir / relative.parent / (out_stem + "_polaroid.jpg")
            )

        ok, info = create_polaroid(
            str(image_path), str(out_path), font_path, geocoding_cache,
            quality=args.quality, verbose=args.verbose,
        )

        if ok:
            success += 1
            if info == "(no metadata)":
                no_meta += 1
        else:
            errors += 1
            if not TQDM_AVAILABLE:
                print(f"  ERROR: {image_path.name} - {info}")

        if not TQDM_AVAILABLE and (idx + 1) % 100 == 0:
            print(f"  Processed {idx + 1}/{len(image_files)}...")

    # --- Summary ---------------------------------------------------------
    print(f"\n{'=' * 50}")
    print("Done!")
    print(f"  Processed        : {success} photo(s)")
    if no_meta:
        print(f"  Without metadata : {no_meta} photo(s)")
    if errors:
        print(f"  Errors           : {errors} photo(s)")
    print(f"  Output folder    : {output_dir}")
    print(f"{'=' * 50}")


if __name__ == "__main__":
    main()
