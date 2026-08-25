import 'package:flutter_test/flutter_test.dart';

import 'package:product_crud/main.dart';

void main() {
  testWidgets('app builds', (tester) async {
    await tester.pumpWidget(const ShelfApp());
    expect(find.text('Shelf'), findsOneWidget);
  });
}
