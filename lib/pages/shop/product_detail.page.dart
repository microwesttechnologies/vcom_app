import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vcom_app/components/shared/modelo_menubar.dart';
import 'package:vcom_app/components/shared/navbar.component.dart';
import 'package:vcom_app/pages/shop/shop.component.dart';
import 'package:vcom_app/core/models/product.model.dart';
import 'package:vcom_app/style/vcom_colors.dart';
import 'package:intl/intl.dart';

// ── Página completa ─────────────────────────────────────────

class ProductDetailPage extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onBack;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: ModeloNavbar(
        showBackButton: true,
        onBackTap: onBack ?? () => Navigator.of(context).pop(),
      ),
      bottomNavigationBar: const ModeloMenuBar(activeRoute: 'shop'),
      body: ProductDetailBody(product: product),
    );
  }
}

// ── Body reutilizable ───────────────────────────────────────

class ProductDetailBody extends StatefulWidget {
  final ProductModel product;

  const ProductDetailBody({super.key, required this.product});

  @override
  State<ProductDetailBody> createState() => _ProductDetailBodyState();
}

class _ProductDetailBodyState extends State<ProductDetailBody> {
  late ShopComponent _shopComponent;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _shopComponent = ShopComponent();
    _shopComponent.addListener(_onChanged);
  }

  @override
  void dispose() {
    _shopComponent.removeListener(_onChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  String _formatPrice(double price) {
    return NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    ).format(price);
  }

  Future<void> _contactWhatsApp() async {
    try {
      await _shopComponent.contactWhatsApp(widget.product);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.product.images.isNotEmpty
        ? widget.product.images
        : <ProductImageModel>[];

    final categoryName = widget.product.category?.nameCategory ??
        widget.product.brand?.nameBrand ??
        '';

    final hasDesc = widget.product.descriptionProduct?.isNotEmpty == true;

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageH = constraints.maxHeight * 0.52;
        final cardTop = imageH * 0.85;

        return Stack(
          children: [
            // ── Imagen ───────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: imageH,
              child: _buildImageGallery(images),
            ),

            // ── Fondo negro ──────────────────────────
            Positioned(
              top: imageH * 0.95,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(color: Colors.black),
            ),

            // ── Card con efecto vidrio ───────────────
            Positioned(
              top: cardTop,
              left: 14,
              right: 14,
              bottom: 14,
              child: SingleChildScrollView(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                            width: 0.8,
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (categoryName.isNotEmpty)
                              Text(
                                categoryName.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: VcomColors.oroLujoso,
                                  letterSpacing: 1.5,
                                ),
                              ),

                            const SizedBox(height: 8),

                            // Nombre
                            Text(
                              widget.product.nameProduct,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: VcomColors.oroLujoso,
                                height: 1.2,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Precio
                            Text(
                              _formatPrice(widget.product.priceCop),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),

                            if (hasDesc) ...[
                              const SizedBox(height: 16),

                              const Text(
                                'DESCRIPCIÓN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: VcomColors.oroLujoso,
                                  letterSpacing: 1.4,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                widget.product.descriptionProduct!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: Color(0xFFB0B0B0),
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Botón contactar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ClipRect(
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(
                                          241, 191, 39, 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color.fromRGBO(
                                            241, 191, 39, 0.3),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                              alpha: 0.3),
                                          blurRadius: 30,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _contactWhatsApp,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          alignment: Alignment.center,
                                          child: const Text(
                                            'CONTACTAR AL VENDEDOR',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFf1bf27),
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageGallery(List<ProductImageModel> images) {
    if (images.isEmpty) {
      return Container(
        color: const Color(0xFF1a2847),
        child: const Icon(Icons.image_not_supported,
            size: 64, color: Colors.white24),
      );
    }

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (i) => setState(() => _currentImageIndex = i),
      itemCount: images.length,
      itemBuilder: (_, i) => Image.network(
        images[i].imageUrl,
        fit: BoxFit.cover,
      ),
    );
  }
}
