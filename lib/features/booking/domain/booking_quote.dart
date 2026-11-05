/// What the customer pays to confirm a booking. All amounts in paise.
///
/// Only the backend fee (`GET /fees/booking`) is ever shown. Without it there is no quote: the screen
/// says the fee is shown at payment instead of inventing an amount (no quote endpoint yet,
/// docs/BACKEND_REQUESTS.md "BookingQuote").
class BookingQuote {
  const BookingQuote({required this.feeMinor});

  final int feeMinor;

  /// The fee is the real amount; no tax rule is defined yet, so the total is the fee.
  int get totalMinor => feeMinor;
}

BookingQuote? bookingQuote({int? backendFeeMinor}) =>
    backendFeeMinor == null ? null : BookingQuote(feeMinor: backendFeeMinor);
