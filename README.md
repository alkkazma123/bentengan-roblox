# Summit Kit - Game Gunung (Roblox)

Game Roblox **mountain climbing / obby** dengan sistem summit lengkap.

## Fitur

- **Checkpoint System**: Start → 8 Checkpoints → Finish (jumlah configurable)
- **Screen Shake + Notifikasi** saat mencapai checkpoint
- **Kill Parts**: teleport ke checkpoint terakhir saat tersentuh
- **Summit/Finish**: award summits + coins, auto teleport ke start
- **Overhead System**: Username, jumlah summit, title (Newbie → Rookie → ... → Summit God)
- **Coin & Shop**: Beli trail dan aura dengan coins
- **Music Player**: UI Spotify-like (play/pause/next/prev/shuffle/loop/volume/queue)
- **Emote System**: 10+ emotes, grid UI, auto-stop saat bergerak
- **Phone Menu UI**: Toggle button di atas tengah, 4 tab swipeable (Shop/Music/Emotes/Settings)
- **Settings**: Hide players, hide auras, hide trails
- **Data Persistence**: DataStore save (summits, coins, inventory, equipped, settings)
- **Auto Map Builder**: Map dibuild otomatis saat runtime jika belum ada

## Quick Start (PowerShell)

```powershell
# 1. Buka PowerShell, jalankan sekali:
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

# 2. Clone dan setup:
git clone https://github.com/alkkazma123/bentengan-roblox.git
cd bentengan-roblox
git checkout devin/1777857766-summit-kit-standalone
.\Setup.ps1
```

Atau manual:
```powershell
rojo build -o SummitKit.rbxlx
rojo serve
```

Lalu di Studio: Rojo Plugin → Connect → F5.

## Struktur File

```
src/
├── ReplicatedStorage/Shared/          # Config modules
│   ├── CheckpointConfig.lua           # Jumlah checkpoint (default 8)
│   ├── SummitConfig.lua               # Summit rewards
│   ├── TitleConfig.lua                # Titles berdasarkan summit count
│   ├── CoinConfig.lua                 # Coin rewards
│   ├── ShopConfig.lua                 # Items (trails & auras)
│   ├── MusicList.lua                  # Playlist musik
│   ├── EmoteList.lua                  # Daftar emotes
│   └── Remotes.lua                    # RemoteEvents/Functions
├── ServerScriptService/Server/        # Server scripts
│   ├── init.server.lua                # Bootstrap
│   ├── DataService.lua                # Save/load player data
│   ├── CheckpointService.lua          # Checkpoint tracking
│   ├── SummitService.lua              # Summit rewards
│   ├── KillPartService.lua            # Kill part teleport
│   ├── OverheadService.lua            # BillboardGui overhead
│   ├── CoinService.lua                # Coin sync
│   ├── ShopService.lua                # Buy/equip items
│   ├── EmoteService.lua               # Play emotes
│   └── MapBuilder.lua                 # Auto-build map
└── StarterPlayer/StarterPlayerScripts/Client/  # Client scripts
    ├── init.client.lua                # Bootstrap
    ├── CheckpointFX.lua               # Shake + notification
    ├── PhoneUI.lua                    # Phone menu (4 tabs)
    ├── ShopUI.lua                     # Shop page
    ├── MusicPlayerUI.lua              # Music player page
    ├── EmoteUI.lua                    # Emote grid page
    ├── SettingsUI.lua                 # Settings toggles page
    ├── OverheadController.lua         # Overhead sync
    └── SettingsController.lua         # Apply hide settings
```

## Konfigurasi

| File | Apa yang bisa diubah |
|------|---------------------|
| `CheckpointConfig.lua` | `TotalCheckpoints = 8` → ubah jumlah |
| `SummitConfig.lua` | `SummitsPerFinish`, `Cooldown`, `TeleportDelay` |
| `TitleConfig.lua` | Threshold dan nama title |
| `CoinConfig.lua` | Coins per summit/checkpoint |
| `ShopConfig.lua` | Tambah/hapus trail dan aura |
| `MusicList.lua` | Tambah lagu (atau folder `ReplicatedStorage.Music`) |
| `EmoteList.lua` | Tambah emote (atau folder `ReplicatedStorage.Emotes`) |

## Lint & Format

```bash
selene src/
stylua src/
stylua --check src/
```
