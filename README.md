# skyscraper4miyoo

A set of bash scripts to scrape and generate game artwork images for the Miyoo Mini using the SkyScraper command line tool. These scripts run on macOS.

## Prerequisites

### Install Skyscraper

On macOS, install Skyscraper using Homebrew:

```bash
brew install skyscraper
```

For other platforms, see the [Skyscraper GitHub repository](https://github.com/Gemba/skyscraper).

### Get ScreenScraper Account (Recommended)

Create a free account at [ScreenScraper](https://www.screenscraper.fr) for the best scraping results. Add your credentials to the config file.

## Quick Start

1. **Clone this repository:**
   ```bash
   git clone https://github.com/Sumidu/skyscraper4miyoo.git
   cd skyscraper4miyoo
   ```

2. **Edit the configuration file:**
   ```bash
   cp config.cfg config.cfg.backup  # Optional backup
   nano config.cfg
   ```
   
   Configure at minimum:
   - `ROM_BASE_PATH` - Path to your ROM collection
   - `SCREENSCRAPER_USER` - Your ScreenScraper username
   - `SCREENSCRAPER_PASS` - Your ScreenScraper password

3. **Run the scraping script:**
   ```bash
   chmod +x scrape.sh
   ./scrape.sh
   ```
   
   Or scrape a specific platform:
   ```bash
   ./scrape.sh gba
   ```

4. **Generate artwork:**
   ```bash
   chmod +x generate_artwork.sh
   ./generate_artwork.sh
   ```

5. **Copy the generated images to your Miyoo Mini SD card.**

## Configuration

Edit `config.cfg` to customize the scraping settings:

| Setting | Description | Default |
|---------|-------------|---------|
| `ROM_BASE_PATH` | Path to your ROM collection | (required) |
| `CACHE_PATH` | Path to store scraped cache | (optional) |
| `ARTWORK_XML` | Path to artwork XML template file | (optional) |
| `SCRAPE_SOURCE` | Scraping source (screenscraper, thegamesdb, etc.) | `screenscraper` |
| `SCREENSCRAPER_USER` | ScreenScraper username | (required for screenscraper) |
| `SCREENSCRAPER_PASS` | ScreenScraper password | (required for screenscraper) |
| `ARTWORK_TYPE` | Type of artwork (screenshot, cover, wheel, marquee) | `screenshot` |
| `IMAGE_WIDTH` | Output image width | `640` |
| `IMAGE_HEIGHT` | Output image height | `480` |
| `PLATFORMS` | Space-separated list of platforms to scrape | (see config) |
| `PLATFORM_FOLDER_<platform>` | Custom folder name for a platform (e.g., `PLATFORM_FOLDER_nes="FC"`) | (optional) |
| `SKIP_EXISTING` | Skip games that already have artwork | `true` |
| `MAX_THREADS` | Number of concurrent threads | `4` |

## Supported Platforms

The scripts support common Miyoo Mini platforms:

- `gb` - Game Boy
- `gbc` - Game Boy Color
- `gba` - Game Boy Advance
- `nes` - Nintendo Entertainment System
- `snes` - Super Nintendo
- `megadrive` - Sega Genesis / Mega Drive
- `mastersystem` - Sega Master System
- `psx` - PlayStation 1
- `arcade` - Arcade
- `pcengine` - PC Engine / TurboGrafx-16
- `neogeo` - Neo Geo

## Directory Structure

The scripts expect ROMs to be organized in platform-specific folders:

```
ROM_BASE_PATH/
├── GB/
│   └── *.gb
├── GBC/
│   └── *.gbc
├── GBA/
│   └── *.gba
├── NES/
│   └── *.nes
└── ...
```

Generated artwork will be placed in `Imgs` subdirectories by default.

### Custom Folder Names (Onion OS)

If you're using Onion OS or have custom folder names, configure the `PLATFORM_FOLDER_<platform>` settings in `config.cfg`. For example, Onion OS uses:

```bash
PLATFORM_FOLDER_nes="FC"
PLATFORM_FOLDER_snes="SFC"
PLATFORM_FOLDER_megadrive="MD"
PLATFORM_FOLDER_mastersystem="MS"
PLATFORM_FOLDER_psx="PS"
PLATFORM_FOLDER_pcengine="PCE"
```

This maps Skyscraper's platform names to your actual folder structure:

## Custom Artwork Templates

The `artwork/` directory contains pre-configured artwork XML templates optimized for the Miyoo Mini's display (250x360 pixels). These templates define how game images are composed using Skyscraper's artwork system.

### Available Styles

1. **artwork-miyoo1.xml** - Screenshot with logo overlay
   - Full-height screenshot (sides cropped if needed)
   - Game logo displayed at the top with shadow
   - Gradient overlay for better logo visibility

2. **artwork-miyoo2.xml** - Screenshot with logo and cover
   - Centered screenshot
   - Game logo at the top
   - Box cover art in the bottom right corner

3. **artwork-miyoo3.xml** - Screenshot with transparent left edge
   - Same as style 1 but with a fade effect on the left side
   - Helps game titles blend into the artwork on certain themes

### Using Custom Artwork

To use one of these artwork templates with Skyscraper:

```bash
Skyscraper -p <platform> -a artwork/artwork-miyoo1.xml -i <rom_path> -o <output_path>
```

Or copy your preferred template to the Skyscraper config directory:

```bash
cp artwork/artwork-miyoo1.xml ~/.skyscraper/artwork.xml
```

### Creating Custom Templates

You can modify these templates or create your own. The `artwork/resources/` directory contains a README explaining the required resource images (gradients, backgrounds).

For detailed documentation on Skyscraper's artwork system, see the [Skyscraper Artwork Documentation](https://github.com/Gemba/skyscraper/blob/master/docs/ARTWORK.md).

## Troubleshooting

### Skyscraper not found
Ensure Skyscraper is installed and in your PATH:
```bash
which Skyscraper
brew install skyscraper  # If not installed
```

### ScreenScraper credentials error
Verify your ScreenScraper account credentials in `config.cfg`.

### No ROMs found
Check that:
- `ROM_BASE_PATH` is set correctly in the config
- ROM folders exist (the scripts check both lowercase and uppercase folder names)

## License

MIT License
