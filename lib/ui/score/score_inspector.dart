import 'package:dirplayer/ui/components/inspector.dart';
import 'package:flutter/material.dart';

import '../../player/player.dart';

class ScoreInspector extends StatefulWidget {
  final DirPlayer player;

  const ScoreInspector({ super.key, required this.player });

  @override
  State<StatefulWidget> createState() => _ScoreInspectorState();
}

class _ScoreInspectorState extends State<ScoreInspector> {
  int framesToRender = 10;
  int channelsToRender = 50;
  int frameWidth = 16;
  int channelHeight = 20;
  int frameHeaderHeight = 20;
  int frameScriptHeight = 16;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.player.vm,
      builder: (context, child) => buildContent(),
    );
  }

  Widget buildContent() {
    var vm = widget.player.vm;
    
    return Inspector(
      title: "Score",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildFrameScriptRow(),
          buildFrameHeaderRow(),
        ],
      )
    );
  }

  Widget buildFrameHeaderRow() {
    return SizedBox(
      height: frameHeaderHeight.toDouble(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int frame = 1; frame <= framesToRender; frame++) Container(
            width: frameWidth.toDouble(),
            color: frame == widget.player.vm.movie.currentFrame ? Colors.red : Colors.transparent,
            child: Text(frame.toString())
          )
        ],
      )
    );
  }

  Widget buildFrameScriptRow() {
    return SizedBox(
      height: frameHeaderHeight.toDouble(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int frame = 1; frame <= framesToRender; frame++) buildFrameScriptRowCell(frame)
        ],
      )
    );
  }

  Widget buildFrameScriptRowCell(int frame) {
    var script = widget.player.vm.movie.score.scriptReferences
      .where((element) => element.startFrame >= frame && element.endFrame <= frame)
      .firstOrNull;
    
    return Container(
      width: frameWidth.toDouble(),
      color: script != null ? Colors.blue : Colors.transparent,
      //child: Text(frame.toString())
    );
  }

  Widget buildChannelRow(int channelNumber) {
    return SizedBox(
      height: channelHeight.toDouble(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
        ],
      )
    );
  }

  /*Widget buildCast(CastLib cast) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(cast.castListEntry.name),
        for (var member in cast.members.values) Text(" - " + member.getName()),
        const Divider(height: 4,)
      ],
    );
  }*/
}
