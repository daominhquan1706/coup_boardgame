import 'package:flutter/widgets.dart';

const bool kEnableE2ETags =
    bool.fromEnvironment('ENABLE_E2E_TAGS', defaultValue: false);

class E2ETag extends StatelessWidget {
  final String label;
  final bool button;
  final bool textField;
  final bool enabled;
  final Widget child;

  const E2ETag({
    super.key,
    required this.label,
    required this.child,
    this.button = false,
    this.textField = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!kEnableE2ETags) return child;

    return Semantics(
      container: true,
      label: label,
      button: button,
      textField: textField,
      enabled: enabled,
      child: child,
    );
  }
}
