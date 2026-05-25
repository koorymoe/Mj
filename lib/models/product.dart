class Product {
  final String name;
  final String unit;
  final double price;
  final String imageBase64;

  const Product({
    required this.name,
    required this.unit,
    required this.price,
    this.imageBase64 = '',
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    name        : json['name']        ?? '',
    unit        : json['unit']        ?? 'قطعة',
    price       : (json['price']      ?? 0).toDouble(),
    imageBase64 : json['imageBase64'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'name'        : name,
    'unit'        : unit,
    'price'       : price,
    'imageBase64' : imageBase64,
  };
}
