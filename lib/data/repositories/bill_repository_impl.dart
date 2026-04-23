import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/data/database/daos/bills_dao.dart';
import 'package:paguei/data/models/bill_model.dart';
import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/bill_document_type.dart';
import 'package:paguei/domain/entities/bill_status.dart';
import 'package:paguei/domain/repositories/bill_repository.dart';
import 'package:paguei/domain/value_objects/barcode.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/domain/value_objects/pix_code.dart';

final class BillRepositoryImpl implements BillRepository {
  const BillRepositoryImpl(this._dao);

  final BillsDao _dao;

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
    await _dao.insertBill(bill.toCompanion());
    return bill;
  }

  @override
  Future<Bill> update(Bill bill) async {
    final existing = await _dao.getById(bill.id);
    if (existing == null) {
      throw NotFoundException(message: 'Boleto não encontrado: ${bill.id}');
    }
    await _dao.updateBill(bill.toCompanion());
    return bill;
  }

  @override
  Future<void> delete(String id) async {
    await _dao.deleteBill(id);
  }

  @override
  Future<Bill?> getById(String id) async {
    final row = await _dao.getById(id);
    return row?.toDomain();
  }

  @override
  Future<List<Bill>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<List<Bill>> getByStatus(BillStatus status) async {
    final rows = await _dao.getByStatus(status.name);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<List<Bill>> getPending() async {
    final rows = await _dao.getPending();
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<List<Bill>> getDueSoon({int days = 7}) async {
    final now = DateTime.now().toUtc();
    final cutoff = now.add(Duration(days: days));
    final rows = await _dao.getDueSoon(now, cutoff);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Stream<List<Bill>> watchAll() {
    return _dao
        .watchAll()
        .map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  @override
  Stream<List<Bill>> watchPending() {
    return _dao
        .watchPending()
        .map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  @override
  Future<Bill> markAsPaid({
    required String id,
    Money? paidAmount,
    DateTime? paidAt,
  }) async {
    final existing = await _dao.getById(id);
    if (existing == null) {
      throw NotFoundException(message: 'Boleto não encontrado: $id');
    }
    final bill = existing.toDomain();
    final effectivePaidAt = paidAt ?? DateTime.now().toUtc();
    final effectivePaidAmount = paidAmount ?? bill.amount;

    await _dao.markAsPaid(id, effectivePaidAmount.amount, effectivePaidAt);

    final updated = await _dao.getById(id);
    return updated!.toDomain();
  }

  @override
  Future<Bill> cancel(String id) async {
    final existing = await _dao.getById(id);
    if (existing == null) {
      throw NotFoundException(message: 'Boleto não encontrado: $id');
    }
    await _dao.updateStatus(id, BillStatus.cancelled.name);
    final updated = await _dao.getById(id);
    return updated!.toDomain();
  }
}
