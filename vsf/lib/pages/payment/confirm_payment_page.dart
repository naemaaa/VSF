import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:math';
import '../../models/event_model.dart';
import '../../models/volunteer_registration.dart';
import '../../models/user_stats_model.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../services/event_service.dart';

class ConfirmPaymentPage extends StatefulWidget {
  final VolunteerRegistration registration;
  final EventModel event;
  final String paymentCurrency;

  const ConfirmPaymentPage({
    super.key,
    required this.registration,
    required this.event,
    this.paymentCurrency = 'IDR',
  });

  @override
  State<ConfirmPaymentPage> createState() => _ConfirmPaymentPageState();
}

class _ConfirmPaymentPageState extends State<ConfirmPaymentPage> {
  bool _isProcessing = false;
  final NotificationService _notificationService = NotificationService();
  final EventService _eventService = EventService();

  final Map<String, double> _exchangeRates = {
    'IDR': 1.0,
    'USD': 15800.0,
    'EUR': 17200.0,
  };

  Future<void> _processPayment() async {
    try {
      setState(() => _isProcessing = true);
      await Future.delayed(const Duration(seconds: 3));
      final isSuccess = Random().nextDouble() > 0.05;

      if (!mounted) return;

      if (isSuccess) {
        try {
          final registrationBox = Hive.box<VolunteerRegistration>('registrations');
          final eventBox = Hive.box<EventModel>('events');
          final statsBox = Hive.box<UserStats>('user_stats');
          
          final notificationBox = Hive.box<NotificationModel>('notifications');

          // ✅ 1. Update registration status jadi paid
          final completedRegistration = VolunteerRegistration(
            id: widget.registration.id,
            eventId: widget.registration.eventId,
            volunteerId: widget.registration.volunteerId,
            volunteerName: widget.registration.volunteerName,
            volunteerEmail: widget.registration.volunteerEmail,
            volunteerPhone: widget.registration.volunteerPhone,
            volunteerNik: widget.registration.volunteerNik,
            birthDate: widget.registration.birthDate,
            agreementNonRefundable: widget.registration.agreementNonRefundable,
            motivation: widget.registration.motivation,
            donationAmount: widget.registration.donationAmount,
            paymentMethod: widget.registration.paymentMethod,
            isPaid: true,
            registeredAt: widget.registration.registeredAt,
            paymentCurrency: widget.paymentCurrency, // ✅ PERBAIKAN: Gunakan paymentCurrency dari parameter
          );
          await registrationBox.put(completedRegistration.id, completedRegistration);
          print('✅ Registration marked as paid');
          print('   Currency: ${widget.paymentCurrency}');

          // ✅ 2. Update UserStats (PENTING: ensure stats tersimpan)
          UserStats? userStats;
          for (var stat in statsBox.values) {
            if (stat.userId == widget.registration.volunteerId) {
              userStats = stat;
              break;
            }
          }

          if (userStats == null) {
            userStats = UserStats(
              userId: widget.registration.volunteerId,
              totalParticipations: 1,
              totalDonations: widget.registration.donationAmount,
            );
            await statsBox.add(userStats);
            print('✅ Created new UserStats');
          } else {
            userStats.addParticipation(widget.registration.donationAmount);
            await userStats.save();
            print('✅ Updated UserStats: ${userStats.totalParticipations} participations, Rp${userStats.totalDonations} donated');
          }

          // ✅ 3. Fetch event terbaru dari API dan sync ke Hive
          print('🔄 Fetching updated event from API...');
          final updatedEventFromAPI = await _eventService.getEventById(widget.event.id);
          if (updatedEventFromAPI != null) {
            await eventBox.put(updatedEventFromAPI.id, updatedEventFromAPI);
            print('✅ Event synced to Hive from API');
            print('   Registered IDs: ${updatedEventFromAPI.registeredVolunteerIds}');
            print('   Current count: ${updatedEventFromAPI.currentVolunteerCount}');
          } else {
            final localEvent = widget.event.copyWith(
              registeredVolunteerIds: [...widget.event.registeredVolunteerIds, widget.registration.volunteerId],
              currentVolunteerCount: widget.event.currentVolunteerCount + 1,
            );
            await eventBox.put(localEvent.id, localEvent);
            print('⚠️ API sync failed, using local data');
          }

          // ✅ 4. Simpan notification history
          final notification = NotificationModel(
            id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
            userId: widget.registration.volunteerId,
            type: 'payment_success',
            title: '✅ Pembayaran Berhasil!',
            message: 'Pembayaran untuk "${widget.event.title}" sebesar ${widget.registration.formattedDonation} telah diproses.',
            relatedEventId: widget.event.id,
            createdAt: DateTime.now(),
            isRead: false,
          );
          await notificationBox.put(notification.id, notification);
          print('✅ Notification saved to history');

          // ✅ 5. Show local notification
          try {
            await _notificationService.showPaymentSuccessNotification(
              eventTitle: widget.event.title,
              amount: widget.registration.donationAmount,
            );
            print('✅ Local notification sent');
          } catch (e) {
            print('⚠️ Notification error: $e');
          }

          _showSuccessDialog();

        } catch (e) {
          print('❌ Error in payment success flow: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
          }
          setState(() => _isProcessing = false);
        }

      } else {
        // Payment failed
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran gagal. Silakan coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Exception: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
              child: Icon(Icons.check_circle, color: Colors.green[600], size: 64),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pembayaran Berhasil!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Terima kasih telah mendaftar sebagai volunteer untuk ${widget.event.title}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.notifications_active, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Notifikasi telah dikirim ke perangkat Anda',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Kembali ke Beranda', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _convertPrice(int priceIDR, String toCurrency) {
    if (toCurrency == 'IDR') return priceIDR.toDouble();
    final rate = _exchangeRates[toCurrency] ?? 1.0;
    return priceIDR / rate;
  }

  String _formatCurrency(double amount, String currency) {
    switch (currency) {
      case 'IDR':
        return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
      case 'USD':
        return '\$${amount.toStringAsFixed(2)}';
      case 'EUR':
        return '€${amount.toStringAsFixed(2)}';
      default:
        return amount.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
        ),
        title: const Text('Konfirmasi Pembayaran',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Konfirmasi Donasi Anda',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            Text('Pastikan semua informasi sudah benar sebelum melanjutkan',
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[100],
                      child: widget.event.imageUrl != null && widget.event.imageUrl!.isNotEmpty
                          ? Image.network(
                              widget.event.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) =>
                                  const Icon(Icons.volunteer_activism, color: Colors.black54, size: 32),
                            )
                          : const Icon(Icons.volunteer_activism, color: Colors.black54, size: 32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.event.title,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(widget.event.organizerName,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Informasi Volunteer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            _buildInfoRow('Nama', widget.registration.volunteerName),
            _buildInfoRow('Email', widget.registration.volunteerEmail),
            _buildInfoRow('Telepon', widget.registration.volunteerPhone),
            const SizedBox(height: 24),
            const Text('Detail Pembayaran',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Jumlah Donasi',
                          style: TextStyle(fontSize: 14, color: Colors.black54)),
                      Text(
                        _formatCurrency(
                          _convertPrice(widget.event.participationFeeIdr, widget.paymentCurrency),
                          widget.paymentCurrency,
                        ),
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[600]),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(Icons.payment, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Metode Pembayaran',
                                style: TextStyle(fontSize: 12, color: Colors.black54)),
                            const SizedBox(height: 2),
                            Text(widget.registration.paymentMethod,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _isProcessing ? null : () => Navigator.pop(context),
                        child: const Text('Ubah'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ✅ TAMPILKAN CURRENCY
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pembayaran dalam ${widget.paymentCurrency} (${widget.paymentCurrency == 'IDR' ? 'Rupiah' : widget.paymentCurrency == 'USD' ? 'Dolar AS' : 'Euro'})',
                            style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Transaksi Aman', style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : const Text('Konfirmasi & Bayar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}