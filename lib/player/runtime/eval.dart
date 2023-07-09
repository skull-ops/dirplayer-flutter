import 'dart:math';

import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/director/lingo/datum/eval/evaluated.dart';
import 'package:dirplayer/player/runtime/color_ref.dart';
import 'package:dirplayer/player/runtime/rect.dart';
import 'package:dirplayer/player/runtime/vm.dart';
import 'package:flutter/material.dart';
import 'package:petitparser/definition.dart';
import 'package:petitparser/expression.dart';
import 'package:petitparser/petitparser.dart' as pp;

class LingoParser {
  static pp.Parser createIntParser() {
    var result = pp.pattern("+-").optional() & pp.digit().plus();
    var intValueParser = result.flatten().map((value) => Datum.ofInt(int.parse(value)));

    return [
      pp.char("#").optional(),
      intValueParser
    ].toSequenceParser().map((value) => value[1]);
  }

  static pp.Parser createFloatParser() {
    var sign = pp.anyOf("+-");
    var exponent = pp.char("e") & pp.anyOf("+-").optional() & pp.digit().plus();
    var floatParser1 = [ // 0*.0+
      sign.optional(),
      pp.digit().star().flatten(),
      pp.digit().plus().skip(before: pp.char(".")).flatten(),
      exponent.optional()
    ].toSequenceParser();
    var floatParser2 = [ //0+.0*
      sign.optional(),
      pp.digit().plus().flatten(),
      pp.digit().star().skip(before: pp.char(".")).flatten(),
      exponent.optional(),
    ].toSequenceParser();

    var floatValueParser = [floatParser1, floatParser2].toChoiceParser()
      .flatten()
      .map((value) => Datum.ofFloat(double.parse(value)));

    return [
      pp.char("#").optional(),
      floatValueParser
    ].toSequenceParser().map((value) => value[1]);
  }

  static pp.Parser createPropListParser() {
    var key = [
      createSymbolParser(),
      createStringParser(),
      createIntParser(),
    ].toChoiceParser();
    var value = pp.ref0(createExprParser);
    var colon = pp.char(":");

    var emptyPropList = (pp.char("[") & colon.trim() & pp.char("]")).map((value) => Datum.ofPropList({}));
    var keyvalue = (key.trim() & colon.trim() & value.trim()).map((value) => MapEntry<Datum, Datum>(value[0], value[2]));
    var propList = [
      pp.char("["),
      keyvalue,
      (keyvalue.trim().skip(before: pp.char(","))).star(),
      pp.char("]"),
    ].toSequenceParser().map((value) {
      MapEntry<Datum, Datum> firstEntry = value[1] as MapEntry<Datum, Datum>;
      List temp = value[2] as List;
      Iterable<MapEntry<Datum, Datum>> otherEntries = temp.whereType<MapEntry<Datum, Datum>>();

      return Datum.ofPropList(Map.fromEntries([firstEntry, ...otherEntries]));
    });

    return [emptyPropList, propList].toChoiceParser();
  }

  static pp.Parser createStringParser() {
    var quote = pp.char("\"");
    var result = pp.pattern("^\"").star().skip(before: quote, after: quote);
    return result.flatten().map((value) => Datum.ofString(value.substring(1, value.length - 1)));
  }

  static pp.Parser<String> createNameParser() {
    return (pp.patternIgnoreCase("a-z_") & pp.patternIgnoreCase("a-z0-9_").star()).map((value) {
      var firstChar = value[0] as String;
      var otherChars = (value[1] as List).whereType<String>();

      return [firstChar, ...otherChars].join();
    });
  }

  static pp.Parser createSymbolParser() {
    var result = pp.char("#") & createNameParser();
    return result.map((value) {
      var symbolName = value[1] as String;
      return Datum.ofSymbol(symbolName);
    });
  }

  static pp.Parser createVoidParser() {
    return pp.stringIgnoreCase("void").trim(pp.char("<"), pp.char(">")).map((value) => Datum.ofVoid());
  }

  static pp.Parser createListParser() {
    var expr = pp.ref0(createExprParser);

    return [
      pp.char("["),
      expr.trim().optional(),
      (expr.trim().skip(before: pp.char(","))).star(),
      pp.char("]")
    ].toSequenceParser().map((value) {
      Datum? firstItem = value[1];
      List otherItems = value[2] ?? [];
      return Datum.ofDatumList(DatumType.kDatumList, [if (firstItem != null) firstItem, ...otherItems]);
    });
  }

  static pp.Parser createRgbParser() {
    var number = createIntParser();
    
    return [
      pp.string("rgb("),
      number.trim().optional(),
      number.trim().skip(before: pp.char(",")),
      number.trim().skip(before: pp.char(",")),
      pp.char(")")
    ].toSequenceParser().map((value) {
      Datum r = value[1];
      Datum g = value[2];
      Datum b = value[3];
      
      return Datum.ofVarRef(ColorRef.fromRgb(r.toInt(), g.toInt(), b.toInt()));
    });
  }

  static pp.Parser createRgbHexParser() {
    return [
      pp.string("rgb("),
      createStringParser(),
      pp.char(")")
    ].toSequenceParser().map((value) {
      Datum hexValue = value[1];
      return Datum.ofVarRef(ColorRef.fromHex(hexValue.stringValue()));
    });
  }

  static pp.Parser createRectParser() {
    var number = createIntParser();
    
    return [
      pp.string("rect("),
      number.trim(),
      number.trim().skip(before: pp.char(",")),
      number.trim().skip(before: pp.char(",")),
      number.trim().skip(before: pp.char(",")),
      pp.char(")")
    ].toSequenceParser().map((value) {
      Datum l = value[1];
      Datum t = value[2];
      Datum r = value[3];
      Datum b = value[4];
      
      return Datum.ofVarRef(IntRect(l.toInt(), t.toInt(), r.toInt(), b.toInt()));
    });
  }

  static pp.Parser<HandlerCallDatum> createCallParser() {
    var literal = pp.ref0(createLiteralParser);

    return [
      createNameParser(),
      pp.char("("),
      literal.trim().optional(),
      (literal.trim().skip(before: pp.char(","))).star(),
      pp.char(")")
    ].toSequenceParser().map((value) {
      String handlerName = value[0];
      Datum? firstArg = value[2];
      List otherArgs = value[3] ?? [];
      var args = [if (firstArg != null) firstArg, ...otherArgs].map((e) => e as Datum).toList();

      return HandlerCallDatum(handlerName, args);
    });
  }

  static pp.Parser createLiteralParser() {
    return [
      createFloatParser(),
      createIntParser(),
      createStringParser(),
      createSymbolParser(),
      createVoidParser(),
      ref0(createListParser),
      ref0(createPropListParser),
      ref0(createRgbParser),
      ref0(createRgbHexParser),
      ref0(createRectParser),
    ].toChoiceParser();
  }

  static pp.Parser createExprParser() {
    var result = [
      // TODO ref0(createCallParser),
      ref0(createLiteralParser),
    ].toChoiceParser();

    return result;
  }

  static pp.Parser createEvalParser() {
    return (createExprParser().trim() & pp.endOfInput()).map((value) => value[0]);
  }

  static pp.Parser optionalSpace() => pp.pattern("\\s").star().skip();
}

Datum eval(PlayerVM vm, String expression) {
  if (expression.isEmpty) {
    return Datum.ofVoid();
  }
  var parser = pp.resolve(LingoParser.createEvalParser());
  var result = parser.parse(expression);
  // TODO hydrate expressions

  if (result.isSuccess) {
    return result.value as Datum;
  } else {
    print("[!!] warn: Could not eval $expression");
    return Datum.ofVoid();
  }
}
