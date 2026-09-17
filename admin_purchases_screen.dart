import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/ar_format.dart';
import '../../data/app_repository.dart';
import '../../models/purchase.dart';
import '../../models/user.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_section_card.dart';
import '../../widgets/app_stat_tile.dart';
import '../../widgets/app_status_chip.dart';

/// شاشة المشتريات: طلبات الشراء واعتمادها واستلامها.
class AdminPurchasesScreen extends StatefulWidget {
  const AdminPurchasesScreen({super.key});

  static const String routeName = '/admin/purchases';

  @override
  State<AdminPurchasesScreen> createState() => _AdminPurchasesScreenState();
}

class _AdminPurchasesScreenState extends State<AdminPurchasesScreen> {
  final AppRepository _repository = AppRepository.instance;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _filter = 'الكل';

  static const List<String> _filters = <String>[
    'الكل',
    'قيد الاعتماد',
    'معتمد',
    'مُستلم',
    'مرفوض',
  ];

  static const List<String> _categories = <String>[
    'مستلزمات مكتبية',
    'نظافة وتعقيم',
    'أثاث مدرسي',
    'أجهزة تقنية',
    'كتب ومراجع',
    'صيانة وخدمات',
    'أخرى',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  PurchaseStatus? get _filterStatus => switch (_filter) {
        'قيد الاعتماد' => PurchaseStatus.pending,
        'معتمد' => PurchaseStatus.approved,
        'مُستلم' => PurchaseStatus.delivered,
        'مرفوض' => PurchaseStatus.rejected,
        _ => null,
      };

  List<PurchaseOrder> get _orders {
    Iterable<PurchaseOrder> list = _repository.purchases;
    final PurchaseStatus? status = _filterStatus;
    if (status != null) {
      list = list.where((PurchaseOrder item) => item.status == status);
    }
    if (_query.trim().isNotEmpty) {
      final String needle = _query.trim();
      list = list.where((PurchaseOrder item) {
        return item.title.contains(needle) ||
            item.category.contains(needle) ||
            item.supplierName.contains(needle) ||
            item.requestedByName.contains(needle);
      });
    }
    return list.toList();
  }

  String _money(double value) => '${value.toStringAsFixed(0)} د.ع';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('المشتريات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDialog,
        backgroundColor: AppTheme.royalPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_shopping_cart_outlined),
        label: const Text('طلب شراء'),
      ),
      body: ListenableBuilder(
        listenable: _repository,
        builder: (BuildContext context, Widget? child) {
          final List<PurchaseOrder> orders = _orders;
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            children: <Widget>[
              _summaryGrid(),
              const SizedBox(height: 12),
              SectionCard(
                title: 'البحث والتصفية',
                icon: Icons.filter_alt_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextField(
                      controller: _searchController,
                      onChanged: (String value) =>
                          setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: 'ابحث بالعنوان أو المورّد أو مقدم الطلب',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _filters
                          .map(
                            (String item) => ChoiceChip(
                              label: Text(item),
                              selected: _filter == item,
                              onSelected: (_) => setState(() => _filter = item),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (orders.isEmpty)
                const EmptyState(
                  title: 'لا توجد طلبات شراء',
                  message: 'جرّب تغيير التصفية أو أضف طلب شراء جديداً.',
                  icon: Icons.shopping_cart_outlined,
                )
              else
                ...orders.map(_orderCard),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryGrid() {
    final AppRepository repo = _repository;
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: StatTile(
                label: 'قيد الاعتماد',
                value: '${repo.pendingPurchasesCount}',
                icon: Icons.hourglass_top_outlined,
                color: AppTheme.lateColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'المصروف المعتمد',
                value: _money(repo.committedPurchasesTotal),
                icon: Icons.approval_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: StatTile(
                label: 'قيمة المُستلم',
                value: _money(repo.deliveredPurchasesTotal),
                icon: Icons.local_shipping_outlined,
                color: AppTheme.presentColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'إجمالي الطلبات',
                value: '${repo.purchases.length}',
                icon: Icons.inventory_2_outlined,
                color: AppTheme.midPurple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _orderCard(PurchaseOrder order) {
    final Color color = order.status.color;
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(order.status.icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      order.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.category} - ${order.supplierName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.notMarkedColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(
                label: order.status.label,
                color: color,
                icon: order.status.icon,
                dense: true,
              ),
            ],
          ),
          const Divider(height: 20),
          _detailRow(
            Icons.inventory_outlined,
            'الكمية',
            '${order.quantity} × ${_money(order.unitPrice)}',
          ),
          _detailRow(
            Icons.calculate_outlined,
            'الإجمالي',
            _money(order.total),
          ),
          _detailRow(
            Icons.person_outline,
            'مقدم الطلب',
            order.requestedByName,
          ),
          _detailRow(
            Icons.calendar_today_outlined,
            'تاريخ الطلب',
            ArFormat.date(order.createdAt),
          ),
          if (order.decidedBy != null)
            _detailRow(
              Icons.verified_outlined,
              order.status == PurchaseStatus.rejected ? 'رفضه' : 'اعتمده',
              order.decidedBy!,
            ),
          if (order.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                order.notes,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.notMarkedColor,
                  height: 1.5,
                ),
              ),
            ),
          const SizedBox(height: 10),
          _actionsRow(order),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: AppTheme.midPurple),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.notMarkedColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionsRow(PurchaseOrder order) {
    final String actor =
        _repository.currentUser?.fullName ?? 'مدير الإدارة';
    final Widget mainAction;
    switch (order.status) {
      case PurchaseStatus.pending:
        mainAction = Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  _repository.decidePurchase(
                    order.id,
                    approve: true,
                    decidedBy: actor,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم اعتماد "${order.title}".')),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.presentColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('اعتماد'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  _repository.decidePurchase(
                    order.id,
                    approve: false,
                    decidedBy: actor,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم رفض "${order.title}".')),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.absentColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('رفض'),
              ),
            ),
          ],
        );
      case PurchaseStatus.approved:
        mainAction = Expanded(
          child: FilledButton.icon(
            onPressed: () {
              _repository.markPurchaseDelivered(order.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم تسجيل استلام "${order.title}".')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.royalPurple,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.local_shipping_outlined, size: 18),
            label: const Text('تسجيل الاستلام'),
          ),
        );
      case PurchaseStatus.delivered:
      case PurchaseStatus.rejected:
        mainAction = const Expanded(
          child: Text(
            'لا توجد إجراءات متاحة',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.notMarkedColor,
            ),
          ),
        );
    }
    return Row(
      children: <Widget>[
        mainAction,
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'حذف الطلب',
          onPressed: () => _confirmRemove(order),
          icon: const Icon(
            Icons.delete_outline,
            color: AppTheme.absentColor,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmRemove(PurchaseOrder order) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('حذف طلب الشراء'),
        content: Text('هل تريد حذف "${order.title}" نهائياً؟'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.absentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _repository.removePurchase(order.id);
    }
  }

  Future<void> _openAddDialog() async {
    final PurchaseOrder? created = await showDialog<PurchaseOrder>(
      context: context,
      builder: (BuildContext context) => const _AddPurchaseDialog(),
    );
    if (created == null) {
      return;
    }
    _repository.addPurchase(created);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('أُرسل طلب الشراء "${created.title}" بانتظار الاعتماد.'),
        ),
      );
    }
  }
}

/// حوار إنشاء طلب شراء جديد.
class _AddPurchaseDialog extends StatefulWidget {
  const _AddPurchaseDialog();

  @override
  State<_AddPurchaseDialog> createState() => _AddPurchaseDialogState();
}

class _AddPurchaseDialogState extends State<_AddPurchaseDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _quantityController =
      TextEditingController(text: '1');
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _category = _AdminPurchasesScreenState._categories.first;

  @override
  void dispose() {
    _titleController.dispose();
    _supplierController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _unitPrice =>
      double.tryParse(_priceController.text.replaceAll(RegExp(r'[^\d.]'), '')) ??
      0;

  int get _quantity => int.tryParse(_quantityController.text) ?? 0;

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final AppUser? user = AppRepository.instance.currentUser;
    Navigator.of(context).pop(
      PurchaseOrder(
        id: AppRepository.instance.nextId('PUR'),
        title: _titleController.text.trim(),
        category: _category,
        quantity: _quantity < 1 ? 1 : _quantity,
        unitPrice: _unitPrice,
        supplierName: _supplierController.text.trim(),
        requestedByName: user?.fullName ?? 'الإدارة',
        createdAt: DateTime.now(),
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('طلب شراء جديد'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'وصف المشتريات',
                    hintText: 'مثال: سبورة زجاجية لقاعة 3',
                    prefixIcon: Icon(Icons.shopping_bag_outlined),
                  ),
                  validator: (String? value) =>
                      (value == null || value.trim().isEmpty)
                          ? 'أدخل وصف الطلب'
                          : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'التصنيف',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _AdminPurchasesScreenState._categories
                      .map(
                        (String item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() => _category = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الكمية',
                          prefixIcon: Icon(Icons.format_list_numbered),
                        ),
                        validator: (String? value) =>
                            (int.tryParse(value ?? '') ?? 0) < 1
                                ? 'كمية غير صحيحة'
                                : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'سعر الوحدة (د.ع)',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        validator: (String? value) =>
                            (double.tryParse(
                                      (value ?? '').replaceAll(
                                        RegExp(r'[^\d.]'),
                                        '',
                                      ),
                                    ) ??
                                    0) <=
                                0
                            ? 'أدخل السعر'
                            : null,
                        onChanged: (String value) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _supplierController,
                  decoration: const InputDecoration(
                    labelText: 'المورّد',
                    prefixIcon: Icon(Icons.store_outlined),
                  ),
                  validator: (String? value) =>
                      (value == null || value.trim().isEmpty)
                          ? 'أدخل اسم المورّد'
                          : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.lightPurple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.calculate_outlined,
                        size: 20,
                        color: AppTheme.royalPurple,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'الإجمالي التقديري: '
                        '${(_quantity * _unitPrice).toStringAsFixed(0)} د.ع',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.royalPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.royalPurple,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.send_outlined, size: 18),
          label: const Text('إرسال الطلب'),
        ),
      ],
    );
  }
}
