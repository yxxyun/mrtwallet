import 'package:flutter/material.dart';
import 'package:mrt_wallet/app/extention/app_extentions/context.dart';
import 'package:mrt_wallet/app/models/models/typedef.dart' show VoidSetT;
import 'text_widget.dart';

class AppSegmentedButton<T> extends StatelessWidget {
  const AppSegmentedButton(
      {super.key,
      required this.items,
      required this.selected,
      required this.onChangeSelected});
  final Set<T> selected;
  final Map<T, String> items;
  final VoidSetT<T> onChangeSelected;
  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 1,
      scaleFactor: 0.5,
      child: SegmentedButton<T>(
        emptySelectionAllowed: false,
        multiSelectionEnabled: false,
        showSelectedIcon: false,
        segments: items.keys
            .map<ButtonSegment<T>>((e) => ButtonSegment(
                value: e,
                label: OneLineTextWidget(items[e]!,
                    style: context.textTheme.labelSmall)))
            .toList(),
        selected: selected,
        onSelectionChanged: onChangeSelected,
      ),
    );
  }
}
