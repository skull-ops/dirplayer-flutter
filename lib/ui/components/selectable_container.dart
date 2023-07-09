import 'package:flutter/material.dart';

class SelectableContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isSelected;
  const SelectableContainer({super.key, required this.child, required this.isSelected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: isSelected ? Colors.blue : Colors.transparent,
        child: child,
      )
    );
  }
}
