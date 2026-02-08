import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:fast_gbk/fast_gbk.dart';
import '../models/fund.dart';
import 'fetcher/fund_fetcher.dart';

class FundService {
  // Fetch fund data from EastMoney and Tencent
  static Future<Fund> fetchFundData(String code) async {
    try {
      // 1. Fetch real-time valuation from EastMoney
      String? name;
      String? dwjz;
      String? gsz;
      String? gszzl;
      String? gztime;
      String? jzrq;

      try {
        final fetcher = FundFetcherFactory.create();
        final json = await fetcher.fetchEastMoney(code);
        
        if (json != null) {
          name = json['name'];
          dwjz = json['dwjz'];
          gsz = json['gsz'];
          gszzl = json['gszzl'];
          gztime = json['gztime'];
          jzrq = json['jzrq'];
        }
      } catch (e) {
        print('EastMoney fetch error for $code: $e');
      }

      // 2. Fetch Tencent data for backup/verification and real growth rate
      // Tencent API usually supports CORS or we might need a similar fetcher if it fails on Web.
      // We use the same fetcher pattern to handle Tencent JSONP on web and HTTP on IO.
      
      String? zzl;
      
      try {
        final fetcher = FundFetcherFactory.create();
        final body = await fetcher.fetchTencent(code);
        
        if (body != null) {
          // body is the content inside quotes: "...~...~..."
          final parts = body.split('~');
          if (parts.length > 8) {
              final tName = parts[1];
              final tDwjz = parts[5];
              final tZzl = parts[7];
              // Tencent date is usually at index 8 (or 13 sometimes? JS says 8)
              // JS: p[8] ? p[8].slice(0, 10) : ''
              String? tJzrq = parts[8].length >= 10 ? parts[8].substring(0, 10) : parts[8];
              
              // If EastMoney failed, use Tencent data
              if (name == null) {
                name = tName;
                dwjz = tDwjz;
                jzrq = tJzrq;
              } else {
                // If EastMoney succeeded, check if Tencent data is newer or equal
                // JS Logic: if (tData.jzrq && (!gzData.jzrq || tData.jzrq >= gzData.jzrq))
                if (tJzrq != null && tJzrq.isNotEmpty) {
                    if (jzrq == null || jzrq!.isEmpty || tJzrq.compareTo(jzrq!) >= 0) {
                      dwjz = tDwjz;
                      jzrq = tJzrq;
                      // Tencent zzl is real growth, usually more accurate for confirmed NAV
                    }
                }
              }
              
              // Always get real growth rate from Tencent if available
              zzl = tZzl;
          }
        }
      } catch (e) {
        print('Tencent fetch error: $e');
        // Ignore Tencent error if we have EastMoney data
      }

      // If we still don't have a name, try fallback search (simplified)
      if (name == null) {
         // TODO: Implement fallback search if needed
         name = 'Unknown Fund';
      }

      // 3. Fetch Top 10 Holdings (Stocks)
      List<FundHolding> holdings = [];
      try {
        holdings = await _fetchHoldings(code);
      } catch (e) {
        print('Error fetching holdings for $code: $e');
      }

      return Fund(
        code: code,
        name: name,
        dwjz: dwjz,
        gsz: gsz,
        gszzl: gszzl,
        gztime: gztime,
        jzrq: jzrq,
        zzl: zzl,
        estPricedCoverage: 1.0, // Default, not calculating coverage yet
        holdings: holdings,
      );
    } catch (e) {
      throw Exception('Failed to load fund $code: $e');
    }
  }

  static Future<List<FundHolding>> _fetchHoldings(String code) async {
    final fetcher = FundFetcherFactory.create();
    final content = await fetcher.fetchHoldings(code);
    
    if (content == null || content.isEmpty) return [];

    // Parse HTML table
    // Since content is a string fragment of HTML, we wrap it
    final document = html_parser.parse('<table>$content</table>');
    final rows = document.getElementsByTagName('tr');
    
    // Find header indices
    int idxCode = -1;
    int idxName = -1;
    int idxWeight = -1;
    
    if (rows.isNotEmpty) {
       final headerCells = rows[0].getElementsByTagName('th');
       if (headerCells.isEmpty) {
           // Maybe headers are in the first row as tds?
           // The JS regex looked for thead/th
       }
       
       for (int i = 0; i < headerCells.length; i++) {
           final text = headerCells[i].text.trim();
           if (idxCode < 0 && (text.contains('股票代码') || text.contains('证券代码'))) idxCode = i;
           if (idxName < 0 && (text.contains('股票名称') || text.contains('证券名称'))) idxName = i;
           if (idxWeight < 0 && (text.contains('占净值比例') || text.contains('占比'))) idxWeight = i;
       }
    }

    // JS logic also handled case where headers might be different or using default indices if not found?
    // JS Logic:
    // headerCells.forEach((h, i) => { ... })
    // if not found, it tries to guess based on content (regex).
    
    List<FundHolding> holdings = [];
    
    // Skip header row
    for (int i = 1; i < rows.length; i++) {
        final cells = rows[i].getElementsByTagName('td');
        if (cells.isEmpty) continue;
        
        String stockCode = '';
        String stockName = '';
        String weight = '';
        
        if (idxCode >= 0 && idxCode < cells.length) {
            // Extract 6 digit code
            final text = cells[idxCode].text.trim();
            final match = RegExp(r'(\d{6})').firstMatch(text);
            stockCode = match?.group(1) ?? text;
        } else {
             // Guess code: 6 digits
             for (var cell in cells) {
                 if (RegExp(r'^\d{6}$').hasMatch(cell.text.trim())) {
                     stockCode = cell.text.trim();
                     break;
                 }
             }
        }
        
        if (idxName >= 0 && idxName < cells.length) {
            stockName = cells[idxName].text.trim();
        } else if (stockCode.isNotEmpty) {
            // Guess name: not code and not percentage
             for (var cell in cells) {
                 final txt = cell.text.trim();
                 if (txt.isNotEmpty && txt != stockCode && !txt.endsWith('%')) {
                     stockName = txt;
                     break;
                 }
             }
        }
        
        if (idxWeight >= 0 && idxWeight < cells.length) {
             weight = cells[idxWeight].text.trim();
        } else {
             // Guess weight
             for (var cell in cells) {
                 if (cell.text.trim().endsWith('%')) {
                     weight = cell.text.trim();
                     break;
                 }
             }
        }
        
        if (stockCode.isNotEmpty || stockName.isNotEmpty) {
            holdings.add(FundHolding(
                code: stockCode,
                name: stockName,
                weight: weight,
                change: null // Will fetch later
            ));
        }
    }
    
    // Limit to 10
    if (holdings.length > 10) holdings = holdings.sublist(0, 10);
    
    // Fetch quotes for holdings
    final needQuotes = holdings.where((h) => RegExp(r'^\d{5,6}$').hasMatch(h.code)).toList();
    if (needQuotes.isNotEmpty) {
        final tencentCodes = needQuotes.map((h) {
             final cd = h.code;
             if (RegExp(r'^\d{6}$').hasMatch(cd)) {
                 final pfx = (cd.startsWith('6') || cd.startsWith('9')) ? 'sh' : 
                             ((cd.startsWith('4') || cd.startsWith('8')) ? 'bj' : 'sz');
                 return 's_$pfx$cd';
             } else if (RegExp(r'^\d{5}$').hasMatch(cd)) {
                 return 's_hk$cd';
             }
             return null;
        }).where((c) => c != null).cast<String>().toList();
        
        if (tencentCodes.isNotEmpty) {
            try {
                final fetcher = FundFetcherFactory.create();
                final body = await fetcher.fetchStockQuotes(tencentCodes);

                if (body != null) {
                     // Parse: v_s_sh600519="1~贵州茅台~600519~1715.11~-1.25~-0.07~12345~...";
                     // We need index 5 for change percent? 
                     // Wait, s_ prefix (simple interface):
                     // v_s_sh600519="1~贵州茅台~600519~1715.11~-1.25~-0.07~...";
                     // Indices:
                     // 0: 1
                     // 1: Name
                     // 2: Code
                     // 3: Current Price
                     // 4: Change Amount
                     // 5: Change Percent (e.g. -0.07) -> need to multiply by something? 
                     // Let's check JS:
                     // const parts = dataStr.split('~');
                     // if (parts.length > 5) { ... change: parseFloat(parts[5]) }
                     // So it is index 5.
                     
                     final lines = body.split(';');
                     for (var line in lines) {
                         if (!line.contains('=')) continue;
                         final parts = line.split('="')[1].replaceAll('"', '').split('~');
                         if (parts.length > 5) {
                             final code = parts[2]; // 600519
                             final change = double.tryParse(parts[5]);
                             
                             // Find holding and update
                             for (var i=0; i<holdings.length; i++) {
                                 if (holdings[i].code == code) {
                                     // Create new holding with change
                                     holdings[i] = FundHolding(
                                         code: holdings[i].code,
                                         name: holdings[i].name,
                                         weight: holdings[i].weight,
                                         change: change
                                     );
                                 }
                             }
                         }
                     }
                }
            } catch (e) {
                print('Error fetching stock quotes: $e');
            }
        }
    }

    return holdings;
  }

  // Fetch holdings (optional, can be implemented later if needed for detailed view)
  // Implementing simplified version for now
  static Future<List<FundHolding>> fetchHoldings(String code) async {
    // Implementation for holdings fetching using HTML parsing
    // skipping for initial migration to focus on core data
    return [];
  }
}
