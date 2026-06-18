import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Temple/features/home/screens/main_shell.dart';
import 'package:Temple/shared/services/api_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: Text(isHindi ? 'मेरा खाता' : 'My Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // My Bookings
            _buildTile(
              icon: Icons.book_online,
              label: isHindi ? 'मेरी बुकिंग' : 'My Bookings',
              onTap: () => context.go('/my-bookings'),
            ),
            const SizedBox(height: 12),

            // My Orders
            _buildTile(
              icon: Icons.shopping_bag,
              label: isHindi ? 'मेरे ऑर्डर' : 'My Orders',
              onTap: () => context.go('/store'),
            ),
            const SizedBox(height: 24),

            // Logout
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.logout),
                label: Text(
                  isHindi ? 'लॉगआउट' : 'Logout',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  await ApiService().clearToken();
                  if (context.mounted) context.go('/login');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(children: [
            Icon(icon, color: Colors.orange, size: 24),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600))),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ]),
        ),
      ),
    );
  }
}
