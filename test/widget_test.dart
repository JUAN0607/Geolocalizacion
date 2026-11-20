import 'package:flutter_test/flutter_test.dart';
import 'package:taller_movilidad/services/notification_service.dart';
import 'package:taller_movilidad/services/park_service.dart';
import 'package:taller_movilidad/widgets/step_counter_widget.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  group('ParkService.parseParks', () {
    test('lee nombre y coordenadas, y pone nombre por defecto', () {
      const body = '{"elements":['
          '{"type":"node","id":1,"lat":4.65,"lon":-74.09,"tags":{"name":"Parque El Virrey"}},'
          '{"type":"node","id":2,"lat":4.66,"lon":-74.1}'
          ']}';
      final parks = ParkService.parseParks(body);
      expect(parks.length, 2);
      expect(parks[0]['name'], 'Parque El Virrey');
      expect(parks[0]['lat'], 4.65);
      expect(parks[1]['name'], 'Parque Público');
      expect(parks[1]['lon'], -74.1);
    });

    test('respuesta sin elementos devuelve lista vacía', () {
      expect(ParkService.parseParks('{"elements":[]}'), isEmpty);
    });
  });

  group('ParkService.parseNominatim', () {
    test('solo toma parques y convierte coordenadas de texto', () {
      const body = '['
          '{"name":"Parque El Paseo","lat":"4.68","lon":"-74.09","category":"leisure","type":"park"},'
          '{"name":"","lat":"4.67","lon":"-74.11","category":"leisure","type":"park"},'
          '{"name":"Calle 80","lat":"4.6","lon":"-74.0","category":"highway","type":"primary"}'
          ']';
      final parks = ParkService.parseNominatim(body);
      expect(parks.length, 2);
      expect(parks[0]['name'], 'Parque El Paseo');
      expect(parks[0]['lat'], 4.68);
      expect(parks[1]['name'], 'Parque Público');
    });
  });

  group('NotificationService.nextInstanceOf', () {
    setUpAll(tz.initializeTimeZones);

    test('hora futura de hoy queda para hoy (prueba de 1 minuto)', () {
      final bogota = tz.getLocation('America/Bogota');
      final now = tz.TZDateTime(bogota, 2026, 11, 19, 15, 30, 10);
      final next = NotificationService.nextInstanceOf(now, 15, 31);
      expect(next, tz.TZDateTime(bogota, 2026, 11, 19, 15, 31));
      expect(next.difference(now).inSeconds, 50);
    });

    test('hora ya pasada se programa para mañana', () {
      final bogota = tz.getLocation('America/Bogota');
      final now = tz.TZDateTime(bogota, 2026, 11, 19, 21, 0);
      final next = NotificationService.nextInstanceOf(now, 20, 0);
      expect(next, tz.TZDateTime(bogota, 2026, 11, 20, 20, 0));
    });
  });

  group('StepCounterWidget.isWalking', () {
    test('reposo no cuenta como caminata', () {
      expect(StepCounterWidget.isWalking(0.1, 0.2, 0.0), isFalse);
    });
    test('rotación fuerte cuenta como caminata', () {
      expect(StepCounterWidget.isWalking(1.0, 1.0, 0.5), isTrue);
    });
  });
}
