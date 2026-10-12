/// Mode target generate canvas (FR-07).
/// Murni hint untuk prompt berikutnya — TIDAK me-resize frame yang sudah ada.
/// [width] adalah lebar CSS fixed frame hasil generate.
enum ViewportMode {
  mobile(390, 'Mobile', '390px'),
  tablet(768, 'Tablet', '768px'),
  desktop(1280, 'Desktop', '1280px');

  const ViewportMode(this.width, this.label, this.widthLabel);

  final double width;
  final String label;
  final String widthLabel;
}
