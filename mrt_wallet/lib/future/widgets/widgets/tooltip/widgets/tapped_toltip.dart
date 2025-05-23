import 'package:flutter/material.dart';
import 'tooltip.dart';

class TappedTooltipView extends StatefulWidget {
  const TappedTooltipView(
      {required this.tooltipWidget, this.ignore = true, super.key});
  final ToolTipView tooltipWidget;
  final bool ignore;

  @override
  State<TappedTooltipView> createState() => _TappedTooltipViewState();
}

class _TappedTooltipViewState extends State<TappedTooltipView> {
  final GlobalKey<TooltipState> tooltipKey = GlobalKey();

  void ensureVisible() {
    tooltipKey.currentState?.ensureTooltipVisible();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: ensureVisible,
      // onHover: (e) {
      //   ensureVisible();
      // },
      child: IgnorePointer(
          ignoring: widget.ignore,
          child: widget.tooltipWidget.setKey(tooltipKey)),
    );
  }
}
