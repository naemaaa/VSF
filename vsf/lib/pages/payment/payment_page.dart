import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../models/volunteer_registration.dart';
import 'confirm_payment_page.dart';

class PaymentPage extends StatefulWidget {
  final VolunteerRegistration registration;
  final EventModel event;
  final String? selectedCurrency;

  const PaymentPage({
    super.key,
    required this.registration,
    required this.event,
    this.selectedCurrency,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}


class _PaymentPageState extends State<PaymentPage> {
  String? _selectedMethod;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'kartu_kredit',
      'name': 'Kartu Kredit/Debit',
      'icon': Icons.credit_card,
      'color': Colors.blue,
    },
    {
      'id': 'bca_va',
      'name': 'BCA Virtual Account',
      'icon': Icons.account_balance,
      'color': Colors.blue[800],
    },
    {
      'id': 'mandiri_va',
      'name': 'Mandiri Virtual Account',
      'icon': Icons.account_balance,
      'color': Colors.blue[700],
    },
    {
      'id': 'bni_va',
      'name': 'BNI Virtual Account',
      'icon': Icons.account_balance,
      'color': Colors.orange[800],
    },
    {
      'id': 'gopay',
      'name': 'GoPay',
      'icon': Icons.payments,
      'color': Colors.green[600],
    },
    {
      'id': 'ovo',
      'name': 'OVO',
      'icon': Icons.payments,
      'color': Colors.purple,
    },
    {
      'id': 'dana',
      'name': 'DANA',
      'icon': Icons.payments,
      'color': Colors.blue[400],
    },
  ];

    void _proceedToConfirmation() {
      if (_selectedMethod == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan pilih metode pembayaran'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

    // Update registration dengan payment method
    final updatedRegistration = VolunteerRegistration(
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
      paymentMethod: _getMethodName(_selectedMethod!),
      isPaid: false,
      paymentCurrency: _currentCurrency,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmPaymentPage(
          registration: updatedRegistration,
          event: widget.event,
          paymentCurrency: _currentCurrency,
        ),
      ),
    );
  }

  String _getMethodName(String id) {
    return _paymentMethods.firstWhere((m) => m['id'] == id)['name'];
  }


late String _currentCurrency;  
final Map<String, double> _exchangeRates = {  
  'IDR': 1.0,
  'USD': 15800.0,
  'EUR': 17200.0,
};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Metode Pembayaran',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Total Donasi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.blue[50],
            child: Column(
              children: [
                const Text(
                  'Total Donasi',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.event.formattedPrice,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kartu Kredit/Debit
                  const Text(
                    'Kartu Kredit/Debit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentTile(_paymentMethods[0]),
                  const SizedBox(height: 24),

                  // Transfer Virtual Account
                  const Text(
                    'Transfer Virtual Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentTile(_paymentMethods[1]),
                  const SizedBox(height: 8),
                  _buildPaymentTile(_paymentMethods[2]),
                  const SizedBox(height: 8),
                  _buildPaymentTile(_paymentMethods[3]),
                  const SizedBox(height: 24),

                  // E-Wallet
                  const Text(
                    'E-Wallet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentTile(_paymentMethods[4]),
                  const SizedBox(height: 8),
                  _buildPaymentTile(_paymentMethods[5]),
                  const SizedBox(height: 8),
                  _buildPaymentTile(_paymentMethods[6]),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _proceedToConfirmation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Lanjutkan Pembayaran',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentTile(Map<String, dynamic> method) {
    final isSelected = _selectedMethod == method['id'];

    return GestureDetector(
      onTap: () {
        setState(() => _selectedMethod = method['id']);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.blue[50] : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: method['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                method['icon'],
                color: method['color'],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                method['name'],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.blue[600], size: 24)
            else
              Icon(Icons.circle_outlined, color: Colors.grey[400], size: 24),
          ],
        ),
      ),
    );
  }
}