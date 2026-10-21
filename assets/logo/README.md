# Logo Centauri

Sumber (ekspor Canva, 1200×1200):

- `tile.png` — squircle hitam + centaur biru, transparan di luar sudut.
- `mark.png` — centaur biru di atas transparan, tanpa kotak.

Turunan yang dipakai aplikasi:

| Berkas | Ukuran | Dipakai untuk |
| :--- | :--- | :--- |
| `android/app/src/main/res/mipmap-*/ic_launcher.png` | 48–192 px | Launcher Android < 8 (legacy) |
| `.../ic_launcher_foreground.png` | 108–432 px | Adaptive icon Android 8+ |
| `.../ic_launcher_monochrome.png` | 108–432 px | Themed icon Android 13+ |
| `windows/runner/resources/app_icon.ico` | 16–256 px | EXE, taskbar, installer |
| `play_store_512.png` | 512 px | Google Play |

Aturan:

- Foreground adaptive memakai `mark.png`, bukan `tile.png`. Sudut tidak dibulatkan — launcher yang memotong.
- Background adaptive hitam `#000000` (`values/colors.xml`).
- `tile.png` hanya untuk legacy, Windows, dan ikon Play (Play memakai versi kotak penuh).
