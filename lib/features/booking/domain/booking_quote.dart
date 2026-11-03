/// What the customer pays to confirm a booking (design: fee, taxes, total). All amounts in paise.
///
/// MOCK: the backend has no quote endpoint yet (docs/BACKEND_REQUESTS.md, "BookingQuote"). Until it
/// does, [bookingQuote] returns an [isEstimate] quote built from the numbers below, unless
/// `GET /fees/booking` supplied the real fee. Replace this one function when the endpoint exists.
class BookingQuote {
  const BookingQuote({
    required this.feeMinor,
    required this.totalMinor,
    this.taxMinor,
    this.isEstimate = false,
    this.taxPending = false,
  });

  final int feeMinor;

  /// Null when the backend fee is quoted as one amount.
  final int? taxMinor;
  final int totalMinor;

  /// True for the mock: the screen says the final amount is shown at payment.
  final bool isEstimate;

  /// True for the backend fee: it is the real amount, but no tax rule is defined yet, so the
  /// screen says taxes are confirmed at payment.
  final bool taxPending;
}

const _mockFeeMinor = 50000; // MOCK: design value, Rs 500
const _mockTaxPercent = 18; // MOCK: design value (Rs 90 on Rs 500)

/// The one place a quote is made. [backendFeeMinor] is the real fee when the backend served one.
BookingQuote bookingQuote({int? backendFeeMinor}) {
  if (backendFeeMinor != null) {
    return BookingQuote(
      feeMinor: backendFeeMinor,
      totalMinor: backendFeeMinor,
      taxPending: true,
    );
  }
  const tax = _mockFeeMinor * _mockTaxPercent ~/ 100;
  return const BookingQuote(
    feeMinor: _mockFeeMinor,
    taxMinor: tax,
    totalMinor: _mockFeeMinor + tax,
    isEstimate: true,
  );
}
