import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/director/util.dart';
import 'package:dirplayer/player/runtime/eval.dart';
import 'package:dirplayer/player/runtime/scope.dart';
import 'package:dirplayer/player/runtime/script.dart';
import 'package:dirplayer/ui/components/selectable_container.dart';
import 'package:dirplayer/ui/components/tree_view.dart';
import 'package:dirplayer/ui/scripting/script_inspector.dart';
import 'package:flutter/material.dart';

import '../../player/runtime/vm.dart';
import '../components/inspector.dart';

typedef OnSelectScopeCallback = void Function(int index);

class DebugInspector extends StatefulWidget {
  final PlayerVM vm;
  final int selectedScopeIndex;
  final OnSelectScopeCallback onSelectScope;
  const DebugInspector({super.key, required this.vm, required this.selectedScopeIndex, required this.onSelectScope});

  @override
  State<StatefulWidget> createState() => _DebugInspectorState();
}

class _DebugInspectorState extends State<DebugInspector> {
  @override
  Widget build(BuildContext context) {
    return Inspector(
      title: "Debug", 
      child: ListenableBuilder(
        listenable: widget.vm,
        builder: (context, child) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildToolbar(),
            buildConsoleContent(),
            Container(
              alignment: Alignment.topLeft,
              width: 300,
              height: 300,
              color: Colors.white, 
              child: SingleChildScrollView(child: buildContent()),
            )
          ]
        )
      )
    );
  }

  Widget buildConsoleContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 300,
          height: 32,
          child: TextField(
            onSubmitted: (value) {
              print(eval(widget.vm, value));
            },
            decoration: const InputDecoration(
              fillColor: Colors.green,
              border: OutlineInputBorder(),
            ),
          )
        )
      ],
    );
  }

  Widget buildScopeList() {
    return TreeView(
      label: const Text("Call Stack"), 
      children: () => [
        for (var (index, scope) in widget.vm.scopes.indexed.toList().reversed) buildScope(index, scope)
      ]
    );
  }

  Widget buildScope(int index, Scope scope) {
    return SelectableContainer(
      isSelected: widget.selectedScopeIndex == index,
      onTap: () => widget.onSelectScope(index),
      child: Text("#${scope.handler.name} - ${scope.receiver ?? scope.script}"),
    );
  }

  Widget buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildVariables(),
        buildScopeList(),
      ],
    );
  }

  Widget buildVariables() {
    var isScriptPaused = widget.vm.isScriptPaused;
    var currentScope = widget.vm.scopes.elementAtOrNull(widget.selectedScopeIndex);
    return TreeView(
      label: const Text("Variables"), 
      children: () => [
        TreeView(
          label: const Text("Globals"), 
          children: () => [
            for (var entry in widget.vm.globals.entries) buildDatumTree(entry.key, entry.value)
          ]
        ),
        if (/*isScriptPaused &&*/ currentScope != null) ...[
          TreeView(
            label: const Text("Locals"),
            children: () => [
              for (var entry in currentScope.locals.entries) buildDatumTree(entry.key, entry.value)
            ]
          ),
          TreeView(
            label: const Text("Params (Arguments)"),
            children: () => [
              for (var entry in currentScope.arguments) buildDatumNode(entry)
            ]
          )
        ],
        if (/*isScriptPaused && */currentScope != null) TreeView(
          label: const Text("Stack"),
          children: () => [
            for (var entry in currentScope.stack) buildDatumNode(entry)
          ]
        ),
      ],
    );
  }

  Widget buildDatumTree(String name, Datum value) {
    return TreeView(
      label: Text(name), 
      children: () => [
        //Text(value.toString()),
        buildDatumNode(value)
      ]
    );
  }

  Widget buildDatumNode(Datum value) {
    switch (value.type) {
    case DatumType.kDatumVarRef:
      return buildRefTree(value.toRef());
    default:
      return Text(value.toString());
    }
  }

  Widget buildRefTree(dynamic ref) {
    if (ref is ScriptInstance) {
      return buildScriptInstancePropertiesTree(ref);
    } else {
      return Text(ref.toString());
    }
  }

  Widget buildScriptInstancePropertiesTree(ScriptInstance obj) {
    var ancestor = obj.ancestor;
    return TreeView(
      label: Text(obj.toString()), 
      children: () => [
        if (ancestor != null) TreeView(label: const Text("#ancestor"), children: () => [buildScriptInstancePropertiesTree(ancestor)]),
        for (var entry in obj.properties.entries) buildDatumTree(entry.key, entry.value)
      ]
    );
  }

  Widget buildToolbar() {
    var currentBreakpoint = widget.vm.currentBreakpoint;
    return Row(
      children: [
        if(currentBreakpoint != null) IconButton(onPressed: () => { widget.vm.resumeBreakpoint() }, icon: const Icon(Icons.play_arrow))
      ]
    );
  }
}