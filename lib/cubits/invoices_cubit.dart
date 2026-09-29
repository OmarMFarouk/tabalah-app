import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/models/invoice_model.dart';
import 'package:tabala/models/json_utils.dart';

import 'async_state.dart';

/// The member's own invoices.
///
/// The list is data; the printable invoice is a web page behind a link the
/// server signs for an hour, which is why opening one is a second call.
class InvoicesCubit extends Cubit<AsyncState<List<InvoiceModel>>> {
  InvoicesCubit() : super(const AsyncState.idle());

  Future<void> load({bool refresh = false}) async {
    emit(refresh ? state.toRefreshing() : const AsyncState.loading());
    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.myInvoices,
        query: {'per_page': 50},
      );
      emit(AsyncState.ready(J.list(response['invoices'], InvoiceModel.fromJson)));
    } on ApiException catch (e) {
      emit(AsyncState.failed(e.message, previous: state.data));
    }
  }

  /// A one-hour signed URL to the printable invoice, or null if the server
  /// refused - the caller hands it to the browser.
  Future<String?> printableLink(int id) async {
    try {
      final response = await ApiClient.instance.get(ApiEndpoints.invoiceLink(id));
      return J.asStringOrNull(response['url']);
    } on ApiException {
      return null;
    }
  }
}
