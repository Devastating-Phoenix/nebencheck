import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

void main() {
  // Bundled fonts (Barlow, Barlow Condensed, Courier Prime) are SIL OFL —
  // surface their licenses in the standard Flutter license page.
  LicenseRegistry.addLicense(() async* {
    for (final file in [
      'assets/fonts/OFL-Barlow.txt',
      'assets/fonts/OFL-CourierPrime.txt',
    ]) {
      yield LicenseEntryWithLineBreaks(
        ['bundled fonts'],
        await rootBundle.loadString(file),
      );
    }
  });
  runApp(const NebenCheckApp());
}

class NebenCheckApp extends StatelessWidget {
  const NebenCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'NebenCheck',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // On wide (desktop web) viewports the app reads as an A4 sheet
        // lying on a desk: a paper column with a hairline edge and a
        // soft paper shadow, centered on the desk gray.
        builder: (context, child) {
          return ColoredBox(
            color: AppColors.paperDeep,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    border: const Border.symmetric(
                      vertical: BorderSide(color: Color(0xFFBDBBAB)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 26,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: child!,
                ),
              ),
            ),
          );
        },
        home: const HomeScreen(),
      ),
    );
  }
}
