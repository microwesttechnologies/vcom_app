import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:vcom_app/core/chat/chat_push.service.dart';
import 'package:vcom_app/core/common/biometric.service.dart';
import 'package:vcom_app/core/common/credentials.service.dart';
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/common/user_status.service.dart';
import 'package:vcom_app/pages/auth/login.page.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Navbar estándar de la app (roles sin diseño especial)
class NavbarComponent extends StatelessWidget implements PreferredSizeWidget {
  const NavbarComponent({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(backgroundColor: VcomColors.azulZafiroProfundo, elevation: 0);
  }
}

/// Navbar glass para el rol MODELO (y cualquier otro rol que lo requiera).
///
/// Parámetros:
/// - [rolLabel]    : etiqueta superior (ej. "MODELO")
/// - [greeting]    : texto de saludo (ej. "Hola, Sofía")
/// - [initial]     : letra del avatar cuando no hay imagen (ej. "S")
/// - [avatarUrl]   : URL de la foto de perfil (opcional)
/// - [onPersonTap] : callback del icono persona
/// - [onHomeTap]   : callback del icono casa
class GlassNavbarComponent extends StatelessWidget
    implements PreferredSizeWidget {
  final String rolLabel;
  final String greeting;
  final String initial;
  final String? avatarUrl;
  final VoidCallback? onPersonTap;
  final VoidCallback? onHomeTap;
  final bool showBackButton;

  const GlassNavbarComponent({
    super.key,
    required this.rolLabel,
    required this.greeting,
    required this.initial,
    this.avatarUrl,
    this.onPersonTap,
    this.onHomeTap,
    this.showBackButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: onHomeTap,
            )
          : null,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          // Avatar con borde degradado
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [VcomColors.primaryPurple, VcomColors.oroLujoso],
              ),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: VcomColors.azulNocheSombra,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      initial,
                      style: const TextStyle(
                        color: VcomColors.oroLujoso,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // Rol + saludo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rolLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: VcomColors.blancoCrema.withValues(alpha: 0.5),
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: VcomColors.blancoCrema,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline, color: Colors.white, size: 26),
          onPressed: onPersonTap,
        ),
        IconButton(
          icon: const Icon(Icons.home_outlined, color: Colors.white, size: 26),
          onPressed: onHomeTap,
        ),
      ],
    );
  }
}

/// Navbar inteligente: muestra `GlassNavbarComponent` para los roles con
/// experiencia visual tipo modelo, o `NavbarComponent` estándar en caso contrario.
///
/// Se auto-configura con los datos del usuario desde `TokenService`.
/// Úsalo en cualquier `Scaffold`:
/// ```dart
/// appBar: const ModeloNavbar(),
/// extendBodyBehindAppBar: true, // necesario para el efecto glass
/// ```
class ModeloNavbar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;

  /// Callback personalizado para el botón atrás.
  /// Si es null y showBackButton es true, usa Navigator.pop().
  final VoidCallback? onBackTap;

  const ModeloNavbar({super.key, this.showBackButton = false, this.onBackTap});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final token = TokenService();
    final role = token.getRole();
    final normalizedRole = role?.toUpperCase() ?? '';
    final usesModeloNavbar =
        normalizedRole == 'MODELO' ||
        normalizedRole == 'MODAL' ||
        normalizedRole == 'MONITOR';

    if (!usesModeloNavbar) {
      return const NavbarComponent();
    }

    final roleLabel = _buildRoleLabel(normalizedRole);
    final fallbackName = normalizedRole == 'MONITOR' ? 'Monitor' : 'Modelo';
    final firstName = _resolveFirstName(token.getUserName(), fallbackName);
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'M';

    return GlassNavbarComponent(
      rolLabel: roleLabel,
      greeting: _buildGreeting(firstName),
      initial: initial,
      showBackButton: showBackButton,
      onPersonTap: () => _showUserMenu(context),
      onHomeTap: showBackButton
          ? (onBackTap ?? () => Navigator.of(context).pop())
          : () => Navigator.of(context).popUntil((route) => route.isFirst),
    );
  }

  // ── Menú emergente del icono persona ──────────────────────────────────────────

  String _buildRoleLabel(String normalizedRole) {
    if (normalizedRole == 'MONITOR') {
      return 'ESPACIO MONITOR';
    }

    return 'ESPACIO MODELO';
  }

  String _buildGreeting(String firstName) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buen dia'
        : hour < 19
        ? 'Buenas tardes'
        : 'Buenas noches';
    return '$greeting, $firstName';
  }

  String _resolveFirstName(String? rawName, String fallbackName) {
    final raw = (rawName ?? '').trim();
    if (raw.isEmpty) return fallbackName;

    final first = raw.split(RegExp(r'\s+')).first.trim();
    if (first.isEmpty) return fallbackName;
    if (first.length == 1) return first.toUpperCase();
    return '${first[0].toUpperCase()}${first.substring(1).toLowerCase()}';
  }

  void _showUserMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserMenuSheet(parentContext: context),
    );
  }
}

// ── Sheet con opciones del usuario ────────────────────────────────────────────

class _UserMenuSheet extends StatefulWidget {
  final BuildContext parentContext;
  const _UserMenuSheet({required this.parentContext});

  @override
  State<_UserMenuSheet> createState() => _UserMenuSheetState();
}

class _UserMenuSheetState extends State<_UserMenuSheet> {
  bool _biometricActive = false;
  bool _loadingBiometric = true;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final active = await CredentialsService().isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricActive = active;
        _loadingBiometric = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = TokenService();
    final normalizedRole = token.getRole()?.toUpperCase() ?? '';
    final roleLabel = normalizedRole == 'MONITOR' ? 'MONITOR' : 'MODELO';
    final fallbackName = normalizedRole == 'MONITOR' ? 'Monitor' : 'Modelo';
    final name = token.getUserName() ?? fallbackName;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0d1525).withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                color: VcomColors.oroLujoso.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador de arrastre
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Info del usuario
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          VcomColors.primaryPurple,
                          VcomColors.oroLujoso,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: VcomColors.azulNocheSombra,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'M',
                        style: const TextStyle(
                          color: VcomColors.oroLujoso,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: VcomColors.blancoCrema,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          roleLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: VcomColors.oroLujoso.withValues(alpha: 0.8),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
              const SizedBox(height: 16),

              // Botón biométrico
              _loadingBiometric
                  ? const SizedBox(height: 48)
                  : SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _onBiometricTap(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _biometricActive
                              ? VcomColors.oroLujoso
                              : Colors.white70,
                          side: BorderSide(
                            color: _biometricActive
                                ? VcomColors.oroLujoso.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.2),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(
                          _biometricActive
                              ? Icons.fingerprint
                              : Icons.fingerprint,
                          size: 20,
                          color: _biometricActive
                              ? VcomColors.oroLujoso
                              : Colors.white38,
                        ),
                        label: Text(
                          _biometricActive
                              ? 'Huella activa  ·  Desactivar'
                              : 'Activar autenticación por huella',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _biometricActive
                                ? VcomColors.oroLujoso
                                : Colors.white60,
                          ),
                        ),
                      ),
                    ),

              const SizedBox(height: 10),

              // Botón cerrar sesión
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _confirmLogout(widget.parentContext);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(
                      color: Colors.redAccent.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text(
                    'Cerrar sesión',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Huella dactilar ────────────────────────────────────────────────────────────

  void _onBiometricTap(BuildContext context) {
    Navigator.of(context).pop(); // cierra este sheet
    if (_biometricActive) {
      _confirmDisableBiometric(widget.parentContext);
    } else {
      _showBiometricSetup(widget.parentContext);
    }
  }

  void _showBiometricSetup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BiometricSetupSheet(
        onActivated: () {
          // Reabrir el menú con estado actualizado
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (_) => _UserMenuSheet(parentContext: context),
          );
        },
      ),
    );
  }

  void _confirmDisableBiometric(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0e1a2e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        title: const Row(
          children: [
            Icon(Icons.fingerprint, color: VcomColors.oroLujoso, size: 22),
            SizedBox(width: 10),
            Text(
              'Desactivar huella',
              style: TextStyle(
                color: VcomColors.blancoCrema,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Deseas desactivar el acceso por huella dactilar?\nDeberás ingresar usuario y contraseña manualmente.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await CredentialsService().disableBiometric();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Autenticación por huella desactivada'),
                    backgroundColor: Color(0xFF1a2847),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: const Text(
              'Desactivar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logout ─────────────────────────────────────────────────────────────────────

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0e1a2e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.redAccent, size: 22),
            SizedBox(width: 10),
            Text(
              'Cerrar sesión',
              style: TextStyle(
                color: VcomColors.blancoCrema,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro que deseas cerrar sesión?',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => _doLogout(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: const Text(
              'Sí, salir',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doLogout(BuildContext context) async {
    Navigator.of(context).pop();
    final tokenService = TokenService();
    final userStatusService = UserStatusService();
    try {
      final url = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.authLogout}',
      );
      await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer ${tokenService.getToken()}',
            },
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
    await ChatPushService().unregisterCurrentDevice();
    await userStatusService.setOffline();
    tokenService.clear();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }
}

// ── Sheet de configuración biométrica ─────────────────────────────────────────

class _BiometricSetupSheet extends StatefulWidget {
  final VoidCallback onActivated;
  const _BiometricSetupSheet({required this.onActivated});

  @override
  State<_BiometricSetupSheet> createState() => _BiometricSetupSheetState();
}

class _BiometricSetupSheetState extends State<_BiometricSetupSheet> {
  final _idController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _idController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
          decoration: BoxDecoration(
            color: const Color(0xFF0d1525).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: VcomColors.oroLujoso.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Icono grande
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VcomColors.oroLujoso.withValues(alpha: 0.1),
                  border: Border.all(
                    color: VcomColors.oroLujoso.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.fingerprint,
                  color: VcomColors.oroLujoso,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),

              // Título
              const Text(
                'Activar acceso por huella',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: VcomColors.blancoCrema,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Ingresa tus credenciales de acceso.\nLa próxima vez solo necesitarás tu huella.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.55),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Campo ID / Correo
              _buildField(
                controller: _idController,
                hint: 'example@email.com',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 12),

              // Campo contraseña
              _buildField(
                controller: _passController,
                hint: 'Contraseña',
                icon: Icons.lock_outline,
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white38,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 16),

              // Error
              if (_errorMsg != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Botón activar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _activate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VcomColors.oroLujoso,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: VcomColors.oroLujoso.withValues(
                      alpha: 0.4,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black54,
                          ),
                        )
                      : const Icon(Icons.fingerprint, size: 20),
                  label: Text(
                    _loading ? 'Verificando...' : 'Activar con huella',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: VcomColors.oroLujoso.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.25),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: VcomColors.oroLujoso.withValues(alpha: 0.5),
            size: 20,
          ),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _activate() async {
    final id = _idController.text.trim();
    final pass = _passController.text;

    if (id.isEmpty || pass.length < 6) {
      setState(
        () => _errorMsg =
            'Completa el ID de usuario y una contraseña válida (mín. 6 caracteres)',
      );
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      // 1. Verificar huella primero (confirmar identidad física)
      bool authenticated = false;
      try {
        authenticated = await BiometricService().authenticate();
      } on PlatformException catch (e) {
        throw Exception(BiometricService.errorMessage(e));
      }

      if (!authenticated) {
        setState(() => _loading = false);
        return; // canceló sin error
      }

      // 2. Guardar credenciales exclusivas de huella (no se sobrescriben con "Recordar credenciales")
      await CredentialsService().saveBiometricCredentials(
        email: id,
        password: pass,
      );
      await CredentialsService().setBiometricEnabled(true);

      if (mounted) {
        Navigator.of(context).pop(); // cierra el setup sheet
        widget.onActivated();

        // Mostrar éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '¡Huella activada! La próxima vez usa tu huella para ingresar.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1B3A2D),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }
}
