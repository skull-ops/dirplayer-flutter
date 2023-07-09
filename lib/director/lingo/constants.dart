
import 'package:dirplayer/director/lingo/chunk_expr_type.dart';
import 'package:dirplayer/director/lingo/opcode.dart';
import 'package:dirplayer/director/lingo/put_type.dart';

Map<OpCode, String> opcodeNames = {
	// single-byte
	OpCode.kOpRet: "ret" ,
	OpCode.kOpRetFactory: "retfactory" ,
	OpCode.kOpMul: "mul" ,
	OpCode.kOpPushZero: "pushzero" ,
	OpCode.kOpAdd: "add" ,
	OpCode.kOpSub: "sub" ,
	OpCode.kOpDiv: "div" ,
	OpCode.kOpMod: "mod" ,
	OpCode.kOpInv: "inv" ,
	OpCode.kOpJoinStr: "joinstr" ,
	OpCode.kOpJoinPadStr: "joinpadstr" ,
	OpCode.kOpLt: "lt" ,
	OpCode.kOpLtEq: "lteq" ,
	OpCode.kOpNtEq: "nteq" ,
	OpCode.kOpEq: "eq" ,
	OpCode.kOpGt: "gt" ,
	OpCode.kOpGtEq: "gteq" ,
	OpCode.kOpAnd: "and" ,
	OpCode.kOpOr: "or" ,
	OpCode.kOpNot: "not" ,
	OpCode.kOpContainsStr: "containsstr" ,
	OpCode.kOpContains0Str: "contains0str" ,
	OpCode.kOpGetChunk: "getchunk" ,
	OpCode.kOpHiliteChunk: "hilitechunk" ,
	OpCode.kOpOntoSpr: "ontospr" ,
	OpCode.kOpIntoSpr: "intospr" ,
	OpCode.kOpGetField: "getfield" ,
	OpCode.kOpStartTell: "starttell" ,
	OpCode.kOpEndTell: "endtell" ,
	OpCode.kOpPushList: "pushlist" ,
	OpCode.kOpPushPropList: "pushproplist" ,
	OpCode.kOpSwap: "swap" ,

	// multi-byte
  OpCode.kOpPushInt8: "pushint8" ,
  OpCode.kOpPushArgListNoRet: "pusharglistnoret" ,
  OpCode.kOpPushArgList: "pusharglist" ,
  OpCode.kOpPushCons: "pushcons" ,
  OpCode.kOpPushSymb: "pushsymb" ,
  OpCode.kOpPushVarRef: "pushvarref" ,
  OpCode.kOpGetGlobal2: "getglobal2" ,
  OpCode.kOpGetGlobal: "getglobal" ,
  OpCode.kOpGetProp: "getprop" ,
  OpCode.kOpGetParam: "getparam" ,
  OpCode.kOpGetLocal: "getlocal" ,
  OpCode.kOpSetGlobal2: "setglobal2" ,
  OpCode.kOpSetGlobal: "setglobal" ,
  OpCode.kOpSetProp: "setprop" ,
  OpCode.kOpSetParam: "setparam" ,
  OpCode.kOpSetLocal: "setlocal" ,
  OpCode.kOpJmp: "jmp" ,
  OpCode.kOpEndRepeat: "endrepeat" ,
  OpCode.kOpJmpIfZ: "jmpifz" ,
  OpCode.kOpLocalCall: "localcall" ,
  OpCode.kOpExtCall: "extcall" ,
  OpCode.kOpObjCallV4: "objcallv4" ,
  OpCode.kOpPut: "put" ,
  OpCode.kOpPutChunk: "putchunk" ,
  OpCode.kOpDeleteChunk: "deletechunk" ,
  OpCode.kOpGet: "get" ,
  OpCode.kOpSet: "set" ,
  OpCode.kOpGetMovieProp: "getmovieprop" ,
  OpCode.kOpSetMovieProp: "setmovieprop" ,
  OpCode.kOpGetObjProp: "getobjprop" ,
  OpCode.kOpSetObjProp: "setobjprop" ,
  OpCode.kOpTellCall: "tellcall" ,
  OpCode.kOpPeek: "peek" ,
  OpCode.kOpPop: "pop" ,
  OpCode.kOpTheBuiltin: "thebuiltin" ,
  OpCode.kOpObjCall: "objcall" ,
  OpCode.kOpPushChunkVarRef: "pushchunkvarref" ,
  OpCode.kOpPushInt16: "pushint16" ,
  OpCode.kOpPushInt32: "pushint32" ,
  OpCode.kOpGetChainedProp: "getchainedprop" ,
  OpCode.kOpPushFloat32: "pushfloat32" ,
  OpCode.kOpGetTopLevelProp: "gettoplevelprop" ,
  OpCode.kOpNewObj: "newobj" 
};

Map<OpCode, String> binaryOpNames = {
  OpCode.kOpMul: "*" ,
  OpCode.kOpAdd: "+" ,
  OpCode.kOpSub: "-" ,
  OpCode.kOpDiv: "/" ,
  OpCode.kOpMod: "mod" ,
  OpCode.kOpJoinStr: "&" ,
  OpCode.kOpJoinPadStr: "&&" ,
  OpCode.kOpLt: "<" ,
  OpCode.kOpLtEq: "<=" ,
  OpCode.kOpNtEq: "<>" ,
  OpCode.kOpEq: "=" ,
  OpCode.kOpGt: ">" ,
  OpCode.kOpGtEq: ">=" ,
  OpCode.kOpAnd: "and" ,
  OpCode.kOpOr: "or" ,
  OpCode.kOpContainsStr: "contains" ,
  OpCode.kOpContains0Str: "starts" 
};

Map<ChunkExprType, String> chunkTypeNames = {
	ChunkExprType.kChunkChar: "char" ,
	ChunkExprType.kChunkWord: "word" ,
	ChunkExprType.kChunkItem: "item" ,
	ChunkExprType.kChunkLine: "line" 
};

Map<PutType, String> putTypeNames = {
	PutType.kPutInto: "into" ,
	PutType.kPutAfter: "after" ,
	PutType.kPutBefore: "before" 
};

Map<int, String> moviePropertyNames = {
	0x00: "floatPrecision" ,
	0x01: "mouseDownScript" ,
	0x02: "mouseUpScript" ,
	0x03: "keyDownScript" ,
	0x04: "keyUpScript" ,
	0x05: "timeoutScript" ,
	0x06: "short time" ,
	0x07: "abbr time" ,
	0x08: "long time" ,
	0x09: "short date" ,
	0x0a: "abbr date" ,
	0x0b: "long date"
};

Map<int, String> whenEventNames = {
	0x01: "mouseDown" ,
	0x02: "mouseUp" ,
	0x03: "keyDown" ,
	0x04: "keyUp" ,
	0x05: "timeOut" ,
};

Map<int, String> menuPropertyNames = {
	0x01: "name" ,
	0x02: "number of menuItems" 
};

Map<int, String> menuItemPropertyNames = {
	0x01: "name" ,
	0x02: "checkMark" ,
	0x03: "enabled" ,
	0x04: "script" 
};

Map<int, String> soundPropertyNames = {
	0x01: "volume" 
};

Map<int, String> spritePropertyNames = {
	0x01: "type" ,
	0x02: "backColor" ,
	0x03: "bottom" ,
	0x04: "castNum" ,
	0x05: "constraint" ,
	0x06: "cursor" ,
	0x07: "foreColor" ,
	0x08: "height" ,
	0x09: "immediate" ,
	0x0a: "ink" ,
	0x0b: "left" ,
	0x0c: "lineSize" ,
	0x0d: "locH" ,
	0x0e: "locV" ,
	0x0f: "movieRate" ,
	0x10: "movieTime" ,
	0x11: "pattern" ,
	0x12: "puppet" ,
	0x13: "right" ,
	0x14: "startTime" ,
	0x15: "stopTime" ,
	0x16: "stretch" ,
	0x17: "top" ,
	0x18: "trails" ,
	0x19: "visible" ,
	0x1a: "volume" ,
	0x1b: "width" ,
	0x1c: "blend" ,
	0x1d: "scriptNum" ,
	0x1e: "moveableSprite" ,
	0x1f: "editableText" ,
	0x20: "scoreColor" ,
	0x21: "loc" ,
	0x22: "rect" ,
	0x23: "memberNum" ,
	0x24: "castLibNum" ,
	0x25: "member" ,
	0x26: "scriptInstanceList" ,
	0x27: "currentTime" ,
	0x28: "mostRecentCuePoint" ,
	0x29: "tweened" ,
	0x2a: "name" 
};

Map<int, String> animationPropertyNames = {
	0x01: "beepOn" ,
	0x02: "buttonStyle" ,
	0x03: "centerStage" ,
	0x04: "checkBoxAccess" ,
	0x05: "checkboxType" ,
	0x06: "colorDepth" ,
	0x07: "colorQD" ,
	0x08: "exitLock" ,
	0x09: "fixStageSize" ,
	0x0a: "fullColorPermit" ,
	0x0b: "imageDirect" ,
	0x0c: "doubleClick" ,
	0x0d: "key" ,
	0x0e: "lastClick" ,
	0x0f: "lastEvent" ,
	0x10: "keyCode" ,
	0x11: "lastKey" ,
	0x12: "lastRoll",
	0x13: "timeoutLapsed" ,
	0x14: "multiSound" ,
	0x15: "pauseState" ,
	0x16: "quickTimePresent" ,
	0x17: "selEnd" ,
	0x18: "selStart" ,
	0x19: "soundEnabled" ,
	0x1a: "soundLevel" ,
	0x1b: "stageColor" ,
	// 0x1c indicates dontPassEvent was called.
	// It doesn't seem to have a Lingo-accessible name.
	0x1d: "switchColorDepth" ,
	0x1e: "timeoutKeyDown" ,
	0x1f: "timeoutLength" ,
	0x20: "timeoutMouse" ,
	0x21: "timeoutPlay" ,
	0x22: "timer" ,
	0x23: "preLoadRAM" ,
	0x24: "videoForWindowsPresent" ,
	0x25: "netPresent" ,
	0x26: "safePlayer" ,
	0x27: "soundKeepDevice" ,
	0x28: "soundMixMedia" 
};

Map<int, String> animation2PropertyNames = {
	0x01: "perFrameHook" ,
	0x02: "number of castMembers" ,
	0x03: "number of menus" ,
	0x04: "number of castLibs" ,
	0x05: "number of xtras" 
};

Map<int, String> memberPropertyNames = {
	0x01: "name" ,
	0x02: "text" ,
	0x03: "textStyle" ,
	0x04: "textFont" ,
	0x05: "textHeight" ,
	0x06: "textAlign" ,
	0x07: "textSize" ,
	0x08: "picture" ,
	0x09: "hilite" ,
	0x0a: "number" ,
	0x0b: "size" ,
	0x0c: "loop" ,
	0x0d: "duration" ,
	0x0e: "controller" ,
	0x0f: "directToStage" ,
	0x10: "sound" ,
	0x11: "foreColor" ,
	0x12: "backColor" ,
	0x13: "type" 
};
