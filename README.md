# Polaroid Photo Formatter

Transform your photos into classic **Polaroid format** (10 cm x 15 cm at 300 DPI) with the **location** and **date** automatically extracted from the photo's EXIF metadata and printed on the white bottom border.

Cross-platform: works on **Windows** and **macOS**.

---

## Features

- Classic Polaroid layout with small top/side borders and a large bottom border for text
- Automatically reads EXIF GPS data and reverse-geocodes it to **City, Country**
- Automatically reads the date the photo was taken
- Adapts orientation to match the photo (portrait or landscape)
- 5 font styles to choose from (interactive menu or CLI flag)
- Batch processes entire folders (thousands of photos)
- Progress bar for large batches
- Geocoding cache to avoid redundant API calls
- Outputs print-ready 300 DPI JPEGs

## Requirements

- **Python 3.8+**
- Dependencies listed in `requirements.txt`

## Installation

### Windows

```powershell
# 1. Install Python from https://www.python.org/downloads/ (check "Add to PATH")

# 2. Open PowerShell or Command Prompt, navigate to this folder:
cd path\to\this\folder

# 3. (Optional) Create a virtual environment:
python -m venv venv
venv\Scripts\activate

# 4. Install dependencies:
pip install -r requirements.txt
```

### macOS

```bash
# 1. Install Python (if not already installed):
brew install python

# 2. Navigate to this folder:
cd /path/to/this/folder

# 3. (Optional) Create a virtual environment:
python3 -m venv venv
source venv/bin/activate

# 4. Install dependencies:
pip install -r requirements.txt
```

## Usage

### Basic (interactive font selection)

```bash
python polaroid_formatter.py /path/to/your/photos
```

The script will:
1. Show a font menu for you to choose a style
2. Scan the folder for images
3. Create Polaroid versions in a `polaroids/` subfolder

### Specify output directory

```bash
python polaroid_formatter.py /path/to/photos -o /path/to/output
```

### Choose a font style directly (skip menu)

```bash
python polaroid_formatter.py /path/to/photos --font 1
```

### Process subdirectories recursively

```bash
python polaroid_formatter.py /path/to/photos --recursive
```

### Quick preview (process only the first image)

```bash
python polaroid_formatter.py /path/to/photos --preview
```

### All options combined

```bash
python polaroid_formatter.py /path/to/photos -o ./output --font 3 --recursive --quality 90
```

## Font Styles

| # | Style                | Description                                    |
|---|----------------------|------------------------------------------------|
| 1 | Handwritten Elegant  | Flowing script, perfect for travel photos      |
| 2 | Casual Handwriting   | Relaxed, informal handwritten style            |
| 3 | Classic Serif        | Timeless, elegant serif for a refined look     |
| 4 | Modern Sans-Serif    | Clean, contemporary minimalist feel            |
| 5 | Typewriter           | Vintage typewriter for a nostalgic retro feel   |

## Polaroid Layout

```
+----------------------------+
|         0.5 cm             |  <- top border
|  +----------------------+  |
|  |                      |  |
|  |                      |  |
|  |      YOUR PHOTO      |  |
|  |                      |  |
|  |                      |  |
|  +----------------------+  |
|                            |
|   Lisbon, Portugal         |  <- 2.5 cm bottom border
|        24 Dec 2024         |
|                            |
+----------------------------+
       10 cm (portrait)
```

- **Portrait**: 10 cm wide x 15 cm tall
- **Landscape**: 15 cm wide x 10 cm tall
- **Resolution**: 300 DPI (print quality)

## How Location & Date Work

The script reads **EXIF metadata** embedded in your photos:

- **GPS coordinates** are reverse-geocoded using OpenStreetMap's Nominatim service into a human-readable "City, Country" format
- **Date taken** is formatted as "DD Mon YYYY" (e.g., "24 Dec 2024")
- Results are cached locally so the same GPS area is only looked up once
- If no EXIF data is found, the Polaroid is still created but without text

> **Note**: Photos taken with some apps or that have been edited/shared may have their EXIF data stripped. The original camera photos usually have full metadata.

## Supported Image Formats

JPG, JPEG, PNG, TIFF, BMP, WebP, HEIC, HEIF

> **Note**: HEIC/HEIF support requires the `pillow-heif` package: `pip install pillow-heif`

## CLI Reference

```
usage: polaroid_formatter.py [-h] [-o OUTPUT] [--font 1-5] [-r]
                              [--quality QUALITY] [--preview]
                              input_dir

positional arguments:
  input_dir             Directory containing photos to process

options:
  -h, --help            show this help message and exit
  -o, --output OUTPUT   Output directory (default: <input_dir>/polaroids)
  --font 1-5            Font style number. Omit to see the interactive menu.
  -r, --recursive       Also process images in subdirectories
  --quality QUALITY     JPEG output quality 1-100 (default: 95)
  --preview             Process only the first image (quick preview)
```
