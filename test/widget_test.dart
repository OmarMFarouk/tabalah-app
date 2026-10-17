import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tabala/cubits/async_state.dart';
import 'package:tabala/cubits/store_cubit.dart';
import 'package:tabala/models/employee_attendance_model.dart';
import 'package:tabala/models/salary_model.dart';
import 'package:tabala/models/store_model.dart';

/// Unit tests for the mobile app's models, store cart and translations.
void main() {
  // ── Attendance ────────────────────────────────────────────────────────

  group('Employee attendance', () {
    test('a finished shift reports its hours', () {
      final r = EmployeeAttendanceRow.fromJson({
        'id': 1,
        'date': '2026-10-17',
        'checked_in_at': '2026-10-17T05:00:00Z',
        'checked_out_at': '2026-10-17T13:30:00Z',
        'distance_meters': 40,
      });
      expect(r.checkedOut, isTrue);
      expect(r.hours, 8.5);
      expect(r.isManual, isFalse); // gps unless told otherwise
    });

    test('an open shift has no hours yet', () {
      final r = EmployeeAttendanceRow.fromJson({
        'id': 1,
        'date': '2026-10-17',
        'checked_in_at': '2026-10-17T05:00:00Z',
        'method': 'manual',
      });
      expect(r.checkedOut, isFalse);
      expect(r.hours, isNull);
      expect(r.isManual, isTrue);
    });

    test('today drives the three states of the clock-in card', () {
      Map<String, dynamic> today(Map<String, dynamic>? a) => {'attendance': a};
      final hist = <String, dynamic>{'attendances': [], 'days_this_month': 0};

      final none = EmployeeAttendanceData.fromJson(today(null), hist);
      expect((none.checkedInToday, none.checkedOutToday), (false, false));

      final on = EmployeeAttendanceData.fromJson(
          today({'id': 1, 'date': 'd', 'checked_in_at': '2026-10-17T05:00:00Z'}), hist);
      expect((on.checkedInToday, on.checkedOutToday), (true, false));

      final done = EmployeeAttendanceData.fromJson(
          today({'id': 1, 'date': 'd', 'checked_in_at': '2026-10-17T05:00:00Z', 'checked_out_at': '2026-10-17T13:00:00Z'}),
          hist);
      expect((done.checkedInToday, done.checkedOutToday), (true, true));
    });
  });

  // ── Payslips ──────────────────────────────────────────────────────────

  group('Payslips', () {
    test('take-home is the net from the payroll run', () {
      final s = SalaryModel.fromJson({
        'id': 1, 'user_id': 2, 'amount': '6000.00', 'period': '2026-10',
        'allowances': 2000, 'deductions': 1264.58, 'net': '6885.42', 'status': 'paid',
      });
      expect(s.takeHome, closeTo(6885.42, .001));
      expect(s.isPaid, isTrue);
    });

    test('a row recorded before payroll existed falls back to its amount', () {
      final s = SalaryModel.fromJson({'id': 1, 'user_id': 2, 'amount': 4000, 'period': '2026-08'});
      expect(s.takeHome, 4000);
      expect(s.isPaid, isTrue);
    });
  });

  // ── Store ─────────────────────────────────────────────────────────────

  group('Store', () {
    ProductModel product(int id, double price, int stock) =>
        ProductModel(id: id, name: 'منتج $id', nameEn: 'Item $id', price: price, stock: stock);

    test('the cart never exceeds stock and totals by price', () {
      final c = StoreCubit();
      final shirt = product(1, 25, 2);
      final water = product(2, 2.5, 10);

      c.add(shirt);
      c.add(shirt);
      c.add(shirt); // only 2 in stock
      c.add(water);
      expect(c.qty(1), 2);
      expect(c.cartCount, 3);
      expect(c.cartTotal, 52.5);

      c.remove(shirt);
      c.remove(water); // last one removes the line
      expect(c.cart.containsKey(2), isFalse);
      expect(c.cartTotal, 25);
      c.close();
    });

    test('changing the cart produces a new state so the badge redraws', () async {
      final c = StoreCubit()..emit(const AsyncState.ready(StoreData()));
      final seen = <AsyncState<StoreData>>[];
      final sub = c.stream.listen(seen.add);
      c.add(product(1, 10, 5));
      c.add(product(1, 10, 5));
      await Future<void>.delayed(Duration.zero);
      expect(seen.length, 2);
      await sub.cancel();
      await c.close();
    });

    test('out-of-stock products cannot be added', () {
      final c = StoreCubit()..add(product(1, 10, 0));
      expect(c.cartCount, 0);
      c.close();
    });

    test('product names follow the language with an Arabic fallback', () {
      expect(product(1, 1, 1).localizedName('en'), 'Item 1');
      expect(product(1, 1, 1).localizedName('ar'), 'منتج 1');
      expect(const ProductModel(id: 1, name: 'قميص', price: 1, stock: 1).localizedName('en'), 'قميص');
    });

    test('an order parses its lines, invoice and pending state', () {
      final o = OrderModel.fromJson({
        'id': 4, 'number': 'ORD-2026-00004', 'status': 'pending', 'total': '57.50',
        'invoice_id': null,
        'items': [{'name': 'قميص', 'quantity': 2, 'unit_price': 25, 'total': 50}],
      });
      expect(o.isPending, isTrue);
      expect(o.total, 57.5);
      expect(o.invoiceId, isNull);
      expect(o.items.single.quantity, 2);
    });

    test('blank contact fields are treated as absent', () {
      final c = ContactModel.fromJson({'unified_number': '  ', 'phone': '0555000111', 'whatsapp_url': ''});
      expect(c.unifiedNumber, isNull);
      expect(c.whatsappUrl, isNull);
      expect(c.phone, '0555000111');
    });
  });

  // ── Translations ──────────────────────────────────────────────────────

  group('Translations', () {
    Map<String, dynamic> load(String lang) =>
        jsonDecode(File('assets/translation/$lang.json').readAsStringSync()) as Map<String, dynamic>;

    test('Arabic and English carry the same keys', () {
      final ar = load('ar').keys.toSet();
      final en = load('en').keys.toSet();
      expect(ar.difference(en), isEmpty, reason: 'missing in en');
      expect(en.difference(ar), isEmpty, reason: 'missing in ar');
    });

    test('placeholders match between the languages', () {
      final ar = load('ar');
      final en = load('en');
      final mismatched = [
        for (final k in ar.keys)
          if ('{}'.allMatches('${ar[k]}').length != '{}'.allMatches('${en[k]}').length) k,
      ];
      expect(mismatched, isEmpty);
    });

    test('every literal key used with .tr() exists', () {
      final keys = load('ar').keys.toSet();
      final used = <String>{};
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        for (final m in RegExp(r"'([a-z0-9_]+)'\.tr\(").allMatches(f.readAsStringSync())) {
          used.add(m.group(1)!);
        }
      }
      expect(used.difference(keys), isEmpty);
    });
  });
}
