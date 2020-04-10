import 'dart:io';
import 'package:http/http.dart' as http;

Future<String> fetchHttpFile(url) async {
  http.Response response = await http.get(url);
  if (response.statusCode == 200) {
    return response.body;
  }
  throw HttpException('Failed to fetch ${url}: ${response.statusCode}');
}
