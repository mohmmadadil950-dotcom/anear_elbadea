import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../core/ar_format.dart';
import '../../data/app_repository.dart';
import '../../models/finance.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_info_row.dart';
import '../../widgets/app_section_card.dart';
import '../../widgets/app_stat_tile.dart';
import '../../widgets/app_status_chip.dart';

/// شاشة المالية: الفواتير والتحصيل وسندات القبض.
class AdminFinanceScreen extends StatefulWidget {
  const AdminFinanceScreen({super.key});

  static const String routeName = '/admin/finance';

  @override
  State<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends State<AdminFinanceScreen> {
  final AppRepository _repository = AppRepository.instance;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _filter = 'الكل';

  static const List<String> _filters = <String>[
    'الكل',
    'غير مسددة',
    'متأخرة',
    'مسددة',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FeeInvoice> get _invoices {
    Iterable<FeeInvoice> list = _repository.invoices;
    switch (_filter) {
      case 'غير مسددة':
        list = list.where((FeeInvoice item) => !item.isFullyPaid);
      case 'متأخرة':
        list = list.where(
          (FeeInvoice item) => item.status == InvoiceStatus.overdue,
        );
      case 'مسددة':
        list = list.where((FeeInvoice item) => item.isFullyPaid);
    }
    if (_query.trim().isNotEmpty) {
      list = list.where(
        (FeeInvoice item) => item.studentName.contains(_query.trim()),
      );
    }
    final List<FeeInvoice> result = list.toList();
    result.sort((FeeInvoice a, FeeInvoice b) => a.dueDate.compareTo(b.dueDate));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('المالية والرسوم')),
      body: ListenableBuilder(
        listenable: _repository,
        builder: (BuildContext context, Widget? child) {
          final List<FeeInvoice> invoices = _invoices;
          return ListView(
            padding: const EdgeInsets.all(12),
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
                      onChanged: (String value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: 'ابحث باسم الطالب',
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
              if (invoices.isEmpty)
                const EmptyState(
                  title: 'لا توجد فواتير',
                  message: 'جرّب تغيير التصفية أو البحث.',
                  icon: Icons.receipt_long_outlined,
                )
              else
                ...invoices.map(_invoiceCard),
              const SizedBox(height: 12),
              _receiptsCard(),
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
                label: 'إجمالي المفوتر',
                value: _money(repo.totalBilled),
                icon: Icons.request_quote_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'إجمالي المحصّل',
                value: _money(repo.totalCollected),
                icon: Icons.savings_outlined,
                color: AppTheme.presentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: StatTile(
                label: 'المتبقي',
                value: _money(repo.totalOutstanding),
                icon: Icons.hourglass_bottom_outlined,
                color: AppTheme.lateColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'فواتير متأخرة',
                value: '${repo.overdueInvoices.length}',
                icon: Icons.warning_amber_outlined,
                color: AppTheme.absentColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _statusColor(InvoiceStatus status) => switch (status) {
        InvoiceStatus.paid => AppTheme.presentColor,
        InvoiceStatus.partial => AppTheme.lateColor,
        InvoiceStatus.unpaid => AppTheme.notMarkedColor,
        InvoiceStatus.overdue => AppTheme.absentColor,
      };

  Widget _invoiceCard(FeeInvoice invoice) {
    final Color color = _statusColor(invoice.status);
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      invoice.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.deepPurple,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${invoice.studentName} - ${invoice.grade}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.notMarkedColor,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(label: invoice.status.label, color: color, dense: true),
            ],
          ),
          const SizedBox(height: 10),
          GradientProgressBar(value: invoice.paidRatio, color: color),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'المبلغ: ${_money(invoice.amount)}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.deepPurple,
                ),
              ),
              Text(
                invoice.isFullyPaid
                    ? 'سُددت بالكامل'
                    : 'المتبقي: ${_money(invoice.remaining)}',
                style: TextStyle(
                  fontSize: 12.5,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.event_outlined,
                      size: 15, color: AppTheme.notMarkedColor),
                  const SizedBox(width: 4),
                  Text(
                    'الاستحقاق: ${ArFormat.date(invoice.dueDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.notMarkedColor,
                    ),
                  ),
                ],
              ),
              if (!invoice.isFullyPaid)
                FilledButton.icon(
                  onPressed: () => _showPaymentDialog(invoice),
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text('تسديد'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.royalPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _receiptsCard() {
    final List<PaymentReceipt> receipts =
        _repository.receipts.take(8).toList();
    return SectionCard(
      title: 'أحدث سندات القبض',
      icon: Icons.receipt_outlined,
      subtitle: receipts.isEmpty ? null : 'آخر ${receipts.length} عملية تسديد',
      child: receipts.isEmpty
          ? const Text(
              'لا توجد عمليات تسديد بعد.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.notMarkedColor),
            )
          : Column(
              children: receipts
                  .map(
                    (PaymentReceipt receipt) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.lightPurple),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.check_circle_outline,
                              color: AppTheme.presentColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  receipt.studentName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.deepPurple,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${ArFormat.dateTime(receipt.paidAt)} - ${receipt.method}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppTheme.notMarkedColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _money(receipt.amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.presentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  void _showPaymentDialog(FeeInvoice invoice) {
    final TextEditingController amountController = TextEditingController(
      text: invoice.remaining.toStringAsFixed(0),
    );
    String method = 'نقدي';

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            void Function(void Function()) setState,
          ) {
            return AlertDialog(
              title: Text('تسديد: ${invoice.title}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'الطالب: ${invoice.studentName}\n'
                    'المتبقي: ${_money(invoice.remaining)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'المبلغ (د.ع)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: <String>['نقدي', 'تحويل مصرفي', 'زين كاش']
                        .map(
                          (String item) => ChoiceChip(
                            label: Text(item),
                            selected: method == item,
                            onSelected: (_) => setState(() => method = item),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.royalPurple,
                  ),
                  onPressed: () {
                    final double? amount =
                        double.tryParse(amountController.text.trim());
                    if (amount == null || amount <= 0) {
                      return;
                    }
                    _repository.recordPayment(
                      invoiceId: invoice.id,
                      amount: amount,
                      method: method,
                    );
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم تسديد ${_money(amount)} - ${invoice.studentName}',
                        ),
                      ),
                    );
                  },
                  child: const Text('تأكيد التسديد'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static String _money(double value) {
    final String digits = value.toStringAsFixed(0);
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      out.write(digits[i]);
      final int left = digits.length - 1 - i;
      if (left > 0 && left % 3 == 0) {
        out.write(',');
      }
    }
    return '$out د.ع';
  }
}
  // __FINANCE_HELPERS__