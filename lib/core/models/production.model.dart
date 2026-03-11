/// Información de la plataforma de streaming
class ProductionPlatform {
  final int idPlatform;
  final String platformName;
  final String? platformUrl;

  const ProductionPlatform({
    required this.idPlatform,
    required this.platformName,
    this.platformUrl,
  });

  factory ProductionPlatform.fromJson(Map<String, dynamic> json) {
    return ProductionPlatform(
      idPlatform: (json['id_platform'] as num?)?.toInt() ?? 0,
      platformName: json['platform_name'] as String? ?? '',
      platformUrl: json['platform_url'] as String?,
    );
  }
}

/// Registro de producción individual (sesión de transmisión)
class ProductionRecord {
  final int idProduction;
  final String idModel;
  final int idPlatform;
  final double earningsUsd;
  final String productionDate;
  final double adjustmentAmount;
  final double hoursWorked;
  final double bonusUsd;
  final ProductionPlatform? platform;

  const ProductionRecord({
    required this.idProduction,
    required this.idModel,
    required this.idPlatform,
    required this.earningsUsd,
    required this.productionDate,
    required this.adjustmentAmount,
    required this.hoursWorked,
    required this.bonusUsd,
    this.platform,
  });

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is bool) return 0.0;
    final str = value.toString().trim();
    if (str.isEmpty || str == 'null' || str == 'undefined') return 0.0;
    // Eliminar caracteres no numéricos excepto punto, coma y signo
    String s = str.replaceAll(RegExp(r'[^0-9,.\-]'), '');
    if (s.isEmpty) return 0.0;
    final hasComma = s.contains(',');
    final hasDot = s.contains('.');
    if (hasComma && hasDot) {
      s = s.lastIndexOf(',') > s.lastIndexOf('.')
          ? s.replaceAll('.', '').replaceAll(',', '.') // 1.234,56
          : s.replaceAll(',', ''); // 1,234.56
    } else if (hasComma) {
      s = s.replaceAll(',', '.');
    }
    return double.tryParse(s) ?? 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  factory ProductionRecord.fromJson(Map<String, dynamic> json) {
    final platformNode = json['platform'];
    final platformMap = platformNode is Map<String, dynamic>
        ? platformNode
        : <String, dynamic>{
            'id_platform': json['id_platform'],
            'platform_name': json['platform_name'] ?? json['platform'],
            'platform_url': json['platform_url'],
          };

    return ProductionRecord(
      idProduction: _parseInt(json['id_production'] ?? json['id']),
      idModel: json['id_model'] as String? ?? '',
      idPlatform: _parseInt(json['id_platform']),
      earningsUsd: _parseDouble(
        json['earnings_usd'] ??
            json['earning_usd'] ??
            json['earnings'] ??
            json['amount_usd'],
      ),
      productionDate:
          (json['production_date'] ??
                  json['date'] ??
                  json['transmission_date'] ??
                  json['created_at'])
              ?.toString() ??
          '',
      adjustmentAmount: _parseDouble(
        json['adjustment_amount'] ??
            json['adjustments_usd'] ??
            json['adjustment'],
      ),
      hoursWorked: _parseDouble(json['hours_worked'] ?? json['hours']),
      bonusUsd: _parseDouble(json['bonus_usd'] ?? json['bonus']),
      platform: platformMap['platform_name'] != null
          ? ProductionPlatform.fromJson(platformMap)
          : null,
    );
  }

  /// Nombre visible para la transmisión (plataforma o fallback)
  String get displayName =>
      platform?.platformName ?? 'Transmisión #$idProduction';

  /// Ganancias totales en USD (earnings + bonus + adjustment)
  double get totalUsd => earningsUsd + bonusUsd + adjustmentAmount;
}

/// Registro de liquidación (desprendible) pasada
class LiquidationRecord {
  final int idLiquidation;
  final String idModel;
  final String? nameUser;
  final String? nickname;
  final String startDate;
  final String endDate;
  final double totalCop;
  final double trmValue;
  final String liquidationDate;

  const LiquidationRecord({
    required this.idLiquidation,
    required this.idModel,
    this.nameUser,
    this.nickname,
    required this.startDate,
    required this.endDate,
    required this.totalCop,
    required this.trmValue,
    required this.liquidationDate,
  });

  static int _parseInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
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

  factory LiquidationRecord.fromJson(Map<String, dynamic> json) {
    final period = json['period'] is Map<String, dynamic>
        ? json['period'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final finalPayment = json['final_payment'] is Map<String, dynamic>
        ? json['final_payment'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final parsedTrm = _parseDouble(json['trm_value'] ?? json['trm']);
    return LiquidationRecord(
      idLiquidation: _parseInt(json['id_liquidation'] ?? json['id']),
      idModel: json['id_model'] as String? ?? '',
      nameUser: json['name_user'] as String?,
      nickname: json['nickname'] as String?,
      startDate: (json['start_date'] ?? period['start_date'])?.toString() ?? '',
      endDate: (json['end_date'] ?? period['end_date'])?.toString() ?? '',
      totalCop: _parseDouble(
        json['total_cop'] ??
            json['final_amount_cop'] ??
            json['amount_cop'] ??
            json['total'] ??
            finalPayment['final_amount_cop'] ??
            finalPayment['amount_cop'],
      ),
      trmValue: parsedTrm == 0 ? 1.0 : parsedTrm,
      liquidationDate:
          (json['liquidation_date'] ?? json['created_at'])?.toString() ?? '',
    );
  }
}

/// Deducción individual aplicada a un modelo
class DeductionRecord {
  final int idDeduction;
  final String idModel;
  final String deductionName;
  final String deductionDetail;
  final String deductionDate;
  final double deductionAmount;

  const DeductionRecord({
    required this.idDeduction,
    required this.idModel,
    required this.deductionName,
    required this.deductionDetail,
    required this.deductionDate,
    required this.deductionAmount,
  });

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final s = value.toString().trim().replaceAll(RegExp(r'[^0-9,.\-]'), '');
    if (s.isEmpty) return 0.0;
    final hasComma = s.contains(',');
    final hasDot = s.contains('.');
    String n = s;
    if (hasComma && hasDot) {
      n = s.lastIndexOf(',') > s.lastIndexOf('.')
          ? s.replaceAll('.', '').replaceAll(',', '.')
          : s.replaceAll(',', '');
    } else if (hasComma) {
      n = s.replaceAll(',', '.');
    }
    return double.tryParse(n) ?? 0.0;
  }

  factory DeductionRecord.fromJson(Map<String, dynamic> json) {
    return DeductionRecord(
      idDeduction: (json['id_deduction'] as num?)?.toInt() ?? 0,
      idModel: json['id_model'] as String? ?? '',
      deductionName: json['deduction_name'] as String? ?? '—',
      deductionDetail: json['deduction_detail'] as String? ?? '',
      deductionDate:
          (json['deduction_date'] ?? json['created_at'])?.toString() ?? '',
      deductionAmount: _parseDouble(json['deduction_amount']),
    );
  }
}

/// Detalle completo de un desprendible de pago (calculo de liquidación)
class LiquidationDetail {
  // Información del período
  final String idModel;
  final String periodStart;
  final String periodEnd;

  // TRM aplicada
  final double trmValue;
  final String trmDate;

  // Valores originales en USD (bruto)
  final double originalEarningsUsd;
  final double originalAdjustmentsUsd;
  final double originalBonusUsd;
  final double originalTotalUsd;

  // Resumen en USD (puede diferir por redondeos)
  final double summaryEarningsUsd;
  final double summaryAdjustmentsUsd;
  final double summaryBonusUsd;
  final double summaryTotalUsd;

  // Resumen en COP
  final double summaryEarningsCop;
  final double summaryAdjustmentsCop;
  final double summaryBonusCop;
  final double summaryTotalCop;

  // Deducciones
  final double totalDeductionsCop;
  final int deductionsCount;
  final List<Map<String, dynamic>> deductions;

  // Antes de retención
  final double beforeRetentionCop;

  // Retención en la fuente
  final double retentionAmountCop;
  final double retentionPercentage;
  final bool retentionApplied;

  // Después de retención (antes de cuota bancaria)
  final double afterRetentionCop;

  // Cuota bancaria / comisión
  final double bankFeeCop;

  // Pago final
  final double finalAmountCop;
  final int recordsCount;

  const LiquidationDetail({
    required this.idModel,
    required this.periodStart,
    required this.periodEnd,
    required this.trmValue,
    required this.trmDate,
    required this.originalEarningsUsd,
    required this.originalAdjustmentsUsd,
    required this.originalBonusUsd,
    required this.originalTotalUsd,
    required this.summaryEarningsUsd,
    required this.summaryAdjustmentsUsd,
    required this.summaryBonusUsd,
    required this.summaryTotalUsd,
    required this.summaryEarningsCop,
    required this.summaryAdjustmentsCop,
    required this.summaryBonusCop,
    required this.summaryTotalCop,
    required this.totalDeductionsCop,
    required this.deductionsCount,
    required this.deductions,
    required this.beforeRetentionCop,
    required this.retentionAmountCop,
    required this.retentionPercentage,
    required this.retentionApplied,
    required this.afterRetentionCop,
    required this.bankFeeCop,
    required this.finalAmountCop,
    required this.recordsCount,
  });

  factory LiquidationDetail.fromJson(Map<String, dynamic> json) {
    // Estructura real del backend (validada contra settlement.model.ts)
    final period = json['period'] as Map<String, dynamic>? ?? {};
    final trmInfo = json['trm_info'] as Map<String, dynamic>? ?? {};
    final originalValues =
        json['original_values'] as Map<String, dynamic>? ?? {};
    final summaryUsd = json['summary_usd'] as Map<String, dynamic>? ?? {};
    final summaryCop = json['summary_cop'] as Map<String, dynamic>? ?? {};
    // El backend devuelve "deductions_summary", no "deductions"
    final deductionsData =
        json['deductions_summary'] as Map<String, dynamic>? ?? {};
    // Los ítems de deducción individuales pueden venir aparte
    final deductionItems = json['deductions'] as List<dynamic>? ?? [];
    // El backend devuelve "retention_summary", no "retention"
    final retentionData =
        json['retention_summary'] as Map<String, dynamic>? ?? {};
    final beforeRetentionData =
        json['before_retention'] as Map<String, dynamic>? ?? {};
    final afterRetentionData =
        json['after_retention'] as Map<String, dynamic>? ?? {};
    final bankData = json['bank_fee'] as Map<String, dynamic>? ?? {};
    final finalData = json['final_payment'] as Map<String, dynamic>? ?? {};

    return LiquidationDetail(
      idModel: json['id_model'] as String? ?? '',
      // period usa start_date / end_date
      periodStart: period['start_date'] as String? ?? '',
      periodEnd: period['end_date'] as String? ?? '',
      // trm_info usa trm_value / trm_date
      trmValue: (trmInfo['trm_value'] as num?)?.toDouble() ?? 1.0,
      trmDate: trmInfo['trm_date'] as String? ?? '',
      // original_values usa total_earnings_usd, total_adjustments_usd, etc.
      originalEarningsUsd:
          (originalValues['total_earnings_usd'] as num?)?.toDouble() ?? 0.0,
      originalAdjustmentsUsd:
          (originalValues['total_adjustments_usd'] as num?)?.toDouble() ?? 0.0,
      originalBonusUsd:
          (originalValues['total_bonus_usd'] as num?)?.toDouble() ?? 0.0,
      originalTotalUsd:
          (originalValues['grand_total_usd'] as num?)?.toDouble() ?? 0.0,
      // summary_usd mismas claves con prefijo total_ y grand_
      summaryEarningsUsd:
          (summaryUsd['total_earnings_usd'] as num?)?.toDouble() ?? 0.0,
      summaryAdjustmentsUsd:
          (summaryUsd['total_adjustments_usd'] as num?)?.toDouble() ?? 0.0,
      summaryBonusUsd:
          (summaryUsd['total_bonus_usd'] as num?)?.toDouble() ?? 0.0,
      summaryTotalUsd:
          (summaryUsd['grand_total_usd'] as num?)?.toDouble() ?? 0.0,
      // summary_cop mismas claves con prefijo total_ y grand_
      summaryEarningsCop:
          (summaryCop['total_earnings_cop'] as num?)?.toDouble() ?? 0.0,
      summaryAdjustmentsCop:
          (summaryCop['total_adjustments_cop'] as num?)?.toDouble() ?? 0.0,
      summaryBonusCop:
          (summaryCop['total_bonus_cop'] as num?)?.toDouble() ?? 0.0,
      summaryTotalCop:
          (summaryCop['grand_total_cop'] as num?)?.toDouble() ?? 0.0,
      // deductions_summary usa total_deductions_cop / deductions_count
      totalDeductionsCop:
          (deductionsData['total_deductions_cop'] as num?)?.toDouble() ?? 0.0,
      deductionsCount:
          (deductionsData['deductions_count'] as num?)?.toInt() ?? 0,
      deductions: deductionItems.whereType<Map<String, dynamic>>().toList(),
      // before_retention es un objeto con amount_cop
      beforeRetentionCop:
          (beforeRetentionData['amount_cop'] as num?)?.toDouble() ?? 0.0,
      // retention_summary usa retention_amount_cop / retention_percentage
      retentionAmountCop:
          (retentionData['retention_amount_cop'] as num?)?.toDouble() ?? 0.0,
      retentionPercentage:
          (retentionData['retention_percentage'] as num?)?.toDouble() ?? 0.0,
      retentionApplied: retentionData['applied'] as bool? ?? false,
      // after_retention es un objeto con amount_cop
      afterRetentionCop:
          (afterRetentionData['amount_cop'] as num?)?.toDouble() ?? 0.0,
      // bank_fee usa bank_fee_amount_cop
      bankFeeCop: (bankData['bank_fee_amount_cop'] as num?)?.toDouble() ?? 0.0,
      // final_payment usa final_amount_cop
      finalAmountCop:
          (finalData['final_amount_cop'] as num?)?.toDouble() ?? 0.0,
      recordsCount: (json['records_count'] as num?)?.toInt() ?? 0,
    );
  }
}
