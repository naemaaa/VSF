import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../models/volunteer_registration.dart';
import 'confirm_payment_page.dart';

class PaymentPage extends StatefulWidget {
  final VolunteerRegistration registration;
  final EventModel event;
  final String? selectedCurrency; // ✅ PERBAIKAN: Tambah parameter

  const PaymentPage({
    super.key,
    required this.registration,
    required this.event,
    this.selectedCurrency, // ✅ PERBAIKAN: Terima dari parameter
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? _selectedMethod;
  late String _currentCurrency; // ✅ PERBAIKAN: Gunakan late dan initialize di initState

  @override
  void initState() {
    super.initState();
    // ✅ PERBAIKAN: Initialize currency dari parameter atau default ke IDR
    _currentCurrency = widget.selectedCurrency ?? 'IDR';
    print('💱 PaymentPage initialized with currency: $_currentCurrency');
  }

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

  final Map<String, double> _exchangeRates = {  
    'IDR': 1.0,
    'USD': 15800.0,
    'EUR': 17200.0,
  };

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

    // ✅ PERBAIKAN: Update registration dengan payment method & currency
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
      paymentCurrency: _currentCurrency, // ✅ PERBAIKAN: Gunakan currency yang sudah diinit
    );

    print('💳 Proceeding to confirmation');
    print('   Currency: $_currentCurrency');
    print('   Method: ${_getMethodName(_selectedMethod!)}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmPaymentPage(
          registration: updatedRegistration,
          event: widget.event,
          paymentCurrency: _currentCurrency, // ✅ PERBAIKAN: Pass currency
        ),
      ),
    );
  }

  String _getMethodName(String id) {
    return _paymentMethods.firstWhere((m) => m['id'] == id)['name'];
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
                  _formatCurrency(
                    _convertPrice(widget.event.participationFeeIdr, _currentCurrency),
                    _currentCurrency,
                  ),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                ),
                // ✅ PERBAIKAN: Tampilkan currency yang aktif
                const SizedBox(height: 8),
                Text(
                  _currentCurrency == 'IDR' 
                    ? 'Rupiah Indonesia' 
                    : _currentCurrency == 'USD'
                      ? 'Dolar Amerika'
                      : 'Euro',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
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