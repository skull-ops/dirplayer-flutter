import 'dart:ui' as ui;

import 'package:dirplayer/player/player.dart';
import 'package:dirplayer/player/runtime/cast_member.dart';
import 'package:dirplayer/player/runtime/score.dart';
import 'package:dirplayer/player/runtime/vm.dart';
import 'package:flutter/material.dart';

import '../../player/runtime/sprite.dart';

class BitmapMemberView extends StatefulWidget {
  final PlayerVM vm;
  final CastMemberReference memberRef;
  final int ink;

  const BitmapMemberView({ super.key, required this.vm, required this.memberRef, required this.ink });
  @override
  State<StatefulWidget> createState() => _BitmapMemberViewState();
}

class _BitmapMemberViewState extends State<BitmapMemberView> {
  BitmapMember get member => widget.vm.movie.castManager.findMemberByRef(widget.memberRef) as BitmapMember;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO blend
    return StreamBuilder(
      key: Key(member.reference.toString()),
      stream: member.imageRef.uiImage,
      initialData: null,
      builder: (context, snapshot) => RawImage(
        image: snapshot.data,
      ),
    );
  }
}

class PlayerUI extends StatefulWidget {
  final DirPlayer player;

  const PlayerUI({ super.key, required this.player });
  @override
  State<StatefulWidget> createState() => _PlayerUIState();
}

class _PlayerUIState extends State<PlayerUI> {
  final stageRenderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.player.vm.stage.repaintKey = stageRenderKey;
  }

  @override
  void deactivate() {
    super.deactivate();
    widget.player.vm.stage.repaintKey = null;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: stageRenderKey,
      child: ListenableBuilder(
        listenable: widget.player.vm,
        builder: (context, child) => buildMovieUI(),
      )
    );
  }

  /*Widget buildStageUI() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      child: Stack(children: [buildMovieUI()]),
    );
  }*/

  Widget buildMovieUI() {
    var movie = widget.player.vm.movie;
    var movieLeft = movie.movieLeft;
    var movieTop = movie.movieTop;
    var movieRight = movie.movieRight;
    var movieBottom = movie.movieBottom;

    var width = movieRight - movieLeft;
    var height = movieBottom - movieTop;
    var color = Colors.black; //.fromARGB(255, config.D7stageColorR, config.D7stageColorG, config.D7stageColorB);

    var sortedSprites = widget.player.vm.movie.score.channels
      .map((e) => e.sprite)
      .where((element) => element.member != null && element.visible)
      .toList();
      
    sortedSprites.sort((left, right) => left.locZ.compareTo(right.locZ));

    return Container(
      width: width.toDouble(),
      height: height.toDouble(),
      decoration: BoxDecoration(
        color: color, 
        border: Border.all(color: Colors.black)
      ),
      child: Stack(
        children: [
          for (var sprite in sortedSprites) buildSprite(sprite)
        ],
      )
    );
  }

  Widget buildSprite(Sprite sprite) {
    var memberRef = sprite.member;
    var member = memberRef != null ? widget.player.vm.movie.castManager.findMemberByRef(memberRef) : null;
    var offsetX = 0;
    var offsetY = 0;

    Widget spriteWidget;
    if (member is BitmapMember) {
      spriteWidget = BitmapMemberView(vm: widget.player.vm, memberRef: member.reference, ink: sprite.ink);
      offsetX = -member.regX;
      offsetY = -member.regY;
    } else if (member is FieldMember) {
      spriteWidget = SizedBox(
        width: sprite.width.toDouble(),
        height: sprite.height.toDouble(),
        child: TextField(
          textAlign: TextAlign.center,
          decoration: null,
          onChanged: (value) => member.text = value, // TODO call keyDown
        ),
      );
    } else {
      spriteWidget = const SizedBox.shrink();
    }

    return Positioned(
      left: (sprite.locH + offsetX).toDouble(), 
      top: (sprite.locV + offsetY).toDouble(), 
      child: spriteWidget
    );
  }
}
