import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/bill_document_type.dart';
import 'package:paguei/domain/repositories/bill_repository.dart';
import 'package:paguei/domain/value_objects/barcode.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/domain/value_objects/pix_code.dart';

final class CreateBillUseCase {
  const CreateBillUseCase(this._repository);

  final BillRepository _repository;

  Future<Bill> execute({
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
  }) {
    return _repository.create(
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
  }
}
