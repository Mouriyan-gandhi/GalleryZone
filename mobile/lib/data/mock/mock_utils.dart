/// Dart port of `frontend-web/lib/mock-utils.ts`. Same 600ms default delay,
/// same shape — every mock repository method awaits [mockDelay] (or throws
/// via [mockError]) instead of returning synchronously, so UI loading states
/// get exercised even against fake data, same as the web mocks.
Future<T> mockDelay<T>(T Function() value, {Duration duration = const Duration(milliseconds: 600)}) async {
  await Future.delayed(duration);
  return value();
}

Future<Never> mockError(String message, {Duration duration = const Duration(milliseconds: 600)}) async {
  await Future.delayed(duration);
  throw Exception(message);
}
