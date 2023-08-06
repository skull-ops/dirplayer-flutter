import 'package:dirplayer/common/exceptions.dart';
import 'package:dirplayer/director/castmembers.dart';
import 'package:dirplayer/director/chunks/cast_member.dart';
import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/director/lingo/datum/list.dart';
import 'package:dirplayer/player/runtime/castlib.dart';
import 'package:dirplayer/player/runtime/color_ref.dart';
import 'package:dirplayer/player/runtime/data_reference.dart';
import 'package:dirplayer/player/runtime/image_ref.dart';
import 'package:dirplayer/player/runtime/palette_ref.dart';
import 'package:dirplayer/player/runtime/prop_interface.dart';
import 'package:dirplayer/player/runtime/rect.dart';
import 'package:dirplayer/player/runtime/score.dart';
import 'package:dirplayer/player/runtime/vm.dart';
import 'package:image/image.dart' as img;

class InvalidMember implements PropInterface {
  @override
  String toString() {
    return "(member -1 of castLib -1)";
  }

  @override
  CallbackRef<Datum>? getPropRef(String propName) {
    switch (propName) {
      case "number":
        return CallbackRef(get: () => Datum.ofInt(-1));
      case "name":
        return CallbackRef(
          get: () => Datum.ofString(""), 
        );
      case "type":
        return CallbackRef(
          get: () => Datum.ofSymbol("empty"), 
        );
      default:
        return null;
    }
  }
}

String memberTypeToSymbol(MemberType type) {
  switch (type) {
  case MemberType.kTextMember:
    return "field";
  case MemberType.kScriptMember:
    return "script";
  case MemberType.kBitmapMember:
    return "bitmap";
  case MemberType.kPaletteMember:
    return "palette";
  default:
    throw Exception("Unknown member type $type");
  }
}

class Member implements PropInterface {
  int number;
  int localCastNumber;
  MemberType type;
  String name = "";
  ColorRef color = ColorRef.fromHex("#000000");
  ColorRef bgColor = ColorRef.fromHex("#ffffff");

  CastLib cast;
  CastMemberReference reference;

  Member({required int number, required this.type, required this.cast}) : 
    reference = CastMemberReference(cast.number, number),
    number = getCastSlotNumber(cast.number, number),
    localCastNumber = number;

  void restoreFrom(Member other) {
    name = other.name;
    color = other.color;
    bgColor = other.bgColor;
  }

  String getName() => name;

  @override
  String toString() {
    return "(member $localCastNumber of castLib ${cast.number})";
  }

  void loadFromChunk(CastMemberChunk chunk) {
    name = chunk.getName();
    type = chunk.type;
  }

  @override
  Ref<Datum>? getPropRef(String propName) {
    switch (propName) {
      case "number":
        return CallbackRef(get: () => Datum.ofInt(number));
      case "name":
        return MutableCallbackRef(
          get: () => Datum.ofString(getName()), 
          set: (value) => name = value.stringValue()
        );
      case "type":
        return CallbackRef(
          get: () => Datum.ofSymbol(memberTypeToSymbol(type)), 
        );
      case "color":
        return MutableCallbackRef(
          get: () => Datum.ofVarRef(color), 
          set: (value) => color = value.toRef()
        );
      case "bgColor":
        return MutableCallbackRef(
          get: () => Datum.ofVarRef(bgColor), 
          set: (value) => bgColor = value.toRef()
        );
      default:
        return null;
    }
  }
}

class FieldMember extends Member {
  String text;
  String alignment = "left";
  String boxType = "adjust";
  bool wordWrap = true;
  String font = "Arial";
  String fontStyle = "plain";
  int fontSize = 12;
  int width = 100;
  bool autoTab = false; // Tabbing order depends on sprite number order, not position on the Stage.
  bool editable = false;
  int border = 0;
  FieldMember({required super.number, required super.cast, required this.text, super.type = MemberType.kTextMember });

  int get height => lineHeight; // TODO use line spacing
  int get lineHeight => fontSize + 3; // TODO
  IntRect get rect => IntRect(0, 0, width, height);
  int get charWidth => 7; // TODO

  @override
  void restoreFrom(Member other) {
    super.restoreFrom(other);
    other as FieldMember;
    text = other.text;
    alignment = other.alignment;
    boxType = other.boxType;
    wordWrap = other.wordWrap;
    font = other.font;
    fontStyle = other.fontStyle;
    fontSize = other.fontSize;
    width = other.width;
  }

  @override
  Ref<Datum>? getPropRef(String propName) {
    switch (propName) {
      case "text":
        return MutableCallbackRef(
          get: () => Datum.ofString(text), 
          set: (value) => text = value.stringValue()
        );
      case "alignment":
        return MutableCallbackRef(
          get: () => Datum.ofString(alignment), 
          set: (value) => alignment = value.stringValue()
        );
      case "wordWrap":
        return MutableCallbackRef(
          get: () => Datum.ofBool(wordWrap), 
          set: (value) => wordWrap = value.toBool()
        );
      case "font":
        return MutableCallbackRef(
          get: () => Datum.ofString(font), 
          set: (value) => font = value.stringValue()
        );
      case "fontStyle":
        return MutableCallbackRef(
          get: () => Datum.ofString(fontStyle), 
          set: (value) => fontStyle = value.stringValue()
        );
      case "fontSize":
        return MutableCallbackRef(
          get: () => Datum.ofInt(fontSize), 
          set: (value) => fontSize = value.toInt()
        );
      case "boxType":
        return MutableCallbackRef(
          get: () => Datum.ofSymbol(boxType), 
          set: (value) => boxType = value.stringValue()
        );
      case "rect":
        return MutableCallbackRef(
          get: () => Datum.ofVarRef(rect), 
          set: (value) => width = value.toRef<IntRect>().width
        );
      case "autoTab":
        return MutableCallbackRef(
          get: () => Datum.ofBool(autoTab), 
          set: (value) => autoTab = value.toBool()
        );
      case "editable":
        return MutableCallbackRef(
          get: () => Datum.ofBool(editable), 
          set: (value) => editable = value.toBool()
        );
      case "border":
        return MutableCallbackRef(
          get: () => Datum.ofInt(border), 
          set: (value) => border = value.toInt()
        );
      default:
        return super.getPropRef(propName);
    }
  }
}

class TextMember extends Member implements HandlerInterface {
  String text;
  String alignment = "left";
  String boxType = "adjust";
  bool wordWrap = true;
  bool antialias = true;
  String font = "Arial";
  List<String> fontStyle = ["plain"];
  int fontSize = 12;
  bool fixedLineSpace = false;
  int topSpacing = 0;
  int width = 100;
  TextMember({required super.number, required super.cast, required this.text, super.type = MemberType.kTextMember });

  int get height => lineHeight; // TODO use line spacing
  int get lineHeight => fontSize + 3; // TODO
  int get charWidth => 7; // TODO
  IntRect get rect => IntRect(0, 0, width, height);

  @override
  void restoreFrom(Member other) {
    super.restoreFrom(other);
    other as TextMember;
    text = other.text;
    alignment = other.alignment;
    boxType = other.boxType;
    wordWrap = other.wordWrap;
    antialias = other.antialias;
    font = other.font;
    fontStyle = other.fontStyle;
    fontSize = other.fontSize;
    fixedLineSpace = other.fixedLineSpace;
    topSpacing = other.topSpacing;
    width = other.width;
  }

  @override
  Ref<Datum>? getPropRef(String propName) {
    switch (propName) {
      case "text":
        return MutableCallbackRef(
          get: () => Datum.ofString(text), 
          set: (value) => text = value.stringValue()
        );
      case "alignment":
        return MutableCallbackRef(
          get: () => Datum.ofSymbol(alignment), 
          set: (value) => alignment = value.stringValue()
        );
      case "wordWrap":
        return MutableCallbackRef(
          get: () => Datum.ofBool(wordWrap), 
          set: (value) => wordWrap = value.toBool()
        );
      case "font":
        return MutableCallbackRef(
          get: () => Datum.ofString(font), 
          set: (value) => font = value.stringValue()
        );
      case "fontStyle":
        return MutableCallbackRef(
          get: () => ListDatum(fontStyle.map((e) => Datum.ofSymbol(e)).toList()), 
          set: (value) { 
            fontStyle = value.toList().map((e) => e.stringValue()).toList();
          }
        );
      case "fontSize":
        return MutableCallbackRef(
          get: () => Datum.ofInt(fontSize), 
          set: (value) => fontSize = value.toInt()
        );
      case "fixedLineSpace":
        return MutableCallbackRef(
          get: () => Datum.ofBool(fixedLineSpace), 
          set: (value) => fixedLineSpace = value.toBool()
        );
      case "topSpacing":
        return MutableCallbackRef(
          get: () => Datum.ofInt(topSpacing), 
          set: (value) => topSpacing = value.toInt()
        );
      case "boxType":
        return MutableCallbackRef(
          get: () => Datum.ofSymbol(boxType), 
          set: (value) => boxType = value.stringValue()
        );
      case "antialias":
        return MutableCallbackRef(
          get: () => Datum.ofBool(antialias), 
          set: (value) => antialias = value.toBool()
        );
      case "rect":
        return MutableCallbackRef(
          get: () => Datum.ofVarRef(rect), 
          set: (value) => width = value.toRef<IntRect>().width
        );
      case "height":
        return CallbackRef(
          get: () => Datum.ofInt(height),
        );
      case "image":
        return CallbackRef(get: () => Datum.ofVarRef(renderToImage()));
      default:
        return super.getPropRef(propName);
    }
  }

  ImageRef renderToImage() {
    // TODO
    var result = img.Image(width: width, height: height, numChannels: 4, format: img.Format.uint8);
    img.drawString(result, text, font: img.arial14, color: color.toImgColor());
    return ImageRef(result, 32, PaletteRef(BuiltInPalette.systemDefault.intValue));
  }

  @override
  Future<Datum> callHandler(PlayerVM vm, String handlerName, List<Datum> argList) async {
    switch (handlerName) {
    case "charPosToLoc":
      // TODO this is a stub
      var charPos = argList.first.toInt();
      if (text.isEmpty || charPos <= 0) {
        return Datum.ofVarRef(IntPoint(0, lineHeight));
      } else if (charPos > text.length) {
        return Datum.ofVarRef(IntPoint(charWidth * text.length, lineHeight));
      } else {
        return Datum.ofVarRef(IntPoint(charWidth * (charPos - 1), lineHeight));
      }
    default:
      return Future.error(UnknownHandlerException(handlerName, this));
    }
  }
}

class ScriptMember extends Member {
  int scriptID;
  ScriptType scriptType;
  ScriptMember({
    required super.number, 
    required super.cast, 
    required this.scriptID, 
    required this.scriptType,
    super.type = MemberType.kTextMember
  });
}

class BitmapMember extends Member {
  final ImageRef imageRef;
  IntPoint regPoint;

  int get regX => regPoint.locH;
  int get regY => regPoint.locV;

  BitmapMember({
    required super.number, 
    required super.cast, 
    required this.imageRef,
    required int regX,
    required int regY,
    super.type = MemberType.kBitmapMember
  }) : regPoint = IntPoint(regX, regY);

  @override
  void restoreFrom(Member other) {
    super.restoreFrom(other);
    other as BitmapMember;
    regPoint = other.regPoint;
    imageRef.copyFrom(other.imageRef);
  }

  @override
  Ref<Datum>? getPropRef(String propName) {
    switch (propName) {
      case "width":
        return CallbackRef(get: () => Datum.ofInt(imageRef.image.width));
      case "height":
        return CallbackRef(get: () => Datum.ofInt(imageRef.image.height));
      case "image":
        return MutableCallbackRef(
          get: () => Datum.ofVarRef(imageRef), 
          set: (value) => imageRef.copyFrom(value.toRef())
        );
      case "regPoint":
        return MutableCallbackRef(
          get: () => Datum.ofVarRef(regPoint), 
          set: (value) => regPoint = value.toRef()
        );
      case "paletteRef":
        return CallbackRef(
          get: () => Datum.ofVarRef(imageRef.paletteRef)
        );
      default:
        return super.getPropRef(propName);
    }
  }
}

class PaletteMember extends Member {
  PaletteMember({
    required super.number, 
    required super.cast, 
    super.type = MemberType.kPaletteMember
  });

  @override
  void restoreFrom(Member other) {
    super.restoreFrom(other);
    print("TODO restore palette");
  }
}
