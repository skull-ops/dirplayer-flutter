import 'package:dirplayer/director/lingo/handler.dart';
import 'package:dirplayer/player/player.dart';
import 'package:dirplayer/player/runtime/cast_member.dart';
import 'package:dirplayer/player/runtime/castlib.dart';
import 'package:dirplayer/player/runtime/score.dart';
import 'package:dirplayer/ui/components/inspector.dart';
import 'package:dirplayer/ui/components/selectable_container.dart';
import 'package:dirplayer/ui/components/tree_view.dart';
import 'package:flutter/material.dart';

typedef OnSelectMemberCallback = Function(CastMemberReference memberRef);

class CastsWindow extends StatefulWidget {
  final DirPlayer player;
  final CastMemberReference? selectedMember;
  final OnSelectMemberCallback? onSelectMember;

  const CastsWindow({ super.key, required this.player, this.selectedMember, this.onSelectMember });

  @override
  State<StatefulWidget> createState() => _CastsWindowState();
}

class _CastsWindowState extends State<CastsWindow> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.player.vm.movie.castManager, widget.player.vm]),
      builder: (context, child) => Inspector(
        title: "Casts",
        child: SizedBox(width: double.infinity, height: 500, child: buildContent())
      ),
    );
  }

  Widget buildContent() {
    var vm = widget.player.vm;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var cast in vm.movie.castManager.casts) buildCast(cast)
        ],
      )
    );
  }

  Widget buildCast(CastLib cast) {
    return TreeView(
      label: Text(cast.name), 
      children: () => [
        for (var member in cast.members.values) buildMemberNode(member),
        const Divider(height: 4,)
      ]
    );
  }

  Widget buildMemberLabel(Member member) {
    return SelectableContainer(
      isSelected: widget.selectedMember == member.reference,
      onTap: () => onTapMember(member),
      child: Text("#${member.localCastNumber}: ${member.getName()}"),
    );
  }

  Widget buildMemberNode(Member member) {
    if (member is ScriptMember) {
      var script = member.cast.getScriptForMember(member.number);
      var handlers = script?.getOwnHandlers() ?? [];
      return TreeView(
        label: buildMemberLabel(member), 
        children: () => [for (var handler in handlers) buildScriptHandlerNode(handler)]
      );
    } else {
      return buildMemberLabel(member);
    }
  }

  Widget buildScriptHandlerNode(Handler handler) {
    return Text(handler.name);
  }

  void onTapMember(Member member) {
    widget.onSelectMember?.call(member.reference);
  }
}
