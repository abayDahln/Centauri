# Centauri Design Import (plugin Figma)

Plugin companion untuk mengimpor desain halaman Centauri menjadi **frame/layer
yang bisa diedit** di Figma. Centauri menghasilkan *payload* JSON (bbox +
computed style + teks); plugin ini merekonstruksinya.

> **Butuh plugin?** Tidak untuk hasil akhir. Menu **Ekspor → Figma** menyalin
> SVG halaman aktif ke clipboard (format `image/svg+xml`), jadi langsung bisa
> ditempel ke board Figma dengan Ctrl+V - group, text layer, gambar, dan frame
> ikut terbawa. Plugin di bawah ini tetap berguna bila ingin memakai payload
> JSON (layer per node) alih-alih hasil render.

## Alur pakai (plugin)

1. Di Centauri, buka halaman yang mau diekspor.
2. Klik **Ekspor → Figma (plugin)**.
   - Payload otomatis **tersalin ke clipboard** dan opsional **disimpan** sebagai
     file `*.centauri-figma.json`.
3. Buka plugin **Centauri Design Import** di Figma (menu Plugins → Development).
4. Tempel payload ke textarea (atau seret file `.centauri-figma.json` ke area itu).
5. Klik **Bangun layer**. Sebuah root frame seukuran halaman dibuat, berisi
   frame/layer bersarang yang mengikuti struktur DOM.

## Instalasi (mode development)

1. Buka Figma Desktop.
2. Menu **Plugins → Development → Import plugin from manifest…**
3. Pilih `figma-plugin/manifest.json` di repo ini.
4. Plugin muncul di daftar *Development*.

## Struktur payload (`centauri-figma` v1)

```jsonc
{
  "app": "centauri",
  "format": "centauri-figma",
  "version": 1,
  "exportedAt": "2026-01-01T00:00:00.000Z",
  "page": { "name": "Home", "slug": "home.html", "width": 1440, "height": 2400 },
  "nodes": [
    {
      "id": "n0",
      "tag": "section",
      "name": "section#hero",
      "rect": { "x": 0, "y": 0, "w": 1440, "h": 600 },
      "styles": { "backgroundColor": "rgb(255,255,255)", "fontSize": "16px" },
      "text": "",
      "children": [ /* ... */ ]
    }
  ]
}
```

### Pemetaan ke Figma

| Payload              | Figma                              |
| -------------------- | ---------------------------------- |
| `page.width/height`  | ukuran root frame                  |
| node                 | `FRAME` (posisi absolut)           |
| `styles.backgroundColor` | `fills` (SOLID)                |
| `styles.borderRadius`| `cornerRadius`                     |
| `styles.borderWidth/Color` | `strokes` + `strokeWeight`   |
| `styles.opacity`     | `opacity`                          |
| `text` (leaf)        | `TEXT` layer (font Inter)          |
| `children`           | frame bersarang                    |

## Batasan

- Font default `Inter`; font lain di-*fallback* ke Inter.
- Gradien, gambar, bayangan kompleks, dan transform 3D tidak direkonstruksi.
- Posisi memakai koordinat absolut (bukan auto-layout Figma) agar hasilnya
  setia pada tampilan preview.
