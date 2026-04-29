import 'package:flutter_test/flutter_test.dart';
import 'package:book_exchange/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BookExchangeApp());
    expect(find.byType(BookExchangeApp), findsOneWidget);
  });
}
