import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../theme.dart';

class ProductsScreen extends StatefulWidget {
  final List<Product> products;
  const ProductsScreen({super.key, required this.products});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late List<Product> _products;
  final _nameCtrl  = TextEditingController();
  final _unitCtrl  = TextEditingController(text: 'قطعة');
  final _priceCtrl = TextEditingController(text: '0');
  String _imgB64 = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _products = List.from(widget.products);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final xf = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 220, maxHeight: 220, imageQuality: 75,
    );
    if (xf == null) return;
    final bytes = await xf.readAsBytes();
    setState(() => _imgB64 = 'data:image/jpeg;base64,${base64Encode(bytes)}');
  }

  Future<void> _saveProduct() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { _msg('أدخل اسم المنتج', isError: true); return; }
    setState(() => _saving = true);
    final product = Product(
      name: name,
      unit: _unitCtrl.text.trim().isEmpty ? 'قطعة' : _unitCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text) ?? 0,
      imageBase64: _imgB64,
    );
    final result = await ApiService.addProduct(product);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result['success'] == true) {
      setState(() {
        _products.add(product);
        _nameCtrl.clear();
        _priceCtrl.text = '0';
        _imgB64 = '';
      });
      _msg(result['message'] ?? 'تم الإضافة');
    } else {
      _msg(result['message'] ?? 'خطأ', isError: true);
    }
  }

  Future<void> _deleteProduct(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف المنتج "$name"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final result = await ApiService.deleteProduct(name);
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() => _products.removeWhere((p) => p.name == name));
      _msg(result['message'] ?? 'تم الحذف');
    } else {
      _msg(result['message'] ?? 'خطأ', isError: true);
    }
  }

  void _msg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.danger : AppTheme.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المنتجات')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildAddForm(),
          const SizedBox(height: 20),
          _buildProductGrid(),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _buildAddForm() => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('إضافة منتج جديد',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
        const SizedBox(height: 14),
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'اسم المنتج *', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextFormField(
            controller: _unitCtrl,
            decoration: const InputDecoration(labelText: 'الوحدة', border: OutlineInputBorder()),
          )),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(
            controller: _priceCtrl,
            decoration: const InputDecoration(labelText: 'السعر (د.ع)', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          )),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image, size: 16),
            label: const Text('اختر صورة'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade600),
          ),
          if (_imgB64.isNotEmpty) ...[const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.memory(
                base64Decode(_imgB64.split(',').last),
                width: 48, height: 48, fit: BoxFit.contain,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppTheme.danger, size: 18),
              onPressed: () => setState(() => _imgB64 = ''),
            ),
          ],
        ]),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _saveProduct,
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save),
            label: Text(_saving ? 'جاري الحفظ...' : 'حفظ المنتج'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
      ],
    )),
  );

  Widget _buildProductGrid() {
    if (_products.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Column(children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('لا توجد منتجات بعد', style: TextStyle(color: Colors.grey)),
          ])),
        ),
      );
    }
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('المنتجات المخزونة',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
              child: Text('${_products.length}', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.72,
            ),
            itemCount: _products.length,
            itemBuilder: (_, i) => _buildCard(_products[i]),
          ),
        ],
      )),
    );
  }

  Widget _buildCard(Product p) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Column(children: [
        Expanded(
          child: p.imageBase64.isNotEmpty
              ? ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: Image.memory(
                    _b64(p.imageBase64),
                    width: double.infinity, fit: BoxFit.contain,
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.indigo.shade50, Colors.indigo.shade100]),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: const Center(child: Icon(Icons.inventory_2_outlined, size: 32, color: AppTheme.primary)),
                ),
        ),
        Padding(padding: const EdgeInsets.all(6), child: Column(children: [
          Text(p.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primary),
              textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          Text(p.unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(_fmt(p.price) + ' د.ع',
              style: const TextStyle(fontSize: 10, color: AppTheme.success, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _deleteProduct(p.name),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(4)),
              child: const Text('حذف', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ])),
      ]),
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
