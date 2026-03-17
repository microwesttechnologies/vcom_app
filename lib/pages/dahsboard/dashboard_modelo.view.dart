import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vcom_app/core/models/dashboard_modelo.model.dart';
import 'package:vcom_app/pages/dahsboard/dashboard_modelo.component.dart';
import 'package:vcom_app/pages/training/training.page.dart';
import 'package:vcom_app/pages/training/video_player.page.dart';
import 'package:vcom_app/pages/shop/shop.page.dart';
import 'package:vcom_app/core/models/video.model.dart';
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
  Duration _countdown = const Duration(hours: 2, minutes: 14, seconds: 10);
  final NumberFormat _fmtCop = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _countdown.inSeconds > 0) {
        setState(() {
          _countdown = Duration(seconds: _countdown.inSeconds - 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatNumber(int n) => n.toString().padLeft(2, '0');

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
            _buildBalanceCard(comp),
            const SizedBox(height: 24),
            _buildNextTrainingSection(comp),
            const SizedBox(height: 24),
            _buildNovedadesSection(),
          ],
        ),
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
                    'SALDO LIQUIDADO',
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
                      'Sin pagos liquidados registrados',
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

  Widget _buildNextTrainingSection(DashboardModeloComponent comp) {
    final next = comp.nextTraining;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.circle, size: 8, color: VcomColors.oroLujoso),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Próximo Entrenamiento',
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
                MaterialPageRoute(builder: (_) => const TrainingPage()),
              ),
              child: Text(
                'VER TODO',
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
        if (next != null)
          _buildTrainingCard(next)
        else
          _buildEmptyTrainingCard(),
      ],
    );
  }

  Widget _buildTrainingCard(NextTrainingModel next) {
    return GestureDetector(
      onTap: () => _openTrainingDetails(next),
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
                      next.imageUrl != null && next.imageUrl!.isNotEmpty
                          ? Image.network(
                              next.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
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
                            next.status ?? 'EN VIVO EN 2H',
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
                              next.title.isNotEmpty
                                  ? next.title
                                  : 'Sesión de Pasarela Pro',
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
                                  Icons.person_outline,
                                  size: 14,
                                  color: VcomColors.blancoCrema.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Coach Maestro: ${next.coachName ?? 'Julian'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: VcomColors.blancoCrema.withValues(
                                      alpha: 0.8,
                                    ),
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
                          'DETALLES DE LA SESIÓN',
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

  Widget _buildPlaceholderImage() {
    return Container(
      height: 144,
      color: VcomColors.azulNocheSombra,
      child: Center(
        child: Icon(
          Icons.video_library,
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
          border: Border.all(color: VcomColors.oroLujoso.withValues(alpha: 0.2)),
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

  Widget _buildNovedadesSection() {
    final novedades = [
      {
        'title': 'Vestido de novia',
        'subtitle': 'Tienda',
        'imageUrl': 'https://picsum.photos/seed/novia/96',
      },
      {
        'title': 'Inteligencia financiera',
        'subtitle': 'Capacitaciones',
        'imageUrl': 'https://picsum.photos/seed/finanzas/96',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Novedades',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: VcomColors.blancoCrema,
          ),
        ),
        const SizedBox(height: 12),
        ...novedades.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildNovedadCard(
              item['title']!,
              item['subtitle']!,
              item['imageUrl']!,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNovedadCard(String title, String subtitle, String imageUrl) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShopPage()),
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
                        child: Image.network(
                          imageUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 48,
                            height: 48,
                            color: VcomColors.azulNocheSombra,
                            child: Icon(
                              Icons.image,
                              color: VcomColors.oroLujoso.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
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

  Widget _buildEmptyTrainingCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: VcomColors.azulZafiroProfundo,
        border: Border.all(color: VcomColors.oroLujoso.withValues(alpha: 0.2)),
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
            'No hay entrenamientos programados',
            style: TextStyle(
              fontSize: 16,
              color: VcomColors.blancoCrema.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TrainingPage()),
            ),
            child: Text(
              'Ver entrenamientos disponibles',
              style: TextStyle(
                color: VcomColors.oroLujoso,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openTrainingDetails(NextTrainingModel next) {
    if (next.imageUrl == null || next.imageUrl!.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TrainingPage()),
      );
      return;
    }
    final video = VideoModel(
      idVideo: next.id,
      titleVideo: next.title,
      urlSource: next.imageUrl!,
      idUser: '',
      categoryVideo: null,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoPlayerPage(video: video)),
    );
  }
}
