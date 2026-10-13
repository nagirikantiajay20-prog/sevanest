import 'package:sevanest_customer/features/home/domain/home_data.dart';

/// Live Home. The backend has no Home aggregate, and interviews, bookings and notifications
/// arrive with their own modules, so for now a live customer sees the new-customer Home. No
/// invented bookings or interviews. The shortlist lives on its own tab.
class HomeRepositoryRemote implements HomeRepository {
  const HomeRepositoryRemote();

  @override
  Future<HomeData> fetch() async => const HomeData();
}
