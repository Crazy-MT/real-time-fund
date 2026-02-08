abstract class FundFetcher {
  Future<Map<String, dynamic>?> fetchEastMoney(String code);
  Future<String?> fetchTencent(String code);
  Future<String?> fetchHoldings(String code);
  Future<String?> fetchStockQuotes(List<String> codes);
}
