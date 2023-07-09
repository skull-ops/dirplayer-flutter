enum ChunkExprType {
  kChunkNone(0x00),
	kChunkChar(0x01),
	kChunkWord(0x02),
	kChunkItem(0x03),
	kChunkLine(0x04);

  const ChunkExprType(this.rawValue);
  final int rawValue;
  static ChunkExprType fromValue(int value) {
    return ChunkExprType.values.firstWhere((element) => element.rawValue == value);
  }
}
