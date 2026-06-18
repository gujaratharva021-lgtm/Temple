import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'https://temple-vdhl.onrender.com/api/v1';
  // Android emulator: 10.0.2.2
  // iOS simulator: localhost
  // Real device: apna IP dalein e.g. 'http://192.168.1.100:8080/api/v1'
  // Production: 'https://api.onebharat.com/api/v1'

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          await _storage.delete(key: 'auth_token');
        }
        return handler.next(e);
      },
    ));
  }

  // ─── AUTH ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> sendOTP(String phone) async {
    final res = await _dio.post('/auth/send-otp', data: {'phone': phone});
    return res.data;
  }

  Future<Map<String, dynamic>> verifyOTP(String phone, String otp) async {
    final res =
        await _dio.post('/auth/verify-otp', data: {'phone': phone, 'otp': otp});
    return res.data;
  }

  Future<Map<String, dynamic>> register({
    required String tempToken,
    required String fullName,
    required String role,
    String? email,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'temp_token': tempToken,
      'full_name': fullName,
      'role': role,
      if (email != null) 'email': email,
    });
    return res.data;
  }

  // ─── USER ──────────────────────────────────────────────────────────────────
  // Backend route: GET /user/me  (Flutter pehle /users/me call karta tha — FIXED)

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/user/me');
    return res.data;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final res = await _dio.put('/user/profile', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> updateFCMToken(String token) async {
    final res =
        await _dio.put('/user/me/fcm-token', data: {'fcm_token': token});
    return res.data;
  }

  // ─── TEMPLES ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getTemples(
      {String? city, String? state, String? search}) async {
    final res = await _dio.get('/temples', queryParameters: {
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (search != null) 'search': search,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getTemple(String id) async {
    final res = await _dio.get('/temples/$id');
    return res.data;
  }

  Future<Map<String, dynamic>> getNearbyTemples(double lat, double lng) async {
    final res = await _dio.get('/temples/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getTempleServices(String templeId) async {
    final res = await _dio.get('/temples/$templeId/services');
    return res.data;
  }

  Future<Map<String, dynamic>> donate({
    required String templeId,
    required double amount,
    String? message,
    bool isAnonymous = false,
  }) async {
    final res = await _dio.post('/wallet/donate', data: {
      'temple_id': templeId,
      'amount': amount,
      if (message != null) 'message': message,
      'is_anonymous': isAnonymous,
    });
    return res.data;
  }

  // ─── POOJA BOOKING ─────────────────────────────────────────────────────────
  // Backend route: POST /pooja/book  (Flutter pehle /bookings call karta tha — FIXED)

  Future<Map<String, dynamic>> createBooking({
    required String templeId,
    required String poojaServiceId,
    required String bookingDate,
    required String bookingTime,
    required int persons,
    required String paymentId,
    double? amount,
    String? sankalp,
  }) async {
    final res = await _dio.post('/pooja/book', data: {
      'temple_id': templeId,
      'pooja_service_id': poojaServiceId,
      'booking_date': bookingDate,
      'booking_time': bookingTime,
      'persons': persons,
      'payment_id': paymentId,
      if (amount != null) 'amount': amount,
      if (sankalp != null) 'sankalp': sankalp,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getMyBookings({String? status}) async {
    // Backend route: GET /pooja/my-bookings  (pehle /bookings tha — FIXED)
    final res = await _dio.get('/pooja/my-bookings', queryParameters: {
      if (status != null) 'status': status,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    final res = await _dio.put('/pooja/booking/$bookingId/cancel');
    return res.data;
  }

  // ─── STORE ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProducts(
      {String? category, String? search}) async {
    final res = await _dio.get('/store/products', queryParameters: {
      if (category != null) 'category': category,
      if (search != null) 'search': search,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getProduct(String id) async {
    final res = await _dio.get('/store/products/$id');
    return res.data;
  }

  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required String shippingAddress,
  }) async {
    final res = await _dio.post('/store/orders', data: {
      'items': items,
      'shipping_address': shippingAddress,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getMyOrders({String? status}) async {
    final res = await _dio.get('/store/orders', queryParameters: {
      if (status != null) 'status': status,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    final res = await _dio.put('/store/orders/$orderId/cancel');
    return res.data;
  }

  // ─── ASTROLOGY ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAstrologers() async {
    final res = await _dio.get('/astrology/astrologers');
    return res.data;
  }

  Future<Map<String, dynamic>> bookConsultation(
      Map<String, dynamic> data) async {
    final res = await _dio.post('/astrology/consultations', data: data);
    return res.data;
  }

  // ─── WALLET ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getWallet() async {
    final res = await _dio.get('/wallet');
    return res.data;
  }

  Future<Map<String, dynamic>> getTransactions(
      {String? type, String? category}) async {
    final res = await _dio.get('/wallet/transactions', queryParameters: {
      if (type != null) 'type': type,
      if (category != null) 'category': category,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getMyDonations() async {
    final res = await _dio.get('/wallet/donations');
    return res.data;
  }

  Future<Map<String, dynamic>> createWalletOrder(int amount) async {
    final res = await _dio.post('/wallet/create-order', data: {
      'amount': amount.toDouble(),
      'currency': 'INR',
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyWalletPayment({
    required String paymentId,
    required int amount,
    String? orderId,
    String? signature,
  }) async {
    final res = await _dio.post('/wallet/verify-payment', data: {
      'razorpay_payment_id': paymentId,
      'razorpay_order_id': orderId ?? '',
      'razorpay_signature': signature ?? '',
      'amount': amount.toDouble(),
    });
    return res.data as Map<String, dynamic>;
  }

  // ─── NOTIFICATIONS ─────────────────────────────────────────────────────────
  // Backend notification routes abhi bane nahi — ye gracefully fail hoga

  Future<Map<String, dynamic>> getNotifications() async {
    final res = await _dio.get('/notifications');
    return res.data;
  }

  // ─── SADHANA ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMantras() async {
    final res = await _dio.get('/sadhana/mantras');
    return res.data;
  }

  Future<Map<String, dynamic>> getPractices() async {
    final res = await _dio.get('/sadhana/practices');
    return res.data;
  }

  Future<Map<String, dynamic>> getFestivals() async {
    final res = await _dio.get('/sadhana/festivals');
    return res.data;
  }

  Future<Map<String, dynamic>> getTodayShloka() async {
    final res = await _dio.get('/sadhana/shloka/today');
    return res.data;
  }

  Future<Map<String, dynamic>> logPractice(String key, bool completed) async {
    final res = await _dio.post('/sadhana/log',
        data: {'practice_key': key, 'completed': completed});
    return res.data;
  }

  Future<Map<String, dynamic>> getTodayLog() async {
    final res = await _dio.get('/sadhana/log/today');
    return res.data;
  }

  // ─── EXTERNAL API ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getFromUrl(String url) async {
    final dio = Dio();
    final res = await dio.get(url);
    // Debug: print response
    print('VedAstro Response: ${res.data}');
    if (res.data is Map<String, dynamic>) {
      return res.data as Map<String, dynamic>;
    }
    return {'Payload': res.data};
  }

  // ─── TOKEN MANAGEMENT ──────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
  }
}
