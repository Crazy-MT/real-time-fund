import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'fund_fetcher_interface.dart';

class FundFetcherImpl implements FundFetcher {
  static final Map<String, Completer<Map<String, dynamic>?>> _pendingRequests = {};
  static bool _initialized = false;

  FundFetcherImpl() {
    _init();
  }

  static void _init() {
    if (_initialized) return;
    
    // Define the global callback function
    js.context['jsonpgz'] = (dynamic data) {
      if (data == null) return;
      
      // Convert JS object to Dart Map
      // Using jsonEncode/jsonDecode as a safe bridge or accessing properties
      try {
        // data is a JsObject
        final jsObj = js.JsObject.fromBrowserObject(data);
        final code = jsObj['fundcode'];
        
        if (code != null && _pendingRequests.containsKey(code)) {
           // Extract all fields
           final map = <String, dynamic>{
             'fundcode': jsObj['fundcode'],
             'name': jsObj['name'],
             'jzrq': jsObj['jzrq'],
             'dwjz': jsObj['dwjz'],
             'gsz': jsObj['gsz'],
             'gszzl': jsObj['gszzl'],
             'gztime': jsObj['gztime'],
           };
           
           _pendingRequests[code]?.complete(map);
           _pendingRequests.remove(code);
        }
      } catch (e) {
        print('Error parsing JSONP data: $e');
      }
    };
    
    _initialized = true;
  }

  @override
  Future<Map<String, dynamic>?> fetchEastMoney(String code) {
    // If a request is already pending, return its future
    if (_pendingRequests.containsKey(code)) {
      return _pendingRequests[code]!.future;
    }

    final completer = Completer<Map<String, dynamic>?>();
    _pendingRequests[code] = completer;

    // Create script element
    final script = html.ScriptElement();
    script.src = 'https://fundgz.1234567.com.cn/js/$code.js?rt=${DateTime.now().millisecondsSinceEpoch}';
    script.type = 'text/javascript';
    script.async = true;
    
    // Handle errors (e.g. 404)
    script.onError.listen((event) {
      if (!_pendingRequests.containsKey(code)) return;
      print('Script load error for $code');
      _pendingRequests[code]?.complete(null);
      _pendingRequests.remove(code);
      script.remove();
    });

    // Cleanup script after load (optional, but good practice)
    script.onLoad.listen((_) {
       // We can remove the script tag after it loads
       Timer(const Duration(seconds: 1), () {
         script.remove();
         // If callback wasn't called after load + timeout, complete with null
         if (_pendingRequests.containsKey(code)) {
            _pendingRequests[code]?.complete(null);
            _pendingRequests.remove(code);
         }
       });
    });

    html.document.head!.append(script);

    return completer.future;
  }

  @override
  Future<String?> fetchTencent(String code) {
    final completer = Completer<String?>();
    
    // Variable name in JS global scope: v_jjCODE
    final varName = 'v_jj$code';
    
    // Create script element
    final script = html.ScriptElement();
    script.src = 'https://qt.gtimg.cn/q=jj$code';
    script.type = 'text/javascript';
    script.async = true;
    // Set charset to GBK if possible, though browsers might ignore it for script src
    // or infer it. Tencent returns GBK.
    // However, recent browsers often treat scripts as UTF-8.
    // If the browser misinterprets GBK as UTF-8, we might get garbage characters.
    // But usually for numeric data (prices) it's fine. Names might be garbled.
    // Let's see if we can force charset.
    script.charset = 'gbk'; 

    script.onError.listen((event) {
      print('Tencent Script load error for $code');
      if (!completer.isCompleted) completer.complete(null);
      script.remove();
    });

    script.onLoad.listen((_) {
      // Check if variable exists
      if (js.context.hasProperty(varName)) {
        final result = js.context[varName];
        if (result is String) {
          if (!completer.isCompleted) completer.complete(result);
        } else {
           if (!completer.isCompleted) completer.complete(null);
        }
        
        // Cleanup variable
        js.context.deleteProperty(varName);
      } else {
         if (!completer.isCompleted) completer.complete(null);
      }
      
      script.remove();
    });

    html.document.head!.append(script);
    
    return completer.future;
  }

  static Future<void> _holdingsLock = Future.value();

  @override
  Future<String?> fetchHoldings(String code) async {
    // Serialize requests to prevent 'apidata' collision
    final previousLock = _holdingsLock;
    final lockCompleter = Completer<void>();
    _holdingsLock = lockCompleter.future;

    try {
      await previousLock;
      return await _doFetchHoldings(code);
    } finally {
      lockCompleter.complete();
    }
  }

  Future<String?> _doFetchHoldings(String code) {
    final completer = Completer<String?>();
    
    // Clear previous apidata
    if (js.context.hasProperty('apidata')) {
      js.context.deleteProperty('apidata');
    }

    final script = html.ScriptElement();
    script.src = 'https://fundf10.eastmoney.com/FundArchivesDatas.aspx?type=jjcc&code=$code&topline=10&year=&month=&_=${DateTime.now().millisecondsSinceEpoch}';
    script.type = 'text/javascript';
    script.async = true;

    script.onError.listen((event) {
      print('Holdings Script load error for $code');
      if (!completer.isCompleted) completer.complete(null);
      script.remove();
    });

    script.onLoad.listen((_) {
      if (js.context.hasProperty('apidata')) {
        final apidata = js.context['apidata'];
        // apidata is a JsObject
        if (apidata != null) {
           try {
             final jsObj = js.JsObject.fromBrowserObject(apidata);
             final content = jsObj['content'];
             if (content is String) {
               completer.complete(content);
             } else {
               completer.complete(null);
             }
           } catch (e) {
             print('Error parsing apidata: $e');
             completer.complete(null);
           }
        } else {
          completer.complete(null);
        }
      } else {
        completer.complete(null);
      }
      
      script.remove();
    });

    html.document.head!.append(script);
    return completer.future;
  }

  @override
  Future<String?> fetchStockQuotes(List<String> codes) {
    if (codes.isEmpty) return Future.value(null);
    final completer = Completer<String?>();
    
    final script = html.ScriptElement();
    script.src = 'https://qt.gtimg.cn/q=${codes.join(',')}';
    script.type = 'text/javascript';
    script.async = true;
    script.charset = 'gbk';

    script.onError.listen((_) {
        if (!completer.isCompleted) completer.complete(null);
        script.remove();
    });

    script.onLoad.listen((_) {
        final buffer = StringBuffer();
        for (final code in codes) {
            final varName = 'v_$code';
            if (js.context.hasProperty(varName)) {
                final val = js.context[varName];
                buffer.write('$varName="$val";\n');
                js.context.deleteProperty(varName);
            }
        }
        completer.complete(buffer.toString());
        script.remove();
    });
    
    html.document.head!.append(script);
    return completer.future;
  }
}
