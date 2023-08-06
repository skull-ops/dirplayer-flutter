import '../../../director/lingo/datum.dart';

abstract class XtraFactory<T> {
  Future<T> newInstance(List<Datum> args);
}
