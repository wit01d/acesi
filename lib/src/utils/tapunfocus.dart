import 'package:flutter/material.dart';

class UnfocusOnTap extends StatelessWidget {
  const UnfocusOnTap({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          final FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },
        child: child,
      );
}
