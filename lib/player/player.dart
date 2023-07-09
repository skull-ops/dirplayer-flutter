
import 'package:dirplayer/director/castmembers.dart';
import 'package:dirplayer/director/file.dart';
import 'package:dirplayer/director/lingo/bytecode.dart';
import 'package:dirplayer/director/lingo/handler.dart';
import 'package:dirplayer/director/lingo/nodes/block.dart';
import 'package:dirplayer/player/runtime/movie.dart';
import 'package:dirplayer/player/runtime/vm.dart';

import '../director/lingo/node.dart';


class DirPlayer {
  PlayerVM vm = PlayerVM();
  //DirPlayer(DirectorFile file) : vm = PlayerVM(Movie(file));

  Future loadMovie(String path) async {
    await vm.loadMovieFromFile(path);
  }

  void play() {
    vm.play();
  }
}
