import 'package:flutter_test/flutter_test.dart';
import 'package:mycahier_mobile/main.dart';

void main() {
testWidgets('MyCahier ENSPD affiche la page de connexion', (
WidgetTester tester,
) async {
await tester.pumpWidget(const MyCahierApp());


expect(find.text('MyCahier ENSPD'), findsOneWidget);
expect(find.text('Bienvenue !'), findsOneWidget);
expect(find.text('Se connecter'), findsOneWidget);

});
}
