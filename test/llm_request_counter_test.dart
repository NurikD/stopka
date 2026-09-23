import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/llm/llm_request_counter.dart';

LlmRequestCounter _inMemoryCounter(Map<String, String> store) {
  return LlmRequestCounter(
    read: (key) async => store[key],
    write: (key, value) async => store[key] = value,
  );
}

void main() {
  test('starts at 0 with no prior history', () async {
    final counter = _inMemoryCounter({});
    expect(await counter.getTodayCount(), 0);
  });

  test('increment increases the count', () async {
    final store = <String, String>{};
    final counter = _inMemoryCounter(store);
    await counter.increment();
    await counter.increment();
    expect(await counter.getTodayCount(), 2);
  });

  test('resets to 0 when the stored date is not today', () async {
    final store = <String, String>{
      'llm_request_count': '42',
      'llm_request_count_date': '2000-1-1',
    };
    final counter = _inMemoryCounter(store);
    expect(await counter.getTodayCount(), 0);
  });

  test('increment after a stale date starts counting from 1, not 43', () async {
    final store = <String, String>{
      'llm_request_count': '42',
      'llm_request_count_date': '2000-1-1',
    };
    final counter = _inMemoryCounter(store);
    await counter.increment();
    expect(await counter.getTodayCount(), 1);
  });
}
