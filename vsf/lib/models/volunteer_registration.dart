import 'package:hive/hive.dart';

part 'volunteer_registration.g.dart';

@HiveType(typeId: 3)
class VolunteerRegistration {
  @HiveField(0)
  String id;

  @HiveField(1)
  String eventId;

  @HiveField(2)
  String volunteerId;

  @HiveField(3)
  String volunteerName;

  @HiveField(4)
  String volunteerEmail;

  @HiveField(5)
  String volunteerPhone;

  @HiveField(6)
  String? volunteerNik;

  @HiveField(7)
  DateTime birthDate;

  @HiveField(8)
  bool agreementNonRefundable; // Agreement for non-refundable registration

  @HiveField(9)
  String motivation; // Motivasi singkat kenapa tertarik

  @HiveField(10)
  int donationAmount; // Jumlah donasi dalam IDR

  @HiveField(11)
  String paymentMethod; // "GoPay", "OVO", "DANA", "BCA VA", "Mandiri VA", "BNI VA", "Kartu Kredit"

  @HiveField(12)
  bool isPaid;

  @HiveField(13)
  DateTime registeredAt;

  @HiveField(14)
  String? feedbackMessage; // Kesan & Pesan setelah event selesai

  @HiveField(15)
  DateTime? feedbackSubmittedAt;

  @HiveField(16)
  String paymentCurrency; 

  VolunteerRegistration({
    required this.id,
    required this.eventId,
    required this.volunteerId,
    required this.volunteerName,
    required this.volunteerEmail,
    required this.volunteerPhone,
    this.volunteerNik,
    required this.birthDate,
    required this.agreementNonRefundable,
    required this.motivation,
    required this.donationAmount,
    required this.paymentMethod,
    this.isPaid = false,
    DateTime? registeredAt,
    this.feedbackMessage,
    this.feedbackSubmittedAt,
    this.paymentCurrency = 'IDR',
  }) : registeredAt = registeredAt ?? DateTime.now();

  // Check apakah sudah submit feedback
  bool get hasFeedback => feedbackMessage != null && feedbackMessage!.isNotEmpty;

  // Format tanggal lahir untuk display
  String get formattedBirthDate {
    return '${birthDate.day}/${birthDate.month}/${birthDate.year}';
  }

  // Hitung umur volunteer
  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Status pembayaran untuk display
  String get paymentStatus {
    return isPaid ? 'Sudah Dibayar' : 'Belum Dibayar';
  }

  // Format donasi untuk display
  String get formattedDonation {
    return 'Rp ${donationAmount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]}.'
    )}';
  }

  // Untuk debugging
  @override
  String toString() {
    return 'VolunteerRegistration(id: $id, name: $volunteerName, eventId: $eventId, isPaid: $isPaid)';
  }
}