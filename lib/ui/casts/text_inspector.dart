import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dirplayer/player/runtime/cast_member.dart';
import 'package:flutter/material.dart';

import '../../director/chunks/bitmap.dart';
import '../../player/runtime/vm.dart';
import '../components/inspector.dart';

class TextInspector extends StatefulWidget {
  final PlayerVM vm;
  final TextMember member;

  const TextInspector({super.key, required this.vm, required this.member});

  @override
  State<StatefulWidget> createState() => _TextInspectorState();
}

class _TextInspectorState extends State<TextInspector> {
  @override
  Widget build(BuildContext context) {
    return Inspector(
      title: "Text: ${widget.member.getName()}", 
      child: Container(
        alignment: Alignment.topLeft,
        width: double.infinity,
        height: 300,
        color: Colors.white, 
        child: ListenableBuilder(
          listenable: Listenable.merge([widget.vm.breakpointManager, widget.vm]),
          builder: (context, child) => SingleChildScrollView(child: buildContent(context))
        ),
      )
    );
  }

  Widget buildContent(BuildContext context) {
    var lineSplitter = const LineSplitter();
    var lines = lineSplitter.convert(widget.member.text);
    
    return SizedBox(
      width: double.infinity,
      child: Text(lines.join("\r\n")),
    );
  }
}
