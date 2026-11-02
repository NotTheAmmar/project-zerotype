import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_zerotype/views/screens/welcome_screen.dart';

void main() {
  testWidgets('WelcomeScreen renders all 6 Indic languages and handles selection', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomeScreen(),
      ),
    );

    // 1. Verify Branding & Subtitles
    expect(find.text('BazaarSetu'), findsOneWidget);
    expect(find.text('बाज़ारसेतु • Karigar ONDC Studio'), findsOneWidget);
    expect(find.text('अपनी भाषा चुनें • Select Language'), findsOneWidget);

    // 2. Verify all 6 Indic language names and scripts are visible
    expect(find.text('हिन्दी'), findsOneWidget);
    expect(find.text('मराठी'), findsOneWidget);
    expect(find.text('ગુજરાતી'), findsOneWidget);
    expect(find.text('বাংলা'), findsOneWidget);
    expect(find.text('தமிழ்'), findsOneWidget);
    expect(find.text('తెలుగు'), findsOneWidget);

    // 3. Verify Default Selection (Hindi)
    expect(find.text('आगे बढ़ें • Continue (हिन्दी)'), findsOneWidget);

    // 4. Tap another language (e.g. Marathi)
    await tester.tap(find.text('मराठी'));
    await tester.pumpAndSettle();

    // Verify selection updated in continue button
    expect(find.text('आगे बढ़ें • Continue (मराठी)'), findsOneWidget);

    // 5. Tap Bengali
    await tester.tap(find.text('বাংলা'));
    await tester.pumpAndSettle();

    expect(find.text('आगे बढ़ें • Continue (বাংলা)'), findsOneWidget);
  });
}
