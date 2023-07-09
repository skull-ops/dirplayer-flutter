import 'dart:ui' as ui;

import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/director/lingo/datum/var_ref.dart';
import 'package:dirplayer/player/runtime/color_ref.dart';
import 'package:dirplayer/player/runtime/data_reference.dart';
import 'package:dirplayer/player/runtime/palette_ref.dart';
import 'package:dirplayer/player/runtime/prop_interface.dart';
import 'package:dirplayer/player/runtime/rect.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;

import 'image_ref.dart';

class Stage extends PropInterface {
  String title = "";
  //int width = 100;
  //int height = 100;
  ColorRef bgColor = ColorRef.fromRgb(0, 0, 0);
  GlobalKey? repaintKey;

  /*void resize(int newWidth, int newHeight) {
    width = newWidth;
    height = newHeight;
  }*/

  Size getRenderedSize() {
    var repaintKey = this.repaintKey;
    if (repaintKey != null) {
      return repaintKey.currentContext?.size ?? Size.zero;
    } else {
      return Size.zero;
    }
  }

  int get left => 0;
  int get top => 0;
  int get right => getRenderedSize().width.toInt();
  int get bottom => getRenderedSize().height.toInt();

  @override
  Ref<Datum>? getPropRef(String propName) {
    switch (propName) {
    case "rect":
      return CallbackRef(get: () {
        var size = getRenderedSize();
        // TODO use rect of the entire stage container
        return Datum.ofVarRef(IntRect(0, 0, size.width.toInt(), size.height.toInt()));
      });
    case "title":
      return MutableCallbackRef(
        get: () => Datum.ofString(title),
        set: (value) => title = value.stringValue()
      );
    case "bgColor":
      return CallbackRef(get: () => Datum.ofVarRef(bgColor));
    case "image":
      // TODO
      var size = getRenderedSize();
      return CallbackRef(
        get: () => Datum.ofVarRef(
          ImageRef(
            img.Image(
              width: size.width.toInt(), 
              height: size.height.toInt(), 
              format: img.Format.uint8
            ),
            8,
            PaletteRef(BuiltInPalette.systemDefault.intValue)
          )
        )
      );
      //return CallbackRef(get: () => Datum.ofVarRef(ImageRef(renderToImageSync())));
    default:
      return null;
    }
  }

  Future<img.Image> renderToImage() async {
    var repaintKey = this.repaintKey;
    final RenderRepaintBoundary? boundary = repaintKey?.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception("Stage has no repaint key");
    }
    var uiImage = boundary.toImageSync();
    final uiBytes = await uiImage.toByteData();

    final image = img.Image.fromBytes(
      width: uiImage.width, 
      height: uiImage.height,
      bytes: uiBytes!.buffer,
      numChannels: 4,
    );
    return image;
  }
}
