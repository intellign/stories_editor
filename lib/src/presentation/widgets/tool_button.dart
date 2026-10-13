import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared editor control, with an accessible hit target and restrained styling.
class ToolButton extends StatelessWidget {
  final Function() onTap;
  final Widget child;
  final Color? backGroundColor;
  final EdgeInsets? padding;
  final Function()? onLongPress;
  final Color colorBorder;

  const ToolButton({
    Key? key,
    required this.onTap,
    required this.child,
    this.backGroundColor,
    this.padding,
    this.onLongPress,
    this.colorBorder = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderColor = colorBorder == Colors.white
        ? Colors.white.withOpacity(.18)
        : colorBorder;
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: backGroundColor ?? const Color(0xDD202126),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          onLongPress: onLongPress == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onLongPress!();
                },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: Center(
              child: IconTheme.merge(
                data: const IconThemeData(size: 21, color: Colors.white),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
