import 'dart:io';

import 'package:flutter/foundation.dart';

String floatToString(double f) {
  // TODO
  return f.toString();
}

String byteToString(int byte) {
	//snprintf(hex, sizeof(hex), "%02X", byte);
	return byte.toRadixString(16);
}

String escapeString(String str) {
	String res = "";
	for (int i = 0; i < str.length; i++) {
		var ch = str[i];
		switch (ch) {
		case '"':
			res += "\\\"";
			break;
		case '\\':
			res += "\\\\";
			break;
		case '\b':
			res += "\\b";
			break;
		case '\f':
			res += "\\f";
			break;
		case '\n':
			res += "\\n";
			break;
		case '\r':
			res += "\\r";
			break;
		case '\t':
			res += "\\t";
			break;
		case '\v':
			res += "\\v";
			break;
		default:
			if (ch.codeUnits[0] < 0x20 || ch.codeUnits[0] > 0x7f) {
				res += "\\x$ch";
			} else {
				res += ch;
			}
			break;
		}
	}
	return res;
}

String getLineSeparator() {
  String lineSeparator;
  if (kIsWeb || Platform.isWindows) {
    lineSeparator = "\r\n";
  } else if (Platform.isMacOS) {
    lineSeparator = "\r";
  } else {
    lineSeparator = "\n";
  }
  return lineSeparator;
}

String getPathSeparator() {
  if (kIsWeb || !Platform.isWindows) {
    return "/";
  } else {
    return "\\";
  }
}

String hexDump(Uint8List bytes) {
  var hexDump = "";
  for (var byte in bytes) {
    hexDump += byte.toRadixString(16).padLeft(2, "0");
  }
  return hexDump;
}

Uri getBaseUri(Uri uri) {
  uri = uri.removeFragment();
  if (uri.pathSegments.isEmpty || uri.pathSegments.last.isEmpty) {
    return uri;
  } else {
    return uri.replace(
      pathSegments: [...uri.pathSegments.getRange(0, uri.pathSegments.length - 1), ""]
    );
  }
}
