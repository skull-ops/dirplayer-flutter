import 'package:flutter/material.dart';

class Inspector extends StatelessWidget {
  final String title;
  final Widget child;

  const Inspector({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(child: Container(
          color: Colors.white,
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge,
          )
        )),
        const Divider(height: 1,),
        child,
      ],
    );
  }
}
