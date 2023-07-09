import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dirplayer/player/runtime/cast_member.dart';
import 'package:dirplayer/ui/player/main.dart';
import 'package:flutter/material.dart';

import '../../director/chunks/bitmap.dart';
import '../../player/runtime/vm.dart';
import '../components/inspector.dart';

class BitmapInspector extends StatefulWidget {
  final PlayerVM vm;
  final BitmapMember member;

  const BitmapInspector({super.key, required this.vm, required this.member});

  @override
  State<StatefulWidget> createState() => _BitmapInspectorState();
}

class _BitmapInspectorState extends State<BitmapInspector> {
  @override
  Widget build(BuildContext context) {
    var width = widget.member.imageRef.image.width;
    var height = widget.member.imageRef.image.height;
    var bitDepth = widget.member.imageRef.bitDepth;
    return Inspector(
      title: "Bitmap: ${widget.member.getName()} (${width}x$height) - $bitDepth bits", 
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: 300,
        color: Colors.black, 
        child: ListenableBuilder(
          listenable: Listenable.merge([widget.vm.breakpointManager, widget.vm]),
          builder: (context, child) => SingleChildScrollView(child: buildContent(context))
        ),
      )
    );
  }

  Widget buildContent(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BitmapMemberView(vm: widget.vm, memberRef: widget.member.reference, ink: 0)
        ],
      )
    );
  }
}
