import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/bill_status.dart';
import 'package:paguei/domain/entities/bill_document_type.dart';
import 'package:paguei/domain/value_objects/barcode.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/domain/value_objects/pix_code.dart';

abstract interface class BillRepository {
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
    bool isRecurring,
    String? recurrenceRule,
    int reminderDaysBefore,
    String? notes,
    String? attachmentPath,
  });

  Future<Bill> update(Bill bill);

  Future<void> delete(String id);

  Future<Bill?> getById(String id);

  Future<List<Bill>> getAll();

  Future<List<Bill>> getByStatus(BillStatus status);

  /// Returns pending + overdue bills (bills not yet paid or cancelled).
  Future<List<Bill>> getPending();

  /// Returns bills due within the next [days] days.
  Future<List<Bill>> getDueSoon({int days = 7});

  Stream<List<Bill>> watchAll();

  Stream<List<Bill>> watchPending();

  Future<Bill> markAsPaid({
    required String id,
    Money? paidAmount,
    DateTime? paidAt,
  });

  Future<Bill> cancel(String id);
}
