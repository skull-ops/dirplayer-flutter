
import 'package:dirplayer/director/file.dart';
import 'package:dirplayer/player/player.dart';
import 'package:dirplayer/player/runtime/vm.dart';
import 'package:dirplayer/ui/player/main.dart';
import 'package:flutter/widgets.dart';

import '../../player/runtime/movie.dart';
/*
class PlayerWrapper extends StatefulWidget {
  String filePath;

  PlayerWrapper({ super.key, required this.filePath });

  @override
  State<StatefulWidget> createState() {
    return _PlayerWrapperState();
  }
}

class _PlayerWrapperState extends State<PlayerWrapper> {
  DirPlayer? player;

  @override
  void initState() {
    super.initState();
    loadMovie();
  }

  void loadMovie() async {
    var dir = await readDirectorFile(widget.filePath);
    setState(() {
      player = DirPlayer(dir);
    });
  }

  @override
  Widget build(BuildContext context) {
    var currentPlayer = player;
    if (currentPlayer == null) {
      return const Text("Loading");
    } else {
      return PlayerUI(player: currentPlayer);
    }
  }
}*/
