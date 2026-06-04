import 'package:flutter/material.dart';

import '../models/panel_layout.dart';

/// Resizable split between [grid] and [terminal] (vertical or horizontal).
class ResizablePanelLayout extends StatefulWidget {
  const ResizablePanelLayout({
    super.key,
    required this.layout,
    required this.grid,
    required this.terminal,
    required this.initialTerminalRatio,
    this.onRatioChanged,
    this.minTerminalSize = 100,
    this.minGridSize = 120,
  });

  final PanelLayout layout;
  final Widget grid;
  final Widget terminal;
  final double initialTerminalRatio;
  final ValueChanged<double>? onRatioChanged;
  final double minTerminalSize;
  final double minGridSize;

  @override
  State<ResizablePanelLayout> createState() => _ResizablePanelLayoutState();
}

class _ResizablePanelLayoutState extends State<ResizablePanelLayout> {
  static const _handleThickness = 8.0;
  late double _terminalRatio;

  @override
  void initState() {
    super.initState();
    _terminalRatio = _clampRatio(widget.initialTerminalRatio);
  }

  @override
  void didUpdateWidget(ResizablePanelLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layout != widget.layout) {
      _terminalRatio = _clampRatio(widget.initialTerminalRatio);
    } else if (oldWidget.initialTerminalRatio != widget.initialTerminalRatio) {
      _terminalRatio = _clampRatio(widget.initialTerminalRatio);
    }
  }

  double _clampRatio(double ratio) => ratio.clamp(0.12, 0.88);

  void _applyDrag(double delta, double total) {
    if (total <= 0) return;
    setState(() {
      if (widget.layout == PanelLayout.stacked) {
        _terminalRatio = _clampRatio(_terminalRatio - delta / total);
      } else {
        _terminalRatio = _clampRatio(_terminalRatio + delta / total);
      }
    });
  }

  void _commitRatio() {
    widget.onRatioChanged?.call(_terminalRatio);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (widget.layout == PanelLayout.stacked) {
          return _buildStacked(constraints.maxHeight);
        }
        return _buildSideBySide(constraints.maxWidth);
      },
    );
  }

  Widget _buildStacked(double totalHeight) {
    var terminalHeight = totalHeight * _terminalRatio;
    terminalHeight = terminalHeight.clamp(
      widget.minTerminalSize,
      totalHeight - widget.minGridSize - _handleThickness,
    );
    final gridHeight = totalHeight - terminalHeight - _handleThickness;

    return Column(
      children: [
        SizedBox(height: gridHeight, child: widget.grid),
        _ResizeHandle(
          axis: Axis.vertical,
          onDragUpdate: (d) => _applyDrag(d, totalHeight),
          onDragEnd: _commitRatio,
        ),
        SizedBox(height: terminalHeight, child: widget.terminal),
      ],
    );
  }

  Widget _buildSideBySide(double totalWidth) {
    var terminalWidth = totalWidth * _terminalRatio;
    terminalWidth = terminalWidth.clamp(
      widget.minTerminalSize,
      totalWidth - widget.minGridSize - _handleThickness,
    );
    final gridWidth = totalWidth - terminalWidth - _handleThickness;

    return Row(
      children: [
        SizedBox(width: gridWidth, child: widget.grid),
        _ResizeHandle(
          axis: Axis.horizontal,
          onDragUpdate: (d) => _applyDrag(d, totalWidth),
          onDragEnd: _commitRatio,
        ),
        SizedBox(width: terminalWidth, child: widget.terminal),
      ],
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.axis,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final Axis axis;
  final ValueChanged<double> onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVertical = axis == Axis.vertical;

    return GestureDetector(
      onVerticalDragUpdate: isVertical
          ? (d) => onDragUpdate(d.delta.dy)
          : null,
      onHorizontalDragUpdate: !isVertical
          ? (d) => onDragUpdate(d.delta.dx)
          : null,
      onVerticalDragEnd: isVertical ? (_) => onDragEnd() : null,
      onHorizontalDragEnd: !isVertical ? (_) => onDragEnd() : null,
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: isVertical
            ? SystemMouseCursors.resizeUpDown
            : SystemMouseCursors.resizeLeftRight,
        child: Container(
          width: isVertical ? double.infinity : 8,
          height: isVertical ? 8 : double.infinity,
          color: theme.dividerColor,
          child: Center(
            child: Container(
              width: isVertical ? 48 : 4,
              height: isVertical ? 4 : 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
