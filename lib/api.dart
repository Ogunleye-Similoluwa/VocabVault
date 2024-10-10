import 'dart:convert';
import 'dart:math';

import 'package:advanced_dictionary/response_model.dart';
import 'package:http/http.dart' as http;

class API {
  static const String baseUrl =
      "https://api.dictionaryapi.dev/api/v2/entries/en/";

  static Future<ResponseModel> fetchMeaning(String word) async {
    print(word);
    final response = await http.get(Uri.parse("$baseUrl$word"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return ResponseModel.fromJson(data[0]);
    } else {
      throw Exception("failed to load meaning");
    }
  }
  static Future<String> fetchRandomWord({int? count})async{

    final letters = 'abcdefghijklmnopqrstuvwxyz';
    final randomLetter = letters[Random().nextInt(letters.length)];
    final response = await http.get(
      Uri.parse('https://api.datamuse.com/words?sp=$randomLetter*&max=${count??1}'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> words = json.decode(response.body);
        final randomIndex = Random().nextInt(words.length);
          return  words[randomIndex]['word'];
    } else {
    throw Exception("failed to load meaning");
  }
  }


}
