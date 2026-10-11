/// Mode rasio aspek canvas (FR-07).
/// [width] null berarti lebar penuh (desktop).
enum ViewportMode {
  mobile(375, 'Mobile', '375px'),
  tablet(768, 'Tablet', '768px'),
  desktop(null, 'Desktop', '100%');

  const ViewportMode(this.width, this.label, this.widthLabel);

  final double? width;
  final String label;
  final String widthLabel;
}
