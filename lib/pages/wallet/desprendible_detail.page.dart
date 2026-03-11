import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:vcom_app/core/models/production.model.dart';
import 'package:vcom_app/pages/wallet/wallet.component.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Pantalla de detalle de un desprendible de pago.
class DesprendibleDetailPage extends StatefulWidget {
  final WalletComponent component;
  final String startDate;
  final String endDate;
  final LiquidationRecord? preloadedRecord;

  const DesprendibleDetailPage({
    super.key,
    required this.component,
    required this.startDate,
    required this.endDate,
    this.preloadedRecord,
  });

  @override
  State<DesprendibleDetailPage> createState() => _DesprendibleDetailPageState();
}

class _DesprendibleDetailPageState extends State<DesprendibleDetailPage> {
  bool _loading = true;
  bool _generatingPdf = false;
  String? _error;
  LiquidationDetail? _detail;

  final _fmtCop =
      NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
  final _fmtUsd =
      NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 2);

  static const _monthNames = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final detail = await widget.component
        .fetchDesprendible(widget.startDate, widget.endDate);
    if (mounted) {
      setState(() {
        _loading = false;
        _detail = detail;
        if (detail == null) _error = 'No se pudo cargar el desprendible.';
      });
    }
  }

  String _fmtDate(String raw) {
    try {
      final d = DateTime.parse(raw.length > 10 ? raw.substring(0, 10) : raw);
      final day = d.day.toString().padLeft(2, '0');
      final month = _monthNames[d.month - 1];
      return '$day/$month/${d.year}';
    } catch (_) {
      return raw;
    }
  }

  // ── PDF ──────────────────────────────────────────────────────────────────────

  Future<void> _downloadPdf() async {
    final d = _detail;
    if (d == null) return;
    setState(() => _generatingPdf = true);
    try {
      final pdf = pw.Document();

      final gold = PdfColor.fromHex('#C49A48');
      final dark = PdfColor.fromHex('#0d1525');
      final grey = PdfColor.fromHex('#A0A8B8');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(
            base: await PdfGoogleFonts.robotoRegular(),
            bold: await PdfGoogleFonts.robotoBold(),
          ),
          header: (ctx) => pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: gold, width: 2),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DESPRENDIBLE DE PAGO',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: dark,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'VCOM',
                      style: pw.TextStyle(fontSize: 11, color: grey),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Período: ${_fmtDate(d.periodStart)} – ${_fmtDate(d.periodEnd)}',
                      style: pw.TextStyle(fontSize: 11, color: dark),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'TRM: ${_fmtCop.format(d.trmValue)}  ·  ${_fmtDate(d.trmDate)}',
                      style: pw.TextStyle(fontSize: 10, color: grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          build: (ctx) => [
            pw.SizedBox(height: 16),

            // Resumen USD
            _pdfSection(
              title: 'RESUMEN EN USD',
              gold: gold,
              dark: dark,
              grey: grey,
              rows: [
                _PdfRow('Ganancias', _fmtUsd.format(d.summaryEarningsUsd)),
                _PdfRow('Ajustes', _fmtUsd.format(d.summaryAdjustmentsUsd)),
                _PdfRow('Bonos', _fmtUsd.format(d.summaryBonusUsd)),
                _PdfRow('Total USD', _fmtUsd.format(d.summaryTotalUsd),
                    isTotal: true),
              ],
            ),
            pw.SizedBox(height: 14),

            // Conversión COP
            _pdfSection(
              title: 'CONVERSIÓN A COP  (TRM: ${_fmtCop.format(d.trmValue)})',
              gold: gold,
              dark: dark,
              grey: grey,
              rows: [
                _PdfRow('Ganancias', _fmtCop.format(d.summaryEarningsCop)),
                _PdfRow('Ajustes', _fmtCop.format(d.summaryAdjustmentsCop)),
                _PdfRow('Bonos', _fmtCop.format(d.summaryBonusCop)),
                _PdfRow('Subtotal', _fmtCop.format(d.summaryTotalCop),
                    isTotal: true),
              ],
            ),
            pw.SizedBox(height: 14),

            // Deducciones
            if (d.deductionsCount > 0) ...[
              _pdfSection(
                title: 'DEDUCCIONES (${d.deductionsCount})',
                gold: PdfColors.red700,
                dark: dark,
                grey: grey,
                rows: [
                  ...d.deductions.map((ded) {
                    final name = ded['concept'] as String? ??
                        ded['name'] as String? ?? '—';
                    final amount =
                        (ded['amount_cop'] as num?)?.toDouble() ??
                        (ded['amount'] as num?)?.toDouble() ?? 0.0;
                    return _PdfRow(name, '- ${_fmtCop.format(amount)}',
                        valueColor: PdfColors.red700);
                  }),
                  _PdfRow('Total Deducciones',
                      '- ${_fmtCop.format(d.totalDeductionsCop)}',
                      isTotal: true, valueColor: PdfColors.red700),
                ],
              ),
              pw.SizedBox(height: 14),
            ],

            // Cálculo final
            _pdfSection(
              title: 'CÁLCULO FINAL',
              gold: gold,
              dark: dark,
              grey: grey,
              rows: [
                _PdfRow('Antes de retención',
                    _fmtCop.format(d.beforeRetentionCop)),
                if (d.retentionApplied) ...[
                  _PdfRow(
                    'Retención (${d.retentionPercentage.toStringAsFixed(1)}%)',
                    '- ${_fmtCop.format(d.retentionAmountCop)}',
                    valueColor: PdfColors.red700,
                  ),
                  _PdfRow('Después retención',
                      _fmtCop.format(d.afterRetentionCop)),
                ],
                if (d.bankFeeCop > 0)
                  _PdfRow('Cuota bancaria',
                      '- ${_fmtCop.format(d.bankFeeCop)}',
                      valueColor: PdfColors.red700),
              ],
            ),
            pw.SizedBox(height: 20),

            // Pago final
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: gold,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'PAGO FINAL',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: dark,
                    ),
                  ),
                  pw.Text(
                    _fmtCop.format(d.finalAmountCop),
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: dark,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Text(
                '${d.recordsCount} sesión(es) registrada(s)',
                style: pw.TextStyle(fontSize: 10, color: grey),
              ),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName =
          'desprendible_${widget.startDate}_${widget.endDate}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generando PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  pw.Widget _pdfSection({
    required String title,
    required PdfColor gold,
    required PdfColor dark,
    required PdfColor grey,
    required List<_PdfRow> rows,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            color: PdfColors.grey100,
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: gold,
              ),
            ),
          ),
          ...rows.map(
            (r) => pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.grey200),
                ),
                color: r.isTotal ? PdfColors.grey50 : PdfColors.white,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    r.label,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: r.isTotal
                          ? pw.FontWeight.bold
                          : pw.FontWeight.normal,
                      color: r.isTotal ? dark : grey,
                    ),
                  ),
                  pw.Text(
                    r.value,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: r.isTotal
                          ? pw.FontWeight.bold
                          : pw.FontWeight.normal,
                      color: r.valueColor ??
                          (r.isTotal ? gold : dark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.8),
            radius: 1.4,
            colors: [
              Color(0xFF273C67),
              Color(0xFF1a2847),
              Color(0xFF0d1525),
              Color(0xFF000000),
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(color: Colors.black.withValues(alpha: 0.15)),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Desprendible de Pago',
        style: TextStyle(
          color: VcomColors.blancoCrema,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (_detail != null)
          _generatingPdf
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: VcomColors.oroLujoso,
                    ),
                  ),
                )
              : IconButton(
                  tooltip: 'Descargar PDF',
                  icon: const Icon(Icons.download_outlined,
                      color: VcomColors.oroLujoso),
                  onPressed: _downloadPdf,
                ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: VcomColors.oroLujoso),
      );
    }
    if (_error != null || _detail == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 60, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Error desconocido',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, color: VcomColors.oroLujoso),
              label: const Text('Reintentar',
                  style: TextStyle(color: VcomColors.oroLujoso)),
            ),
          ],
        ),
      );
    }

    final d = _detail!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSlipHeader(d),
            const SizedBox(height: 20),

            _buildSection(
              title: 'Resumen en USD',
              icon: Icons.attach_money,
              rows: [
                _Row('Ganancias', _fmtUsd.format(d.summaryEarningsUsd)),
                _Row('Ajustes', _fmtUsd.format(d.summaryAdjustmentsUsd)),
                _Row('Bonos', _fmtUsd.format(d.summaryBonusUsd)),
                _Row('Total USD', _fmtUsd.format(d.summaryTotalUsd),
                    isTotal: true),
              ],
            ),
            const SizedBox(height: 14),

            _buildSection(
              title: 'Conversión a COP  (TRM: ${_fmtCop.format(d.trmValue)})',
              icon: Icons.currency_exchange,
              rows: [
                _Row('Ganancias', _fmtCop.format(d.summaryEarningsCop)),
                _Row('Ajustes', _fmtCop.format(d.summaryAdjustmentsCop)),
                _Row('Bonos', _fmtCop.format(d.summaryBonusCop)),
                _Row('Subtotal', _fmtCop.format(d.summaryTotalCop),
                    isTotal: true),
              ],
            ),
            const SizedBox(height: 14),

            if (d.deductionsCount > 0) ...[
              _buildSection(
                title: 'Deducciones (${d.deductionsCount})',
                icon: Icons.remove_circle_outline,
                iconColor: Colors.redAccent,
                rows: [
                  ...d.deductions.map((ded) {
                    final name = ded['concept'] as String? ??
                        ded['name'] as String? ?? '—';
                    final amount =
                        (ded['amount_cop'] as num?)?.toDouble() ??
                        (ded['amount'] as num?)?.toDouble() ?? 0.0;
                    return _Row(name, '- ${_fmtCop.format(amount)}',
                        valueColor: Colors.redAccent);
                  }),
                  _Row('Total Deducciones',
                      '- ${_fmtCop.format(d.totalDeductionsCop)}',
                      isTotal: true, valueColor: Colors.redAccent),
                ],
              ),
              const SizedBox(height: 14),
            ],

            _buildSection(
              title: 'Cálculo Final',
              icon: Icons.calculate_outlined,
              rows: [
                _Row('Antes de retención',
                    _fmtCop.format(d.beforeRetentionCop)),
                if (d.retentionApplied) ...[
                  _Row(
                    'Retención (${d.retentionPercentage.toStringAsFixed(1)}%)',
                    '- ${_fmtCop.format(d.retentionAmountCop)}',
                    valueColor: Colors.redAccent,
                  ),
                  _Row('Después retención',
                      _fmtCop.format(d.afterRetentionCop)),
                ],
                if (d.bankFeeCop > 0)
                  _Row('Cuota bancaria', '- ${_fmtCop.format(d.bankFeeCop)}',
                      valueColor: Colors.redAccent),
              ],
            ),
            const SizedBox(height: 14),

            _buildFinalPaymentCard(d.finalAmountCop),
            const SizedBox(height: 16),

            // Botón descarga PDF
            OutlinedButton.icon(
              onPressed: _generatingPdf ? null : _downloadPdf,
              icon: _generatingPdf
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: VcomColors.oroLujoso,
                      ),
                    )
                  : const Icon(Icons.download_outlined,
                      color: VcomColors.oroLujoso, size: 18),
              label: Text(
                _generatingPdf ? 'Generando PDF...' : 'Descargar desprendible',
                style: const TextStyle(
                  color: VcomColors.oroLujoso,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: VcomColors.oroLujoso, width: 1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Center(
              child: Text(
                '${d.recordsCount} sesión(es) registrada(s)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Header del slip ──────────────────────────────────────────────────────────

  Widget _buildSlipHeader(LiquidationDetail d) {
    // Stack + Positioned evita borderRadius con colores no uniformes
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long,
                        color: VcomColors.oroLujoso, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'DESPRENDIBLE DE PAGO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: VcomColors.oroLujoso,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined,
                        size: 13, color: Colors.white54),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Período: ${_fmtDate(d.periodStart)}  –  ${_fmtDate(d.periodEnd)}',
                        style: const TextStyle(
                            fontSize: 13, color: VcomColors.blancoCrema),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.trending_up,
                        size: 13, color: Colors.white54),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'TRM: ${_fmtCop.format(d.trmValue)}  ·  Fecha TRM: ${_fmtDate(d.trmDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Barra dorada izquierda
          const Positioned(
            left: 0, top: 0, bottom: 0,
            child: SizedBox(
              width: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(color: VcomColors.oroLujoso),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sección genérica ─────────────────────────────────────────────────────────

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<_Row> rows,
    Color iconColor = VcomColors.oroLujoso,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0e1a2e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.06), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
          ...rows.asMap().entries.map((entry) {
            final isLast = entry.key == rows.length - 1;
            return _buildRow(entry.value, isLast: isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildRow(_Row row, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.04))),
        color: row.isTotal
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            row.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  row.isTotal ? FontWeight.w600 : FontWeight.w400,
              color: row.isTotal
                  ? VcomColors.blancoCrema
                  : Colors.white.withValues(alpha: 0.65),
            ),
          ),
          Text(
            row.value,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  row.isTotal ? FontWeight.bold : FontWeight.w500,
              color: row.valueColor ??
                  (row.isTotal
                      ? VcomColors.oroLujoso
                      : Colors.white.withValues(alpha: 0.85)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tarjeta pago final ───────────────────────────────────────────────────────

  Widget _buildFinalPaymentCard(double amount) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [VcomColors.bronceDorado, VcomColors.oroLujoso],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: VcomColors.oroLujoso.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PAGO FINAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0d1525).withValues(alpha: 0.8),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Monto a transferir',
                style: TextStyle(fontSize: 12, color: Color(0xFF0d1525)),
              ),
            ],
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _fmtCop.format(amount),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0d1525),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modelos auxiliares ────────────────────────────────────────────────────────

class _Row {
  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;
  const _Row(this.label, this.value, {this.isTotal = false, this.valueColor});
}

class _PdfRow {
  final String label;
  final String value;
  final bool isTotal;
  final PdfColor? valueColor;
  const _PdfRow(this.label, this.value,
      {this.isTotal = false, this.valueColor});
}
