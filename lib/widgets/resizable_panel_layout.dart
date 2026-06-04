import 'package:flutter/material.dart';

import '../models/panel_layout.dart';
import '../theme/app_spacing.dart';

/// Resizable split between [grid] and [terminal] (vertical or horizontal).
///
/// Uses flex so the split never exceeds the parent (fixed [SizedBox] heights
/// could overflow when min grid + min terminal + handle > viewport).
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
  static const _flexScale = 1000;
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

  int get _terminalFlex =>
      (_terminalRatio * _flexScale).round().clamp(1, _flexScale - 1);

  int get _gridFlex => _flexScale - _terminalFlex;

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
          final total = constraints.maxHeight;
          return Column(
            children: [
              Expanded(flex: _gridFlex, child: widget.grid),
              _ResizeHandle(
                axis: Axis.vertical,
                onDragUpdate: (d) => _applyDrag(d, total),
                onDragEnd: _commitRatio,
              ),
              Expanded(flex: _terminalFlex, child: widget.terminal),
            ],
          );
        }

        final total = constraints.maxWidth;
        return Row(
          children: [
            Expanded(flex: _gridFlex, child: widget.grid),
            _ResizeHandle(
              axis: Axis.horizontal,
              onDragUpdate: (d) => _applyDrag(d, total),
              onDragEnd: _commitRatio,
            ),
            Expanded(flex: _terminalFlex, child: widget.terminal),
          ],
        );
      },
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
          color: theme.colorScheme.surfaceContainerLow,
          alignment: Alignment.center,
          child: Container(
            width: isVertical ? 56 : 4,
            height: isVertical ? 4 : 56,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
        ),
      ),
    );
  }
}
