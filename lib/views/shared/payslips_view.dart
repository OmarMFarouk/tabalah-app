import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/models/json_utils.dart';
import 'package:tabala/models/salary_model.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/src/utils/app_date.dart';
import 'package:tabala/src/utils/app_money.dart';
import 'package:url_launcher/url_launcher.dart';

/// Open the printable payslip for [salaryId] in the browser, where it can be
/// saved as a PDF. Shared by the trainer's performance tab and this view.
Future<void> openPayslip(BuildContext context, int salaryId) async {
  try {
    final r = await ApiClient.instance.get(ApiEndpoints.payslipLink(salaryId));
    final url = J.asStringOrNull(r['url']);
    if (url != null) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } on ApiException catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// An employee's payslips, newest first; each expands to its breakdown.
class PayslipsView extends StatefulWidget {
  final bool asTab;
  const PayslipsView({super.key, this.asTab = false});

  @override
  State<PayslipsView> createState() => _PayslipsViewState();
}

class _PayslipsViewState extends State<PayslipsView> {
  List<SalaryModel>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await ApiClient.instance.get(ApiEndpoints.employeeSalaries, query: {'per_page': 24});
      if (mounted) setState(() => _rows = J.list(r['salaries'], SalaryModel.fromJson));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    return Scaffold(
      backgroundColor: AppColors.scaffoldcolor,
      appBar: widget.asTab ? null : AppBar(title: Text('my_payslips'.tr())),
      body: SafeArea(
        top: widget.asTab,
        bottom: false,
        child: rows == null
            ? AsyncStateView(isLoading: _error == null, errorMessage: _error, onRetry: _load, child: const SizedBox())
            : RefreshIndicator(
                color: AppColors.goldInk,
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                  children: [
                    if (widget.asTab) ...[
                      Text('my_payslips'.tr(), style: AppStyles.bold24Black),
                      const SizedBox(height: 12),
                    ],
                    if (rows.isEmpty)
                      ClubCard(
                        child: EmptyState(
                          icon: Icons.request_quote_outlined,
                          title: 'no_salary_records'.tr(),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      )
                    else
                      for (final s in rows) PayslipCard(salary: s),
                  ],
                ),
              ),
      ),
    );
  }
}

/// One month's pay, collapsed to the take-home figure and opening into the
/// breakdown and the PDF.
class PayslipCard extends StatelessWidget {
  final SalaryModel salary;
  const PayslipCard({super.key, required this.salary});

  @override
  Widget build(BuildContext context) {
    final s = salary;
    Widget line(String key, double v, {bool minus = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(child: Text(key.tr(), style: AppStyles.regular14Grey)),
            Text(
              v == 0 ? '—' : '${minus ? '- ' : ''}${AppMoney.amount(v)}',
              style: minus && v > 0 ? AppStyles.medium14Red : AppStyles.medium14Black,
            ),
          ]),
        );

    return ClubCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          leading: Icon(Icons.payments_rounded, color: AppColors.goldInk),
          title: Text(AppDate.monthYear(s.period), style: AppStyles.bold14Black),
          subtitle: Text(s.statusLabel ?? '', style: AppStyles.regular12Grey),
          trailing: Text(AppMoney.amount(s.takeHome), style: AppStyles.bold16Gold),
          children: [
            line('basic_salary', s.amount),
            line('allowances', s.allowances),
            line('overtime', s.overtimeAmount),
            line('bonus', s.bonus),
            line('deductions', s.deductions, minus: true),
            Divider(color: AppColors.borderColor),
            Row(children: [
              Text('net_salary'.tr(), style: AppStyles.bold14Black),
              const Spacer(),
              Text(AppMoney.amount(s.takeHome), style: AppStyles.bold16Gold),
            ]),
            const SizedBox(height: 6),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => openPayslip(context, s.id),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: Text('download_payslip'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
