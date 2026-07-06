import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

import '../logic/letter_generator.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/common.dart';
import '../util/l10n.dart';
import '../util/save_file.dart';

class LetterScreen extends StatelessWidget {
  const LetterScreen({super.key});

  /// Renders the letter as a typewritten A4 PDF, DIN-5008-like margins
  /// (25 mm left, 27 mm top, 20 mm right/bottom).
  Future<void> _downloadPdf(String letter) async {
    final doc = pw.Document();
    final font = pw.Font.courier();
    final lines = letter.split('\n');
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(
            25 * PdfPageFormat.mm,
            27 * PdfPageFormat.mm,
            20 * PdfPageFormat.mm,
            20 * PdfPageFormat.mm),
        build: (_) => [
          for (final l in lines)
            if (l.trim().isEmpty)
              pw.SizedBox(height: 11)
            else
              pw.Text(
                l,
                style: pw.TextStyle(font: font, fontSize: 10.5, lineSpacing: 2),
              ),
        ],
      ),
    );
    downloadBytes(
        await doc.save(), 'widerspruch-nebenkosten.pdf', 'application/pdf');
  }

  void _email(String letter) {
    final subject =
        Uri.encodeComponent('Widerspruch gegen die Betriebskostenabrechnung');
    final body = Uri.encodeComponent(letter);
    openExternal('mailto:?subject=$subject&body=$body');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final report = app.report;
    if (report == null) {
      return Scaffold(
          body: Center(
              child: Text(tr('No analysis yet.', 'Noch keine Analyse.'))));
    }
    final letter = LetterGenerator.build(app.draft, report);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('Objection letter', 'Widerspruchsschreiben'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
          children: [
            Text(
              tr(
                'This is a formal German letter (Widerspruch) citing § 556 BGB, the BetrKV and your right to inspect receipts (§ 259 BGB). Fill in the bracketed placeholders, then send it by email or registered mail.',
                'Ein formeller Widerspruch nach § 556 BGB und BetrKV, inklusive Belegeinsicht nach § 259 BGB. Ergänzen Sie die Platzhalter in Klammern und versenden Sie das Schreiben per E-Mail oder Einschreiben.',
              ),
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 14),
            SurfaceCard(
              child: SelectableText(
                letter,
                style: AppText.mono(size: 12.5, weight: FontWeight.w400)
                    .copyWith(height: 1.6),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                onPressed: () => _downloadPdf(letter),
                icon: const Icon(Icons.download_rounded, size: 20),
                label: Text(
                    tr('Download as PDF (DIN 5008)', 'Als PDF laden (DIN 5008)')),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await Clipboard.setData(ClipboardData(text: letter));
                        messenger.showSnackBar(
                          SnackBar(
                              content: Text(tr('Letter copied to clipboard.',
                                  'Schreiben in die Zwischenablage kopiert.'))),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(tr('Copy', 'Kopieren')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _email(letter),
                      icon: const Icon(Icons.mail_outline_rounded, size: 18),
                      label: Text(tr('Email', 'E-Mail')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
