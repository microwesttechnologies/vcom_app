/// Modelo de marca
class BrandModel {
  final int idBrand;
  final int idCategory;
  final String nameBrand;
  final String? descriptionBrand;
  final String? logo;
  final String? website;
  final bool stateBrand;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BrandModel({
    required this.idBrand,
    required this.idCategory,
    required this.nameBrand,
    this.descriptionBrand,
    this.logo,
    this.website,
    this.stateBrand = true,
    this.createdAt,
    this.updatedAt,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      idBrand: json['id_brand'] as int? ?? 0,
      idCategory: json['id_category'] as int? ?? 0,
      nameBrand: json['name_brand'] as String? ?? '',
      descriptionBrand: json['description_brand'] as String?,
      logo: json['logo'] as String?,
      website: json['website'] as String?,
      stateBrand: json['state_brand'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id_category': idCategory,
      'name_brand': nameBrand,
      'state_brand': stateBrand,
    };
    
    // Solo incluir campos opcionales si no están vacíos
    if (descriptionBrand != null && descriptionBrand!.isNotEmpty) {
      json['description_brand'] = descriptionBrand;
    }
    
    // Solo incluir logo si es una URL válida
    if (logo != null && logo!.isNotEmpty && _isValidUrl(logo!)) {
      json['logo'] = logo;
    }
    
    // Solo incluir website si es una URL válida
    if (website != null && website!.isNotEmpty && _isValidUrl(website!)) {
      json['website'] = website;
    }
    
    // Solo incluir id_brand si no es 0 (para actualizaciones)
    if (idBrand != 0) {
      json['id_brand'] = idBrand;
    }
    
    return json;
  }
  
  /// Valida si una cadena es una URL válida
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}

