import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../models/volunteer_registration.dart';
import '../../services/event_service.dart';
import '../payment/payment_page.dart';

class RegisterVolunteerPage extends StatefulWidget {
  final EventModel event;
  final UserModel currentUser;

  const RegisterVolunteerPage({
    super.key,
    required this.event,
    required this.currentUser,
  });

  @override
  State<RegisterVolunteerPage> createState() => _RegisterVolunteerPageState();
}

class _RegisterVolunteerPageState extends State<RegisterVolunteerPage> {
  final EventService _eventService = EventService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _motivationController = TextEditingController();
  DateTime? _selectedBirthDate;
  bool _agreementChecked = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentUser.displayName;
    _emailController.text = widget.currentUser.email;
    _phoneController.text = widget.currentUser.phone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _motivationController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[600]!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  Future<void> _proceedToPayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreementChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan setujui ketentuan pendaftaran terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih tanggal lahir'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      print('📝 Creating registration...');
      
      // Buat registration object
      final registration = VolunteerRegistration(
        id: 'reg_${DateTime.now().millisecondsSinceEpoch}',
        eventId: widget.event.id,
        volunteerId: widget.currentUser.id,
        volunteerName: _nameController.text.trim(),
        volunteerEmail: _emailController.text.trim(),
        volunteerPhone: _phoneController.text.trim(),
        volunteerNik: widget.currentUser.nik ?? '',
        birthDate: _selectedBirthDate!,
        motivation: _motivationController.text.trim(),
        registeredAt: DateTime.now(),
        isPaid: false,
        donationAmount: widget.event.participationFeeIdr,
        paymentMethod: '',
        agreementNonRefundable: _agreementChecked,
      );

      // Save to Hive dulu (sementara)
      final regBox = Hive.box<VolunteerRegistration>('registrations');
      await regBox.put(registration.id, registration);
      print('✅ Registration saved to Hive');

      if (mounted) {
        setState(() => _isProcessing = false);
        
        // Navigate to payment
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentPage(
              registration: registration,
              event: widget.event,
            ),
          ),
        );

        // ⬅️ JIKA PAYMENT BERHASIL, UPDATE API
        if (result == true && mounted) {
          print('💳 Payment successful, updating API...');
          
          // Update registration status
          registration.isPaid = true;
          await regBox.put(registration.id, registration);

          // Update event via API
          final success = await _eventService.incrementVolunteerCount(
            widget.event.id,
            widget.currentUser.id,
          );

          if (success) {
            print('✅ API updated successfully!');
            if (mounted) {
              Navigator.pop(context, true); // Return true ke activity_detail
            }
          } else {
            print('⚠️ API update failed');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pendaftaran berhasil tapi gagal sinkronisasi. Silakan hubungi admin.'),
                  backgroundColor: Colors.orange,
                ),
              );
              Navigator.pop(context, true);
            }
          }
        } else {
          // Payment dibatalkan, hapus registrasi sementara
          await regBox.delete(registration.id);
          print('❌ Payment cancelled, registration deleted');
        }
      }
    } catch (e) {
      print('❌ Error in registration: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        title: const Text(
          'Formulir Pendaftaran',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _isProcessing,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[600],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.volunteer_activism,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.event.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.event.formattedEventDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Isi data di bawah ini untuk bergabung dalam kegiatan volunteer',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),

                // Nama Lengkap
                const Text(
                  'Nama Lengkap',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama lengkap Anda',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Alamat Email
                const Text(
                  'Alamat Email',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'contoh@email.com',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!value.contains('@')) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Nomor Telepon
                const Text(
                  'Nomor Telepon',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '08123456789',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nomor telepon tidak boleh kosong';
                    }
                    if (value.length < 10) {
                      return 'Nomor telepon tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Tanggal Lahir
                const Text(
                  'Tanggal Lahir',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectBirthDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[50],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _selectedBirthDate != null
                              ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                              : 'mm/dd/yyyy',
                          style: TextStyle(
                            fontSize: 14,
                            color: _selectedBirthDate != null
                                ? Colors.black87
                                : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Agreement Checkbox
                const Text(
                  'Ketersediaan Anda',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _agreementChecked,
                  onChanged: (value) {
                    setState(() => _agreementChecked = value ?? false);
                  },
                  title: const Text(
                    'Saya menyetujui bahwa biaya pendaftaran yang telah dibayarkan tidak dapat dikembalikan',
                    style: TextStyle(fontSize: 14),
                  ),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  checkColor: Colors.white,
                  activeColor: Colors.blue[600],
                ),
                const SizedBox(height: 20),

                // Motivasi Singkat
                const Text(
                  'Motivasi Singkat (Mengapa Anda tertarik?)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _motivationController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Ceritakan motivasi Anda bergabung dalam kegiatan ini...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Motivasi tidak boleh kosong';
                    }
                    if (value.length < 20) {
                      return 'Motivasi minimal 20 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Donation Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.event.isFree ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.event.isFree
                          ? Colors.green[100]!
                          : Colors.orange[100]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        color: widget.event.isFree ? Colors.green[600] : Colors.orange[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jumlah Donasi',
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.event.isFree
                                    ? Colors.green[600]
                                    : Colors.orange[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.event.formattedPrice,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: widget.event.isFree
                                    ? Colors.green[600]
                                    : Colors.orange[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _proceedToPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: Colors.grey[400],
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Lanjut ke Pembayaran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}