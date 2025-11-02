import 'package:hive/hive.dart';

part 'user_stats_model.g.dart';

@HiveType(typeId: 7) // Ganti ke typeId yang belum dipakai
class UserStats extends HiveObject {
  @HiveField(0)
  late String userId;

  @HiveField(1)
  late int totalParticipations;

  @HiveField(2)
  late int totalDonations;

  @HiveField(3)
  late DateTime lastUpdated;

  UserStats({
    required this.userId,
    int? totalParticipations,
    int? totalDonations,
    DateTime? lastUpdated,
  }) {
    this.totalParticipations = totalParticipations ?? 0;
    this.totalDonations = totalDonations ?? 0;
    this.lastUpdated = lastUpdated ?? DateTime.now();
  }

  /// Tambah partisipasi saat user join event
  void addParticipation(int donationAmount) {
    totalParticipations++;
    totalDonations += donationAmount;
    lastUpdated = DateTime.now();
  }

  /// Kurangi partisipasi saat user cancel
  void removeParticipation(int donationAmount) {
    if (totalParticipations > 0) totalParticipations--;
    if (totalDonations >= donationAmount) {
      totalDonations -= donationAmount;
    }
    lastUpdated = DateTime.now();
  }

  /// Format donasi untuk display
  String get formattedDonations {
    return 'Rp ${totalDonations.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
}