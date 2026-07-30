import 'package:flutter_test/flutter_test.dart';
import 'package:vcom_app/core/common/user_role.dart';

void main() {
  group('UserRole.normalize', () {
    test('reconoce variantes de modelo', () {
      expect(UserRole.normalize('Modelo'), UserRole.modelo);
      expect(UserRole.normalize('modelo'), UserRole.modelo);
      expect(UserRole.normalize('  MODAL '), UserRole.modelo);
      expect(UserRole.normalize('Model'), UserRole.modelo);
      expect(UserRole.normalize('Modelos'), UserRole.modelo);
    });

    test('reconoce variantes de monitor', () {
      expect(UserRole.normalize('Monitor'), UserRole.monitor);
      expect(UserRole.normalize('MONITOR '), UserRole.monitor);
      expect(UserRole.normalize('Monitor de modelos'), UserRole.monitor);
    });

    test('ignora acentos', () {
      expect(UserRole.normalize('Módelo'), UserRole.modelo);
      expect(UserRole.normalize('Mónitor'), UserRole.monitor);
    });

    test('devuelve el valor crudo en mayusculas si no mapea', () {
      expect(UserRole.normalize('employee'), 'EMPLOYEE');
      expect(UserRole.normalize(null), '');
      expect(UserRole.normalize('   '), '');
    });
  });

  group('UserRole.usesModeloExperience', () {
    test('siempre true: app exclusiva de modelos y monitores', () {
      expect(UserRole.usesModeloExperience('Modelo'), isTrue);
      expect(UserRole.usesModeloExperience('Monitor'), isTrue);
      expect(UserRole.usesModeloExperience('employee'), isTrue);
      expect(UserRole.usesModeloExperience('Admin'), isTrue);
      expect(UserRole.usesModeloExperience(null), isTrue);
    });
  });
}
