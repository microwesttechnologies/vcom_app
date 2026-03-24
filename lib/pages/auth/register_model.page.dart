import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vcom_app/core/auth/register/register_model.service.dart';
import 'package:vcom_app/core/common/media_upload.service.dart';
import 'package:vcom_app/core/models/model_register.model.dart';
import 'package:vcom_app/style/vcom_colors.dart';

class RegisterModelPage extends StatefulWidget {
  const RegisterModelPage({super.key});

  @override
  State<RegisterModelPage> createState() => _RegisterModelPageState();
}

class _RegisterModelPageState extends State<RegisterModelPage> {
  final PageController _pageController = PageController();
  final RegisterModelService _service = RegisterModelService();
  final MediaUploadService _mediaUploadService = MediaUploadService();

  int _currentStep = 0;
  bool _loading = false;
  bool _success = false;
  bool _platformsLoading = false;
  bool _photoLoading = false;
  List<PlatformRecord> _platforms = [];
  File? _profilePhotoFile;
  String? _profilePhotoDataUrl;

  // ---------- Step 1: Datos Personales ----------
  final _fullNameCtrl = TextEditingController();
  final _artisticNameCtrl = TextEditingController();
  final _documentCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _socialUsernameCtrl = TextEditingController();

  // ---------- Step 2: Banco ----------
  final _bankCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();

  // ---------- Step 3: Información Laboral ----------
  final _experienceCtrl = TextEditingController();
  String? _selectedModelType;
  final _weeklyHoursCtrl = TextEditingController();
  final _weeklyGoalCtrl = TextEditingController();
  final List<PlatformEntry> _platformEntries = [];
  PlatformRecord? _newPlatformSelected;
  final _newPlatformUsernameCtrl = TextEditingController();

  // ---------- Step 4: Acceso & Compromisos ----------
  final _passwordCtrl = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool? _dataAuthorization;
  bool? _financeConfidentialAck;
  bool _commitTruth = false;

  // ---------- Errors per step ----------
  String _step1Error = '';
  String _step3Error = '';
  String _step4Error = '';
  String _submitError = '';
  String _platformsError = '';
  String _photoError = '';

  @override
  void initState() {
    super.initState();
    _loadPlatforms();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameCtrl.dispose();
    _artisticNameCtrl.dispose();
    _documentCtrl.dispose();
    _birthDateCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _socialUsernameCtrl.dispose();
    _bankCtrl.dispose();
    _bankAccountCtrl.dispose();
    _experienceCtrl.dispose();
    _weeklyHoursCtrl.dispose();
    _weeklyGoalCtrl.dispose();
    _newPlatformUsernameCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPlatforms() async {
    setState(() {
      _platformsLoading = true;
      _platformsError = '';
    });

    try {
      final list = await _service.getPlatforms();
      if (!mounted) return;
      setState(() {
        _platforms = list;
        _platformsLoading = false;
        _platformsError = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _platforms = [];
        _platformsLoading = false;
        _platformsError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _showProfilePhotoSourcePicker() async {
    final fromCamera = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1628),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: VcomColors.oroLujoso,
                ),
                title: const Text(
                  'Galeria',
                  style: TextStyle(color: VcomColors.blancoCrema),
                ),
                onTap: () => Navigator.of(context).pop(false),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: VcomColors.oroLujoso,
                ),
                title: const Text(
                  'Camara',
                  style: TextStyle(color: VcomColors.blancoCrema),
                ),
                onTap: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );
      },
    );

    if (fromCamera == null) return;
    await _pickProfilePhoto(fromCamera: fromCamera);
  }

  Future<void> _pickProfilePhoto({required bool fromCamera}) async {
    setState(() {
      _photoLoading = true;
      _photoError = '';
    });

    try {
      final file = await _mediaUploadService.pickImage(fromCamera: fromCamera);
      if (!mounted || file == null) return;

      final encodedPhoto = await _encodeProfilePhoto(file);
      if (!mounted) return;

      setState(() {
        _profilePhotoFile = file;
        _profilePhotoDataUrl = encodedPhoto;
        _photoError = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _photoError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _photoLoading = false);
      }
    }
  }

  Future<String> _encodeProfilePhoto(File file) async {
    final bytes = await file.readAsBytes();
    const maxBytes = 5 * 1024 * 1024;

    if (bytes.length > maxBytes) {
      throw Exception(
        'La foto no debe superar los 5MB para enviarla con la solicitud.',
      );
    }

    final mimeType = _resolveProfilePhotoMimeType(file.path);
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  String _resolveProfilePhotoMimeType(String path) {
    final normalized = path.toLowerCase();
    if (normalized.endsWith('.png')) return 'image/png';
    if (normalized.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = step);
  }

  // ─── Validation ─────────────────────────────────────────────────────────────

  bool _validateStep1() {
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (_fullNameCtrl.text.trim().length < 3) {
      setState(
        () => _step1Error =
            'El nombre completo debe tener al menos 3 caracteres.',
      );
      return false;
    }
    if (_documentCtrl.text.trim().length < 5) {
      setState(
        () =>
            _step1Error = 'Número de documento inválido (mínimo 5 caracteres).',
      );
      return false;
    }
    if (_birthDateCtrl.text.isEmpty) {
      setState(() => _step1Error = 'La fecha de nacimiento es obligatoria.');
      return false;
    }
    if (_cityCtrl.text.trim().isEmpty) {
      setState(() => _step1Error = 'La ciudad de residencia es obligatoria.');
      return false;
    }
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(phone)) {
      setState(
        () => _step1Error = 'Número de celular inválido (10–15 dígitos).',
      );
      return false;
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _step1Error = 'Correo electrónico inválido.');
      return false;
    }
    setState(() => _step1Error = '');
    return true;
  }

  bool _validateStep4() {
    if (_passwordCtrl.text.length < 8) {
      setState(
        () => _step4Error = 'La contraseña debe tener al menos 8 caracteres.',
      );
      return false;
    }
    if (_passwordCtrl.text != _passwordConfirmCtrl.text) {
      setState(() => _step4Error = 'Las contraseñas no coinciden.');
      return false;
    }
    if (_dataAuthorization == null) {
      setState(() => _step4Error = 'Debe responder la autorización de datos.');
      return false;
    }
    if (_financeConfidentialAck == null) {
      setState(
        () => _step4Error = 'Debe aceptar la confidencialidad financiera.',
      );
      return false;
    }
    if (!_commitTruth) {
      setState(
        () => _step4Error = 'Debe confirmar que la información es verídica.',
      );
      return false;
    }
    setState(() => _step4Error = '');
    return true;
  }

  // ─── Platform helpers ────────────────────────────────────────────────────────

  List<PlatformRecord> get _availablePlatforms {
    final usedIds = _platformEntries.map((e) => e.idPlatform).toSet();
    return _platforms.where((p) => !usedIds.contains(p.idPlatform)).toList();
  }

  void _addPlatform() {
    final p = _newPlatformSelected;
    final username = _newPlatformUsernameCtrl.text.trim();
    if (p == null || username.isEmpty) {
      setState(
        () => _step3Error = 'Selecciona una plataforma e ingresa el usuario.',
      );
      return;
    }
    setState(() {
      _platformEntries.add(
        PlatformEntry(
          idPlatform: p.idPlatform,
          platformName: p.platformName,
          username: username,
        ),
      );
      _newPlatformSelected = null;
      _newPlatformUsernameCtrl.clear();
      _step3Error = '';
    });
  }

  void _removePlatform(int index) {
    setState(() => _platformEntries.removeAt(index));
  }

  // ─── Date picker ─────────────────────────────────────────────────────────────

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year - 16, now.month, now.day),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFd4af37),
            onPrimary: Colors.black,
            surface: Color(0xFF1a2847),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _birthDateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // ─── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_validateStep4()) return;
    setState(() {
      _loading = true;
      _submitError = '';
    });

    final payload = ModelRegisterPayload(
      fullName: _fullNameCtrl.text.trim(),
      artisticName: _artisticNameCtrl.text.trim(),
      documentNumber: _documentCtrl.text.trim(),
      birthDate: _birthDateCtrl.text.trim(),
      residenceCity: _cityCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      socialUsername: _socialUsernameCtrl.text.trim(),
      profilePhoto: _profilePhotoDataUrl,
      bank: _bankCtrl.text.trim(),
      bankAccount: _bankAccountCtrl.text.trim(),
      experienceTime: _experienceCtrl.text.trim(),
      modelType: _selectedModelType,
      weeklyHours: int.tryParse(_weeklyHoursCtrl.text.trim()),
      weeklyGoalUsd: double.tryParse(_weeklyGoalCtrl.text.trim()),
      platformUsernames: List.from(_platformEntries),
      dataAuthorization: _dataAuthorization!,
      financeConfidentialAck: _financeConfidentialAck!,
      commitTruth: _commitTruth,
      password: _passwordCtrl.text,
    );

    try {
      await _service.registerModel(payload);
      if (mounted) {
        setState(() {
          _loading = false;
          _success = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _submitError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.8),
              radius: 1.2,
              colors: [
                Color(0xFF273C67),
                Color(0xFF1a2847),
                Color(0xFF0d1525),
                Color(0xFF000000),
              ],
              stops: [0.0, 0.35, 0.7, 1.0],
            ),
          ),
          child: SafeArea(child: _success ? _buildSuccess() : _buildForm()),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFFd4af37),
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              '¡Solicitud enviada!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFd4af37),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tu solicitud de membresía ha sido recibida con éxito.\nUn administrador revisará tu información y te contactará pronto.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.75),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            _buildGoldButton(
              label: 'Volver al inicio',
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        _buildHeader(),
        _buildStepIndicator(),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStep1(),
              _buildStep2(),
              _buildStep3(),
              _buildStep4(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_currentStep > 0) {
                _goToStep(_currentStep - 1);
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Solicitar Membresía',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _stepTitle(_currentStep),
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFFd4af37).withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _stepTitle(int step) {
    const titles = [
      'Paso 1 de 4 · Datos Personales',
      'Paso 2 de 4 · Información Bancaria',
      'Paso 3 de 4 · Información Laboral',
      'Paso 4 de 4 · Acceso y Compromisos',
    ];
    return titles[step];
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = i <= _currentStep;
          final isCurrent = i == _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isCurrent ? 4 : 3,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFd4af37)
                          : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                if (i < 3) const SizedBox(width: 6),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── STEP 1: Datos Personales ────────────────────────────────────────────────

  Widget _buildStep1() {
    return _buildScrollStep(
      children: [
        _buildSectionTitle('Datos del Modelo'),
        _buildProfilePhotoPicker(),
        _buildField(
          controller: _fullNameCtrl,
          label: 'Nombre completo *',
          hint: 'Ej: Ana María García',
          icon: Icons.person_outline,
        ),
        _buildField(
          controller: _artisticNameCtrl,
          label: 'Nombre artístico',
          hint: 'Ej: AnaMarie',
          icon: Icons.star_outline,
        ),
        _buildField(
          controller: _documentCtrl,
          label: 'Número de documento *',
          hint: 'Ej: 1098765432',
          icon: Icons.badge_outlined,
          keyboardType: TextInputType.number,
        ),
        _buildDateField(),
        _buildField(
          controller: _cityCtrl,
          label: 'Ciudad de residencia *',
          hint: 'Ej: Bogotá',
          icon: Icons.location_city_outlined,
        ),
        _buildField(
          controller: _addressCtrl,
          label: 'Dirección',
          hint: 'Ej: Calle 10 #5-20',
          icon: Icons.home_outlined,
        ),
        _buildField(
          controller: _phoneCtrl,
          label: 'Número de celular *',
          hint: 'Ej: 3001234567',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        _buildField(
          controller: _emailCtrl,
          label: 'Correo electrónico *',
          hint: 'tu@email.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        _buildField(
          controller: _socialUsernameCtrl,
          label: 'Usuario en redes sociales',
          hint: 'Ej: @ana_garcia',
          icon: Icons.alternate_email,
        ),
        if (_step1Error.isNotEmpty) _buildErrorBanner(_step1Error),
        const SizedBox(height: 8),
        _buildGoldButton(
          label: 'Siguiente',
          onTap: () {
            if (_validateStep1()) _goToStep(1);
          },
        ),
      ],
    );
  }

  // ─── STEP 2: Banco ──────────────────────────────────────────────────────────

  Widget _buildStep2() {
    return _buildScrollStep(
      children: [
        _buildSectionTitle('Información Bancaria'),
        Text(
          'Esta información es opcional y solo se usará para el pago de tus producciones.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.5),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildField(
          controller: _bankCtrl,
          label: 'Banco',
          hint: 'Ej: Bancolombia',
          icon: Icons.account_balance_outlined,
        ),
        _buildField(
          controller: _bankAccountCtrl,
          label: 'Número de cuenta',
          hint: 'Ej: 1234567890',
          icon: Icons.credit_card_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildOutlineButton(
                label: 'Anterior',
                onTap: () => _goToStep(0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGoldButton(
                label: 'Siguiente',
                onTap: () => _goToStep(2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── STEP 3: Información Laboral ─────────────────────────────────────────────

  Widget _buildStep3() {
    return _buildScrollStep(
      children: [
        _buildSectionTitle('Información Laboral'),
        _buildField(
          controller: _experienceCtrl,
          label: 'Tiempo de experiencia',
          hint: 'Ej: 2 años',
          icon: Icons.history_outlined,
        ),
        _buildDropdown(
          label: 'Tipo de modelo',
          value: _selectedModelType,
          items: const ['Satelite', 'Fambase', 'Ambas'],
          labels: const ['Satélite', 'Fambase', 'Ambas'],
          icon: Icons.category_outlined,
          onChanged: (v) => setState(() => _selectedModelType = v),
        ),
        _buildField(
          controller: _weeklyHoursCtrl,
          label: 'Horas promedio semanales',
          hint: 'Ej: 20',
          icon: Icons.schedule_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        _buildField(
          controller: _weeklyGoalCtrl,
          label: 'Meta semanal en USD',
          hint: 'Ej: 500',
          icon: Icons.attach_money_outlined,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 8),
        _buildSectionTitle('Plataformas'),
        Text(
          'Agrega las plataformas en las que trabajas.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 12),
        if (_platformsLoading)
          _buildInfoBanner('Cargando plataformas disponibles…')
        else
          _platforms.isEmpty
              ? _buildInfoBanner(
                  'No hay plataformas disponibles en este momento.',
                )
              : _buildPlatformAdder(),
        if (_platformsError.isNotEmpty) ...[
          _buildErrorBanner(_platformsError),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _loadPlatforms,
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Color(0xFFd4af37), fontSize: 14),
              ),
            ),
          ),
        ],
        if (_platformEntries.isNotEmpty) _buildPlatformList(),
        if (_step3Error.isNotEmpty) _buildErrorBanner(_step3Error),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildOutlineButton(
                label: 'Anterior',
                onTap: () => _goToStep(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGoldButton(
                label: 'Siguiente',
                onTap: () {
                  setState(() => _step3Error = '');
                  _goToStep(3);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlatformAdder() {
    final available = _availablePlatforms;
    return Column(
      children: [
        _buildDropdown(
          label: 'Selecciona plataforma',
          value: _newPlatformSelected?.idPlatform.toString(),
          items: available.map((p) => p.idPlatform.toString()).toList(),
          labels: available.map((p) => p.platformName).toList(),
          icon: Icons.devices_outlined,
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _newPlatformSelected = available.firstWhere(
                (p) => p.idPlatform.toString() == v,
              );
            });
          },
        ),
        _buildField(
          controller: _newPlatformUsernameCtrl,
          label: 'Tu usuario en la plataforma',
          hint: 'Ej: ana_model',
          icon: Icons.person_pin_outlined,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _addPlatform,
            icon: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFFd4af37),
              size: 20,
            ),
            label: const Text(
              'Agregar plataforma',
              style: TextStyle(color: Color(0xFFd4af37), fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformList() {
    return Column(
      children: [
        const SizedBox(height: 4),
        ...List.generate(_platformEntries.length, (i) {
          final entry = _platformEntries[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFd4af37).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.devices_outlined,
                  color: Color(0xFFd4af37),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.platformName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        entry.username,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _removePlatform(i),
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── STEP 4: Acceso & Compromisos ────────────────────────────────────────────

  Widget _buildStep4() {
    return _buildScrollStep(
      children: [
        _buildSectionTitle('Acceso a la App'),
        _buildField(
          controller: _passwordCtrl,
          label: 'Contraseña *',
          hint: 'Mínimo 8 caracteres',
          icon: Icons.lock_outline,
          obscure: _obscurePassword,
          suffix: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.white.withValues(alpha: 0.35),
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        _buildField(
          controller: _passwordConfirmCtrl,
          label: 'Confirmar contraseña *',
          hint: '••••••••',
          icon: Icons.lock_outline,
          obscure: _obscureConfirm,
          suffix: IconButton(
            icon: Icon(
              _obscureConfirm
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.white.withValues(alpha: 0.35),
              size: 20,
            ),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        const SizedBox(height: 8),
        _buildSectionTitle('Compromisos'),
        _buildYesNoField(
          label:
              '¿Autoriza el uso de sus datos para fines internos del estudio? *',
          value: _dataAuthorization,
          onChanged: (v) => setState(() => _dataAuthorization = v),
        ),
        const SizedBox(height: 12),
        _buildYesNoField(
          label:
              '¿Acepta que la información financiera es confidencial y de uso exclusivo personal? *',
          value: _financeConfidentialAck,
          onChanged: (v) => setState(() => _financeConfidentialAck = v),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => _commitTruth = !_commitTruth),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _commitTruth
                  ? const Color(0xFFd4af37).withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _commitTruth
                    ? const Color(0xFFd4af37).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _commitTruth,
                  onChanged: (v) => setState(() => _commitTruth = v ?? false),
                  activeColor: const Color(0xFFd4af37),
                  checkColor: Colors.black,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Declaro que toda la información suministrada es verídica y acepto los términos de uso de la plataforma VCOM. *',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_step4Error.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildErrorBanner(_step4Error),
        ],
        if (_submitError.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildErrorBanner(_submitError),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOutlineButton(
                label: 'Anterior',
                onTap: () => _goToStep(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _loading
                  ? const Center(
                      child: SizedBox(
                        height: 48,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFd4af37),
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    )
                  : _buildGoldButton(label: 'Enviar solicitud', onTap: _submit),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Reusable widgets ────────────────────────────────────────────────────────

  Widget _buildScrollStep({required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildProfilePhotoPicker() {
    final hasPhoto = _profilePhotoFile != null && _profilePhotoDataUrl != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Foto de perfil',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Opcional. Agrega una foto para que el equipo te identifique mejor.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _photoLoading ? null : _showProfilePhotoSourcePicker,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFd4af37).withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFd4af37).withValues(alpha: 0.3),
                      ),
                    ),
                    child: ClipOval(
                      child: hasPhoto
                          ? Image.file(
                              _profilePhotoFile!,
                              fit: BoxFit.cover,
                              width: 74,
                              height: 74,
                            )
                          : Container(
                              color: Colors.white.withValues(alpha: 0.04),
                              child: Icon(
                                Icons.person_outline,
                                color: Colors.white.withValues(alpha: 0.3),
                                size: 32,
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
                          hasPhoto
                              ? 'Foto lista para tu solicitud'
                              : 'Agrega tu foto desde galeria o camara',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hasPhoto
                              ? 'Si quieres, puedes cambiarla antes de enviar.'
                              : 'Una foto clara ayuda a que tu perfil se reconozca mas rapido.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _photoLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Color(0xFFd4af37),
                          ),
                        )
                      : Icon(
                          hasPhoto
                              ? Icons.edit_outlined
                              : Icons.add_a_photo_outlined,
                          color: const Color(0xFFd4af37),
                          size: 20,
                        ),
                ],
              ),
            ),
          ),
          if (hasPhoto) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _photoLoading
                    ? null
                    : () {
                        setState(() {
                          _profilePhotoFile = null;
                          _profilePhotoDataUrl = null;
                          _photoError = '';
                        });
                      },
                child: const Text(
                  'Quitar foto',
                  style: TextStyle(color: Color(0xFFd4af37), fontSize: 14),
                ),
              ),
            ),
          ],
          if (_photoError.isNotEmpty) _buildErrorBanner(_photoError),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFFd4af37),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFd4af37).withValues(alpha: 0.15),
              ),
            ),
            child: TextFormField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  icon,
                  color: const Color(0xFFd4af37).withValues(alpha: 0.5),
                  size: 20,
                ),
                suffixIcon: suffix,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fecha de nacimiento *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickBirthDate,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFd4af37).withValues(alpha: 0.15),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.cake_outlined,
                    color: const Color(0xFFd4af37).withValues(alpha: 0.5),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _birthDateCtrl.text.isEmpty
                          ? 'Seleccionar fecha'
                          : _birthDateCtrl.text,
                      style: TextStyle(
                        color: _birthDateCtrl.text.isEmpty
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required List<String> labels,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFd4af37).withValues(alpha: 0.15),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: items.contains(value) ? value : null,
                isExpanded: true,
                dropdownColor: const Color(0xFF1a2847),
                icon: Icon(
                  Icons.expand_more,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 20,
                ),
                hint: Row(
                  children: [
                    Icon(
                      icon,
                      color: const Color(0xFFd4af37).withValues(alpha: 0.5),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Seleccionar',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                items: List.generate(items.length, (i) {
                  return DropdownMenuItem<String>(
                    value: items[i],
                    child: Text(
                      labels[i],
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  );
                }),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYesNoField({
    required String label,
    required bool? value,
    required ValueChanged<bool> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.75),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildRadioOption(
              label: 'Sí',
              selected: value == true,
              onTap: () => onChanged(true),
            ),
            const SizedBox(width: 12),
            _buildRadioOption(
              label: 'No',
              selected: value == false,
              onTap: () => onChanged(false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRadioOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFd4af37).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? const Color(0xFFd4af37).withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.12),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFFd4af37) : Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: VcomColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: VcomColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: VcomColors.error.withValues(alpha: 0.8),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                color: VcomColors.error.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        msg,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildGoldButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFd4af37).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFd4af37).withValues(alpha: 0.35),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              splashColor: const Color(0xFFd4af37).withValues(alpha: 0.2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFd4af37),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
