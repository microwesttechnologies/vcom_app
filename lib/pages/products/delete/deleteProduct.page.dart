import 'package:flutter/material.dart';
import 'package:vcom_app/components/commons/button.dart';
import 'package:vcom_app/pages/products/delete/deleteProduct.component.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Página para eliminar productos
class DeleteProductPage extends StatefulWidget {
  final int productId;
  final String productName;
  
  const DeleteProductPage({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<DeleteProductPage> createState() => _DeleteProductPageState();
}

class _DeleteProductPageState extends State<DeleteProductPage> {
  late DeleteProductComponent _deleteProductComponent;

  @override
  void initState() {
    super.initState();
    _deleteProductComponent = DeleteProductComponent();
    _deleteProductComponent.addListener(_onComponentChanged);
  }

  @override
  void dispose() {
    _deleteProductComponent.removeListener(_onComponentChanged);
    super.dispose();
  }

  void _onComponentChanged() {
    setState(() {});
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VcomColors.azulZafiroProfundo,
        title: Text(
          'Confirmar eliminación',
          style: TextStyle(color: VcomColors.blancoCrema),
        ),
        content: Text(
          '¿Está seguro de que desea eliminar el producto "${widget.productName}"? Esta acción no se puede deshacer.',
          style: TextStyle(color: VcomColors.blancoCrema),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: VcomColors.oroLujoso),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _deleteProductComponent.deleteProduct(widget.productId);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eliminar Producto'),
        backgroundColor: VcomColors.azulZafiroProfundo,
        foregroundColor: VcomColors.blancoCrema,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: VcomColors.gradienteNocturno,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  '¿Eliminar producto?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: VcomColors.blancoCrema,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Está a punto de eliminar el producto:',
                  style: TextStyle(
                    fontSize: 16,
                    color: VcomColors.blancoCrema.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.productName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: VcomColors.oroBrillante,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Esta acción no se puede deshacer.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  children: [
                    Expanded(
                      child: ButtonComponent(
                        label: 'Cancelar',
                        size: ButtonSize.large,
                        color: Colors.grey[800],
                        textColor: VcomColors.blancoCrema,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ButtonComponent(
                        label: 'Eliminar',
                        size: ButtonSize.large,
                        color: Colors.red,
                        textColor: VcomColors.blancoCrema,
                        onPressed: _deleteProductComponent.isLoading ? null : _handleDelete,
                      ),
                    ),
                  ],
                ),
                if (_deleteProductComponent.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(
                      color: VcomColors.oroLujoso,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

