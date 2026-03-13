import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/trip.dart';

class PdfExportService {
  static Future<void> exportTrip(
    BuildContext context,
    Trip trip, {
    String submittedBy = '',
  }) async {
    final total = trip.expenses.fold<double>(
        0, (sum, e) => sum + (e['amount'] as num? ?? 0).toDouble());

    final byCategory = <String, double>{};
    for (final e in trip.expenses) {
      final cat = (e['category'] as String?) ?? 'Other';
      byCategory[cat] =
          (byCategory[cat] ?? 0) + (e['amount'] as num? ?? 0).toDouble();
    }
    final sortedCategories = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final dateRange =
        '${DateFormat('MMM d, yyyy').format(trip.startDate)} – ${DateFormat('MMM d, yyyy').format(trip.endDate)}';
    final reportNo =
        'TB-${trip.id?.substring(0, 6).toUpperCase() ?? DateFormat('yyyyMMdd').format(DateTime.now())}';
    final generatedOn = DateFormat('MMMM d, yyyy').format(DateTime.now());

    final sortedExpenses = List<Map<String, dynamic>>.from(trip.expenses);
    sortedExpenses.sort((a, b) =>
        ((a['date'] as String?) ?? '').compareTo((b['date'] as String?) ?? ''));

    const navy = PdfColor.fromInt(0xFF1A1A2E);
    const purple = PdfColor.fromInt(0xFF7C6AFF);
    const lightPurple = PdfColor.fromInt(0xFFEEEDFE);
    const teal = PdfColor.fromInt(0xFF0F6E56);
    const lightGray = PdfColor.fromInt(0xFFF7F6FF);
    const midGray = PdfColor.fromInt(0xFFD3D1C7);
    const textMuted = PdfColor.fromInt(0xFF6B7280);
    const white = PdfColors.white;

    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => [
        // Header
        pw.Container(
          color: navy,
          padding: const pw.EdgeInsets.fromLTRB(40, 28, 40, 28),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('EXPENSE REPORT',
                    style: pw.TextStyle(color: purple, fontSize: 9,
                        fontWeight: pw.FontWeight.bold, letterSpacing: 2.5)),
                pw.SizedBox(height: 6),
                pw.Text(trip.name,
                    style: pw.TextStyle(color: white, fontSize: 22,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(trip.destination,
                    style: const pw.TextStyle(
                        color: PdfColor.fromInt(0xFF6AFFD4), fontSize: 13)),
                pw.SizedBox(height: 2),
                pw.Text(dateRange,
                    style: const pw.TextStyle(color: textMuted, fontSize: 10)),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('Tour Buddy',
                    style: pw.TextStyle(color: purple, fontSize: 14,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('Report No: $reportNo',
                    style: const pw.TextStyle(color: textMuted, fontSize: 9)),
                pw.Text('Date: $generatedOn',
                    style: const pw.TextStyle(color: textMuted, fontSize: 9)),
              ]),
            ],
          ),
        ),

        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(40, 22, 40, 0),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [

            // Submitter block
            if (submittedBy.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                    color: lightPurple, borderRadius: pw.BorderRadius.circular(8)),
                child: pw.Row(children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('SUBMITTED BY',
                        style: pw.TextStyle(fontSize: 7, color: purple,
                            fontWeight: pw.FontWeight.bold, letterSpacing: 1.2)),
                    pw.SizedBox(height: 3),
                    pw.Text(submittedBy,
                        style: pw.TextStyle(fontSize: 14,
                            fontWeight: pw.FontWeight.bold, color: navy)),
                  ]),
                  pw.Spacer(),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                    pw.Text('PURPOSE',
                        style: pw.TextStyle(fontSize: 7, color: purple,
                            fontWeight: pw.FontWeight.bold, letterSpacing: 1.2)),
                    pw.SizedBox(height: 3),
                    pw.Text('Travel Expense Claim',
                        style: const pw.TextStyle(fontSize: 11, color: navy)),
                  ]),
                  pw.SizedBox(width: 20),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                    pw.Text('STATUS',
                        style: pw.TextStyle(fontSize: 7, color: purple,
                            fontWeight: pw.FontWeight.bold, letterSpacing: 1.2)),
                    pw.SizedBox(height: 3),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xFFEAF3DE),
                          borderRadius: pw.BorderRadius.circular(4)),
                      child: pw.Text('PENDING APPROVAL',
                          style: pw.TextStyle(fontSize: 8, color: teal,
                              fontWeight: pw.FontWeight.bold)),
                    ),
                  ]),
                ]),
              ),
              pw.SizedBox(height: 20),
            ],

            // Summary cards
            pw.Row(children: [
              _billCard(label: 'TOTAL CLAIMED',
                  value: '${trip.currency} ${total.toStringAsFixed(2)}',
                  accent: purple, highlight: true),
              if (trip.budget > 0) ...[
                pw.SizedBox(width: 10),
                _billCard(label: 'APPROVED BUDGET',
                    value: '${trip.currency} ${trip.budget.toStringAsFixed(2)}',
                    accent: teal, highlight: false),
                pw.SizedBox(width: 10),
                _billCard(
                    label: 'BALANCE',
                    value: trip.budget >= total
                        ? '${trip.currency} ${(trip.budget - total).toStringAsFixed(2)}'
                        : '-${trip.currency} ${(total - trip.budget).toStringAsFixed(2)}',
                    accent: trip.budget >= total
                        ? teal
                        : const PdfColor.fromInt(0xFFA32D2D),
                    highlight: false),
              ],
              pw.SizedBox(width: trip.budget > 0 ? 10 : 0),
              _billCard(label: 'NO. OF ITEMS',
                  value: '${trip.expenses.length}',
                  accent: const PdfColor.fromInt(0xFF993556), highlight: false),
            ]),

            pw.SizedBox(height: 22),

            // Itemised table
            _sectionHeader('Itemised Expenses'),
            pw.SizedBox(height: 8),
            pw.Table(
              columnWidths: const {
                0: pw.FixedColumnWidth(20),
                1: pw.FixedColumnWidth(56),
                2: pw.FlexColumnWidth(3),
                3: pw.FlexColumnWidth(2),
                4: pw.FixedColumnWidth(90),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: navy),
                  children: [
                    _th('#'), _th('Date'), _th('Description'),
                    _th('Category'), _th('Amount', right: true),
                  ],
                ),
                ...sortedExpenses.asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  final dateStr = e['date'] as String? ?? '';
                  String fmt = dateStr;
                  try { fmt = DateFormat('MMM d').format(DateTime.parse(dateStr)); } catch (_) {}
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: i.isEven ? lightGray : white),
                    children: [
                      _td('${i + 1}', color: textMuted),
                      _td(fmt, color: textMuted),
                      _td((e['title'] as String?) ?? ''),
                      _td((e['category'] as String?) ?? 'Other', color: textMuted),
                      _td('${trip.currency} ${(e['amount'] as num? ?? 0).toStringAsFixed(2)}',
                          right: true, bold: true),
                    ],
                  );
                }),
                // Grand total row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: navy),
                  children: [
                    _td('', color: white), _td('', color: white),
                    _td('', color: white),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: pw.Text('GRAND TOTAL',
                          style: pw.TextStyle(color: white, fontSize: 9,
                              fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: pw.Text(
                        '${trip.currency} ${total.toStringAsFixed(2)}',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          color: const PdfColor.fromInt(0xFF6AFFD4),
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 32),

            // Signature row
            pw.Row(children: [
              pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Container(height: 0.5, color: midGray, width: 160),
                pw.SizedBox(height: 4),
                pw.Text('Submitted by', style: const pw.TextStyle(fontSize: 9, color: textMuted)),
                if (submittedBy.isNotEmpty)
                  pw.Text(submittedBy,
                      style: pw.TextStyle(fontSize: 10,
                          fontWeight: pw.FontWeight.bold, color: navy)),
              ])),
              pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Container(height: 0.5, color: midGray, width: 160),
                pw.SizedBox(height: 4),
                pw.Text('Approved by', style: const pw.TextStyle(fontSize: 9, color: textMuted)),
                pw.Text('___________________',
                    style: const pw.TextStyle(fontSize: 9, color: midGray)),
              ])),
              pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Container(height: 0.5, color: midGray, width: 130),
                pw.SizedBox(height: 4),
                pw.Text('Date', style: const pw.TextStyle(fontSize: 9, color: textMuted)),
                pw.Text('_______________',
                    style: const pw.TextStyle(fontSize: 9, color: midGray)),
              ])),
            ]),

            pw.SizedBox(height: 16),
          ]),
        ),
      ],
      footer: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 10),
        decoration: const pw.BoxDecoration(
            border: pw.Border(
                top: pw.BorderSide(
                    color: PdfColor.fromInt(0xFFD3D1C7), width: 0.5))),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
                'Generated by Tour Buddy  |  $reportNo  |  $generatedOn',
                style: const pw.TextStyle(fontSize: 8, color: textMuted)),
            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: textMuted)),
          ],
        ),
      ),
    ));

    final dir = await getTemporaryDirectory();
    final safeName = trip.name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final file = File('${dir.path}/expense_report_$safeName.pdf');
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Expense Report – ${trip.name}',
    ));
  }

  static pw.Widget _sectionHeader(String title) {
    const purple = PdfColor.fromInt(0xFF7C6AFF);
    const navy = PdfColor.fromInt(0xFF1A1A2E);
    return pw.Row(children: [
      pw.Container(width: 3, height: 14, color: purple),
      pw.SizedBox(width: 8),
      pw.Text(title,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: navy)),
    ]);
  }

  static pw.Widget _billCard({
    required String label,
    required String value,
    required PdfColor accent,
    required bool highlight,
  }) {
    const navy = PdfColor.fromInt(0xFF1A1A2E);
    const lightGray = PdfColor.fromInt(0xFFF7F6FF);
    const lightPurple = PdfColor.fromInt(0xFFEEEDFE);
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: highlight ? lightPurple : lightGray,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: accent, width: highlight ? 1 : 0.5),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(label,
              style: pw.TextStyle(fontSize: 7, color: accent,
                  fontWeight: pw.FontWeight.bold, letterSpacing: 0.8)),
          pw.SizedBox(height: 4),
          pw.Text(value,
              style: pw.TextStyle(fontSize: highlight ? 13 : 11,
                  fontWeight: pw.FontWeight.bold, color: navy)),
        ]),
      ),
    );
  }

  static pw.Widget _th(String text, {bool center = false, bool right = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: pw.Text(text,
            textAlign: right ? pw.TextAlign.right : center ? pw.TextAlign.center : pw.TextAlign.left,
            style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
      );

  static pw.Widget _td(String text,
      {bool center = false, bool right = false, bool bold = false, PdfColor? color}) {
    const navy = PdfColor.fromInt(0xFF1A1A2E);
    const textMuted = PdfColor.fromInt(0xFF6B7280);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(text,
          textAlign: right ? pw.TextAlign.right : center ? pw.TextAlign.center : pw.TextAlign.left,
          style: pw.TextStyle(
              fontSize: 9,
              color: color ?? (bold ? navy : textMuted),
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }
}
