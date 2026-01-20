import 'category.model.dart';
import 'brand.model.dart';

/// Modelo de imagen de producto
class ProductImageModel {
  final int? idImage;
  final String imageUrl;
  final int imageOrder;
  final bool isPrimary;

  ProductImageModel({
    this.idImage,
    required this.imageUrl,
    required this.imageOrder,
    required this.isPrimary,
  });

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      idImage: json['id_image'] as int?,
      imageUrl: json['image_url'] as String? ?? '',
      imageOrder: json['image_order'] as int? ?? 0,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_image': idImage,
      'image_url': imageUrl,
      'image_order': imageOrder,
      'is_primary': isPrimary,
    };
  }
}

/// Modelo de producto
class ProductModel {
  final int? idProduct;
  final int idBrand;
  final String nameProduct;
  final String? descriptionProduct;
  final String? sku;
  final double priceCop;
  final int stock;
  final bool stateProduct;
  final BrandModel? brand;
  final CategoryModel? category;
  final List<ProductImageModel> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductModel({
    this.idProduct,
    required this.idBrand,
    required this.nameProduct,
    this.descriptionProduct,
    this.sku,
    required this.priceCop,
    required this.stock,
    this.stateProduct = true,
    this.brand,
    this.category,
    this.images = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      idProduct: json['id_product'] as int?,
      idBrand: json['id_brand'] as int? ?? 0,
      nameProduct: json['name_product'] as String? ?? '',
      descriptionProduct: json['description_product'] as String?,
      sku: json['sku'] as String?,
      priceCop: (json['price_cop'] as num?)?.toDouble() ?? 0.0,
      stock: json['stock'] as int? ?? 0,
      stateProduct: json['state_product'] as bool? ?? true,
      brand: json['brand'] != null
          ? BrandModel.fromJson(json['brand'] as Map<String, dynamic>)
          : null,
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      images: json['images'] != null
          ? (json['images'] as List)
              .map((img) => ProductImageModel.fromJson(img as Map<String, dynamic>))
              .toList()
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    final map = <String, dynamic>{
      'id_brand': idBrand,
      'name_product': nameProduct,
      'description_product': descriptionProduct,
      'sku': sku,
      'price_cop': priceCop,
      'stock': stock,
      'state_product': stateProduct,
    };

    // Solo incluir imágenes que tengan URLs válidas (no rutas locales)
    final validImages = images.where((img) => 
      img.imageUrl.startsWith('http://') || 
      img.imageUrl.startsWith('https://')
    ).toList();
    
    if (validImages.isNotEmpty) {
      map['images'] = validImages.map((img) => img.toJson()).toList();
    }

    if (includeId && idProduct != null) {
      map['id_product'] = idProduct;
    }

    return map;
  }
}

