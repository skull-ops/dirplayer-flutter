/*

TODO
#ifdef _WIN32
static const char *kPlatformLineEnding = "\r\n";
#else
static const char *kPlatformLineEnding = "\n";
#endif

*/

const String kPlatformLineEnding = "\r\n";

class CodeWriter {
  final StringBuffer _stream = StringBuffer();
  String lineEnding;
	String indentation;

	int _indentationLevel = 0;
	bool _indentationWritten = false;
	int _lineWidth = 0;
	int _size = 0;

  bool doIndentation = true;

  CodeWriter({ this.lineEnding = kPlatformLineEnding, this.indentation = "  " });

  void write(String str) {
    if (str.isEmpty) {
      return;
    }

    writeIndentation();
    _stream.write(str);
    _lineWidth += str.length;
    _size += str.length;
  }

	void writeChar(int ch) {
    write(String.fromCharCode(ch));
  }

	void writeLine(String str) {
    if (str.isEmpty) {
      _stream.write(lineEnding);
    } else {
      writeIndentation();
      _stream.write(str + lineEnding);
    }
    _indentationWritten = false;
    _lineWidth = 0;
    _size += str.length + lineEnding.length;
  }

  void writeEmptyLine() {
    writeLine("");
  }

	void indent() {
    _indentationLevel += 1;
  }

	void unindent() {
    if (_indentationLevel > 0) {
      _indentationLevel -= 1;
    }
  }

	String str() {
    return _stream.toString();
  }

	int lineWidth() { return _lineWidth; }
	int size() { return _size; }

  void writeIndentation() {
    if (_indentationWritten || !doIndentation) {
      return;
    }

    for (int i = 0; i < _indentationLevel; i++) {
      _stream.write(indentation);
    }

    _indentationWritten = true;
    _lineWidth = _indentationLevel * indentation.length;
    _size += _lineWidth;
  }
}