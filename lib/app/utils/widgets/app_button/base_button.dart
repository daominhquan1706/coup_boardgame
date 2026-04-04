import 'package:flutter/cupertino.dart';

class BaseButton extends StatelessWidget {
  const BaseButton({
    super.key,
    required this.onPressed,
    this.color,
    this.disabledColor = CupertinoColors.quaternarySystemFill,
    required this.child,
  });
  final VoidCallback? onPressed;
  final Color? color;
  final Color disabledColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      color: color,
      borderRadius: BorderRadius.zero,
      disabledColor: disabledColor,
      child: child,
    );
  }
}
