import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/quotation.dart';
import '../models/quotation_item.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/pdf_generator.dart';
import 'products_screen.dart';

class QuotationScreen extends StatefulWidget {
  const QuotationScreen({super.key});

  @override
  State<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends State<QuotationScreen> {
  final _quotation   = Quotation();
  List<Product> _products = [];
  bool _saving = false;

  final _qNumberCtrl  = TextEditingController();
  final _dateCtrl     = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _addressCtrl  = TextEditingController();
  final _projectCtrl  = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  final _notesCtrl    = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final now = DateTime.now();
    _dateCtrl.text = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _quotation.date = _dateCtrl.text;

    final results = await Future.wait([
      ApiService.getNextQuotationNumber(),
      ApiService.getAllProducts(),
    ]);
    if (!mounted) return;
    setState(() {
      _qNumberCtrl.text    = results[0] as String;
      _quotation.quotationNumber = results[0] as String;
      _products            = results[1] as List<Product>;
    });
  }

  @override
  void dispose() {
    for (final c in [_qNumberCtrl, _dateCtrl, _durationCtrl, _nameCtrl,
                     _phoneCtrl, _addressCtrl, _projectCtrl, _discountCtrl, _notesCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _addItem() => setState(() => _quotation.items.add(QuotationItem()));

  void _removeItem(int index) {
    if (_quotation.items.length <= 1) {
      _msg('لا يمكن حذف البند الأخير', isError: true);
      return;
    }
    setState(() => _quotation.items.removeAt(index));
  }

  void _recalc() => setState(() {
    _quotation.discountPercent = double.tryParse(_discountCtrl.text) ?? 0;
  });

  void _fillQuotationFromFields() {
    _quotation
      ..customerName    = _nameCtrl.text.trim()
      ..customerPhone   = _phoneCtrl.text.trim()
      ..customerAddress = _addressCtrl.text.trim()
      ..projectName     = _projectCtrl.text.trim()
      ..duration        = _durationCtrl.text.trim()
      ..notes           = _notesCtrl.text.trim()
      ..discountPercent = double.tryParse(_discountCtrl.text) ?? 0
      ..quotationNumber = _qNumberCtrl.text
      ..date            = _dateCtrl.text;
  }

  bool _validate() {
    if (_nameCtrl.text.trim().isEmpty) {
      _msg('الرجاء إدخال اسم الزبون', isError: true);
      return false;
    }
    if (_quotation.items.any((i) => i.productName.trim().isEmpty)) {
      _msg('الرجاء ملء جميع أسماء المنتجات', isError: true);
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    _fillQuotationFromFields();
    setState(() => _saving = true);
    final result = await ApiService.saveQuotation(_quotation);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result['success'] == true) {
      _msg(result['message'] ?? 'تم الحفظ بنجاح');
      if (result['quotationNumber'] != null) {
        _qNumberCtrl.text          = result['quotationNumber'] as String;
        _quotation.quotationNumber = result['quotationNumber'] as String;
      }
    } else {
      _msg(result['message'] ?? 'خطأ في الحفظ', isError: true);
    }
  }

  Future<void> _print() async {
    if (!_validate()) return;
    _fillQuotationFromFields();
    await PdfGenerator.printQuotation(_quotation);
  }

  void _msg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.danger : AppTheme.success,
      duration: const Duration(seconds: 4),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Column(children: [
          Text('شركة الأماني', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text('نظام عروض الأسعار', style: TextStyle(fontSize: 11, color: Color(0xFFFFECB3))),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'إدارة المنتجات',
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ProductsScreen(products: _products)));
              final updated = await ApiService.getAllProducts();
              if (mounted) setState(() => _products = updated);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildInfoCard(),
          const SizedBox(height: 14),
          _buildCustomerCard(),
          const SizedBox(height: 14),
          _buildItemsCard(),
          const SizedBox(height: 14),
          _buildDiscountCard(),
          const SizedBox(height: 14),
          _buildNotesCard(),
          const SizedBox(height: 14),
          _buildTotalBox(),
          const SizedBox(height: 20),
          _buildActionButtons(),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _buildInfoCard() => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('معلومات العرض'),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _field('رقم العرض', _qNumberCtrl, readOnly: true)),
          const SizedBox(width: 12),
          Expanded(child: _field('التاريخ', _dateCtrl, readOnly: true)),
        ]),
        const SizedBox(height: 12),
        _field('مدة التنفيذ', _durationCtrl, hint: 'مثال: 10 أيام عمل'),
      ],
    )),
  );

  Widget _buildCustomerCard() => Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: AppTheme.primary, width: 1.5),
    ),
    child: Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: const Row(children: [
          Icon(Icons.business, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text('بيانات الزبون', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
      ),
      Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Row(children: [
          Expanded(child: _field('اسم الزبون *', _nameCtrl, hint: 'الاسم الكامل')),
          const SizedBox(width: 12),
          Expanded(child: _field('رقم الهاتف', _phoneCtrl, hint: '07XX-XXX-XXXX', type: TextInputType.phone)),
        ]),
        const SizedBox(height: 12),
        _field('العنوان / المحافظة', _addressCtrl, hint: 'مثال: كربلاء'),
        const SizedBox(height: 12),
        _field('اسم المشروع والموقع', _projectCtrl, hint: 'مثال: منظومة طاقة شمسية...'),
      ])),
    ]),
  );

  Widget _buildItemsCard() => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('تفاصيل المنتجات'),
            ElevatedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('إضافة بند'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(_quotation.items.length, (i) => _ItemRow(
          key: ObjectKey(_quotation.items[i]),
          item: _quotation.items[i],
          index: i,
          products: _products,
          onChanged: () => setState(() {}),
          onDelete: () => _removeItem(i),
        )),
      ],
    )),
  );

  Widget _buildDiscountCard() => Card(
    color: const Color(0xFFFFF8E1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: Color(0xFFFFa000), width: 1.5),
    ),
    child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('الخصم والصافي',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: TextField(
            controller: _discountCtrl,
            decoration: const InputDecoration(labelText: 'نسبة الخصم (%)', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (_) => _recalc(),
          )),
          const SizedBox(width: 10),
          Expanded(child: _readonlyInfo('قيمة الخصم', _fmtNum(_quotation.discountValue) + ' د.ع', Colors.red.shade700)),
          const SizedBox(width: 10),
          Expanded(child: _readonlyInfo('الصافي', _fmtNum(_quotation.netTotal) + ' د.ع', AppTheme.success)),
        ]),
      ],
    )),
  );

  Widget _buildNotesCard() => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('ملاحظات'),
        const SizedBox(height: 12),
        TextField(
          controller: _notesCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'اكتب هنا أي ملاحظات إضافية...',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    )),
  );

  Widget _buildTotalBox() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(children: [
      const Text('الإجمالي الكلي للعرض',
          style: TextStyle(color: Colors.white70, fontSize: 14)),
      const SizedBox(height: 8),
      Text(
        _fmtNum(_quotation.grandTotal) + ' د.ع',
        style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 32, fontWeight: FontWeight.w800),
      ),
    ]),
  );

  Widget _buildActionButtons() => Column(children: [
    SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save),
        label: Text(_saving ? 'جاري الحفظ...' : 'حفظ في Google Sheet'),
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
      ),
    ),
    const SizedBox(height: 12),
    SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _print,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('طباعة / تصدير PDF'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: const Color(0xFFE65100),
        ),
      ),
    ),
  ]);

  Widget _sectionTitle(String text) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 14));

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, bool readOnly = false, TextInputType? type}) =>
      TextFormField(
        controller: ctrl,
        readOnly: readOnly,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          filled: readOnly,
          fillColor: readOnly ? const Color(0xFFECEFF1) : null,
        ),
        style: readOnly ? const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary) : null,
      );

  Widget _readonlyInfo(String label, String value, Color valueColor) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor, fontSize: 12)),
      ],
    ),
  );

  String _fmtNum(double n) => n
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ================================================================
// _ItemRow — صف منتج واحد مع autocomplete
// ================================================================
class _ItemRow extends StatefulWidget {
  final QuotationItem item;
  final int index;
  final List<Product> products;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _ItemRow({
    required super.key,
    required this.item,
    required this.index,
    required this.products,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  late TextEditingController _unitCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _unitCtrl  = TextEditingController(text: widget.item.unit);
    _qtyCtrl   = TextEditingController(text: widget.item.qty.toStringAsFixed(0));
    _priceCtrl = TextEditingController(text: widget.item.price.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _unitCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _update() {
    widget.item
      ..unit  = _unitCtrl.text
      ..qty   = double.tryParse(_qtyCtrl.text)   ?? 0
      ..price = double.tryParse(_priceCtrl.text) ?? 0;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('البند ${widget.index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13)),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
                onPressed: widget.onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Autocomplete<Product>(
            initialValue: TextEditingValue(text: widget.item.productName),
            optionsBuilder: (val) {
              if (val.text.isEmpty) return const [];
              final q = val.text.toLowerCase();
              return widget.products.where((p) => p.name.toLowerCase().contains(q));
            },
            displayStringForOption: (p) => p.name,
            onSelected: (p) {
              widget.item
                ..productName = p.name
                ..unit        = p.unit
                ..price       = p.price
                ..imageBase64 = p.imageBase64;
              _unitCtrl.text  = p.unit;
              _priceCtrl.text = p.price.toStringAsFixed(0);
              widget.onChanged();
            },
            fieldViewBuilder: (ctx, ctrl, focus, _) => TextField(
              controller: ctrl,
              focusNode: focus,
              decoration: const InputDecoration(
                labelText: 'اسم المنتج / الخدمة',
                hintText: 'ابحث عن منتج...',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search, size: 18),
              ),
              onChanged: (v) {
                widget.item.productName = v;
                widget.onChanged();
              },
            ),
            optionsViewBuilder: (ctx, onSel, opts) => Align(
              alignment: AlignmentDirectional.topStart,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220, maxWidth: 350),
                  child: ListView(
                    shrinkWrap: true,
                    children: opts.map((p) => ListTile(
                      dense: true,
                      leading: p.imageBase64.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.memory(_b64(p.imageBase64), width: 36, height: 36, fit: BoxFit.contain),
                            )
                          : const Icon(Icons.inventory_2_outlined, color: AppTheme.primary),
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('${_fmt(p.price)} د.ع  |  ${p.unit}', style: const TextStyle(fontSize: 11)),
                      onTap: () => onSel(p),
                    )).toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(
              controller: _unitCtrl,
              decoration: const InputDecoration(labelText: 'الوحدة', border: OutlineInputBorder()),
              textAlign: TextAlign.center,
              onChanged: (_) => _update(),
            )),
            const SizedBox(width: 8),
            Expanded(child: TextField(
              controller: _qtyCtrl,
              decoration: const InputDecoration(labelText: 'العدد', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (_) => _update(),
            )),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: TextField(
              controller: _priceCtrl,
              decoration: const InputDecoration(labelText: 'السعر (د.ع)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (_) => _update(),
            )),
          ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFECEFF1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الإجمالي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary)),
                Text(_fmt(widget.item.total) + ' د.ع',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 14)),
              ],
            ),
          ),
          if (widget.item.imageBase64.isNotEmpty) ...[const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.memory(_b64(widget.item.imageBase64), height: 55, width: 55, fit: BoxFit.contain),
            ),
          ],
        ],
      ),
    );
  }

  Uint8List _b64(String s) {
    final data = s.contains(',') ? s.split(',').last : s;
    return base64Decode(data);
  }

  String _fmt(double n) => n
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}
