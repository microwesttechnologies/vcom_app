/// Modelo de saldo del modelo
class ModelBalanceModel {
  final double amount;
  final String currency;

  ModelBalanceModel({required this.amount, this.currency = 'USD'});

  factory ModelBalanceModel.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) {
        String sanitized = value.replaceAll(RegExp(r'[^0-9,.-]'), '').trim();
        if (sanitized.isEmpty) return 0.0;

        final hasComma = sanitized.contains(',');
        final hasDot = sanitized.contains('.');
        if (hasComma && hasDot) {
          if (sanitized.lastIndexOf(',') > sanitized.lastIndexOf('.')) {
            // 1.234,56 -> 1234.56
            sanitized = sanitized.replaceAll('.', '').replaceAll(',', '.');
          } else {
            // 1,234.56 -> 1234.56
            sanitized = sanitized.replaceAll(',', '');
          }
        } else if (hasComma) {
          sanitized = sanitized.replaceAll(',', '.');
        }

        return double.tryParse(sanitized) ?? 0.0;
      }
      return 0.0;
    }

    final rawAmount =
        json['balance'] ??
        json['amount'] ??
        json['saldo'] ??
        json['total_cop'] ??
        json['final_amount_cop'] ??
        json['amount_cop'] ??
        0;
    final amount = parseAmount(rawAmount);

    final rawCurrency = (json['currency'] ?? json['currency_code'])?.toString();
    final currency = (rawCurrency != null && rawCurrency.trim().isNotEmpty)
        ? rawCurrency.toUpperCase()
        : (json.containsKey('total_cop') ||
              json.containsKey('final_amount_cop') ||
              json.containsKey('amount_cop'))
        ? 'COP'
        : 'USD';

    return ModelBalanceModel(amount: amount, currency: currency);
  }
}

/// Modelo de próximo entrenamiento
class NextTrainingModel {
  final int id;
  final String title;
  final String? coachName;
  final String? imageUrl;
  final DateTime? scheduledAt;
  final String? status; // EN VIVO EN 2H, etc.

  NextTrainingModel({
    required this.id,
    required this.title,
    this.coachName,
    this.imageUrl,
    this.scheduledAt,
    this.status,
  });

  factory NextTrainingModel.fromJson(Map<String, dynamic> json) {
    return NextTrainingModel(
      id: json['id'] as int? ?? json['id_video'] as int? ?? 0,
      title:
          json['title'] as String? ??
          json['title_video'] as String? ??
          json['name'] as String? ??
          '',
      coachName:
          json['coach_name'] as String? ??
          json['coach'] as String? ??
          json['id_user']?.toString(),
      imageUrl: json['image_url'] as String? ?? json['url_source'] as String?,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'] as String)
          : null,
      status: json['status'] as String? ?? 'EN VIVO EN 2H',
    );
  }

  /// Crea desde VideoModel para usar como fallback
  factory NextTrainingModel.fromVideo(Map<String, dynamic> videoJson) {
    return NextTrainingModel(
      id: videoJson['id_video'] as int? ?? 0,
      title: videoJson['title_video'] as String? ?? '',
      coachName: null,
      imageUrl: videoJson['url_source'] as String?,
      scheduledAt: null,
      status: 'EN VIVO EN 2H',
    );
  }
}
