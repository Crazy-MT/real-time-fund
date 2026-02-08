import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fast_gbk/fast_gbk.dart';
import 'fund_fetcher_interface.dart';

class FundFetcherImpl implements FundFetcher {
  @override
  Future<Map<String, dynamic>?> fetchEastMoney(String code) async {
    final gzUrl = Uri.parse(
        'https://fundgz.1234567.com.cn/js/$code.js?rt=${DateTime.now().millisecondsSinceEpoch}');
    
    try {
      final gzResponse = await http.get(gzUrl);

      if (gzResponse.statusCode == 200) {
        String body;
        try {
          body = utf8.decode(gzResponse.bodyBytes);
        } catch (e) {
          body = String.fromCharCodes(gzResponse.bodyBytes);
        }

        if (body.contains('jsonpgz')) {
          final startIndex = body.indexOf('({');
          if (startIndex != -1) {
            final jsonStr =
                body.substring(startIndex + 1, body.lastIndexOf(')'));
            return jsonDecode(jsonStr);
          }
        }
      }
    } catch (e) {
      print('EastMoney IO fetch error for $code: $e');
    }
    return null;
  }

  @override
  Future<String?> fetchTencent(String code) async {
    final tUrl = Uri.parse('https://qt.gtimg.cn/q=jj$code');
    try {
      final tResponse = await http.get(tUrl);

      if (tResponse.statusCode == 200) {
        String body;
        try {
          body = gbk.decode(tResponse.bodyBytes);
        } catch (e) {
          body = utf8.decode(tResponse.bodyBytes, allowMalformed: true);
        }

        if (body.contains('=')) {
          // v_jjCODE="...~...~...";
          return body.split('="')[1].replaceAll('";', '');
        }
      }
    } catch (e) {
      print('Tencent IO fetch error for $code: $e');
    }
    return null;
  }

  @override
  Future<String?> fetchHoldings(String code) async {
    final url = Uri.parse(
        'https://fundf10.eastmoney.com/FundArchivesDatas.aspx?type=jjcc&code=$code&topline=10&year=&month=&_=${DateTime.now().millisecondsSinceEpoch}');
    
    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      String body;
      try {
        body = utf8.decode(response.bodyBytes);
      } catch (e) {
        body = String.fromCharCodes(response.bodyBytes);
      }
      
      // EastMoney returns JS: var apidata={ content:"...", ...};
      final match = RegExp(r'content:"(.*?)",').firstMatch(body);
      if (match != null) {
          return match.group(1);
      }
    } catch (e) {
      print('Holdings IO fetch error for $code: $e');
    }
    return null;
  }

  @override
  Future<String?> fetchStockQuotes(List<String> codes) async {
    if (codes.isEmpty) return null;
    final url = Uri.parse('https://qt.gtimg.cn/q=${codes.join(',')}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
         try {
           return utf8.decode(response.bodyBytes);
         } catch(e) {
           return utf8.decode(response.bodyBytes, allowMalformed: true);
         }
      }
    } catch (e) {
      print('Stock Quotes IO fetch error: $e');
    }
    return null;
  }
}
