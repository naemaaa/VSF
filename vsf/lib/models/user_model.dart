// user_model.dart
import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
enum UserType {
  @HiveField(0)
  individual,
  @HiveField(1)
  organization,
}

@HiveType(typeId: 1)
class UserModel extends HiveObject {
  @HiveField(0)
  String id; // UID dari Supabase

  @HiveField(1)
  String email;

  @HiveField(2)
  String passwordHash; // Disimpan lokal di Hive

  @HiveField(3)
  UserType userType;

  // Untuk Individu
  @HiveField(4)
  String? fullName;

  @HiveField(5)
  String? nik; // Nomor Induk Kependudukan

  // Untuk Organisasi
  @HiveField(6)
  String? organizationName;

  @HiveField(7)
  String? npwp; // Nomor Pokok Wajib Pajak

  @HiveField(8)
  String? phone;

  @HiveField(9)
  String? bio;

  @HiveField(10)
  String? profileImagePath;

  @HiveField(11)
  DateTime createdAt;
  
  // Tambahan untuk lokasi individu
  @HiveField(12)
  double? latitude;
  
  @HiveField(13)
  double? longitude;

  UserModel({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.userType,
    this.fullName,
    this.nik,
    this.organizationName,
    this.npwp,
    this.phone,
    this.bio,
    this.profileImagePath,
    this.latitude,
    this.longitude,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // ==================== GETTERS ====================

  String get displayName {
    if (userType == UserType.individual) {
      return fullName ?? 'User';
    } else {
      return organizationName ?? 'Organization';
    }
  }

  String? get identityNumber {
    if (userType == UserType.individual) {
      return nik;
    } else {
      return npwp;
    }
  }

  String get identityLabel {
    if (userType == UserType.individual) {
      return 'NIK';
    } else {
      return 'NPWP';
    }
  }

  bool get isOrganization => userType == UserType.organization;
  bool get isIndividual => userType == UserType.individual;

  String get formattedJoinDate {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}';
  }

  String get initials {
    final name = displayName;
    final parts = name.split(' ');
    
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  String get formattedPhone {
    if (phone == null || phone!.isEmpty) return '-';
    
    String formatted = phone!.replaceAll(RegExp(r'[^\d]'), '');
    
    if (formatted.startsWith('62')) {
      formatted = '0${formatted.substring(2)}';
    }
    
    if (formatted.length >= 11) {
      return '${formatted.substring(0, 4)}-${formatted.substring(4, 8)}-${formatted.substring(8)}';
    }
    
    return phone!;
  }

  // ==================== METHODS ====================

  void updateProfile({
    String? fullName,
    String? organizationName,
    String? phone,
    String? bio,
    String? profileImagePath,
  }) {
    if (userType == UserType.individual && fullName != null) {
      this.fullName = fullName;
    }
    if (userType == UserType.organization && organizationName != null) {
      this.organizationName = organizationName;
    }
    if (phone != null) this.phone = phone;
    if (bio != null) this.bio = bio;
    if (profileImagePath != null) this.profileImagePath = profileImagePath;
    
    save(); // Save ke Hive
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $displayName, type: $userType)';
  }
}