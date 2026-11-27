
import 'dart:convert';
import 'package:http/http.dart' as http;

class Holiday {
  final String date;
  final String name;

  Holiday({
    required this.date,
    required this.name,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      date: json['locdate'].toString(),
      name: json['dateName'] ?? '공휴일',
    );
  }

  DateTime get dateTime {
    final value = date;
    return DateTime(
      int.parse(value.substring(0, 4)),
      int.parse(value.substring(4, 6)),
      int.parse(value.substring(6, 8)),
    );
  }
}

class HolidayService {
  static const String baseUrl =
      'https://apis.data.go.kr/B090041/openapi/service/SpcdeInfoService/getRestDeInfo';

  // 공공데이터포털에서 발급받은 Decoding 인증키
  static const String serviceKey = 'b2d8f3d6a6dd0e285169d5ad17955894fbbc64c9aabbcfb3f97529b7525159b2';

  Future<List<Holiday>> fetchHolidays(
    int year,
    int month,
  ) async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        'ServiceKey': serviceKey,
        'solYear': year.toString(),
        'solMonth': month.toString().padLeft(2, '0'),
        '_type': 'json',
        'numOfRows': '100',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('API 요청 실패: ${response.statusCode}');
    }

    final jsonData = jsonDecode(response.body);

    final items = jsonData['response']?['body']?['items']?['item'];

    if (items == null) {
      return [];
    }

    final List<dynamic> itemList =
        items is List ? items : [items];

    return itemList
        .map((item) => Holiday.fromJson(item))
        .toList();
  }
}
