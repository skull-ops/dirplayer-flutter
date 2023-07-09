import 'dart:typed_data';

final UINT32_MAX = 0xFFFFFFFF;

int humanVersion(int ver) {
	// This is based on Lingo's `the fileVersion` with a correction to the
	// version number for Director 12.
	if (ver >= 1951) {
	  return 1200;
	}
	if (ver >= 1922) {
	  return 1150;
	}
	if (ver >= 1921) {
	  return 1100;
	}
	if (ver >= 1851) {
	  return 1000;
	}
	if (ver >= 1700) {
	  return 850;
	}
	if (ver >= 1410) {
	  return 800;
	}
	if (ver >= 1224) {
	  return 700;
	}
	if (ver >= 1218) {
	  return 600;
	}
	if (ver >= 1201) {
	  return 500;
	}
	if (ver >= 1117) {
	  return 404;
	}
	if (ver >= 1115) {
	  return 400;
	}
	if (ver >= 1029) {
	  return 310;
	}
	if (ver >= 1028) {
	  return 300;
	}
	return 200;
}

int FOURCC(String fourCC) {
  var a0 = fourCC.codeUnits[0];
  var a1 = fourCC.codeUnits[1];
  var a2 = fourCC.codeUnits[2];
  var a3 = fourCC.codeUnits[3];
  return (((a3) | ((a2) << 8) | ((a1) << 16) | ((a0) << 24)));
}

String fourCCToString(int fourcc) {
  var chars = <int>[
    (fourcc >> 24) & 0xFF,
    (fourcc >> 16) & 0xFF,
    (fourcc >> 8) & 0xFF,
    (fourcc) & 0xFF,
  ];

  return String.fromCharCodes(chars);
}

double int32BytesToFloat(int value) {
  // TODO check if this works
  var result = Int32List.fromList([value])
    .buffer
    .asFloat32List()
    .first;

  print("int32 $value = float32 $result");
    
  // *(float *)(&value)
  return result;
}

String posToString(int pos) {
	// TODO ss << "[" << std::setfill(' ') << std::setw(3) << pos << "]";
	return "[$pos]";
}

T? tryOrNull<T>(T Function() call) {
  try {
    return call();
  } catch (e) {
    return null;
  }
}