import 'package:flutter/material.dart';
import 'login.component.dart';
import '../../components/commons/label.component.dart';
import '../../components/commons/button.dart';
import '../../components/commons/check.component.dart';
import 'package:vcom_app/style/vcom_colors.dart';
import '../dahsboard/dashboard.page.dart';
import 'package:vcom_app/core/common/user_status.service.dart';

/// Página de login
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late final LoginComponent _loginComponent;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loginComponent = LoginComponent();
    
    // Escuchar cambios en el componente de login
    _loginComponent.addListener(_onLoginComponentChanged);
    
    // Cargar credenciales guardadas
    _loginComponent.initialize().then((_) {
      if (mounted) {
        setState(() {
          // Actualizar el estado para reflejar las credenciales cargadas
        });
      }
    });
    
    // Configurar animación de fade in
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // Iniciar la animación
    _animationController.forward();
  }

  void _onLoginComponentChanged() {
    if (mounted) {
      setState(() {
        // Actualizar cuando cambie el estado del componente
      });
    }
  }

  @override
  void dispose() {
    _loginComponent.removeListener(_onLoginComponentChanged);
    _animationController.dispose();
    _loginComponent.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_loginComponent.validateFields()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingrese un correo y contraseña válidos'),
        ),
      );
      return;
    }

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _loginComponent.performLogin();

      // Activar presencia global después de login exitoso
      await UserStatusService().setOnline();
      
      // Cerrar el diálogo de carga
      if (mounted) {
        Navigator.of(context).pop();
        
        // Navegar al dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardPage(),
          ),
        );
      }
    } catch (e) {
      // Cerrar el diálogo de carga
      if (mounted) {
        Navigator.of(context).pop();
        
        // Extraer mensaje de error más legible
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        
        // Mostrar mensaje de error con mejor formato
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: VcomColors.gradienteNocturno,
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Logo centrado en la parte superior
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        'assets/image/VCOM_G_PNG.png',
                        width: size.width * 0.8,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Espaciador flexible para empujar el formulario hacia abajo
                  const SizedBox(height: 20),

                  // Campo de correo
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: LabelComponent(
                          label: 'Correo',
                          size: LabelSize.medium,
                          fontWeight: FontWeight.w600,
                          color: VcomColors.oroBrillante,
                        ),
                      ),
                      TextFormField(
                        controller: _loginComponent.emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(
                          color: VcomColors.blancoCrema,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ingrese su correo electrónico',
                          hintStyle: TextStyle(
                            color: VcomColors.blancoCrema.withOpacity(0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: VcomColors.oroLujoso,
                          ),
                          filled: true,
                          fillColor: VcomColors.azulOverlayTransparente60,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: VcomColors.oroLujoso.withOpacity(0.3),
                              width: 1.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: VcomColors.oroLujoso.withOpacity(0.3),
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: VcomColors.oroBrillante,
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20.0),

                  // Campo de contraseña
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: LabelComponent(
                          label: 'Contraseña',
                          size: LabelSize.medium,
                          fontWeight: FontWeight.w600,
                          color: VcomColors.oroBrillante,
                        ),
                      ),
                      TextFormField(
                        controller: _loginComponent.passwordController,
                        obscureText: _loginComponent.obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        style: TextStyle(
                          color: VcomColors.blancoCrema,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ingrese su contraseña',
                          hintStyle: TextStyle(
                            color: VcomColors.blancoCrema.withOpacity(0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outlined,
                            color: VcomColors.oroLujoso,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _loginComponent.obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: VcomColors.oroLujoso,
                            ),
                            onPressed: () {
                              setState(() {
                                _loginComponent.togglePasswordVisibility();
                              });
                            },
                          ),
                          filled: true,
                          fillColor: VcomColors.azulOverlayTransparente60,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: VcomColors.oroLujoso.withOpacity(0.3),
                              width: 1.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: VcomColors.oroLujoso.withOpacity(0.3),
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: VcomColors.oroBrillante,
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24.0),

                  // Botón de iniciar sesión
                  ButtonComponent(
                    label: 'Iniciar sesión',
                    size: ButtonSize.large,
                    width: double.infinity,
                    color: VcomColors.oroLujoso,
                    textColor: VcomColors.azulMedianocheTexto,
                    onPressed: _handleLogin,
                  ),

                  const SizedBox(height: 16.0),

                  // Checkbox de recordar credenciales
                  CheckComponent(
                    label: 'Recordar credenciales',
                    size: CheckSize.medium,
                    isChecked: _loginComponent.rememberCredentials,
                    color: VcomColors.oroLujoso,
                    textColor: VcomColors.oroBrillante,
                    onChanged: (value) {
                      setState(() {
                        _loginComponent.toggleRememberCredentials();
                      });
                    },
                  ),

                  // Espacio inferior
                  SizedBox(height: size.height * 0.1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

