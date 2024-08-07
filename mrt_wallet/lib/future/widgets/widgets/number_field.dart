import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mrt_wallet/app/core.dart'
    show APPConst, QuickContextAccsess, RangeTextInputFormatter, SafeState;
import 'package:mrt_wallet/app/models/models/typedef.dart'
    show NullStringString, StringVoid;
import 'constraints_box_view.dart';
import 'widget_constant.dart';

class NumberTextField extends StatefulWidget {
  const NumberTextField({
    super.key,
    required this.label,
    required this.onChange,
    this.padding = WidgetConstant.paddingVertical8,
    this.helperText,
    this.hintText,
    this.error,
    this.validator,
    this.defaultValue,
    required this.max,
    required this.min,
    this.suffixIcon,
    this.focusNode,
    this.nextFocus,
    this.disableWriting = false,
  });
  final int min;
  final int? max;
  final EdgeInsets padding;
  final String label;
  final String? helperText;
  final String? hintText;
  final String? error;
  final NullStringString? validator;
  final StringVoid onChange;
  final int? defaultValue;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final bool disableWriting;
  final Widget? suffixIcon;
  @override
  State<NumberTextField> createState() => NumberTextFieldState();
}

class NumberTextFieldState extends State<NumberTextField> with SafeState {
  bool add = false;
  bool minus = false;

  final TextEditingController controller = TextEditingController(text: "");
  void _add(bool isAdd) {
    int index = int.parse(controller.text);
    if (isAdd) {
      if (widget.max != null && index >= widget.max!) {
        index = widget.max!;
      } else {
        index++;
      }
    } else {
      if (index <= widget.min) {
        index = widget.min;
      } else {
        index--;
      }
    }
    controller.text = index.toString();
  }

  void onTap(bool isAdd) {
    _add(isAdd);
  }

  Timer? _timer;
  void onLongPress(bool isAdd) {
    if (isAdd) {
      add = true;
    } else {
      minus = true;
    }
    _add(isAdd);
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _add(isAdd);
    });
    setState(() {});
  }

  void onLongPressCancel() {
    add = false;
    minus = false;
    _timer?.cancel();
    _timer = null;
    setState(() {});
  }

  void onSubmitField(String v) {
    if (widget.nextFocus != null) {
      if (mounted) widget.nextFocus?.requestFocus();
    }
  }

  void listener() {
    widget.onChange(controller.text);
  }

  void changeIndex(int newIndex) {
    if (newIndex < widget.min ||
        (widget.max != null && newIndex > widget.max!)) {
      return;
    }
    controller.text = "$newIndex";
  }

  int? getValue() {
    return int.tryParse(controller.text);
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(listener);

    Future.delayed(Duration.zero, () {
      changeIndex(widget.defaultValue ?? widget.min);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    controller.removeListener(listener);
    controller.dispose();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (!mounted) return;
    super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Column(
        children: [
          ConstraintsBoxView(
            maxWidth: 350,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    WidgetConstant.height8,
                    AnimatedContainer(
                      duration: APPConst.animationDuraion,
                      decoration: BoxDecoration(
                          color: minus
                              ? context.theme.highlightColor
                              : Colors.transparent,
                          shape: BoxShape.circle),
                      child: GestureDetector(
                        onTap: () => onTap(false),
                        onLongPress: () => onLongPress(false),
                        onLongPressEnd: (e) => onLongPressCancel(),
                        child: IconButton(
                            onPressed: () {
                              onTap(false);
                            },
                            icon: const Icon(
                                Icons.indeterminate_check_box_rounded)),
                      ),
                    ),
                  ],
                ),
                Flexible(
                  child: TextFormField(
                    textAlign: TextAlign.center,
                    autovalidateMode: AutovalidateMode.always,
                    focusNode: widget.focusNode,
                    keyboardType: TextInputType.numberWithOptions(
                        decimal: false, signed: widget.min < 0),
                    controller: controller,
                    validator: widget.validator,
                    onFieldSubmitted: onSubmitField,
                    minLines: null,
                    maxLines: null,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      RangeTextInputFormatter(min: widget.min, max: widget.max)
                    ],
                    readOnly: widget.disableWriting,
                    decoration: InputDecoration(
                        filled: true,
                        hintText: widget.hintText,
                        helperText: widget.helperText,
                        suffixIcon: widget.suffixIcon,
                        errorText: widget.error,
                        labelText: widget.label,
                        border: OutlineInputBorder(
                            borderRadius: WidgetConstant.border8,
                            borderSide: BorderSide.none)),
                  ),
                ),
                Column(
                  children: [
                    WidgetConstant.height8,
                    AnimatedContainer(
                      duration: APPConst.animationDuraion,
                      decoration: BoxDecoration(
                          color: add
                              ? context.theme.highlightColor
                              : Colors.transparent,
                          shape: BoxShape.circle),
                      child: GestureDetector(
                        onTap: () => onTap(true),
                        onLongPress: () => onLongPress(true),
                        onLongPressEnd: (e) => onLongPressCancel(),
                        child: IconButton(
                          icon: const Icon(Icons.add_box),
                          onPressed: () {
                            onTap(true);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
