import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/cubits/async_state.dart';
import 'package:tabala/cubits/leaves_cubit.dart';
import 'package:tabala/models/leave_model.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';

/// Leave, from the phone: what is left of the year's allowance, every
/// request already filed, and the form to raise another.
///
/// Used by trainers and by employees - the endpoint is the signed-in
/// account's own, so the same screen serves both without a role check.
class LeavesView extends StatefulWidget {
  /// True when hosted inside a bottom-nav shell: no app bar, and room left
  /// under the list for the floating bar.
  final bool asTab;

  const LeavesView({super.key, this.asTab = false});

  @override
  State<LeavesView> createState() => _LeavesViewState();
}

class _LeavesViewState extends State<LeavesView> {
  late final LeavesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = LeavesCubit()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldcolor,
        appBar: widget.asTab ? null : AppBar(title: Text('leaves'.tr())),
        floatingActionButton: BlocBuilder<LeavesCubit, AsyncState<LeavesPage>>(
          bloc: _cubit,
          builder: (context, state) => state.data == null
              ? const SizedBox.shrink()
              : FloatingActionButton.extended(
                  onPressed: () => _openRequestSheet(state.data!),
                  backgroundColor: AppColors.goldInk,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: Text(
                    'request_leave'.tr(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
        ),
        body: SafeArea(
          top: widget.asTab,
          bottom: false,
          child: BlocBuilder<LeavesCubit, AsyncState<LeavesPage>>(
            builder: (context, state) {
              final page = state.data;

              if (page == null) {
                return AsyncStateView(
                  isLoading: state.isBusy || !state.hasError,
                  errorMessage: state.error,
                  onRetry: _cubit.load,
                  child: const SizedBox(),
                );
              }

              return RefreshIndicator(
                color: AppColors.goldInk,
                backgroundColor: AppColors.surfacecolor,
                onRefresh: () => _cubit.load(refresh: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  children: [
                    if (widget.asTab) ...[
                      Text('leaves'.tr(), style: AppStyles.bold24Black),
                      const SizedBox(height: 12),
                    ],
                    _balance(page.balance),
                    SectionHeader(
                      title: 'my_leave_requests'.tr(),
                      subtitle: 'leaves_desc'.tr(),
                    ),
                    if (page.items.isEmpty)
                      ClubCard(
                        child: EmptyState(
                          icon: Icons.beach_access_outlined,
                          title: 'no_leaves'.tr(),
                          message: 'no_leaves_desc'.tr(),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      )
                    else
                      ...page.items.map(
                        (l) => _LeaveCard(
                          leave: l,
                          onWithdraw: l.isPending ? () => _withdraw(l) : null,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _balance(LeaveBalance b) {
    return ClubGradientPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('annual_leave_balance'.tr(), style: AppStyles.bold11Gold),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'entitlement'.tr(),
                  value: '${b.entitlement}',
                  icon: Icons.event_available_rounded,
                  onDark: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'used'.tr(),
                  value: '${b.used}',
                  icon: Icons.event_busy_rounded,
                  accent: AppColors.goldInk,
                  onDark: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'remaining'.tr(),
                  value: '${b.remaining}',
                  icon: Icons.savings_rounded,
                  accent: b.remaining > 0
                      ? AppColors.greencolor
                      : AppColors.redcolor,
                  onDark: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _withdraw(LeaveRequest leave) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfacecolor,
        title: Text('withdraw_leave'.tr()),
        content: Text('withdraw_leave_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'withdraw'.tr(),
              style: TextStyle(color: AppColors.redcolor),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final error = await _cubit.withdraw(leave.id);
    if (!mounted || error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  void _openRequestSheet(LeavesPage page) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RequestSheet(page: page, cubit: _cubit),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final LeaveRequest leave;
  final VoidCallback? onWithdraw;

  const _LeaveCard({required this.leave, this.onWithdraw});

  (String, Color, IconData) get _status => switch (leave.status) {
        'approved' => ('approved'.tr(), AppColors.greencolor, Icons.check_circle_rounded),
        'rejected' => ('rejected'.tr(), AppColors.redcolor, Icons.cancel_rounded),
        _ => ('pending_decision'.tr(), AppColors.goldInk, Icons.schedule_rounded),
      };

  @override
  Widget build(BuildContext context) {
    final (label, tone, icon) = _status;

    return ClubCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  leave.typeLabel,
                  style: AppStyles.bold14Black,
                ),
              ),
              StatusChip(label: label, color: tone, icon: icon, dense: true),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.date_range_rounded, size: 15, color: AppColors.greycolor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${leave.startDate ?? ''}  ←  ${leave.endDate ?? ''}',
                  style: AppStyles.regular12Grey,
                ),
              ),
              Text(
                'days_count'.tr(args: ['${leave.days}']),
                style: AppStyles.bold12Gold,
              ),
            ],
          ),
          if ((leave.reason ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(leave.reason!, style: AppStyles.regular12Grey),
          ],
          if ((leave.reviewNote ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tone.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tone.withValues(alpha: .30)),
              ),
              child: Text(leave.reviewNote!, style: AppStyles.regular12Grey),
            ),
          ],
          if (onWithdraw != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: onWithdraw,
                icon: Icon(Icons.undo_rounded, size: 16, color: AppColors.redcolor),
                label: Text(
                  'withdraw'.tr(),
                  style: TextStyle(color: AppColors.redcolor, fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The request form. A sheet rather than a page: four fields, and the
/// balance it spends is on the screen behind it.
class _RequestSheet extends StatefulWidget {
  final LeavesPage page;
  final LeavesCubit cubit;

  const _RequestSheet({required this.page, required this.cubit});

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  late String _type = widget.page.types.keys.isEmpty
      ? 'annual'
      : widget.page.types.keys.first;
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now();
  final _reason = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  int get _days => _end.difference(_start).inDays + 1;

  Future<void> _pick({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null) return;

    setState(() {
      if (start) {
        _start = picked;
        // Keep the pair valid without making the person go and fix it.
        if (_end.isBefore(_start)) _end = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await widget.cubit.request(
      type: _type,
      start: _start,
      end: _end,
      reason: _reason.text,
    );

    if (!mounted) return;

    if (error == null) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _saving = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.page.balance;
    final overBalance = _type == 'annual' && _days > balance.remaining;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfacecolor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.borderColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text('request_leave'.tr(), style: AppStyles.bold18Black),
              const SizedBox(height: 16),

              Text('leave_type'.tr(), style: AppStyles.bold12Gold),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in widget.page.types.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: _type == entry.key,
                      onSelected: (_) => setState(() => _type = entry.key),
                      selectedColor: AppColors.goldInk.withValues(alpha: .22),
                    ),
                ],
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: 'from_date'.tr(),
                      date: _start,
                      onTap: () => _pick(start: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateButton(
                      label: 'to_date'.tr(),
                      date: _end,
                      onTap: () => _pick(start: false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Text(
                'days_count'.tr(args: ['$_days']),
                style: overBalance ? AppStyles.bold12Gold : AppStyles.regular12Grey,
              ),
              if (overBalance) ...[
                const SizedBox(height: 4),
                Text(
                  'leave_over_balance'.tr(args: ['${balance.remaining}']),
                  style: TextStyle(color: AppColors.redcolor, fontSize: 12),
                ),
              ],

              const SizedBox(height: 14),
              TextField(
                controller: _reason,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'leave_reason'.tr(),
                  border: const OutlineInputBorder(),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: AppColors.redcolor, fontSize: 12),
                ),
              ],

              const SizedBox(height: 18),
              FilledButton(
                onPressed: _saving || overBalance ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.goldInk,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'send_request'.tr(),
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateButton({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardcolor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppStyles.bold11Gold),
            const SizedBox(height: 4),
            Text(
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              style: AppStyles.bold14Black,
            ),
          ],
        ),
      ),
    );
  }
}
