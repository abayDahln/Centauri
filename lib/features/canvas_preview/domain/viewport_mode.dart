import 'dart:ui';

/// Target layout hasil generate (FR-07) — internal saja.
/// Dipilih OTOMATIS: eksplisit dari prompt user menang, selebihnya AI
/// memilih via [detectAutoViewport] + `<meta name="viewport-target">`.
/// Tidak ada toggle manual di UI.
/// [width] adalah lebar CSS fixed frame hasil generate.
enum ViewportMode {
  mobile(390, 'Mobile', '390px', height: 844),
  tablet(768, 'Tablet', '768px', height: 1024),
  desktop(1280, 'Windows', '1280px', height: 800),
  hd(1920, 'HD', '1920px', height: 1080);

  const ViewportMode(
    this.width,
    this.label,
    this.widthLabel, {
    this.height = 800,
  });

  final double width;
  final String label;
  final String widthLabel;
  final double height;

  Size get defaultSize => Size(width, height);
}
