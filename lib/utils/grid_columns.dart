/// Responsive column count for repo grid (1–6) based on available width.
int gridColumnsForWidth(double width, {double minTileWidth = 220}) {
  if (width <= 0) return 1;
  final computed = (width / minTileWidth).floor();
  return computed.clamp(1, 6);
}
