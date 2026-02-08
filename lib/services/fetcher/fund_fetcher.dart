import 'fund_fetcher_interface.dart';
import 'fund_fetcher_io.dart' if (dart.library.html) 'fund_fetcher_web.dart';

class FundFetcherFactory {
  static FundFetcher create() {
    return FundFetcherImpl();
  }
}
