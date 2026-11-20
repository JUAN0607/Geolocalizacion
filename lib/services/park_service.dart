import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ParkService {
  static const List<String> _servers = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
    'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
  ];

  static Future<List<Map<String, dynamic>>> fetchNearbyParks(
    double lat,
    double lon,
  ) async {
    final query =
        '[out:json];node["leisure"="park"](around:3000,$lat,$lon);out 20;';

    for (final server in _servers) {
      final url = Uri.parse('$server?data=${Uri.encodeComponent(query)}');
      try {
        final response = await http
            .get(url, headers: {'User-Agent': 'taller_movilidad/1.0 (Flutter)'})
            .timeout(const Duration(seconds: 12));
        if (response.statusCode == 200) {
          return parseParks(utf8.decode(response.bodyBytes));
        }
        debugPrint('Overpass ($server) respondió ${response.statusCode}');
      } catch (e) {
        debugPrint('Error al consultar API de parques ($server): $e');
      }
    }
    return _fetchFromNominatim(lat, lon);
  }

  static Future<List<Map<String, dynamic>>> _fetchFromNominatim(
    double lat,
    double lon,
  ) async {
    const d = 0.027;
    final url = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': 'park',
      'format': 'jsonv2',
      'limit': '20',
      'bounded': '1',
      'viewbox': '${lon - d},${lat + d},${lon + d},${lat - d}',
    });
    try {
      final response = await http
          .get(url, headers: {'User-Agent': 'taller_movilidad/1.0 (Flutter)'})
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        return parseNominatim(utf8.decode(response.bodyBytes));
      }
      debugPrint('Nominatim respondió ${response.statusCode}');
    } catch (e) {
      debugPrint('Error al consultar Nominatim: $e');
    }
    return [];
  }

  static List<Map<String, dynamic>> parseNominatim(String body) {
    final List results = json.decode(body);
    return results
        .where((e) => e['category'] == 'leisure' && e['type'] == 'park')
        .map<Map<String, dynamic>>((e) {
          final String name = (e['name'] ?? '').toString();
          return {
            'name': name.isEmpty ? 'Parque Público' : name,
            'lat': double.parse(e['lat'].toString()),
            'lon': double.parse(e['lon'].toString()),
          };
        })
        .toList();
  }

  static List<Map<String, dynamic>> parseParks(String body) {
    final data = json.decode(body);
    final List elements = data['elements'] ?? [];
    return elements
        .where((e) => e['lat'] != null && e['lon'] != null)
        .map<Map<String, dynamic>>((e) {
          final tags = e['tags'] ?? {};
          return {
            'name': tags['name'] ?? 'Parque Público',
            'lat': (e['lat'] as num).toDouble(),
            'lon': (e['lon'] as num).toDouble(),
          };
        })
        .toList();
  }
}
