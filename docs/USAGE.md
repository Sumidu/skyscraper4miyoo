# Usage Guide

## Directory Structure

Organize your ROMs in folders matching Miyoo Mini system names:

```
~/MiyooMini/Roms/
├── FC/          # Famicom/NES
├── SFC/         # Super Famicom/SNES
├── GB/          # Game Boy
├── GBC/         # Game Boy Color
├── GBA/         # Game Boy Advance
├── MD/          # Mega Drive/Genesis
├── MS/          # Master System
├── GG/          # Game Gear
├── PCE/         # PC Engine/TurboGrafx-16
├── PS/          # PlayStation
├── ARCADE/      # Arcade/MAME
├── NEOGEO/      # Neo Geo
└── ...
```

## Basic Usage

### Scrape All Systems

```bash
./scripts/scrape.sh --all
```

This will scan all ROM directories and download artwork for every game.

### Scrape New ROMs Only

```bash
./scripts/scrape.sh
```

Without arguments, the script only processes ROMs added since the last run.

### Scrape Specific Systems

```bash
./scripts/scrape.sh GBA SFC FC
```

## Advanced Options

### Skip Existing Artwork

Don't re-scrape games that already have artwork:

```bash
./scripts/scrape.sh --skip --all
```

### Import Local Images

If you have your own screenshots or covers:

1. Place them in `~/.skyscraper/import/<platform>/<type>/`
   - Example: `~/.skyscraper/import/snes/screenshot/Game Name.png`
2. Run: `./scripts/scrape.sh --import SFC`

### Clean Orphaned Artwork

Remove artwork for deleted ROMs:

```bash
./scripts/scrape.sh --clean
```

Preview what would be deleted:

```bash
./scripts/scrape.sh --clean --pretend
```

### Override Region

Get artwork from a specific region:

```bash
./scripts/scrape.sh --region us GBA
./scripts/scrape.sh --region jp SFC
./scripts/scrape.sh --region eu MD
```

Common region codes: `us`, `eu`, `jp`, `wor` (world)

### Use Different Scraping Source

```bash
./scripts/scrape.sh --module thegamesdb GBA
```

Available modules:
- `screenscraper` (default, requires account)
- `thegamesdb`
- `openretro`
- `igdb`
- `mobygames`

## Output

After scraping, each system folder will contain:

```
GBA/
├── Game1.gba
├── Game2.gba
├── Imgs/
│   ├── Game1.png
│   └── Game2.png
└── miyoogamelist.xml
```

## Transferring to Miyoo Mini

1. Insert your Miyoo Mini's SD card into your computer
2. Copy the system folders (with Imgs/ and miyoogamelist.xml) to the Roms directory
3. Eject safely and insert into Miyoo Mini

### Using SSH (Miyoo Mini Plus)

If your Miyoo Mini Plus has SSH enabled:

```bash
# Mount the filesystem
sshfs root@192.168.1.XX:/mnt/SDCARD ~/MiyooMount

# Set ROM path in config to ~/MiyooMount/Roms
# Run scraping
./scripts/scrape.sh --all

# Unmount when done
fusermount -u ~/MiyooMount
```

## Supported Systems

| Miyoo Folder | Platform | Description |
|--------------|----------|-------------|
| FC | nes | Famicom/NES |
| SFC | snes | Super Famicom/SNES |
| GB | gb, gbc | Game Boy |
| GBC | gbc | Game Boy Color |
| GBA | gba | Game Boy Advance |
| MD | megadrive | Mega Drive/Genesis |
| MS | mastersystem | Master System |
| GG | gamegear | Game Gear |
| PCE | pcengine | PC Engine |
| PCECD | pcenginecd | PC Engine CD |
| PS | psx | PlayStation |
| ARCADE | mame-libretro | Arcade/MAME |
| NEOGEO | neogeo | Neo Geo |
| NGP | ngp, ngpc | Neo Geo Pocket |
| WS | wonderswan | WonderSwan |
| LYNX | atarilynx | Atari Lynx |
| VB | virtualboy | Virtual Boy |
| COLECO | coleco | ColecoVision |
| MSX | msx | MSX |
| AMIGA | amiga | Amiga |
| ZXS | zxspectrum | ZX Spectrum |
| CPC | amstradcpc | Amstrad CPC |

## Artwork Styles

Three artwork styles are included:

1. **artwork-miyoo1.xml** - Screenshot with logo overlay (default)
2. **artwork-miyoo2.xml** - Screenshot with logo and cover
3. **artwork-miyoo3.xml** - Screenshot with transparent left edge

To change styles, edit `~/.skyscraper/config.ini`:

```ini
artworkXml="artwork-miyoo2.xml"
```

## Troubleshooting

### No artwork found for some games

1. Try a different region: `--region wor`
2. Check if the game name matches the database
3. Try a different scraping module
4. Import artwork manually

### Scraping is very slow

- Create a ScreenScraper account for more API requests
- Use `--skip` to skip already scraped games
- Scrape specific systems instead of all at once

### Images not showing on Miyoo Mini

- Ensure `miyoogamelist.xml` is in each system folder
- Check that image paths in the XML are relative
- Verify images are in the `Imgs/` subfolder
