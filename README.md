# Bentengan - Roblox Game

Game Roblox bertema **bentengan** (permainan tradisional Indonesia: dua tim saling menjaga benteng/base, menangkap lawan dengan menyentuh saat keluar dari zona aman, dan membebaskan teman yang tertangkap).

Satu server berisi **4 lobby terpisah** (Lobby 1-4), masing-masing punya arena sendiri, dan berjalan paralel.

## Fitur

- **Loading screen dengan progress bar real** (`ContentProvider:PreloadAsync`, menunggu sync awal dari server).
- **Rules UI** muncul setelah loading, dengan tombol close.
- **Lobby UI maker**: 4 kartu lobby, status live (Idle / Countdown / InMatch), join/leave, tombol shop.
- **Minimal 2 pemain** memicu countdown 10-15 detik (default 12).
- **Map per lobby** dengan arena terpisah jauh, dua base, dua penjara, dua safe zone, dua spawn pad, dan lobby pad.
- **Tag / capture / jail / free** dengan deteksi `Touched` dan aturan "siapa paling baru keluar safe zone boleh nge-tag".
- **Win condition**: semua lawan tertangkap, salah satu pemain menyentuh base lawan, atau timeout (tim dengan pemain bebas terbanyak menang).
- **Leaderboard**: `Wins`, `Coins`, `Tags`, `Deaths` pada default Roblox leaderboard.
- **Shop dark minimalist** dengan Speed Boost / Jump Boost / Hacker ESP / Fly.
- **Validasi equip** server-side: maksimal 3 ability, tidak boleh tipe sama.
- **Fly**: hanya 10 detik per match, cooldown 30 detik, dikontrol via WASD/space/shift.
- **ESP**: Highlight musuh lewat tembok saat equip HackerESP.
- **HUD in-match**: timer, team indicator, coin counter, 3 slot ability (Q/E/R hotkey), toast, banner jail.
- **Anti-exploit dasar**: rate limit per remote, validasi server-side untuk semua aksi (tag, coin, equip, fly).
- **Save data** via `DataStoreService` (fallback in-memory di Studio).
- **Modular**: dipisah antara `ReplicatedStorage/Shared`, `ServerScriptService/Server`, `StarterPlayer/Client`.

## Struktur File

```
src/
├── ReplicatedStorage/Shared/   # Dipakai bersama client+server
│   ├── GameConfig.lua          # Konstanta, definisi ability, harga, warna tim
│   ├── Remotes.lua             # RemoteEvent / RemoteFunction
│   ├── RulesText.lua           # Teks rules
│   ├── Theme.lua               # Token warna & helper UI
│   └── Utils.lua
├── ServerScriptService/Server/
│   ├── init.server.lua         # Bootstrap server, routing remote
│   ├── LobbyManager.lua        # Owns 4 Lobby
│   ├── Lobby.lua               # State machine per lobby + match
│   ├── TagSystem.lua           # Tag/jail/base touch detection
│   ├── ArenaResolver.lua       # Baca workspace.Arenas.Arena_X (edit manual di Studio)
│   ├── DataService.lua         # DataStore wrapper
│   ├── ShopService.lua         # Buy/Equip/Unequip validation
│   ├── AbilityService.lua      # Efek ability (speed/jump/fly) server-side
│   ├── AntiExploit.lua         # Rate limiting
│   └── Leaderstats.lua         # Mirror ke leaderstats folder
└── StarterPlayer/StarterPlayerScripts/Client/
    ├── init.client.lua         # Bootstrap client
    ├── LoadingUI.lua
    ├── RulesUI.lua
    ├── LobbyUI.lua
    ├── ShopUI.lua
    ├── HUD.lua
    └── AbilityController.lua   # ESP rendering + Fly input
```

## Cara Menggunakan (Rojo)

1. Install [Rojo](https://rojo.space/) (via `aftman install`, `rokit install`, atau binary manual).
2. Install plugin Rojo di Roblox Studio.
3. Di terminal, jalankan `rojo serve` dari folder repo.
4. Di Studio, place kosong, klik plugin Rojo → **Connect**.
5. **Setup arena (sekali saja):**
   - Buka `tools/SetupArenas.lua`, copy semua isinya
   - Di Studio: **View → Command Bar**
   - Paste → Enter
   - Muncul `workspace.Arenas` dengan Arena_1..Arena_4
   - **Ctrl+S** untuk save place (supaya arena persisted)
6. Tekan **F5** / Play.

### Edit arena manual

Setelah setup selesai, semua part (base, jail, safe zone, spawn, lobby pad)
ada sebagai instance persistent di `workspace.Arenas`. Kamu bebas:

- Pindah posisi
- Ganti ukuran / material / warna
- Tambah dekorasi (cukup jangan hapus nama part aslinya)
- Rebuild dari nol: hapus folder `Arenas` → run `SetupArenas.lua` lagi

Server hanya memerlukan **9 child part berikut** di tiap Arena_X:
`RedSpawn`, `BlueSpawn`, `RedBase`, `BlueBase`, `RedJail`, `BlueJail`,
`RedSafeZone`, `BlueSafeZone`, `LobbySpawn`.

> `rojo build -o BentenganGame.rbxlx` juga bisa dipakai untuk build file place manual.

## Lobby UI

- Tombol **—** di top bar atau tekan **M** untuk minimize lobby UI → pemain bisa jalan-jalan di lobby pad.
- Klik pill "OPEN LOBBY [M]" di atas layar atau tekan **M** lagi untuk membuka kembali.
- BillboardGui (label base/jail/lobby) hanya terlihat dari jarak ≤60 studs.

## Pengembangan

Lint dengan [selene](https://github.com/Kampfkarren/selene):

```bash
selene src/
```

Format dengan [StyLua](https://github.com/JohnnyMorganz/StyLua):

```bash
stylua src/
```

## Balancing

Edit `src/ReplicatedStorage/Shared/GameConfig.lua`:

- `MinPlayersPerLobby`, `MaxPlayersPerLobby`
- `CountdownSeconds`, `MatchDurationSeconds`
- `Rewards.*` - jumlah coin reward
- `Abilities.*.Price` / `Params` - harga dan parameter ability

## Lisensi

MIT.
