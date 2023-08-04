import 'package:dirplayer/player/runtime/chunk_ref.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("Delete char chunk", () {
    expect(CharStringChunkRef(2, 4).deletingFrom("Hello"), "Ho");
    expect(CharStringChunkRef(1, 1).deletingFrom("World"), "orld");
    expect(CharStringChunkRef(1, 100).deletingFrom("Hello world"), "");
    expect(CharStringChunkRef(-99, 100).deletingFrom("Hello world"), "");
  });
}
