import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const StockApp());
}

class StockApp extends StatelessWidget {
  const StockApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Stock Inventory Manager',
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.nunito().fontFamily,
      scaffoldBackgroundColor: const Color(0xFFF3F6FB),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B82)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDE4EE))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDE4EE))),
      ),
    ),
    home: const InventoryPage(),
  );
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});
  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _sku = TextEditingController();
  final _name = TextEditingController();
  final _qty = TextEditingController();
  final _price = TextEditingController();
  final _reorder = TextEditingController();
  final _search = TextEditingController();
  final _items = FirebaseFirestore.instance.collection('stockItems');
  final _categories = ['Electronics', 'Stationery', 'Hardware', 'Grocery'];
  String? _category;
  String _filterCategory = 'All';
  bool _lowOnly = false;
  bool _ascending = true;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_sku, _name, _qty, _price, _reorder, _search]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'This field is required' : null;

  String? _wholeNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final n = int.tryParse(value.trim());
    if (n == null || n < 0) return 'Enter a whole number (0 or more)';
    return null;
  }

  String? _validPrice(String? value) {
    if (value == null || value.trim().isEmpty) return 'Price is required';
    final n = double.tryParse(value.trim());
    if (n == null || !n.isFinite || n <= 0) return 'Enter a price greater than 0';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      await _items.add({
        'sku': _sku.text.trim().toUpperCase(),
        'itemName': _name.text.trim(),
        'category': _category!,
        'quantity': int.parse(_qty.text.trim()),
        'unitPrice': double.parse(_price.text.trim()),
        'reorderLevel': int.parse(_reorder.text.trim()),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      for (final c in [_sku, _name, _qty, _price, _reorder]) {
        c.clear();
      }
      setState(() => _category = null);
      _formKey.currentState!.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item saved to Firestore successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String label, TextEditingController controller,
      String? Function(String?) validator, {bool numeric = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          validator: validator,
        ),
      );

  void _clearFilters() {
    _search.clear();
    setState(() {
      _filterCategory = 'All';
      _lowOnly = false;
      _ascending = true;
    });
  }

  Widget _panel({required Widget child}) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EDF5)),
        boxShadow: const [BoxShadow(color: Color(0x0A172A46), blurRadius: 22, offset: Offset(0, 8))]),
    child: child,
  );

  Widget _heading(IconData icon, String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(
          color: const Color(0xFFE5F4F5), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFF176B82))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF14263D))),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF78869A))),
      ])),
    ]),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: const Color(0xFF14263D), foregroundColor: Colors.white,
      toolbarHeight: 72,
      title: const Row(children: [
        Icon(Icons.inventory_2_rounded, color: Color(0xFF75D5C5)),
        SizedBox(width: 12),
        Text('STOCKFLOW', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        SizedBox(width: 14),
        Text('Inventory Manager', style: TextStyle(fontSize: 13, color: Color(0xFFB7C5D6))),
      ]),
    ),
    body: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1120),
      child: ListView(padding: const EdgeInsets.all(22), children: [
        const Text('Inventory Dashboard', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF14263D))),
        const SizedBox(height: 6),
        const Text('Manage products, track stock levels and find items instantly.',
            style: TextStyle(color: Color(0xFF78869A), fontSize: 14)),
        const SizedBox(height: 22),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _items.snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            final low = docs.where((doc) {
              final d = doc.data();
              return ((d['quantity'] as num?)?.toInt() ?? 0) <= ((d['reorderLevel'] as num?)?.toInt() ?? 0);
            }).length;
            final units = docs.fold<int>(0, (sum, doc) => sum + ((doc.data()['quantity'] as num?)?.toInt() ?? 0));
            return LayoutBuilder(builder: (context, c) {
              final narrow = c.maxWidth < 620;
              final tiles = [
                _stat('Total Products', '${docs.length}', Icons.category_outlined, const Color(0xFF176B82)),
                _stat('Stock Units', '$units', Icons.inventory_2_outlined, const Color(0xFF5066B5)),
                _stat('Low Stock Alerts', '$low', Icons.warning_amber_rounded, const Color(0xFFD98438)),
              ];
              return narrow ? Column(children: [for (final tile in tiles) Padding(
                  padding: const EdgeInsets.only(bottom: 10), child: tile)])
                  : Row(children: [for (final tile in tiles) Expanded(child: Padding(
                  padding: const EdgeInsets.only(right: 12), child: tile))]);
            });
          },
        ),
        const SizedBox(height: 24),
        _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _heading(Icons.add_box_outlined, 'Add New Stock Item', 'Enter product details to save them to Cloud Firestore'),
          Form(key: _formKey, child: LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth >= 680;
            final fields = <Widget>[
              _field('SKU (STK-101)', _sku, (v) => RegExp(r'^STK-\d{3}$').hasMatch((v ?? '').trim())
                  ? null : 'Use format STK- followed by 3 digits'),
              _field('Item Name', _name, (v) {
                if (_required(v) != null) return 'Item name is required';
                return v!.trim().length < 3 ? 'At least 3 characters required' : null;
              }),
              Padding(padding: const EdgeInsets.only(bottom: 12), child: DropdownButtonFormField<String>(
                initialValue: _category, decoration: const InputDecoration(labelText: 'Category'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v),
                validator: (v) => v == null ? 'Select a category' : null,
              )),
              _field('Quantity', _qty, _wholeNumber, numeric: true),
              _field('Unit Price (RM)', _price, _validPrice, numeric: true),
              _field('Reorder Level', _reorder, _wholeNumber, numeric: true),
            ];
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (wide) ...[for (int i = 0; i < fields.length; i += 2)
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: fields[i])),
                  Expanded(child: Padding(padding: const EdgeInsets.only(left: 8), child: fields[i + 1])),
                ])] else ...fields,
              const SizedBox(height: 4),
              SizedBox(height: 48, child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF176B82),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _saving ? null : _save,
                icon: _saving ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.add_circle_outline),
                label: Text(_saving ? 'Saving...' : 'Save Item', style: const TextStyle(fontWeight: FontWeight.bold)),
              )),
            ]);
          })),
        ])),
        const SizedBox(height: 24),
        _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _heading(Icons.manage_search_rounded, 'Inventory & Advanced Search',
              'Live inventory records from Firebase'),
          TextField(controller: _search, onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Search by item name or SKU',
                  prefixIcon: Icon(Icons.search_rounded))),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, c) {
            final category = DropdownButtonFormField<String>(
              key: ValueKey(_filterCategory), initialValue: _filterCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ['All', ..._categories].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _filterCategory = v!),
            );
            final sort = DropdownButtonFormField<bool>(
              key: ValueKey(_ascending), initialValue: _ascending,
              decoration: const InputDecoration(labelText: 'Sort by quantity'),
              items: const [DropdownMenuItem(value: true, child: Text('Low to High')),
                DropdownMenuItem(value: false, child: Text('High to Low'))],
              onChanged: (v) => setState(() => _ascending = v!),
            );
            return c.maxWidth >= 600 ? Row(children: [Expanded(child: category),
              const SizedBox(width: 12), Expanded(child: sort)])
                : Column(children: [category, const SizedBox(height: 12), sort]);
          }),
          const SizedBox(height: 12),
          Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12, runSpacing: 8, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Switch(value: _lowOnly, onChanged: (v) => setState(() => _lowOnly = v)),
                  const Text('Low stock only', style: TextStyle(fontWeight: FontWeight.w600)),
                ]),
                TextButton.icon(onPressed: _clearFilters, icon: const Icon(Icons.filter_alt_off_outlined),
                    label: const Text('Clear Filters')),
              ]),
          const Divider(height: 28),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _items.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text('Firestore error: ${snapshot.error}');
              if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator()));
              final keyword = _search.text.trim().toLowerCase();
              final records = snapshot.data!.docs.where((doc) {
                final d = doc.data();
                final name = (d['itemName'] ?? '').toString().toLowerCase();
                final sku = (d['sku'] ?? '').toString().toLowerCase();
                final qty = (d['quantity'] as num?)?.toInt() ?? 0;
                final reorder = (d['reorderLevel'] as num?)?.toInt() ?? 0;
                return (name.contains(keyword) || sku.contains(keyword)) &&
                    (_filterCategory == 'All' || d['category'] == _filterCategory) &&
                    (!_lowOnly || qty <= reorder);
              }).toList();
              records.sort((a, b) {
                final x = (a.data()['quantity'] as num?)?.toInt() ?? 0;
                final y = (b.data()['quantity'] as num?)?.toInt() ?? 0;
                return _ascending ? x.compareTo(y) : y.compareTo(x);
              });
              if (records.isEmpty) return Padding(padding: const EdgeInsets.all(26),
                  child: Center(child: Column(children: [
                    const Icon(Icons.inventory_2_outlined, size: 38, color: Color(0xFF9BA9B9)),
                    const SizedBox(height: 10),
                    Text(snapshot.data!.docs.isEmpty ? 'No inventory items yet. Add your first item.'
                        : 'No matching items. Try clearing the filters.', textAlign: TextAlign.center),
                  ])));
              return Column(children: records.map((doc) {
                final d = doc.data();
                final qty = (d['quantity'] as num).toInt();
                final reorder = (d['reorderLevel'] as num).toInt();
                final price = (d['unitPrice'] as num).toDouble();
                final low = qty <= reorder;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFD),
                      border: Border.all(color: const Color(0xFFE7EDF5)),
                      borderRadius: BorderRadius.circular(14)),
                  child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    leading: Container(width: 44, height: 44,
                        decoration: BoxDecoration(color: const Color(0xFFE5F4F5), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF176B82))),
                    title: Text('${d['itemName']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Padding(padding: const EdgeInsets.only(top: 5),
                        child: Text('${d['sku']}  •  ${d['category']}  •  Qty: $qty  •  RM ${price.toStringAsFixed(2)}  •  Reorder: $reorder')),
                    trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(color: low ? const Color(0xFFFFE8DC) : const Color(0xFFE0F5E9),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(low ? 'LOW STOCK' : 'IN STOCK', style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w800,
                            color: low ? const Color(0xFFB85B2B) : const Color(0xFF228455)))),
                  ),
                );
              }).toList());
            },
          ),
        ])),
        const SizedBox(height: 22),
        const Center(child: Text('STOCKFLOW  •  Powered by Flutter & Cloud Firestore',
            style: TextStyle(fontSize: 11, color: Color(0xFF9BA9B9)))),
      ]),
    )),
  );

  Widget _stat(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EDF5))),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF78869A))),
        Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Color(0xFF14263D))),
      ])),
    ]),
  );
}
