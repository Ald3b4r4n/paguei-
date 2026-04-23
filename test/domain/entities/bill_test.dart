import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/bill_status.dart';
import 'package:paguei/domain/value_objects/money.dart';

Bill _build({
  String id = 'bill-1',
  String title = 'Energia Elétrica',
  Money? amount,
  DateTime? dueDate,
  BillStatus status = BillStatus.pending,
}) {
  final due = dueDate ?? DateTime.utc(2026, 5, 10);
  return Bill(
    id: id,
    title: title,
    amount: amount ?? Money.fromDouble(120.0),
    dueDate: due,
    status: status,
    isRecurring: false,
    reminderDaysBefore: 3,
    createdAt: DateTime.utc(2026, 4, 1),
    updatedAt: DateTime.utc(2026, 4, 1),
  );
}

void main() {
  group('Bill.create — validações', () {
    test('cria boleto válido com campos obrigatórios', () {
      final bill = Bill.create(
        id: 'b-1',
        title: 'Energia',
        amount: Money.fromDouble(150.0),
        dueDate: DateTime.utc(2026, 5, 1),
      );
      expect(bill.title, equals('Energia'));
      expect(bill.amount, equals(Money.fromDouble(150.0)));
      expect(bill.status, equals(BillStatus.pending));
    });

    test('lança ValidationException para título vazio', () {
      expect(
        () => Bill.create(
          id: 'b-1',
          title: '   ',
          amount: Money.fromDouble(100.0),
          dueDate: DateTime.utc(2026, 5, 1),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('lança ValidationException para título com mais de 150 caracteres',
        () {
      expect(
        () => Bill.create(
          id: 'b-1',
          title: 'A' * 151,
          amount: Money.fromDouble(100.0),
          dueDate: DateTime.utc(2026, 5, 1),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('lança ValidationException para amount zero', () {
      expect(
        () => Bill.create(
          id: 'b-1',
          title: 'Conta',
          amount: Money.zero,
          dueDate: DateTime.utc(2026, 5, 1),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('lança ValidationException para amount negativo', () {
      expect(
        () => Bill.create(
          id: 'b-1',
          title: 'Conta',
          amount: Money.fromDouble(-10.0),
          dueDate: DateTime.utc(2026, 5, 1),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('trim é aplicado no título', () {
      final bill = Bill.create(
        id: 'b-1',
        title: '  Energia  ',
        amount: Money.fromDouble(100.0),
        dueDate: DateTime.utc(2026, 5, 1),
      );
      expect(bill.title, equals('Energia'));
    });
  });

  group('Bill — effectiveStatus', () {
    test('status pending com dueDate futuro retorna pending', () {
      final bill = _build(
        status: BillStatus.pending,
        dueDate: DateTime.now().toUtc().add(const Duration(days: 5)),
      );
      expect(bill.effectiveStatus, equals(BillStatus.pending));
    });

    test('status pending com dueDate passado retorna overdue', () {
      final bill = _build(
        status: BillStatus.pending,
        dueDate: DateTime.utc(2020, 1, 1),
      );
      expect(bill.effectiveStatus, equals(BillStatus.overdue));
    });

    test('status paid com dueDate passado permanece paid', () {
      final bill = _build(
        status: BillStatus.paid,
        dueDate: DateTime.utc(2020, 1, 1),
      );
      expect(bill.effectiveStatus, equals(BillStatus.paid));
    });

    test('status cancelled com dueDate passado permanece cancelled', () {
      final bill = _build(
        status: BillStatus.cancelled,
        dueDate: DateTime.utc(2020, 1, 1),
      );
      expect(bill.effectiveStatus, equals(BillStatus.cancelled));
    });
  });

  group('Bill — helpers booleanos', () {
    test('isPaid retorna true quando status paid', () {
      expect(_build(status: BillStatus.paid).isPaid, isTrue);
    });

    test('isCancelled retorna true quando status cancelled', () {
      expect(_build(status: BillStatus.cancelled).isCancelled, isTrue);
    });

    test('isOverdue retorna true para boleto vencido', () {
      final bill = _build(
        status: BillStatus.pending,
        dueDate: DateTime.utc(2020, 1, 1),
      );
      expect(bill.isOverdue, isTrue);
      expect(bill.isPending, isFalse);
    });
  });

  group('Bill — copyWith', () {
    test('copyWith atualiza apenas os campos informados', () {
      final original = _build();
      final updated =
          original.copyWith(title: 'Água', amount: Money.fromDouble(50.0));

      expect(updated.id, equals(original.id));
      expect(updated.title, equals('Água'));
      expect(updated.amount, equals(Money.fromDouble(50.0)));
      expect(updated.dueDate, equals(original.dueDate));
    });
  });

  group('Bill — igualdade', () {
    test('dois Bills com mesmo id são iguais', () {
      expect(_build(id: 'b-1'), equals(_build(id: 'b-1')));
    });

    test('dois Bills com ids diferentes não são iguais', () {
      expect(_build(id: 'b-1'), isNot(equals(_build(id: 'b-2'))));
    });
  });

  group('BillStatus — labels e fromString', () {
    test('todos os status têm labels pt-BR', () {
      expect(BillStatus.pending.label, equals('Pendente'));
      expect(BillStatus.paid.label, equals('Pago'));
      expect(BillStatus.overdue.label, equals('Vencido'));
      expect(BillStatus.cancelled.label, equals('Cancelado'));
    });

    test('fromString funciona para todos os valores', () {
      for (final s in BillStatus.values) {
        expect(BillStatus.fromString(s.name), equals(s));
      }
    });

    test('fromString lança ArgumentError para valor desconhecido', () {
      expect(() => BillStatus.fromString('unknown'), throwsArgumentError);
    });
  });
}
