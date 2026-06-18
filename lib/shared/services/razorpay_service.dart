import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  static Razorpay? _razorpay;

  static void init({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
  }

  static void openPayment({
    required double amount,
    String? orderId,
    required String description,
    String? userName,
    String? userEmail,
    String? userPhone,
  }) {
    final options = {
      'key': 'rzp_test_T12Lul1BLAYp2N', // Test key — baad mein replace karna
      'amount': (amount * 100).toInt(), // Razorpay paisa mein leta hai

      'name': 'One Bharat',
      'description': description,
      'prefill': {
        'contact': userPhone ?? '9999999999',
        'email': userEmail ?? 'user@onebharat.com',
        'name': userName ?? 'Devotee',
      },
      'theme': {'color': '#B8621C'},
    };

    _razorpay!.open(options);
  }

  static void dispose() {
    _razorpay?.clear();
  }
}
