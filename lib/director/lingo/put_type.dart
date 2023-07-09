enum PutType {
	kPutInto(0x01),
	kPutAfter(0x02),
	kPutBefore(0x03);

  const PutType(this.rawValue);
  final int rawValue;
  static PutType fromValue(int value) {
    return PutType.values.firstWhere((element) => element.rawValue == value);
  }
}
