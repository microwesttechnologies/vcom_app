import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vcom_app/components/shared/modelo_menubar.dart';
import 'package:vcom_app/components/shared/navbar.component.dart';
import 'package:vcom_app/core/models/production.model.dart';
import 'package:vcom_app/pages/wallet/desprendible_detail.page.dart';
import 'package:vcom_app/pages/wallet/wallet.component.dart';
import 'package:vcom_app/style/vcom_colors.dart';

// ── Modelo de semana ──────────────────────────────────────────────────────────

class _WeekOption {
  final int number; // SEM 1, SEM 2 ...
  final String startDate; // YYYY-MM-DD
  final String endDate; // YYYY-MM-DD
  final String label; // "SEM 1  07/01/2026 - 13/01/2026"

  const _WeekOption({
    required this.number,
    required this.startDate,
    required this.endDate,
    required this.label,
  });
}

/// Genera semanas de domingo a sábado desde el 1 de enero del año actual
/// hasta la semana actual (inclusive).
List<_WeekOption> _generateWeeks() {
  final now = DateTime.now();
  final fmt = DateFormat('dd/MM/yyyy');
  String fmtIso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // Primer domingo ≥ 1 de enero del año actual
  DateTime cursor = DateTime(now.year, 1, 1);
  // weekday: 1=Lun...7=Dom → avanzar hasta el primer domingo
  if (cursor.weekday != 7) {
    cursor = cursor.add(Duration(days: 7 - cursor.weekday));
  }

  final weeks = <_WeekOption>[];
  int num = 1;

  while (!cursor.isAfter(now)) {
    final saturday = cursor.add(const Duration(days: 6));
    weeks.add(
      _WeekOption(
        number: num,
        startDate: fmtIso(cursor),
        endDate: fmtIso(saturday),
        label: 'SEM $num  ${fmt.format(cursor)} - ${fmt.format(saturday)}',
      ),
    );
    cursor = cursor.add(const Duration(days: 7));
    num++;
  }

  // Más reciente primero
  return weeks.reversed.toList();
}

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late WalletComponent _component;

  // Semanas generadas una sola vez
  late final List<_WeekOption> _weeks;
  _WeekOption? _selectedWeek;
  _WeekOption? _selectedDeductionsWeek; // semana seleccionada en Deducciones

  // Filtros de transmisiones
  String? _filterPlatform; // null = todas
  String? _filterDate; // null = todas  (YYYY-MM-DD)

  // Formateadores de moneda
  final _fmtCop = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );
  final _fmtUsd = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _weeks = _generateWeeks();
    _tabController = TabController(length: 3, vsync: this);
    _component = WalletComponent();
    _component.addListener(_onData);
    _component.fetchWalletData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _component.removeListener(_onData);
    _component.dispose();
    super.dispose();
  }

  void _onData() {
    // Al cargar, pre-seleccionar la semana de la última liquidación
    if (_selectedWeek == null && _component.lastLiquidation != null) {
      final last = _component.lastLiquidation!;
      final match = _weeks.cast<_WeekOption?>().firstWhere(
        (w) => w!.startDate == last.startDate && w.endDate == last.endDate,
        orElse: () => null,
      );
      _selectedWeek = match ?? (_weeks.isNotEmpty ? _weeks.first : null);
      // Deducciones arranca en la misma semana
      _selectedDeductionsWeek ??= _selectedWeek;
    }
    setState(() {});
  }

  // ── Helpers de formato ────────────────────────────────────────────────────────

  String _copAmount(double v) => _fmtCop.format(v);
  String _usdAmount(double v) => _fmtUsd.format(v);

  /// Formatea la fecha de producción: "03/Ene/2026"
  String _fmtDate(String raw) {
    try {
      final d = DateTime.parse(raw.length > 10 ? raw.substring(0, 10) : raw);
      return DateFormat('dd/MMM/yyyy', 'es').format(d);
    } catch (_) {
      return raw;
    }
  }

  static const _monthNames = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  /// Formatea fecha+hora ISO a "11/mar/2026 · 4:40 p.m."
  String _fmtDateTime(String raw) {
    try {
      final d = DateTime.parse(raw).toLocal();
      final day = d.day.toString().padLeft(2, '0');
      final month = _monthNames[d.month - 1];
      final year = d.year;
      final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final min = d.minute.toString().padLeft(2, '0');
      final period = d.hour < 12 ? 'a.m.' : 'p.m.';
      return '$day/$month/$year · $hour:$min $period';
    } catch (_) {
      return raw;
    }
  }

  /// Convierte DateTime a "YYYY-MM-DD"
  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: const ModeloNavbar(),
      bottomNavigationBar: const ModeloMenuBar(activeIndex: 3),
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
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGananciasTab(),
                    _buildDeduccionesTab(),
                    _buildHistorialTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: VcomColors.oroLujoso,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'My wallet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: VcomColors.blancoCrema,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── TabBar ────────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Ganancias'),
          Tab(text: 'Deducciones'),
          Tab(text: 'Historial'),
        ],
        indicatorColor: VcomColors.oroLujoso,
        indicatorWeight: 2,
        labelColor: VcomColors.oroLujoso,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.45),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        dividerColor: Colors.transparent,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // TAB GANANCIAS
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildGananciasTab() {
    if (_component.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: VcomColors.oroLujoso),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _component.fetchWalletData(),
      color: VcomColors.oroLujoso,
      backgroundColor: const Color(0xFF1a2847),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 20),
            // ── Selector de semana ──────────────────────────────────────────
            _buildWeekSelector(),
            const SizedBox(height: 16),
            // ── Stats y transmisiones de la semana seleccionada ─────────────
            _buildSelectedWeekContent(),
          ],
        ),
      ),
    );
  }

  // ── Tarjeta de saldo ──────────────────────────────────────────────────────────

  Widget _buildBalanceCard() {
    final liq =
        _component.selectedWeekLiquidation ?? _component.lastLiquidation;
    final totalCop = _resolveLiquidatedCop(liq);
    final hasValue = totalCop > 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(23, 18, 20, 18),
            decoration: BoxDecoration(
              color: const Color(0xFF0e1a2e),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: VcomColors.oroLujoso.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            'SALDO LIQUIDADO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: VcomColors.oroLujoso,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          // Monto
          Text(
            _copAmount(totalCop),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: VcomColors.blancoCrema,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Etiqueta COP + período
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'COP',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (liq != null) ...[
                Text(
                  '  ·  ${_fmtDate(liq.startDate)} – ${_fmtDate(liq.endDate)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ],
          ),
          if (liq == null && !hasValue) ...[
            const SizedBox(height: 6),
            Text(
              'Sin liquidaciones registradas',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ],
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

  double _resolveLiquidatedCop(LiquidationRecord? liq) {
    // 1) Valor pagado de liquidación (fuente principal)
    if (liq != null && liq.totalCop > 0) {
      return liq.totalCop;
    }

    // 2) Fallback: saldo del endpoint /models/balance
    final balance = _component.balance;
    if (balance != null && balance.amount > 0) {
      final currency = balance.currency.toUpperCase();
      if (currency == 'COP') return balance.amount;
      if (currency == 'USD' && _component.trmValue > 0) {
        return balance.amount * _component.trmValue;
      }
    }

    // 3) Fallback: acumulado de la semana seleccionada convertido a COP
    final weekUsd = _component.selectedWeekProductions.fold<double>(
      0,
      (sum, r) => sum + (r.totalUsd > 0 ? r.totalUsd : r.earningsUsd),
    );
    if (weekUsd > 0 && _component.trmValue > 0) {
      return weekUsd * _component.trmValue;
    }

    return 0.0;
  }

  // ── Selector de semana ────────────────────────────────────────────────────────

  Widget _buildWeekSelector() {
    final selected = _selectedWeek;
    return GestureDetector(
      onTap: _openWeekPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: VcomColors.oroLujoso.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              color: VcomColors.oroLujoso,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selected?.label ?? 'Seleccionar semana...',
                style: TextStyle(
                  fontSize: 13,
                  color: selected != null
                      ? VcomColors.blancoCrema
                      : Colors.white.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: VcomColors.oroLujoso.withValues(alpha: 0.8),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  void _openWeekPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WeekPickerSheet(
        weeks: _weeks,
        selected: _selectedWeek,
        onSelect: (week) {
          setState(() {
            _selectedWeek = week;
            _filterPlatform = null;
            _filterDate = null;
          });
          _component.fetchWeekData(week.startDate, week.endDate);
        },
      ),
    );
  }

  // ── Contenido de la semana seleccionada ───────────────────────────────────────

  Widget _buildSelectedWeekContent() {
    final week = _selectedWeek;

    if (week == null) {
      return _buildNoLiquidationBanner();
    }

    if (_component.isLoadingWeekData) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: VcomColors.oroLujoso),
        ),
      );
    }

    final liq = _component.selectedWeekLiquidation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildTransmisionesSection(liq)],
    );
  }

  Widget _buildNoLiquidationBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 10),
          Text(
            'Aún no hay liquidaciones registradas',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sección Transmisiones ─────────────────────────────────────────────────────

  Widget _buildTransmisionesSection(LiquidationRecord? liq) {
    final all = _component.selectedWeekProductions;

    // Solo registros con valor real (ocultar los que tendrían "—")
    final withValue = all.where((r) => r.totalUsd > 0 || r.earningsUsd > 0).toList();

    // Opciones únicas para los filtros (solo de registros con valor)
    final platforms =
        withValue.map((r) => r.displayName).toSet().toList()..sort();
    final dates =
        withValue
            .map(
              (r) => r.productionDate.length >= 10
                  ? r.productionDate.substring(0, 10)
                  : r.productionDate,
            )
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a)); // más reciente primero

    // Aplicar filtros de plataforma y fecha sobre los que tienen valor
    final filtered = withValue.where((r) {
      final matchPlatform =
          _filterPlatform == null || r.displayName == _filterPlatform;
      final matchDate =
          _filterDate == null || r.productionDate.startsWith(_filterDate!);
      return matchPlatform && matchDate;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Encabezado ────────────────────────────────────────────────────────
        Row(
          children: [
            const Text(
              'Transmisiones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: VcomColors.blancoCrema,
              ),
            ),
            // if (liq != null) ...[
            //   const SizedBox(width: 8),
            //   Container(
            //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            //     decoration: BoxDecoration(
            //       color: VcomColors.oroLujoso.withValues(alpha: 0.15),
            //       borderRadius: BorderRadius.circular(6),
            //       border: Border.all(
            //         color: VcomColors.oroLujoso.withValues(alpha: 0.4),
            //       ),
            //     ),
            //     // child: const Text(
            //     //   'Liquidado',
            //     //   style: TextStyle(
            //     //     fontSize: 10,
            //     //     color: VcomColors.oroLujoso,
            //     //     fontWeight: FontWeight.w600,
            //     //   ),
            //     // ),
            //   ),
            // ],
          ],
        ),
        const SizedBox(height: 10),

        // ── Filtros ───────────────────────────────────────────────────────────
        if (withValue.isNotEmpty)
          Row(
            children: [
              // Filtro plataforma
              Expanded(
                child: _buildFilterDropdown(
                  icon: Icons.device_hub_outlined,
                  hint: 'Plataforma',
                  value: _filterPlatform,
                  items: platforms,
                  onChanged: (v) => setState(() => _filterPlatform = v),
                ),
              ),
              const SizedBox(width: 10),
              // Filtro fecha
              Expanded(
                child: _buildFilterDropdown(
                  icon: Icons.calendar_today_outlined,
                  hint: 'Fecha',
                  value: _filterDate,
                  items: dates,
                  displayBuilder: (v) => _fmtDate(v),
                  onChanged: (v) => setState(() => _filterDate = v),
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),

        // ── Lista filtrada ────────────────────────────────────────────────────
        if (filtered.isEmpty) ...[
          _buildEmptyState(_noValueMessage()),
        ] else
          ...filtered.map((r) => _buildTransmisionItem(r)),
      ],
    );
  }

  /// Mensaje de estado vacío contextual según filtros y datos disponibles.
  String _noValueMessage() {
    if (_filterDate != null && _filterPlatform != null) {
      return 'No hay saldos disponibles en $_filterPlatform para el ${_fmtDate(_filterDate!)}';
    }
    if (_filterDate != null) {
      return 'No hay saldos disponibles para el ${_fmtDate(_filterDate!)}';
    }
    if (_filterPlatform != null) {
      return 'No hay saldos disponibles en $_filterPlatform';
    }
    return 'No hay saldos disponibles para este período';
  }

  /// Combobox genérico para los filtros de transmisiones.
  Widget _buildFilterDropdown({
    required IconData icon,
    required String hint,
    required String? value,
    required List<String> items,
    String Function(String)? displayBuilder,
    required ValueChanged<String?> onChanged,
  }) {
    return GestureDetector(
      onTap: () => _showFilterSheet(
        hint: hint,
        value: value,
        items: items,
        displayBuilder: displayBuilder,
        onChanged: onChanged,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value != null
                ? VcomColors.oroLujoso.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: value != null
                  ? VcomColors.oroLujoso
                  : Colors.white.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value != null
                    ? (displayBuilder != null ? displayBuilder(value) : value)
                    : hint,
                style: TextStyle(
                  fontSize: 12,
                  color: value != null
                      ? VcomColors.blancoCrema
                      : Colors.white.withValues(alpha: 0.35),
                  fontWeight: value != null ? FontWeight.w500 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              )
            else
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.35),
              ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet({
    required String hint,
    required String? value,
    required List<String> items,
    String Function(String)? displayBuilder,
    required ValueChanged<String?> onChanged,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(
        title: hint,
        value: value,
        items: items,
        displayBuilder: displayBuilder,
        onSelect: (v) {
          Navigator.of(context).pop();
          onChanged(v);
        },
      ),
    );
  }

  Widget _buildTransmisionItem(ProductionRecord record) {
    final usdAmount = record.totalUsd > 0
        ? record.totalUsd
        : record.earningsUsd;
    final trm = _component.trmValue > 0 ? _component.trmValue : 0.0;
    final amountCop = trm > 0 ? usdAmount * trm : 0.0;
    final hasAmount = usdAmount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0e1a2e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: VcomColors.blancoCrema,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  _fmtDate(record.productionDate),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                if (record.hoursWorked > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${record.hoursWorked.toStringAsFixed(1)}h',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hasAmount
                    ? (amountCop > 0 ? _copAmount(amountCop) : _usdAmount(usdAmount))
                    : '—',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: hasAmount
                      ? VcomColors.oroLujoso
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
              if (hasAmount && amountCop > 0)
                Text(
                  '\$${usdAmount.toStringAsFixed(2)} USD',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // TAB DEDUCCIONES
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildDeduccionesTab() {
    if (_component.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: VcomColors.oroLujoso),
      );
    }

    final selectedDed = _selectedDeductionsWeek;
    final start = selectedDed?.startDate ?? _fmt(_component.weekStart);
    final end = selectedDed?.endDate ?? _fmt(_component.weekEnd);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Selector de semana ──────────────────────────────────────────────
          GestureDetector(
            onTap: () => _openDeductionsWeekPicker(),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: VcomColors.oroLujoso.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined,
                      color: VcomColors.oroLujoso, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedDed?.label ?? 'Seleccionar semana...',
                      style: TextStyle(
                        fontSize: 13,
                        color: selectedDed != null
                            ? VcomColors.blancoCrema
                            : Colors.white.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      color: VcomColors.oroLujoso.withValues(alpha: 0.8),
                      size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ── Loader de deducciones ───────────────────────────────────────────
          _DeduccionesLoader(
            key: ValueKey('$start-$end'),
            component: _component,
            startDate: start,
            endDate: end,
            fmtCop: _fmtCop,
          ),
        ],
      ),
    );
  }

  void _openDeductionsWeekPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WeekPickerSheet(
        weeks: _weeks,
        selected: _selectedDeductionsWeek,
        onSelect: (week) {
          setState(() => _selectedDeductionsWeek = week);
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // TAB HISTORIAL
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildHistorialTab() {
    if (_component.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: VcomColors.oroLujoso),
      );
    }
    final liquidations = _component.liquidations;
    return RefreshIndicator(
      onRefresh: () => _component.fetchWalletData(),
      color: VcomColors.oroLujoso,
      backgroundColor: const Color(0xFF1a2847),
      child: liquidations.isEmpty
          ? ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              children: [_buildEmptyState('Sin desprendibles registrados')],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              itemCount: liquidations.length,
              itemBuilder: (ctx, i) => _buildLiquidationItem(liquidations[i]),
            ),
    );
  }

  Widget _buildLiquidationItem(LiquidationRecord liq) {
    return GestureDetector(
      onTap: () => _openDesprendible(liq),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0e1a2e),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.07),
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: VcomColors.oroLujoso.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: VcomColors.oroLujoso,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Semana ${_fmtDate(liq.startDate)} – ${_fmtDate(liq.endDate)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: VcomColors.blancoCrema,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Liquidado: ${_fmtDateTime(liq.liquidationDate)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _fmtCop.format(liq.totalCop),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: VcomColors.oroLujoso,
                  ),
                ),
                const SizedBox(height: 2),
                const Icon(
                  Icons.chevron_right,
                  color: VcomColors.oroLujoso,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDesprendible(LiquidationRecord liq) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DesprendibleDetailPage(
          component: _component,
          startDate: liq.startDate,
          endDate: liq.endDate,
          preloadedRecord: liq,
        ),
      ),
    );
  }

  // ── Helpers compartidos ───────────────────────────────────────────────────────


  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget interno: carga y muestra las deducciones de la semana actual ───────

class _DeduccionesLoader extends StatefulWidget {
  final WalletComponent component;
  final String startDate;
  final String endDate;
  final NumberFormat fmtCop;

  const _DeduccionesLoader({
    super.key,
    required this.component,
    required this.startDate,
    required this.endDate,
    required this.fmtCop,
  });

  @override
  State<_DeduccionesLoader> createState() => _DeduccionesLoaderState();
}

class _DeduccionesLoaderState extends State<_DeduccionesLoader> {
  bool _loading = false;
  LiquidationDetail? _detail;
  List<DeductionRecord> _deductions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      widget.component.fetchDesprendible(widget.startDate, widget.endDate),
      widget.component.fetchDeductions(widget.startDate, widget.endDate),
    ]);
    if (mounted) {
      setState(() {
        _loading = false;
        _detail = results[0] as LiquidationDetail?;
        _deductions = results[1] as List<DeductionRecord>;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: VcomColors.oroLujoso),
        ),
      );
    }

    final d = _detail;
    final hasEndpointDeductions = _deductions.isNotEmpty;
    final hasCalcDeductions = d != null && d.deductions.isNotEmpty;

    // Si no hay ningún dato disponible
    if (d == null && !hasEndpointDeductions) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.info_outline,
              size: 48,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              'Sin datos para este período',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Total de deducciones del endpoint
    final endpointTotal = _deductions.fold(
      0.0,
      (sum, r) => sum + r.deductionAmount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Deducciones del endpoint ──────────────────────────────────────────
        if (hasEndpointDeductions) ...[
          const Text(
            'Deducciones',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: VcomColors.blancoCrema,
            ),
          ),
          const SizedBox(height: 10),
          ..._deductions.map((ded) => _buildEndpointDeductionRow(ded)),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Total deducciones',
            widget.fmtCop.format(endpointTotal),
            isNegative: true,
          ),
          const Divider(color: Colors.white12, height: 24),
        ] else if (hasCalcDeductions) ...[
          // Deducciones del calculate-payment si el endpoint no trae nada
          const Text(
            'Deducciones',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: VcomColors.blancoCrema,
            ),
          ),
          const SizedBox(height: 10),
          ...d.deductions.map((ded) => _buildCalcDeductionRow(ded)),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Total deducciones',
            widget.fmtCop.format(d.totalDeductionsCop),
            isNegative: true,
          ),
          const Divider(color: Colors.white12, height: 24),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No hay deducciones para esta semana.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),

        // ── Retención y cuota bancaria (del calculate-payment) ────────────────
        if (d != null) ...[
          if (d.retentionApplied)
            _buildSummaryRow(
              'Retención en la fuente (${d.retentionPercentage.toStringAsFixed(1)}%)',
              widget.fmtCop.format(d.retentionAmountCop),
              isNegative: true,
            ),
          const SizedBox(height: 4),
          _buildSummaryRow(
            'Cuota bancaria',
            widget.fmtCop.format(d.bankFeeCop),
            isNegative: true,
          ),
          const Divider(color: Colors.white12, height: 24),
          _buildSummaryRow(
            'PAGO FINAL',
            widget.fmtCop.format(d.finalAmountCop),
            isBold: true,
            isGold: true,
          ),
        ],
      ],
    );
  }

  Widget _buildEndpointDeductionRow(DeductionRecord ded) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0e1a2e),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.remove_circle_outline,
            size: 14,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ded.deductionName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                if (ded.deductionDetail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    ded.deductionDetail,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '- ${widget.fmtCop.format(ded.deductionAmount)}',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.redAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcDeductionRow(Map<String, dynamic> ded) {
    final name = ded['concept'] as String? ?? ded['name'] as String? ?? '—';
    final amount =
        (ded['amount_cop'] as num?)?.toDouble() ??
        (ded['amount'] as num?)?.toDouble() ??
        0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0e1a2e),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.remove_circle_outline,
            size: 14,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
          Text(
            '- ${widget.fmtCop.format(amount)}',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.redAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isNegative = false,
    bool isBold = false,
    bool isGold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w400,
              color: isGold
                  ? VcomColors.oroLujoso
                  : Colors.white.withValues(alpha: 0.7),
            ),
          ),
          Text(
            isNegative ? '- $value' : value,
            style: TextStyle(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isGold
                  ? VcomColors.oroLujoso
                  : isNegative
                  ? Colors.redAccent
                  : Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Sheet buscador de semanas
// ══════════════════════════════════════════════════════════════════════════════

class _WeekPickerSheet extends StatefulWidget {
  final List<_WeekOption> weeks;
  final _WeekOption? selected;
  final ValueChanged<_WeekOption> onSelect;

  const _WeekPickerSheet({
    required this.weeks,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<_WeekPickerSheet> createState() => _WeekPickerSheetState();
}

class _WeekPickerSheetState extends State<_WeekPickerSheet> {
  late List<_WeekOption> _filtered;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.weeks;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.weeks
          : widget.weeks
                .where((w) => w.label.toLowerCase().contains(q))
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.75;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxH),
          decoration: BoxDecoration(
            color: const Color(0xFF0a1628).withValues(alpha: 0.97),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                color: VcomColors.oroLujoso.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Título ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: VcomColors.oroLujoso,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Semana',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: VcomColors.blancoCrema,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Buscador ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: VcomColors.oroLujoso.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          Icons.search,
                          color: Colors.white.withValues(alpha: 0.45),
                          size: 18,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Buscar semana...',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      // Botón limpiar
                      if (_searchCtrl.text.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Colors.white.withValues(alpha: 0.4),
                            size: 16,
                          ),
                          onPressed: () => _searchCtrl.clear(),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Lista de semanas ───────────────────────────────────────────
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: _filtered.isEmpty ? 1 : _filtered.length,
                  itemBuilder: (ctx, i) {
                    if (_filtered.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Sin resultados',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      );
                    }
                    final week = _filtered[i];
                    final isSelected =
                        widget.selected?.startDate == week.startDate;
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        widget.onSelect(week);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? VcomColors.oroLujoso.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? VcomColors.oroLujoso.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                week.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected
                                      ? VcomColors.oroLujoso
                                      : Colors.white.withValues(alpha: 0.8),
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: VcomColors.oroLujoso,
                                size: 16,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Sheet genérico de filtro (plataforma / fecha)
// ══════════════════════════════════════════════════════════════════════════════

class _FilterSheet extends StatelessWidget {
  final String title;
  final String? value;
  final List<String> items;
  final String Function(String)? displayBuilder;
  final ValueChanged<String?> onSelect;

  const _FilterSheet({
    required this.title,
    required this.value,
    required this.items,
    required this.onSelect,
    this.displayBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.55;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxH),
          decoration: BoxDecoration(
            color: const Color(0xFF0a1628).withValues(alpha: 0.97),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                color: VcomColors.oroLujoso.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Título
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: VcomColors.blancoCrema,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Opción "Todas"
              _FilterItem(
                label: 'Todas',
                isSelected: value == null,
                onTap: () => onSelect(null),
              ),
              const Divider(height: 1, color: Colors.white10),
              // Opciones
              Flexible(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final label = displayBuilder != null
                        ? displayBuilder!(item)
                        : item;
                    return _FilterItem(
                      label: label,
                      isSelected: value == item,
                      onTap: () => onSelect(item),
                    );
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: isSelected
            ? VcomColors.oroLujoso.withValues(alpha: 0.08)
            : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected
                      ? VcomColors.oroLujoso
                      : Colors.white.withValues(alpha: 0.75),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: VcomColors.oroLujoso, size: 16),
          ],
        ),
      ),
    );
  }
}
