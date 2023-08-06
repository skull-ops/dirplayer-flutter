import 'package:dirplayer/player/runtime/cast_member.dart';
import 'package:dirplayer/player/runtime/scope.dart';
import 'package:dirplayer/player/runtime/score.dart';
import 'package:dirplayer/player/runtime/script.dart';
import 'package:dirplayer/ui/casts/bitmap_inspector.dart';
import 'package:dirplayer/ui/casts/text_inspector.dart';
import 'package:dirplayer/ui/debug/debug_inspector.dart';
import 'package:dirplayer/ui/player/main.dart';
import 'package:dirplayer/ui/player/wrapper.dart';
import 'package:dirplayer/ui/score/score_inspector.dart';
import 'package:dirplayer/ui/scripting/script_inspector.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../player/player.dart';
import '../casts/casts_window.dart';
import '../casts/field_inspector.dart';

class DirStudio extends StatefulWidget {
  final DirPlayer player;
  final bool autoPlay;
  final String? initialMovieFileName;

  const DirStudio({
    super.key, 
    required this.player,
    this.autoPlay = false,
    this.initialMovieFileName = kIsWeb ? "dcr/habbo.dcr" : null
  });

  @override
  State<StatefulWidget> createState() => _DirStudioState();
}

class _DirStudioState extends State<DirStudio> {
  CastMemberReference? selectedMemberRef;
  bool isFilePicked = false;
  var selectedScopeIndex = 0;

  @override
  void initState() {
    super.initState();

    widget.player.vm.onScriptError = onScriptError;
    loadInitialMovie();
  }

  void loadInitialMovie() async {
    String? preloadMovieName = widget.initialMovieFileName;
    if (preloadMovieName != null && preloadMovieName.isNotEmpty) {
      await widget.player.loadMovie(preloadMovieName).then((_) => setState(() { isFilePicked = true; }));
      if (widget.autoPlay) {
        widget.player.play();
      }
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    widget.player.vm.onScriptError = null;
  }

  void onScriptError(Scope scope, dynamic err) {
    var member = widget.player.vm.movie.castManager.findMemberForScript(scope.script);
    selectMember(member!.reference);
  }

  void loadMovieAndPlay() async {
    var pickerResult = await FilePicker.platform.pickFiles(); 
    if (pickerResult != null) {
      await widget.player.loadMovie(pickerResult.files.single.path!);
      widget.player.play();
    }
  }

  Script? get selectedScript {
    var selectedMemberRef = this.selectedMemberRef;
    if (selectedMemberRef != null) {
      return widget.player.vm.movie.castManager
        .getCastByNumber(selectedMemberRef.castLib)
        ?.getScriptForMember(selectedMemberRef.castMember);
    } else {
      return null;
    }
  }

  void selectMember(CastMemberReference? ref) {
    setState(() {
      selectedMemberRef = ref;
    });
  }

  Widget buildPlayerUI() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.transparent,
      alignment: Alignment.center,
      child: PlayerUI(player: widget.player)
    );
  }

  Widget buildSidebar() {
    return Container(
      width: 300,
      color: Colors.grey,
      child: Column(
        children: [
          buildTimeToolBar(),
          ScoreInspector(player: widget.player),
          CastsWindow(
            player: widget.player,
            onSelectMember: (ref) { selectMember(ref); },
            selectedMember: selectedMemberRef,
          ),
        ],
      ),
    );
  }

  void pickAndLoadMovie() async {
    var result = await FilePicker.platform.pickFiles();
    if (result != null) {
      var file = result.files.single;
      if (kIsWeb) {
        await widget.player.vm.loadMovieFromBytes(file.bytes!, file.name);
      } else {
        await widget.player.vm.loadMovieFromFile(file.path!);
      }
      setState(() {
        isFilePicked = true;
      });
      if (widget.autoPlay) {
        widget.player.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isFilePicked) {
      return IconButton(onPressed: () => { pickAndLoadMovie() }, icon: Icon(Icons.folder));
    }
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black12,
      alignment: Alignment.topLeft,
      child: Row(
        //alignment: Alignment.topLeft,
        children: [
          buildSidebar(),
          Expanded(child: Column(
            children: [
              Expanded(child: buildPlayerUI()),
              IntrinsicHeight(child: buildSelectedMemberWindow()),
            ],
          )),
        ],
      )
    );
  }

  void selectScope(int index) {
    var scope = widget.player.vm.scopes.elementAtOrNull(index);
    var member = scope != null ? widget.player.vm.movie.castManager.findMemberForScript(scope.script) : null;
    setState(() {
      selectedScopeIndex = index;
      if (scope != null && member != null) {
        selectedMemberRef = member.reference;
      }
    });
  }

  Widget buildScriptingWindow() {
    var selectedScript = this.selectedScript;
    return Row(
      children: [
        DebugInspector(
          vm: widget.player.vm,
          selectedScopeIndex: selectedScopeIndex,
          onSelectScope: (index) => selectScope(index),
        ),
        if (selectedScript != null) Expanded(
          child: ScriptInspector(
            key: Key("script_inspector_${selectedScript.name}"), 
            vm: widget.player.vm, 
            script: selectedScript,
            selectedScopeIndex: selectedScopeIndex,
          )
        )
      ],
    );
  }

  Widget buildSelectedMemberWindow() {
    var selectedScript = this.selectedScript;
    var selectedMemberRef = this.selectedMemberRef;
    if (selectedScript != null) {
      return buildScriptingWindow();
    } if (selectedMemberRef != null) {
      var selectedMember = widget.player.vm.movie.castManager.findMemberByRef(selectedMemberRef);
      if (selectedMember != null) {
        return buildMemberInspector(selectedMember);
      }
    }
    return const SizedBox.shrink();
  }

  Widget buildMemberInspector(Member member) {
    if (member is BitmapMember) {
      return BitmapInspector(vm: widget.player.vm, member: member);
    } else if (member is TextMember) {
      return TextInspector(vm: widget.player.vm, member: member);
    } else if (member is FieldMember) {
      return FieldInspector(vm: widget.player.vm, member: member);
    } else {
      //return const SizedBox.shrink();
      return Text(member.type.name);
    }
  }

  Widget buildTimeToolBar() {
    return Row(
      children: [
        IconButton(onPressed: () => { widget.player.vm.play() }, icon: const Icon(Icons.play_arrow)),
        IconButton(onPressed: () => { widget.player.vm.stop() }, icon: const Icon(Icons.stop)),
        IconButton(onPressed: () => { widget.player.vm.reset() }, icon: const Icon(Icons.restart_alt)),
      ],
    );
  }
}
