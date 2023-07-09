import 'package:flutter/material.dart';

class BreakpointIcon extends StatelessWidget {
  const BreakpointIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white, width: 1, strokeAlign: BorderSide.strokeAlignOutside)
      ),
    );
  }
}