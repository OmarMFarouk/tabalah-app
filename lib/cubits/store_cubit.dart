import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/models/json_utils.dart';
import 'package:tabala/models/store_model.dart';

import 'async_state.dart';

class StoreData {
  final List<ProductModel> products;
  final List<String> categories;
  final int page;
  final int lastPage;

  const StoreData({
    this.products = const [],
    this.categories = const [],
    this.page = 1,
    this.lastPage = 1,
  });

  bool get hasMore => page < lastPage;
}

/// The shelf, a page at a time, plus the cart.
///
/// The cart lives here rather than on the server: nothing is reserved until
/// the order is placed, and the order is placed in one call.
class StoreCubit extends Cubit<AsyncState<StoreData>> {
  StoreCubit() : super(const AsyncState.idle());

  String? category;
  final Map<int, int> cart = {};
  final Map<int, ProductModel> _known = {};
  bool loadingMore = false;

  Future<void> load({bool refresh = false}) async {
    emit(refresh ? state.toRefreshing() : const AsyncState.loading());
    try {
      emit(AsyncState.ready(await _page(1, const [])));
    } on ApiException catch (e) {
      emit(AsyncState.failed(e.message, previous: state.data));
    }
  }

  Future<void> loadMore() async {
    final data = state.data;
    if (data == null || !data.hasMore || loadingMore) return;
    loadingMore = true;
    try {
      emit(AsyncState.ready(await _page(data.page + 1, data.products)));
    } on ApiException catch (_) {
      // The rows already on screen stay; scrolling again retries.
    } finally {
      loadingMore = false;
    }
  }

  Future<StoreData> _page(int page, List<ProductModel> before) async {
    final r = await ApiClient.instance.get(ApiEndpoints.storeProducts, query: {
      'page': page,
      'per_page': 20,
      if (category != null) 'category': category,
    });
    final items = J.list(r['products'], ProductModel.fromJson);
    for (final p in items) {
      _known[p.id] = p;
    }
    final meta = r['meta'] is Map ? Map<String, dynamic>.from(r['meta']) : const <String, dynamic>{};
    return StoreData(
      products: [...before, ...items],
      categories: (r['categories'] as List? ?? []).map((e) => '$e').toList(),
      page: J.asInt(meta['current_page'], fallback: page),
      lastPage: J.asInt(meta['last_page'], fallback: page),
    );
  }

  void setCategory(String? c) {
    category = c;
    load();
  }

  // ── Cart ────────────────────────────────────
  int qty(int productId) => cart[productId] ?? 0;
  int get cartCount => cart.values.fold(0, (a, b) => a + b);
  double get cartTotal =>
      cart.entries.fold(0, (sum, e) => sum + (_known[e.key]?.price ?? 0) * e.value);
  List<(ProductModel, int)> get cartLines => [
        for (final e in cart.entries)
          if (_known[e.key] != null) (_known[e.key]!, e.value),
      ];

  void add(ProductModel p) {
    if (qty(p.id) >= p.stock) return;
    _known[p.id] = p; // the total needs its price, wherever it was added from
    cart[p.id] = qty(p.id) + 1;
    _refresh();
  }

  void remove(ProductModel p) {
    final q = qty(p.id);
    if (q <= 1) {
      cart.remove(p.id);
    } else {
      cart[p.id] = q - 1;
    }
    _refresh();
  }

  /// A fresh StoreData so the state compares unequal and the cart badge
  /// redraws - AsyncState is Equatable, and the same instance is "no change".
  void _refresh() {
    final d = state.data;
    if (d == null) return;
    emit(AsyncState.ready(StoreData(
      products: d.products,
      categories: d.categories,
      page: d.page,
      lastPage: d.lastPage,
    )));
  }

  /// Places the order. Returns the server's message on success, throws
  /// [ApiException] with its reason otherwise.
  Future<String> placeOrder({String? notes}) async {
    final r = await ApiClient.instance.post(ApiEndpoints.storeOrders, data: {
      'items': cart.entries.map((e) => {'product_id': e.key, 'quantity': e.value}).toList(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });
    cart.clear();
    await load(refresh: true);
    return J.asStringOrNull(r['message']) ?? '';
  }
}

/// The member's own orders.
class OrdersCubit extends Cubit<AsyncState<List<OrderModel>>> {
  OrdersCubit() : super(const AsyncState.idle());

  Future<void> load({bool refresh = false}) async {
    emit(refresh ? state.toRefreshing() : const AsyncState.loading());
    try {
      final r = await ApiClient.instance.get(ApiEndpoints.storeOrders, query: {'per_page': 50});
      emit(AsyncState.ready(J.list(r['orders'], OrderModel.fromJson)));
    } on ApiException catch (e) {
      emit(AsyncState.failed(e.message, previous: state.data));
    }
  }

  Future<String?> cancel(int id) async {
    try {
      await ApiClient.instance.post(ApiEndpoints.storeOrderCancel(id));
      await load(refresh: true);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}
