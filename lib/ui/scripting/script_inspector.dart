import 'package:dirplayer/common/codewriter.dart';
import 'package:dirplayer/director/lingo/bytecode.dart';
import 'package:dirplayer/director/lingo/handler.dart';
import 'package:dirplayer/player/runtime/debug/breakpoint_manager.dart';
import 'package:dirplayer/player/runtime/script.dart';
import 'package:dirplayer/player/runtime/vm.dart';
import 'package:dirplayer/ui/components/inspector.dart';
import 'package:dirplayer/ui/components/tree_view.dart';
import 'package:dirplayer/ui/icons/breakpoint.dart';
import 'package:flutter/material.dart';

import '../../player/runtime/scope.dart';

class ScriptInspector extends StatefulWidget {
  final PlayerVM vm;
  final Script script;
  final int selectedScopeIndex;

  const ScriptInspector({super.key, required this.vm, required this.script, required this.selectedScopeIndex});

  @override
  State<StatefulWidget> createState() => _ScriptInspectorState();
}

class _ScriptInspectorState extends State<ScriptInspector> {
  @override
  Widget build(BuildContext context) {
    return Inspector(
        title: "Script: ${widget.script.name}",
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
    return SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (var handler in widget.script.getOwnHandlers()) buildHandlerContent(context, handler)],
      )
    );
  }

  Widget buildHandlerContent(BuildContext context, Handler handler) {
    var currentScope = widget.vm.currentScope;
    var currentHandler = currentScope?.handler;
    var isCurrent = currentHandler == handler;
    var isSelectedScope = selectedScope?.handler == handler;

    Color? color;
    if (isCurrent) {
      color = Colors.yellow;
    } else if (isSelectedScope) {
      color = Colors.black12;
    }

    var writer = CodeWriter();
    handler.writeHandlerDefinition(writer);
    var definitionString = writer.str();

    return TreeView(
      label: Container(
          color: color,
        child: Text(definitionString, style: monospacedTextStyle)
      ),
      children: () => [
        for (var bytecode in handler.bytecodeArray) buildBytecodeLine(handler, bytecode),
      ],
    );

    /*return Text(
      codeString,
      style: monospacedTextStyle,
    );*/
  }

  Scope? get selectedScope {
    if (widget.selectedScopeIndex == -1) {
      return null;
    } else {
      return widget.vm.scopes.elementAtOrNull(widget.selectedScopeIndex);
    }
  }

  Widget buildBytecodeLine(Handler handler, Bytecode bytecode) {
    var currentScope = widget.vm.currentScope;
    var currentHandler = currentScope?.handler;
    var isCurrent = currentHandler == handler && currentHandler!.bytecodeArray[currentScope!.handlerPosition] == bytecode;
    var isSelectedScope = selectedScope?.handler == handler && handler.bytecodeArray[selectedScope!.handlerPosition] == bytecode;

    var writer = CodeWriter();
    bytecode.writeBytecodeText(writer, handler.script.dir.dotSyntax);

    Color? color;
    if (isCurrent) {
      color = Colors.yellow;
    } else if (isSelectedScope) {
      color = Colors.black12;
    }

    return IntrinsicHeight(
        child: Container(
            color: color,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildLineHeader(handler, bytecode, isCurrent),
                Text(
                  writer.str(),
                  style: monospacedTextStyle,
                )
              ],
        )
      )
    );
  }

  Widget buildLineHeader(Handler handler, Bytecode bytecode, bool isCurrent) {
    var breakpoint = widget.vm.breakpointManager.findBreakpointForBytecode(widget.script, handler, bytecode.pos);
    var hasBreakpoint = breakpoint != null;
    return GestureDetector(
        onTap: () => toggleBreakpoint(handler, bytecode),
        child: Container(
          alignment: Alignment.center,
          color: isCurrent ? Colors.red : Colors.black12,
          width: 16,
        child: hasBreakpoint ? BreakpointIcon() : null, //Text(isCurrent ? ">" : ""),
      )
    );
  }

  TextStyle get monospacedTextStyle {
    return const TextStyle(
      fontFamily: "Courier New",
      fontSize: 16
    );
  }

  void toggleBreakpoint(Handler handler, Bytecode bytecode) {
    var breakpoint = widget.vm.breakpointManager.findBreakpointForBytecode(widget.script, handler, bytecode.pos);
    if (breakpoint != null) {
      widget.vm.breakpointManager.removeBreakpoint(breakpoint);
    } else {
      widget.vm.breakpointManager.addBreakpoint(
        Breakpoint(widget.script.name, handler.name, bytecode.pos)
      );
    }
  }
}
