abstract class Ref<T> {
  T get();
}

abstract class MutableRef<T> implements Ref<T> {
  void set(T value);
}

typedef GetterCallback<T> = T Function();
typedef SetterCallback<T> = void Function(T value);

class CallbackRef<T> implements Ref<T> {
  final GetterCallback<T> _get;
  CallbackRef({ required GetterCallback<T> get }) : _get = get;

  @override
  T get() => _get();
}

class MutableCallbackRef<T> implements MutableRef<T> {
  final GetterCallback<T> _get;
  final SetterCallback<T> _set;
  MutableCallbackRef({ required GetterCallback<T> get, required SetterCallback<T> set }) : _get = get, _set = set;

  @override
  T get() => _get();

  @override
  void set(T value) => _set(value);
}

