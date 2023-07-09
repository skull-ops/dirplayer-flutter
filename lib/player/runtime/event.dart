class Event {
  bool isPreventDefault = false;

  void preventDefault() {
    isPreventDefault = true;
  }
}
