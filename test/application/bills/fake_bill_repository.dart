import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/bill_document_type.dart';
import 'package:paguei/domain/entities/bill_status.dart';
import 'package:paguei/domain/repositories/bill_repository.dart';
import 'package:paguei/domain/value_objects/barcode.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/domain/value_objects/pix_code.dart';

class FakeBillRepository implements BillRepository {
  final _store = <String, Bill>{};

  @override
  Future<Bill> create({
    required String id,
    required String title,
    required Money amount,
    required DateTime dueDate,
    String? accountId,
    String? categoryId,
    Barcode? barcode,
    PixCode? pixCode,
    String? beneficiary,
    String? issuer,
    BillDocumentType? documentType,
    bool isRecurring = false,
    String? recurrenceRule,
    int reminderDaysBefore = 3,
    String? notes,
    String? attachmentPath,
  }) async {
    final bill = Bill.create(
      id: id,
      title: title,
      amount: amount,
      dueDate: dueDate,
      accountId: accountId,
      categoryId: categoryId,
      barcode: barcode,
      pixCode: pixCode,
      beneficiary: beneficiary,
      issuer: issuer,
      documentType: documentType,
      isRecurring: isRecurring,
      recurrenceRule: recurrenceRule,
      reminderDaysBefore: reminderDaysBefore,
      notes: notes,
      attachmentPath: attachmentPath,
    );
    _store[bill.id] = bill;
    return bill;
  }

  @override
  Future<Bill> update(Bill bill) async {
    _store[bill.id] = bill;
    return bill;
  }

  @override
  Future<void> delete(String id) async => _store.remove(id);

  @override
  Future<Bill?> getById(String id) async => _store[id];

  @override
  Future<List<Bill>> getAll() async => _store.values.toList();

  @override
  Future<List<Bill>> getByStatus(BillStatus status) async =>
      _store.values.where((b) => b.status == status).toList();

  @override
  Future<List<Bill>> getPending() async => _store.values
      .where((b) =>
          b.status == BillStatus.pending || b.status == BillStatus.overdue)
      .toList();

  @override
  Future<List<Bill>> getDueSoon({int days = 7}) async {
    final cutoff = DateTime.now().toUtc().add(Duration(days: days));
    return _store.values
        .where(
            (b) => b.status == BillStatus.pending && b.dueDate.isBefore(cutoff))
        .toList();
  }

  @override
  Stream<List<Bill>> watchAll() => Stream.value(_store.values.toList());

  @override
  Stream<List<Bill>> watchPending() => Stream.value(
        _store.values.where((b) => b.status == BillStatus.pending).toList(),
      );

  @override
  Future<Bill> markAsPaid({
    required String id,
    Money? paidAmount,
    DateTime? paidAt,
  }) async {
    final bill = _store[id]!;
    final updated = bill.copyWith(
      status: BillStatus.paid,
      paidAt: paidAt ?? DateTime.now().toUtc(),
      paidAmount: paidAmount ?? bill.amount,
      updatedAt: DateTime.now().toUtc(),
    );
    _store[id] = updated;
    return updated;
  }

  @override
  Future<Bill> cancel(String id) async {
    final bill = _store[id]!;
    final updated = bill.copyWith(
      status: BillStatus.cancelled,
      updatedAt: DateTime.now().toUtc(),
    );
    _store[id] = updated;
    return updated;
  }
}
