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
│   ├── MapGenerator.lua        # Bangun 4 arena prosedural
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

1. Install [Rojo](https://rojo.space/) di komputer kamu (via `aftman install`, `foreman`, `rokit install`, atau binary manual).
2. Install plugin Rojo di Roblox Studio.
3. Buka folder repo ini di terminal dan jalankan:

   ```bash
   rojo serve
   ```

4. Di Roblox Studio, buka place baru (kosong), klik tombol plugin Rojo, lalu **Connect** ke `localhost:34872` (default).
5. Tekan **F5** / Play untuk menjalankan game. Loading screen akan muncul, lalu rules UI, lalu lobby UI.

> Alternatif: `rojo build -o BentenganGame.rbxlx` untuk membangun file place lalu dibuka manual di Studio.

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
