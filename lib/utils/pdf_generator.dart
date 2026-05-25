import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/quotation.dart';

class PdfGenerator {
  static final _primary  = PdfColor.fromHex('#47528f');
  static final _accent   = PdfColor.fromHex('#c97a3a');
  static final _lightBg  = PdfColor.fromHex('#fbede2');
  static final _totalBg  = PdfColor.fromHex('#d4ddef');

  static Future<void> printQuotation(Quotation q) async {
    final doc  = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();

    final baseStyle = pw.TextStyle(font: font, fontSize: 11, color: _primary);
    final boldStyle = pw.TextStyle(font: bold, fontSize: 11, color: _primary);

    // ======== صفحة 1: المنتجات ========
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(12, 12, 12, 20),
      textDirection: pw.TextDirection.rtl,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _header(font, bold),
          pw.SizedBox(height: 10),
          _infoRow4(q, font, bold),
          pw.SizedBox(height: 8),
          pw.Text('عرض السعر الأولي', style: pw.TextStyle(font: bold, fontSize: 13, color: _primary)),
          pw.Divider(color: _primary, thickness: 1.5),
          pw.Text('تفاصيل المنتجات والخدمات', style: boldStyle),
          pw.SizedBox(height: 6),
          _itemsTable(q, font, bold),
        ],
      ),
    ));

    // ======== صفحة 2: الملخص + الشروط ========
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(12, 12, 12, 20),
      textDirection: pw.TextDirection.rtl,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _header(font, bold),
          pw.SizedBox(height: 10),
          _infoRow3(q, font, bold),
          pw.Divider(color: _primary, thickness: 1.5),
          pw.Text('ملخص المبالغ', style: boldStyle),
          pw.SizedBox(height: 8),
          _summary(q, font, bold),
          pw.Divider(color: PdfColors.grey300),
          pw.Text('ملاحظات خاصة بالعرض:', style: boldStyle),
          pw.Divider(color: PdfColors.grey300),
          pw.Text(q.notes.isEmpty ? 'لا توجد ملاحظات' : q.notes, style: baseStyle),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey300),
          _terms(font, bold),
          pw.Spacer(),
          _thankYou(font, bold),
        ],
      ),
    ));

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  static pw.Widget _header(pw.Font font, pw.Font bold) => pw.Column(children: [
    pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('متخصصون في منظومات\nالطاقة الشمسية والشبكات',
            style: pw.TextStyle(font: bold, fontSize: 11, color: _primary)),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text('شركة الأماني للتجارة العامة والاستثمارات العقارية والوكالات التجارية م.م',
              style: pw.TextStyle(font: bold, fontSize: 11, color: _primary)),
          pw.Text('Al-Amani for General Trading, Real Estate & Commercial Agencies LLC',
              style: pw.TextStyle(font: font, fontSize: 9, color: _accent)),
        ]),
      ],
    ),
    pw.Divider(color: _primary, thickness: 1.5),
  ]);

  static pw.Widget _infoRow4(Quotation q, pw.Font font, pw.Font bold) =>
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        _info('اسم المشروع:', q.projectName.isEmpty ? '---' : q.projectName, font, bold),
        _info('اسم الزبون:', q.customerName, font, bold),
        _info('رقم الهاتف:', q.customerPhone.isEmpty ? '---' : q.customerPhone, font, bold),
        _info('العنوان:', q.customerAddress.isEmpty ? '---' : q.customerAddress, font, bold),
      ]);

  static pw.Widget _infoRow3(Quotation q, pw.Font font, pw.Font bold) =>
      pw.Row(children: [
        _info('اسم الزبون:', q.customerName, font, bold),
        pw.SizedBox(width: 20),
        _info('رقم العرض:', q.quotationNumber, font, bold),
        pw.SizedBox(width: 20),
        _info('التاريخ:', q.date, font, bold),
      ]);

  static pw.Widget _info(String label, String value, pw.Font font, pw.Font bold) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        pw.Text(label, style: pw.TextStyle(font: bold, fontSize: 10, color: _primary)),
        pw.SizedBox(height: 3),
        pw.Text(value, style: pw.TextStyle(font: font, fontSize: 10, color: _primary)),
      ]);

  static pw.Widget _itemsTable(Quotation q, pw.Font font, pw.Font bold) {
    final headers = ['NO.', 'الصورة', 'البيان / المنتج', 'الوحدة', 'العدد', 'السعر', 'الإجمالي'];
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(28),
        1: const pw.FixedColumnWidth(52),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(1.5),
        6: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _lightBg),
          children: headers.map((h) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 4),
            child: pw.Text(h, style: pw.TextStyle(font: bold, fontSize: 10, color: _primary), textAlign: pw.TextAlign.center),
          )).toList(),
        ),
        ...q.items.asMap().entries.map((e) {
          final i    = e.key;
          final item = e.value;
          pw.Widget imgW = pw.Container(
            width: 44, height: 44,
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            child: pw.Center(child: pw.Text('📦', style: pw.TextStyle(font: bold, fontSize: 18))),
          );
          if (item.imageBase64.isNotEmpty) {
            try {
              final data  = item.imageBase64.contains(',') ? item.imageBase64.split(',').last : item.imageBase64;
              imgW = pw.Image(pw.MemoryImage(base64Decode(data)), width: 44, height: 44, fit: pw.BoxFit.contain);
            } catch (_) {}
          }
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: i.isOdd ? PdfColors.grey50 : PdfColors.white),
            children: [
              _cell('${i + 1}', font),
              pw.Padding(padding: const pw.EdgeInsets.all(3), child: imgW),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(item.productName, style: pw.TextStyle(font: bold, fontSize: 11, color: _primary), textAlign: pw.TextAlign.right),
              ),
              _cell(item.unit, font),
              _cell(_fmt(item.qty), font),
              _cell(_fmt(item.price), font),
              _cell(_fmt(item.total), bold),
            ],
          );
        }),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _totalBg),
          children: [
            pw.Container(), pw.Container(),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('المجموع الكلي', style: pw.TextStyle(font: bold, fontSize: 13, color: _primary), textAlign: pw.TextAlign.right),
            ),
            pw.Container(), pw.Container(), pw.Container(),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_fmt(q.grandTotal), style: pw.TextStyle(font: bold, fontSize: 13, color: _primary), textAlign: pw.TextAlign.center),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _cell(String text, pw.Font f) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(text, style: pw.TextStyle(font: f, fontSize: 10, color: _primary), textAlign: pw.TextAlign.center),
  );

  static pw.Widget _summary(Quotation q, pw.Font font, pw.Font bold) => pw.Column(children: [
    _sumRow('اجمالي قيمة العرض',  'د.ع ${_fmt(q.grandTotal)}',      font, bold),
    _sumRow('نسبة الخصم',          '${q.discountPercent.toStringAsFixed(0)}%', font, bold),
    _sumRow('قيمة الخصم',          'د.ع ${_fmt(q.discountValue)}',  font, bold),
    _sumRow('الصافي بعد الخصم',    'د.ع ${_fmt(q.netTotal)}',       font, bold, highlight: true),
  ]);

  static pw.Widget _sumRow(String label, String value, pw.Font font, pw.Font bold, {bool highlight = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text(label, style: pw.TextStyle(font: highlight ? bold : font, fontSize: 13, color: PdfColors.black)),
          pw.Text(value, style: pw.TextStyle(font: bold, fontSize: highlight ? 15 : 13, color: PdfColors.black)),
        ]),
      );

  static pw.Widget _terms(pw.Font font, pw.Font bold) {
    const terms = [
      'هذا العرض ساري المفعول لمدة 30 يوماً من تاريخ الإصدار.',
      'الأسعار المذكورة بالدينار العراقي وشاملة لضريبة القيمة المضافة.',
      'يتم بدء التنفيذ بعد استلام دفعة مقدمة 50% من قيمة العقد.',
      'الدفعة المتبقية تُسدد عند الانتهاء من التركيب والتسليم.',
      'الشركة غير مسؤولة عن أي تأخير ناجم عن قوة قاهرة خارجة عن إرادتها.',
    ];
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('شروط وأحكام عرض السعر',
          style: pw.TextStyle(font: bold, fontSize: 13, color: _primary), textAlign: pw.TextAlign.center),
      pw.SizedBox(height: 6),
      ...terms.asMap().entries.map((e) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('${e.key + 1}. ', style: pw.TextStyle(font: bold, fontSize: 10, color: _primary)),
          pw.Expanded(child: pw.Text(e.value, style: pw.TextStyle(font: font, fontSize: 10, color: _primary))),
        ]),
      )),
    ]);
  }

  static pw.Widget _thankYou(pw.Font font, pw.Font bold) => pw.Column(children: [
    pw.Text('كلمة شكر وتقدير', style: pw.TextStyle(font: bold, fontSize: 15, color: _primary), textAlign: pw.TextAlign.center),
    pw.SizedBox(height: 6),
    pw.Text(
      'تتقدم شركة الأماني بخالص الشكر والتقدير على ثقتكم الكريمة، ونتطلع إلى أن نكون عند حسن ظنكم في تقديم أفضل الحلول التقنية والخدمات الهندسية المتخصصة.',
      style: pw.TextStyle(font: font, fontSize: 11, color: _primary),
      textAlign: pw.TextAlign.center,
    ),
    pw.SizedBox(height: 6),
    pw.Text('مع خالص التحية والاحترام - إدارة شركة الأماني',
        style: pw.TextStyle(font: bold, fontSize: 12, color: _accent), textAlign: pw.TextAlign.center),
  ]);

  static String _fmt(double n) => n
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}
