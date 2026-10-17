import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/cubits/async_state.dart';
import 'package:tabala/cubits/invoices_cubit.dart';
import 'package:tabala/cubits/store_cubit.dart';
import 'package:tabala/models/store_model.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/src/utils/app_date.dart';
import 'package:tabala/src/utils/app_money.dart';
import 'package:url_launcher/url_launcher.dart';

/// The academy shop: browse, add to the cart, order, then pay and collect
/// at the front desk. Two tabs - the shelf, and the member's own orders.
class StoreView extends StatefulWidget {
  /// Opens on "my orders" when coming from a notification about one.
  final bool openOrders;

  const StoreView({super.key, this.openOrders = false});

  static Future<void> open(BuildContext context, {bool orders = false}) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => StoreView(openOrders: orders)));

  @override
  State<StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this, initialIndex: widget.openOrders ? 1 : 0);
  final _store = StoreCubit()..load();
  final _orders = OrdersCubit()..load();

  @override
  void dispose() {
    _tabs.dispose();
    _store.close();
    _orders.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _store),
        BlocProvider.value(value: _orders),
      ],
      child: Scaffold(
        backgroundColor: AppColors.scaffoldcolor,
        appBar: AppBar(
          title: Text('store'.tr()),
          bottom: TabBar(
            controller: _tabs,
            labelColor: AppColors.goldInk,
            indicatorColor: AppColors.goldInk,
            unselectedLabelColor: AppColors.greycolor,
            tabs: [
              Tab(icon: const Icon(Icons.storefront_rounded), text: 'shop'.tr()),
              Tab(icon: const Icon(Icons.receipt_long_rounded), text: 'my_orders'.tr()),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            _Shelf(onOrdered: () {
              _orders.load(refresh: true);
              _tabs.animateTo(1);
            }),
            const _Orders(),
          ],
        ),
      ),
    );
  }
}

// ── The shelf ────────────────────────────────

class _Shelf extends StatelessWidget {
  final VoidCallback onOrdered;
  const _Shelf({required this.onOrdered});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StoreCubit>();
    final lang = context.locale.languageCode;

    return BlocBuilder<StoreCubit, AsyncState<StoreData>>(
      builder: (context, state) {
        final data = state.data;
        if (data == null) {
          return AsyncStateView(
            isLoading: state.isBusy || !state.hasError,
            errorMessage: state.error,
            onRetry: cubit.load,
            child: const SizedBox(),
          );
        }

        return Stack(
          children: [
            RefreshIndicator(
              color: AppColors.goldInk,
              onRefresh: () => cubit.load(refresh: true),
              child: NotificationListener<ScrollNotification>(
                // Next page when the shelf nears its end.
                onNotification: (n) {
                  if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) cubit.loadMore();
                  return false;
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _hint()),
                    if (data.categories.isNotEmpty)
                      SliverToBoxAdapter(child: _categories(context, cubit, data.categories)),
                    if (data.products.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: ClubCard(
                            child: EmptyState(
                              icon: Icons.inventory_2_outlined,
                              title: 'store_empty'.tr(),
                              message: 'store_empty_desc'.tr(),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: .66,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _ProductCard(product: data.products[i], lang: lang),
                            childCount: data.products.length,
                          ),
                        ),
                      ),
                    if (data.hasMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 120),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (cubit.cartCount > 0)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16 + MediaQuery.paddingOf(context).bottom,
                child: _CartBar(onOrdered: onOrdered),
              ),
          ],
        );
      },
    );
  }

  Widget _hint() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Row(children: [
          Icon(Icons.info_outline_rounded, size: 16, color: AppColors.goldInk),
          const SizedBox(width: 8),
          Expanded(child: Text('store_pay_at_desk'.tr(), style: AppStyles.regular12Grey)),
        ]),
      );

  Widget _categories(BuildContext context, StoreCubit cubit, List<String> cats) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          for (final c in [null, ...cats])
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(c ?? 'all'.tr()),
                selected: cubit.category == c,
                selectedColor: AppColors.primary.withValues(alpha: .25),
                onSelected: (_) => cubit.setCategory(c),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final String lang;
  const _ProductCard({required this.product, required this.lang});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StoreCubit>();
    final q = cubit.qty(product.id);

    return ClubCard(
      padding: EdgeInsets.zero,
      onTap: () => _details(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: product.imageUrl == null
                  ? Container(
                      color: AppColors.primary.withValues(alpha: .1),
                      child: Icon(Icons.shopping_bag_rounded, size: 44, color: AppColors.goldInk),
                    )
                  : Image.network(product.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.broken_image_rounded, color: AppColors.greycolor)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.localizedName(lang), maxLines: 2, overflow: TextOverflow.ellipsis, style: AppStyles.bold14Black),
                const SizedBox(height: 4),
                Text(AppMoney.amount(product.price), style: AppStyles.bold14Gold),
                const SizedBox(height: 8),
                if (!product.inStock)
                  StatusChip(label: 'out_of_stock'.tr(), color: AppColors.redcolor, dense: true)
                else if (q == 0)
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: OutlinedButton.icon(
                      onPressed: () => cubit.add(product),
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                      label: Text('add_to_cart'.tr(), style: const TextStyle(fontSize: 12)),
                    ),
                  )
                else
                  _Stepper(
                    qty: q,
                    onMinus: () => cubit.remove(product),
                    onPlus: q >= product.stock ? null : () => cubit.add(product),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _details(BuildContext context) {
    final cubit = context.read<StoreCubit>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfacecolor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: BlocBuilder<StoreCubit, AsyncState<StoreData>>(
          builder: (ctx, _) => Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.paddingOf(ctx).bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(aspectRatio: 16 / 10, child: Image.network(product.imageUrl!, fit: BoxFit.cover)),
                  ),
                const SizedBox(height: 14),
                Text(product.localizedName(lang), style: AppStyles.bold18Black),
                const SizedBox(height: 4),
                Text(AppMoney.amount(product.price), style: AppStyles.bold16Gold),
                if ((product.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(product.description!, style: AppStyles.regular14Grey),
                ],
                const SizedBox(height: 6),
                Text('in_stock_n'.tr(args: ['${product.stock}']), style: AppStyles.regular12Grey),
                const SizedBox(height: 16),
                if (product.inStock)
                  cubit.qty(product.id) == 0
                      ? SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => cubit.add(product),
                            icon: const Icon(Icons.add_shopping_cart_rounded),
                            label: Text('add_to_cart'.tr()),
                          ),
                        )
                      : _Stepper(
                          qty: cubit.qty(product.id),
                          onMinus: () => cubit.remove(product),
                          onPlus: cubit.qty(product.id) >= product.stock ? null : () => cubit.add(product),
                        ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback? onPlus;
  const _Stepper({required this.qty, required this.onMinus, this.onPlus});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(visualDensity: VisualDensity.compact, onPressed: onMinus, icon: const Icon(Icons.remove_rounded, size: 18)),
          Text('$qty', style: AppStyles.bold14Black),
          IconButton(visualDensity: VisualDensity.compact, onPressed: onPlus, icon: const Icon(Icons.add_rounded, size: 18)),
        ],
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  final VoidCallback onOrdered;
  const _CartBar({required this.onOrdered});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StoreCubit>();
    return Material(
      color: AppColors.primarycolor,
      borderRadius: BorderRadius.circular(16),
      elevation: 6,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _checkout(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.clubGreenDeep,
              child: Text('${cubit.cartCount}', style: AppStyles.bold12White),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('review_order'.tr(), style: TextStyle(color: AppColors.clubGreenDeep, fontWeight: FontWeight.w800))),
            Text(AppMoney.amount(cubit.cartTotal), style: TextStyle(color: AppColors.clubGreenDeep, fontWeight: FontWeight.w900, fontSize: 16)),
          ]),
        ),
      ),
    );
  }

  void _checkout(BuildContext context) {
    final cubit = context.read<StoreCubit>();
    final notes = TextEditingController();
    final lang = context.locale.languageCode;
    var sending = false;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfacecolor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetCtx) => BlocProvider.value(
        value: cubit,
        child: StatefulBuilder(
          builder: (ctx, setLocal) => BlocBuilder<StoreCubit, AsyncState<StoreData>>(
            builder: (ctx, _) => Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom + MediaQuery.paddingOf(ctx).bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('your_order'.tr(), style: AppStyles.bold18Black),
                  const SizedBox(height: 12),
                  for (final (p, q) in cubit.cartLines)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Expanded(child: Text(p.localizedName(lang), style: AppStyles.medium14Black)),
                        SizedBox(
                          width: 120,
                          child: _Stepper(
                            qty: q,
                            onMinus: () => cubit.remove(p),
                            onPlus: q >= p.stock ? null : () => cubit.add(p),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(width: 72, child: Text(AppMoney.amount(p.price * q), textAlign: TextAlign.end, style: AppStyles.bold14Black)),
                      ]),
                    ),
                  Divider(color: AppColors.borderColor, height: 24),
                  Row(children: [
                    Text('total'.tr(), style: AppStyles.bold16Black),
                    const Spacer(),
                    Text(AppMoney.amount(cubit.cartTotal), style: AppStyles.bold18Gold),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notes,
                    decoration: InputDecoration(labelText: 'order_notes'.tr(), prefixIcon: const Icon(Icons.notes_rounded)),
                  ),
                  const SizedBox(height: 10),
                  Text('store_pay_at_desk'.tr(), style: AppStyles.regular12Grey),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: sending || cubit.cartCount == 0
                          ? null
                          : () async {
                              setLocal(() => sending = true);
                              try {
                                final msg = await cubit.placeOrder(notes: notes.text);
                                if (!sheetCtx.mounted) return;
                                Navigator.pop(sheetCtx);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.isEmpty ? 'order_placed'.tr() : msg)));
                                onOrdered();
                              } on ApiException catch (e) {
                                setLocal(() => sending = false);
                                if (!ctx.mounted) return;
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.message)));
                              }
                            },
                      icon: sending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check_circle_rounded),
                      label: Text('place_order'.tr()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── My orders ────────────────────────────────

class _Orders extends StatelessWidget {
  const _Orders();

  static Color _color(String s) => switch (s) {
        'paid' => AppColors.goldInk,
        'delivered' => AppColors.greencolor,
        'cancelled' => AppColors.redcolor,
        _ => AppColors.greycolor,
      };

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrdersCubit>();

    return BlocBuilder<OrdersCubit, AsyncState<List<OrderModel>>>(
      builder: (context, state) {
        final orders = state.data;
        if (orders == null) {
          return AsyncStateView(
            isLoading: state.isBusy || !state.hasError,
            errorMessage: state.error,
            onRetry: cubit.load,
            child: const SizedBox(),
          );
        }

        return RefreshIndicator(
          color: AppColors.goldInk,
          onRefresh: () => cubit.load(refresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 14, 16, 24 + MediaQuery.paddingOf(context).bottom),
            children: [
              if (orders.isEmpty)
                ClubCard(
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'no_orders'.tr(),
                    message: 'no_orders_desc'.tr(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                )
              else
                for (final o in orders)
                  ClubCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: EdgeInsets.zero,
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        title: Text(o.number, style: AppStyles.bold14Black),
                        subtitle: Text(
                          '${AppDate.friendlyDate(o.createdAt ?? '')} · ${AppMoney.amount(o.total)}',
                          style: AppStyles.regular12Grey,
                        ),
                        trailing: StatusChip(label: 'order_${o.status}'.tr(), color: _color(o.status), dense: true),
                        children: [
                          for (final i in o.items)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(children: [
                                Expanded(child: Text('${i.name} × ${i.quantity}', style: AppStyles.regular14Black)),
                                Text(AppMoney.amount(i.total), style: AppStyles.medium14Black),
                              ]),
                            ),
                          const SizedBox(height: 8),
                          if (o.isPending)
                            Text('store_pay_at_desk'.tr(), style: AppStyles.regular12Grey),
                          Row(children: [
                            if (o.invoiceId != null)
                              TextButton.icon(
                                onPressed: () => _openInvoice(context, o.invoiceId!),
                                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                                label: Text('view_invoice'.tr()),
                              ),
                            const Spacer(),
                            if (o.isPending)
                              TextButton.icon(
                                onPressed: () => _cancel(context, o),
                                icon: Icon(Icons.cancel_rounded, size: 18, color: AppColors.redcolor),
                                label: Text('cancel_order'.tr(), style: TextStyle(color: AppColors.redcolor)),
                              ),
                          ]),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openInvoice(BuildContext context, int id) async {
    final url = await InvoicesCubit().printableLink(id);
    if (url == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('something_went_wrong'.tr())));
      }
      return;
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _cancel(BuildContext context, OrderModel o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfacecolor,
        title: Text('cancel_order'.tr()),
        content: Text('cancel_order_confirm'.tr(args: [o.number])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('cancel_order'.tr(), style: TextStyle(color: AppColors.redcolor)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final error = await context.read<OrdersCubit>().cancel(o.id);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}
