import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vcom_app/core/models/event.model.dart';
import 'package:vcom_app/core/models/product.model.dart';
import 'package:vcom_app/pages/dahsboard/dashboard_modelo.component.dart';
import 'package:vcom_app/pages/events/event_detail.page.dart';
import 'package:vcom_app/pages/events/events.page.dart';
import 'package:vcom_app/pages/shop/product_detail.page.dart';
import 'package:vcom_app/pages/shop/shop.page.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Vista del dashboard para rol MODELO
class DashboardModeloView extends StatefulWidget {
  final DashboardModeloComponent component;

  const DashboardModeloView({super.key, required this.component});

  @override
  State<DashboardModeloView> createState() => _DashboardModeloViewState();
}

class _DashboardModeloViewState extends State<DashboardModeloView> {
  Timer? _countdownTimer;
  Duration _countdown = Duration.zero;
  final NumberFormat _fmtCop = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCountdown();
      _startCountdown();
    });
  }

  void _updateCountdown() {
    final event = widget.component.nextEvent;
    if (event == null) {
      _countdown = Duration.zero;
      return;
    }
    final start = _parseEventStart(event);
    if (start == null) {
      _countdown = Duration.zero;
      return;
    }
    final now = DateTime.now();
    if (start.isBefore(now)) {
      _countdown = Duration.zero;
      return;
    }
    setState(() {
      _countdown = start.difference(now);
    });
  }

  DateTime? _parseEventStart(EventModel e) {
    final dateStr = e.startEvent.trim();
    final timeStr = e.startTime.trim();
    if (dateStr.isEmpty) return null;
    final timePart = timeStr.length >= 5 ? timeStr.substring(0, 5) : '09:00';
    return DateTime.tryParse('$dateStr $timePart');
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateCountdown();
        if (_countdown == Duration.zero) _countdownTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatNumber(int n) => n.toString().padLeft(2, '0');

  String _resolveFirstName(DashboardModeloComponent comp) {
    final rawName = (comp.userName ?? '').trim();
    if (rawName.isEmpty) {
      return 'bienvenida';
    }

    return rawName.split(RegExp(r'\s+')).first;
  }

  String _resolveGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Buen dia';
    }
    if (hour < 19) {
      return 'Buenas tardes';
    }
    return 'Buenas noches';
  }

  String _resolveHeaderCopy(DashboardModeloComponent comp) {
    if (comp.nextEvent != null) {
      return 'Tu espacio de hoy ya tiene movimiento. Revisa tu agenda, tus pagos y lo nuevo del estudio.';
    }

    if (comp.liquidatedAmountCop != null) {
      return 'Todo lo importante de tu ritmo de trabajo esta aqui: agenda, pagos y novedades del estudio.';
    }

    return 'Este es tu espacio personal para seguir tu agenda, tus pagos y lo que viene en VCOM.';
  }

  @override
  Widget build(BuildContext context) {
    final comp = widget.component;

    final topInset = MediaQuery.of(context).padding.top;
    final appBarHeight = kToolbarHeight;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return RefreshIndicator(
      onRefresh: () => widget.component.fetchDashboardData(forceRefresh: true),
      color: VcomColors.oroLujoso,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          topInset + appBarHeight + 8,
          20,
          100 + bottomInset,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPersonalHeader(comp),
            const SizedBox(height: 20),
            _buildBalanceCard(comp),
            const SizedBox(height: 24),
            _buildNextEventSection(comp),
            const SizedBox(height: 24),
            _buildNovedadesSection(comp),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalHeader(DashboardModeloComponent comp) {
    final firstName = _resolveFirstName(comp);
    final greeting = _resolveGreeting();
    final today = DateFormat(
      "EEEE d 'de' MMMM",
      'es_CO',
    ).format(DateTime.now());
    final chips = <Widget>[
      _buildHeaderChip(
        Icons.favorite_border,
        comp.nextEvent != null ? 'Agenda activa' : 'Sin agenda cercana',
      ),
      _buildHeaderChip(
        Icons.account_balance_wallet_outlined,
        comp.liquidatedAmountCop != null
            ? 'Saldo actualizado'
            : 'Pago pendiente',
      ),
      _buildHeaderChip(
        Icons.shopping_bag_outlined,
        comp.latestProducts.isNotEmpty
            ? '${comp.latestProducts.length} novedades'
            : 'Tienda disponible',
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                VcomColors.secondaryBlue.withValues(alpha: 0.18),
                Colors.black.withValues(alpha: 0.24),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: VcomColors.oroLujoso.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: VcomColors.oroLujoso.withValues(alpha: 0.28),
                  ),
                ),
                child: Text(
                  'TU HUB VCOM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: VcomColors.oroLujoso,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$greeting, $firstName',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: VcomColors.blancoCrema,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _resolveHeaderCopy(comp),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: VcomColors.blancoCrema.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                today,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.2,
                  color: VcomColors.blancoCrema.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: chips),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: VcomColors.oroLujoso.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: VcomColors.blancoCrema.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(DashboardModeloComponent comp) {
    final amountCop = comp.liquidatedAmountCop;
    final hasAmount = amountCop != null;
    final formatted = hasAmount ? _fmtCop.format(amountCop) : '—';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(28, 24, 24, 24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TU SALDO LIQUIDADO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: VcomColors.oroLujoso,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatted,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: VcomColors.blancoCrema,
                              letterSpacing: -1,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'COP',
                        style: TextStyle(
                          fontSize: 14,
                          color: VcomColors.blancoCrema.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  if (!hasAmount) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Aun no vemos pagos liquidados para ti',
                      style: TextStyle(
                        fontSize: 12,
                        color: VcomColors.blancoCrema.withValues(alpha: 0.55),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    Text(
                      'Este valor refleja tu liquidacion mas reciente.',
                      style: TextStyle(
                        fontSize: 12,
                        color: VcomColors.blancoCrema.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Barra dorada izquierda (evita border con colores no uniformes)
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: VcomColors.oroLujoso),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextEventSection(DashboardModeloComponent comp) {
    final next = comp.nextEvent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.circle, size: 8, color: VcomColors.oroLujoso),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tu agenda',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: VcomColors.blancoCrema,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EventsPage()),
              ),
              child: Text(
                'VER CALENDARIO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 255, 255, 255),
                  letterSpacing: 1,
                  decoration: TextDecoration.underline,
                  decorationColor: VcomColors.primaryPurple.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (next != null) _buildEventCard(next) else _buildEmptyEventCard(),
      ],
    );
  }

  Widget _buildEventCard(EventModel event) {
    final imageUrl = event.imageEvent;
    final statusLabel = _computeEventStatusLabel(event);

    return GestureDetector(
      onTap: () => _openEventDetails(event),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black.withValues(alpha: 0.5),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 144,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholderImage(),
                            )
                          : _buildPlaceholderImage(),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              VcomColors.azulNocheSombra.withValues(alpha: 0.4),
                              VcomColors.azulNocheSombra.withValues(alpha: 0.9),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: VcomColors.secondaryBlue,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            statusLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: VcomColors.blancoCrema,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.titleEvent.isNotEmpty
                                  ? event.titleEvent
                                  : 'Evento programado',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: VcomColors.blancoCrema,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: VcomColors.blancoCrema.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    (event.locationEvent ?? '').isNotEmpty
                                        ? event.locationEvent!
                                        : 'Sin ubicación',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: VcomColors.blancoCrema.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white.withValues(alpha: 0.05),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildCountdownBox(
                            _formatNumber(_countdown.inHours),
                            'HORAS',
                          ),
                          const SizedBox(width: 8),
                          _buildCountdownBox(
                            _formatNumber(_countdown.inMinutes.remainder(60)),
                            'MINUTOS',
                          ),
                          const SizedBox(width: 8),
                          _buildCountdownBox(
                            _formatNumber(_countdown.inSeconds.remainder(60)),
                            'SEGUNDOS',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          'VER DETALLES',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 255, 255, 255),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _computeEventStatusLabel(EventModel event) {
    final start = _parseEventStart(event);
    if (start == null) return 'PRÓXIMAMENTE';
    final now = DateTime.now();
    if (start.isBefore(now)) return 'EN VIVO';
    final diff = start.difference(now);
    if (diff.inHours > 0) return 'EN VIVO EN ${diff.inHours}H';
    if (diff.inMinutes > 0) return 'EN ${diff.inMinutes} MIN';
    return 'EN VIVO';
  }

  Widget _productPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      color: VcomColors.azulNocheSombra,
      child: Icon(
        Icons.image,
        color: VcomColors.oroLujoso.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 144,
      color: VcomColors.azulNocheSombra,
      child: Center(
        child: Icon(
          Icons.event,
          size: 48,
          color: VcomColors.oroLujoso.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildCountdownBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: VcomColors.azulNocheSombra,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: VcomColors.oroLujoso.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9E9E9E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: VcomColors.blancoCrema.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNovedadesSection(DashboardModeloComponent comp) {
    final products = comp.latestProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lo nuevo para ti',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: VcomColors.blancoCrema,
          ),
        ),
        const SizedBox(height: 12),
        if (products.isEmpty)
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShopPage()),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withValues(alpha: 0.5),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.store,
                    color: VcomColors.oroLujoso.withValues(alpha: 0.5),
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Todavia no hay novedades en la tienda para ti',
                      style: TextStyle(
                        fontSize: 14,
                        color: VcomColors.blancoCrema.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: VcomColors.blancoCrema.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          )
        else
          ...products.map(
            (product) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildNovedadCard(product),
            ),
          ),
      ],
    );
  }

  Widget _buildNovedadCard(ProductModel product) {
    final imageUrl = product.images.isNotEmpty
        ? (product.images
              .firstWhere(
                (img) => img.isPrimary,
                orElse: () => product.images.first,
              )
              .imageUrl)
        : null;
    final subtitle = product.category?.nameCategory ?? 'Tienda';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: product),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _productPlaceholder(),
                              )
                            : _productPlaceholder(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.nameProduct,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: VcomColors.blancoCrema,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 10,
                                color: VcomColors.blancoCrema.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: VcomColors.blancoCrema.withValues(alpha: 0.5),
                        size: 24,
                      ),
                    ],
                  ),
                ),
                // Barra dorada izquierda
                const Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: SizedBox(
                    width: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: VcomColors.oroLujoso),
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

  Widget _buildEmptyEventCard() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: VcomColors.azulZafiroProfundo,
          border: Border.all(
            color: VcomColors.oroLujoso.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: VcomColors.oroLujoso.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Por ahora no tienes eventos programados',
              style: TextStyle(
                fontSize: 16,
                color: VcomColors.blancoCrema.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando se asigne algo nuevo, lo veras aqui primero.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: VcomColors.blancoCrema.withValues(alpha: 0.52),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EventsPage()),
              ),
              child: Text(
                'Ir a mi calendario',
                style: TextStyle(
                  color: VcomColors.oroLujoso,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEventDetails(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailPage(event: event)),
    );
  }
}
