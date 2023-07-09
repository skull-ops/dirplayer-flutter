import 'package:flutter/material.dart';

class TreeView extends StatefulWidget {
  final Widget label;
  final List<Widget> Function() children;

  const TreeView({
    super.key,
    required this.label,
    required this.children,
  });
  
  @override
  State<StatefulWidget> createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> {
  bool isExpanded = false;

  void toggleExpanded() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
            onTap: () { toggleExpanded(); },
            child: Container(
              width: 12,
              height: 12,
              alignment: Alignment.center,
              transformAlignment: Alignment.center,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
              child: OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                alignment: Alignment.center,
                child: Text(isExpanded ? "-" : "+")
                )
              )
            ),
          const SizedBox(width: 4),
          widget.label,
          ],
        ),
        buildChildren(isExpanded ? widget.children() : []),
      ],
    );
  }

  Widget buildChildren(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      )
    );
  }
}

