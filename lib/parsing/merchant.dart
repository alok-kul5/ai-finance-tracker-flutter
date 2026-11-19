/// Merchant name clean-up. Bank messages spell the same shop many ways
/// ("SWIGGY", "swiggy@icici", "Swiggy Instamart Pvt Ltd", "RAZORPAY*SWIGGY"),
/// so everything that groups by merchant (remembered categories, recurring
/// detection, Q&A) goes through [merchantKey].
library;

const _noise = <String>{
  'pvt', 'private', 'ltd', 'limited', 'llp', 'inc', 'india', 'in', 'co',
  'company', 'technologies', 'technology', 'tech', 'services', 'service',
  'solutions', 'retail', 'online', 'payments', 'payment', 'upi', 'pay',
  'the', 'and', 'store', 'stores', 'enterprises', 'internet', 'digital',
  'com', 'www', 'p2m', 'p2a', 'mandate', 'autopay', 'ecom', 'pos',
  'electricity', 'bill', 'bills', 'recharge', 'prepaid', 'postpaid', 'subscription',
};

/// Payment gateways that prefix the real merchant: "RAZORPAY*SWIGGY".
final _gatewayPrefix = RegExp(
    r'^(razorpay|rzp|paytm|payu|cashfree|ccavenue|billdesk|phonepe|gpay|bharatpe|pinelabs|juspay)\s*[\*\-_/:. ]+\s*',
    caseSensitive: false);

/// Well-known brands: any key containing the left side collapses to the right.
const _aliases = <String, String>{
  'swiggy': 'swiggy',
  'zomato': 'zomato',
  'amazon': 'amazon',
  'amzn': 'amazon',
  'flipkart': 'flipkart',
  'netflix': 'netflix',
  'spotify': 'spotify',
  'uber': 'uber',
  'olacabs': 'ola',
  'rapido': 'rapido',
  'bigbasket': 'bigbasket',
  'blinkit': 'blinkit',
  'zepto': 'zepto',
  'airtel': 'airtel',
  'jio': 'jio',
  'irctc': 'irctc',
  'myntra': 'myntra',
  'hotstar': 'hotstar',
  'bookmyshow': 'bookmyshow',
  'makemytrip': 'makemytrip',
  'dmart': 'dmart',
  'avenue supermarts': 'dmart',
  'apollo': 'apollo pharmacy',
  'pharmeasy': 'pharmeasy',
  'youtube': 'youtube premium',
};

/// A stable, lower-case grouping key for a merchant or VPA.
String merchantKey(String raw) {
  var s = raw.trim().toLowerCase();
  // A VPA: keep the handle, drop the bank suffix ("swiggy.rzp@icici").
  final at = s.indexOf('@');
  if (at > 0 && !s.contains(' ')) s = s.substring(0, at);
  s = s.replaceFirst(_gatewayPrefix, '');
  s = s.replaceAll(RegExp(r'[._\-*/\\:#]+'), ' ');
  s = s.replaceAll(RegExp(r'\d+'), ' ');
  s = s.replaceAll(RegExp(r'[^a-z& ]'), ' ');
  final words = s
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty && !_noise.contains(w))
      .toList();
  final key = words.join(' ');
  for (final e in _aliases.entries) {
    if (key.contains(e.key) || key.replaceAll(' ', '').contains(e.key)) {
      return e.value;
    }
  }
  return key.isEmpty ? raw.trim().toLowerCase() : key;
}

/// A human display name: "swiggy.rzp@icici" → "Swiggy", "AMAZON PAY INDIA"
/// → "Amazon Pay India".
String displayMerchant(String raw) {
  var s = raw.trim();
  final at = s.indexOf('@');
  if (at > 0 && !s.contains(' ')) {
    s = s.substring(0, at).replaceAll(RegExp(r'[._\-]+'), ' ');
    s = s.replaceAll(RegExp(r'\b(rzp|razorpay|payu|paytm|pay|upi|bil|billdesk)\b', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'\d{4,}'), ' ');
  }
  s = s.replaceFirst(_gatewayPrefix, '');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (s.isEmpty) return raw.trim();
  return s
      .split(' ')
      .map((w) => w.length <= 2 && w.toUpperCase() == w && w.length > 1
          ? w
          : w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}

/// True when a VPA looks like a person ("rahul.sharma@okaxis",
/// "9876543210@ybl") rather than a business.
bool looksLikePersonVpa(String vpa) {
  final v = vpa.toLowerCase();
  if (!v.contains('@')) return false;
  final handle = v.substring(0, v.indexOf('@'));
  final bank = v.substring(v.indexOf('@') + 1);
  if (RegExp(r'^\d{10}$').hasMatch(handle)) return true;
  const personalBanks = {'okaxis', 'okhdfcbank', 'okicici', 'oksbi', 'ybl', 'ibl', 'axl', 'apl', 'paytm', 'upi'};
  if (!personalBanks.contains(bank)) return false;
  if (_aliases.values.contains(merchantKey(vpa))) return false;
  if (RegExp(r'merchant|store|shop|mart|bharatpe|paytmqr|q\d').hasMatch(handle)) {
    return false;
  }
  return RegExp(r'^[a-z]+([._][a-z]+)?\d{0,4}$').hasMatch(handle);
}
