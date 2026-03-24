class PlatformRecord {
  final int idPlatform;
  final String platformName;

  PlatformRecord({required this.idPlatform, required this.platformName});

  factory PlatformRecord.fromJson(Map<String, dynamic> json) {
    return PlatformRecord(
      idPlatform: json['id_platform'] as int,
      platformName: json['platform_name'] as String? ?? '',
    );
  }
}

class PlatformEntry {
  final int idPlatform;
  final String platformName;
  final String username;

  PlatformEntry({
    required this.idPlatform,
    required this.platformName,
    required this.username,
  });

  Map<String, dynamic> toJson() => {
        'id_platform': idPlatform,
        'username': username,
      };
}

class ModelRegisterPayload {
  final String fullName;
  final String? artisticName;
  final String documentNumber;
  final String birthDate;
  final String residenceCity;
  final String? address;
  final String phone;
  final String email;
  final String? socialUsername;
  final String? profilePhoto;
  final String? bank;
  final String? bankAccount;
  final String? experienceTime;
  final String? modelType;
  final int? weeklyHours;
  final double? weeklyGoalUsd;
  final List<PlatformEntry> platformUsernames;
  final bool dataAuthorization;
  final bool financeConfidentialAck;
  final bool commitTruth;
  final String password;
  final String? quickNote;

  ModelRegisterPayload({
    required this.fullName,
    this.artisticName,
    required this.documentNumber,
    required this.birthDate,
    required this.residenceCity,
    this.address,
    required this.phone,
    required this.email,
    this.socialUsername,
    this.profilePhoto,
    this.bank,
    this.bankAccount,
    this.experienceTime,
    this.modelType,
    this.weeklyHours,
    this.weeklyGoalUsd,
    required this.platformUsernames,
    required this.dataAuthorization,
    required this.financeConfidentialAck,
    required this.commitTruth,
    required this.password,
    this.quickNote,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'full_name': fullName,
      'document_number': documentNumber,
      'birth_date': birthDate,
      'residence_city': residenceCity,
      'phone': phone,
      'email': email,
      'data_authorization': dataAuthorization,
      'finance_confidential_ack': financeConfidentialAck,
      'commit_truth': commitTruth,
      'password': password,
    };
    if (artisticName != null && artisticName!.isNotEmpty) {
      data['artistic_name'] = artisticName;
    }
    if (address != null && address!.isNotEmpty) data['address'] = address;
    if (socialUsername != null && socialUsername!.isNotEmpty) {
      data['social_username'] = socialUsername;
    }
    if (profilePhoto != null && profilePhoto!.isNotEmpty) {
      data['profile_photo'] = profilePhoto;
    }
    if (bank != null && bank!.isNotEmpty) data['bank'] = bank;
    if (bankAccount != null && bankAccount!.isNotEmpty) {
      data['bank_account'] = bankAccount;
    }
    if (experienceTime != null && experienceTime!.isNotEmpty) {
      data['experience_time'] = experienceTime;
    }
    if (modelType != null && modelType!.isNotEmpty) {
      data['model_type'] = modelType;
    }
    if (weeklyHours != null) data['weekly_hours'] = weeklyHours;
    if (weeklyGoalUsd != null) data['weekly_goal_usd'] = weeklyGoalUsd;
    if (platformUsernames.isNotEmpty) {
      data['platform_usernames'] =
          platformUsernames.map((p) => p.toJson()).toList();
    }
    if (quickNote != null && quickNote!.isNotEmpty) {
      data['quick_note'] = quickNote;
    }
    return data;
  }
}
