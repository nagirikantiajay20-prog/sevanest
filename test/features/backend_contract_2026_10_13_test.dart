// The routes the backend added on 2026-10-13, against the published OpenAPI: worker reviews, rating
// scale, search minRating / sort / startDate, Home, price guidance, address label / line2 / state,
// position to service area.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/core/errors/app_failure.dart';
import 'package:sevanest_customer/features/addresses/data/address_repository_remote.dart';
import 'package:sevanest_customer/features/addresses/domain/address.dart';
import 'package:sevanest_customer/features/home/data/home_repository_remote.dart';
import 'package:sevanest_customer/features/home/domain/home_data.dart';
import 'package:sevanest_customer/features/service_discovery/data/guidance_repository_remote.dart';
import 'package:sevanest_customer/features/service_discovery/domain/budget.dart';
import 'package:sevanest_customer/features/service_discovery/domain/catalog.dart';
import 'package:sevanest_customer/features/worker_profile/data/worker_reviews_repository_remote.dart';
import 'package:sevanest_customer/features/worker_search/data/worker_search_repository_remote.dart';
import 'package:sevanest_customer/features/worker_search/domain/worker_search.dart';

import '../helpers/fakes.dart';

void main() {
  late List<RequestOptions> seen;

  Dio dio(Future<ResponseBody> Function(RequestOptions) h) {
    seen = [];
    return Dio(BaseOptions(baseUrl: 'http://x'))
      ..httpClientAdapter = FakeAdapter((o) async {
        seen.add(o);
        return h(o);
      });
  }

  group('worker reviews', () {
    test('reads score, comment, date and first name; pages by number', () async {
      final repo = WorkerReviewsRepositoryRemote(
        dio(
          (o) async => jsonBody(
            '{"data":[{"score":4,"comment":"Great","createdAt":"2026-10-01T05:00:00Z","reviewerFirstName":"Anita"},'
            '{"score":5,"comment":null,"createdAt":"2026-09-01T05:00:00Z","reviewerFirstName":null},'
            '{"score":3,"createdAt":"bad"}],"meta":{"page":1,"limit":20,"total":45}}',
            200,
          ),
        ),
      );
      final page = await repo.reviews('w 1');
      expect(seen.single.path, '/search/workers/w%201/ratings');
      expect(seen.single.queryParameters, {'page': 1, 'limit': 20});
      expect(page.items.length, 2);
      expect(page.items[0].rating, 4);
      expect(page.items[0].text, 'Great');
      expect(page.items[0].reviewerFirstName, 'Anita');
      expect(page.items[1].text, isNull);
      expect(page.items[1].reviewerFirstName, isEmpty);
      expect(page.nextCursor, '2');
      expect((await repo.reviews('w1', cursor: '3')).nextCursor, isNull);
    });

    test('an unknown worker is a NotFoundFailure', () async {
      final repo = WorkerReviewsRepositoryRemote(
        dio((o) async => jsonBody('{"code":"WORKER_NOT_FOUND"}', 404)),
      );
      await expectLater(repo.reviews('x'), throwsA(isA<NotFoundFailure>()));
    });
  });

  group('search', () {
    test('sends minRating, sort and startDate when set', () async {
      final repo = WorkerSearchRepositoryRemote(
        dio((o) async => jsonBody('{"data":[],"meta":{"total":0}}', 200)),
      );
      await repo.search(
        WorkerQuery(
          category: 'COOK',
          areaId: 'a1',
          startDate: DateTime(2026, 11, 3),
          filters: const WorkerFilters(
            minRating: 4,
            sort: WorkerSort.highestRated,
          ),
        ),
      );
      final q = seen.single.queryParameters;
      expect(q['minRating'], 4);
      expect(q['sort'], 'RATING_DESC');
      expect(q['startDate'], '2026-11-03');
      await repo.search(const WorkerQuery(category: 'COOK', areaId: 'a1'));
      expect(seen.last.queryParameters.containsKey('minRating'), isFalse);
      expect(seen.last.queryParameters.containsKey('sort'), isFalse);
      expect(seen.last.queryParameters.containsKey('startDate'), isFalse);
    });

    test('rating and sort count as filters and change the query', () {
      const f = WorkerFilters(minRating: 4, sort: WorkerSort.highestRated);
      expect(f.count, 2);
      expect(const WorkerFilters(minRating: 4), isNot(const WorkerFilters()));
      expect(
        WorkerQuery(
          category: 'c',
          areaId: 'a',
          startDate: DateTime(2026, 1, 1),
        ),
        isNot(const WorkerQuery(category: 'c', areaId: 'a')),
      );
    });
  });

  group('Home', () {
    test('maps the aggregate and hides what is null', () async {
      final repo = HomeRepositoryRemote(
        dio(
          (o) async => jsonBody(
            '{"activeBooking":{"id":"bk-123456","status":"INTERVIEW_TRIAL_SCHEDULED",'
            '"category":{"code":"COOK","name":"Cook"},"area":{"id":"a1","name":"Madhapur","city":"Hyderabad"},'
            '"engagement":"PART_TIME","workerId":"w1","startDate":"2026-11-08","timeline":[]},'
            '"upcomingInterview":{"id":"iv1","bookingId":"bk-123456","type":"TRIAL","status":"CONFIRMED",'
            '"preferredAt":"2026-11-03T04:30:00Z","scheduledAt":"2026-11-03T04:30:00Z","allowedActions":[],"timeline":[]},'
            '"unreadNotifications":3,'
            '"shortlistPreview":[{"workerId":"w1","addedAt":"2026-10-01T00:00:00Z","available":true,'
            '"worker":{"workerId":"w1","categories":[{"code":"COOK","name":"Cook"}],"engagementPreference":"FULL_TIME"}},'
            '{"workerId":"w2","addedAt":"2026-10-01T00:00:00Z","available":false,"worker":null}],'
            '"shortlistTotal":2}',
            200,
          ),
        ),
      );
      final h = await repo.fetch();
      expect(seen.single.path, '/customers/me/home');
      final b = h.activeBooking!;
      expect(b.id, 'bk-123456');
      expect(b.service, 'Cook');
      expect(b.engagement, 'Part-time');
      expect(b.startLabel, 'From 8 Nov');
      expect(b.stage, BookingStage.trial);
      final i = h.upcomingInterview!;
      expect(i.id, 'iv1');
      expect(i.isTrialVisit, isTrue);
      expect(i.workerName, 'Cook');
      expect(h.unreadCount, 3);
      expect(h.shortlist.map((s) => s.workerId), ['w1']);
      expect(h.shortlist.single.service, 'Full-time');
    });

    test('a new customer gets the empty view', () async {
      final repo = HomeRepositoryRemote(
        dio(
          (o) async => jsonBody(
            '{"activeBooking":null,"upcomingInterview":null,"unreadNotifications":0,'
            '"shortlistPreview":[],"shortlistTotal":0}',
            200,
          ),
        ),
      );
      final h = await repo.fetch();
      expect(h.isNewUser, isTrue);
      expect(h.unreadCount, 0);
    });
  });

  group('price guidance', () {
    const query = GuidanceQuery(
      serviceId: 'COOK',
      engagement: EngagementType.partTime,
      area: 'Madhapur',
      city: 'Hyderabad',
      areaId: 'a1',
    );

    test(
      'paise become rupees; the query carries category, engagement, area',
      () async {
        final repo = GuidanceRepositoryRemote(
          dio(
            (o) async => jsonBody(
              '{"minMinor":600000,"maxMinor":1000000,"period":"MONTH","basis":"Based on recent bookings"}',
              200,
            ),
          ),
        );
        final g = await repo.guidance(query);
        expect(seen.single.path, '/pricing/guidance');
        expect(seen.single.queryParameters, {
          'category': 'COOK',
          'engagement': 'PART_TIME',
          'areaId': 'a1',
        });
        expect((g.min, g.max), (6000, 10000));
        expect(g.period, BudgetPeriod.monthly);
        expect(g.basis, 'Based on recent bookings');
      },
    );

    test('no band (404) and unsupported periods hide the card', () async {
      await expectLater(
        GuidanceRepositoryRemote(
          dio(
            (o) async => jsonBody('{"code":"PRICING_GUIDANCE_NOT_FOUND"}', 404),
          ),
        ).guidance(query),
        throwsA(isA<NotFoundFailure>()),
      );
      await expectLater(
        GuidanceRepositoryRemote(
          dio(
            (o) async => jsonBody(
              '{"minMinor":1,"maxMinor":2,"period":"DAY","basis":"x"}',
              200,
            ),
          ),
        ).guidance(query),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('addresses', () {
    const input = AddressInput(
      line: '12-3',
      line2: 'Rose Apartments',
      label: 'Home',
      area: 'Madhapur',
      city: 'Hyderabad',
      pincode: '500081',
    );

    test('label and line2 are sent; a blank label clears it', () async {
      final repo = AddressRepositoryRemote(
        dio((o) async => jsonBody('{"id":"ad1","line":"12-3"}', 201)),
      );
      await repo.create(input);
      final body = seen.single.data as Map;
      expect(body['label'], 'Home');
      expect(body['line2'], 'Rose Apartments');
      expect(body['state'], isNull);
      await repo.update(
        'ad1',
        const AddressInput(
          line: '12-3',
          label: '  ',
          area: 'Madhapur',
          city: 'Hyderabad',
          pincode: '500081',
        ),
      );
      expect((seen.last.data as Map)['label'], isNull);
    });

    test('parsed back: label, line2, state, full line and title', () {
      final a = parseAddress({
        'id': 'ad1',
        'line': '12-3',
        'line2': 'Rose Apartments',
        'label': 'Parents\' home',
        'state': 'Telangana',
        'area': 'Madhapur',
        'city': 'Hyderabad',
        'pincode': '500081',
      })!;
      expect(a.label, 'Parents\' home');
      expect(a.state, 'Telangana');
      expect(a.fullLine, '12-3, Rose Apartments');
      expect(a.title, 'Parents\' home');
      final old = parseAddress({
        'id': 'ad2',
        'line': '1, Road',
        'label': null,
        'line2': null,
        'area': 'Madhapur',
        'city': 'Hyderabad',
        'pincode': '500081',
      })!;
      expect(old.label, isNull);
      expect(old.fullLine, '1, Road');
      expect(old.title, 'Madhapur');
    });

    test('position to area: params, the area, and null on 404', () async {
      final repo = AddressRepositoryRemote(
        dio(
          (o) async => o.queryParameters['name'] == 'Nowhere'
              ? jsonBody('{"code":"AREA_NOT_FOUND"}', 404)
              : jsonBody(
                  '{"id":"a1","name":"Madhapur","city":"Hyderabad"}',
                  200,
                ),
        ),
      );
      final area = await repo.resolveServiceArea(
        latitude: 17.44,
        longitude: 78.39,
        name: 'Hitec City',
        city: 'Hyderabad',
      );
      expect(seen.single.path, '/locations/service-area');
      expect(seen.single.queryParameters, {
        'latitude': 17.44,
        'longitude': 78.39,
        'name': 'Hitec City',
        'city': 'Hyderabad',
      });
      expect((area!.id, area.name), ('a1', 'Madhapur'));
      expect(await repo.resolveServiceArea(name: 'Nowhere'), isNull);
    });
  });
}
