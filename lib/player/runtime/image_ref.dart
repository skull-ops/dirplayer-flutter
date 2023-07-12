import 'dart:math';
import 'dart:ui' as ui;

import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/director/lingo/datum/list.dart';
import 'package:dirplayer/director/lingo/datum/prop_list.dart';
import 'package:dirplayer/director/lingo/datum/var_ref.dart';
import 'package:dirplayer/image_utils.dart';
import 'package:dirplayer/player/runtime/color_ref.dart';
import 'package:dirplayer/player/runtime/data_reference.dart';
import 'package:dirplayer/player/runtime/palette_ref.dart';
import 'package:dirplayer/player/runtime/prop_interface.dart';
import 'package:dirplayer/player/runtime/rect.dart';
import 'package:dirplayer/player/runtime/score.dart';
import 'package:dirplayer/player/runtime/vm.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'package:rxdart/rxdart.dart';

class ImageRef implements PropInterface, HandlerInterface {
  img.Image image;
  int bitDepth;
  PaletteRef paletteRef;
  late BehaviorSubject<ui.Image> uiImage = BehaviorSubject();

  ImageRef(this.image, this.bitDepth, this.paletteRef) {
    uiImage = BehaviorSubject(onListen: () { cacheUiImage(); });
  }

  void copyFrom(ImageRef other) {
    image = other.image.clone();
    bitDepth = other.bitDepth;
    paletteRef = other.paletteRef;
    if (uiImage.hasListener) {
      cacheUiImage();
    }
  }

  ImageRef clone() {
    return ImageRef(image.clone(), bitDepth, paletteRef);
  }

  @override
  Ref<Datum>? getPropRef(String propName) {
    switch (propName) {
    case "width":
      return CallbackRef(get: () => Datum.ofInt(image.width));
    case "height":
      return CallbackRef(get: () => Datum.ofInt(image.height));
    case "rect":
      return CallbackRef(get: () => Datum.ofVarRef(IntRect(0, 0, image.width, image.height)));
    case "depth":
      return CallbackRef(get: () => Datum.ofInt(bitDepth));
    case "paletteRef":
      return MutableCallbackRef(
        get: () {
          if (paletteRef.isBuiltin()) {
            return Datum.ofSymbol(paletteRef.toBuiltin().name);
          } else {
            return Datum.ofVarRef(paletteRef);
          }
        },
        set: (value) {
          if (value.isSymbol()) {
            paletteRef = PaletteRef(BuiltInPalette.fromName(value.stringValue()).intValue);
          } else if (value is VarRefDatum && value.value is PaletteRef) {
            paletteRef = value.toRef();
          } else {
            print("[!!] warn: setting palette to member is unsupported");
          }
        }
      );
    default:
      return null;
    }
  }

  void startEditing() {
  }

  void endEditing() {
    if (uiImage.hasListener) {
      cacheUiImage();
    }
  }

  Future cacheUiImage() async {
    var newUiImage = await convertImageToFlutterUi(image);
    uiImage.add(newUiImage);
  }

  void edit(void Function(img.Image) callback) {
    startEditing();
    callback(image);
    endEditing();
  }

  Datum fill(IntRect rect, ColorRef color) {
    startEditing();
    img.fillRect(
      image, 
      x1: rect.left, 
      y1: rect.top, 
      x2: rect.right - 1, 
      y2: rect.bottom - 1, 
      color: color.toImgColor()
    );
    endEditing();
    return Datum.ofBool(true);
  }

  Datum draw(IntRect rect, Map<Datum, Datum> drawMap) {
    final color = drawMap[Datum.ofSymbol("color")]!.toRef<ColorRef>();
    final shapeType = drawMap[Datum.ofSymbol("shapeType")]!.stringValue();

    startEditing();
    switch (shapeType) {
    case "rect":
      img.drawRect(
        image, 
        x1: rect.left, 
        y1: rect.top, 
        x2: rect.right - 1, 
        y2: rect.bottom - 1, 
        color: color.toImgColor()
      );
      break;
    default:
      throw Exception("Invalid draw shape type $shapeType");
    }
    endEditing();

    return Datum.ofBool(true);
  }

  bool copyPixels(ImageRef sourceImg, IntRect destRect, IntRect sourceRect, PropListDatum? paramList) {
    bool flipH = false, flipV = false;
    if (destRect.width < 0) {
      flipH = true;
    }
    if (destRect.height < 0) {
      flipV = true;
    }
    
    img.Image transformedSource;
    if (flipH && flipV) {
      transformedSource = img.flipHorizontalVertical(sourceImg.image);
      destRect = IntRect(destRect.right, destRect.bottom, destRect.left, destRect.top);
    } else if (flipH) {
      transformedSource = img.flipHorizontal(sourceImg.image);
      destRect = IntRect(destRect.right, destRect.top, destRect.left, destRect.bottom);
    } else if (flipV) {
      transformedSource = img.flipVertical(sourceImg.image);
      destRect = IntRect(destRect.left, destRect.bottom, destRect.right, destRect.top);
    } else {
      transformedSource = sourceImg.image;
    }

    IntRect srcImageRect = IntRect(0, 0, sourceImg.image.width, sourceImg.image.height);
    IntRect destImageRect = IntRect(0, 0, image.width, image.height);

    // Create new rectangles that represent the intersection of the source and destination rectangles with the image bounds
    IntRect intersectedSrcRect = sourceRect.intersect(srcImageRect);
    IntRect intersectedDestRect = destRect.intersect(destImageRect);

    // If the intersected rectangles have zero width or height, then there's nothing to copy
    if (intersectedSrcRect.width <= 0 || intersectedSrcRect.height <= 0 || intersectedDestRect.width <= 0 || intersectedDestRect.height <= 0) {
      return false;
    }

    startEditing();
    img.compositeImage(
      image, 
      transformedSource, 
      dstX: intersectedDestRect.left, 
      dstY: intersectedDestRect.top, 
      dstW: intersectedDestRect.width, 
      dstH: intersectedDestRect.height, 
      srcX: intersectedSrcRect.left, 
      srcY: intersectedSrcRect.top,
      srcW: intersectedSrcRect.width,
      srcH: intersectedSrcRect.height
    );
    endEditing();
    return true;
  }

  @override
  Future<Datum> callHandler(PlayerVM vm, String handlerName, List<Datum> argList) async {
    switch (handlerName) {
    case "fill":
      IntRect rect;
      ColorRef color;
      if (argList.length == 2) {
        rect = argList[0].toRef<IntRect>();
        color = argList[1].toRef<ColorRef>();
      } else if (argList.length == 5) {
        rect = IntRect(argList[0].toInt(), argList[1].toInt(), argList[2].toInt(), argList[3].toInt());
        color = argList[4].toRef<ColorRef>();
      } else {
        return Future.error(Exception("Invalid ImageRef fill call"));
      }
      return fill(rect, color);
    case "draw":
      var rect = argList[0].toRef<IntRect>();
      var drawMap = argList[1].toMap();
      return draw(rect, drawMap);
    case "setPixel":
      var x = argList[0].toInt();
      var y = argList[1].toInt();
      var colorObjOrIntValue = argList[2];

      if (x < 0 || y < 0 || x >= image.width || y >= image.height) {
        return Datum.ofBool(false);
      }
      if (colorObjOrIntValue.isInt()) {
        if (bitDepth != 8) {
          return Future.error("Setting pixel to int is only supported for 8-bit images");
        }
        image.setPixelIndex(x, y, colorObjOrIntValue.toInt());
      } else {
        ColorRef colorRef = colorObjOrIntValue.toRef();
        image.setPixel(x, y, colorRef.toImgColor());
      }

      return Datum.ofBool(true);
    case "duplicate":
      return Datum.ofVarRef(ImageRef(image.clone(), bitDepth, paletteRef));
    case "copyPixels":
      var sourceImgObj = argList[0].toRef<ImageRef>();
      var destRectOrQuad = argList[1];
      var sourceRect = argList[2].toRef<IntRect>();
      var paramList = argList.elementAtOrNull(3) as PropListDatum?;

      IntRect destRect;
      if (destRectOrQuad is VarRefDatum && destRectOrQuad.value is IntRect) {
        destRect = destRectOrQuad.toRef();
      } else if (destRectOrQuad is ListDatum) {
        var list = destRectOrQuad.toList();
        destRect = IntRect.fromQuad(list[0].toRef(), list[1].toRef(), list[2].toRef(), list[3].toRef());
      } else {
        return Future.error(Exception("Invalid rect $destRectOrQuad"));
      }
      return Datum.ofBool(copyPixels(sourceImgObj, destRect, sourceRect, paramList));
    default:
      return Future.error(Exception("Unknown handler $handlerName for $this"));
    }
  }

  @override
  String toString() {
    return "<image ${image.width}x${image.height}x$bitDepth)>";
  }
}
