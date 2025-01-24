class Product {
  final String id; // Added id field
  final String type;
  final String code;
  final String designNo;
  final String name;
  final String description;
  final String size;
  final String color;
  final String packing;
  final int rate;
  final String meter;
  final List<String>? imagePaths; // Updated to handle multiple images

  Product({
    required this.id, // Added id to the constructor
    required this.type,
    required this.code,
    required this.designNo,
    required this.name,
    required this.description,
    required this.size,
    required this.color,
    required this.packing,
    required this.rate,
    required this.meter,
    this.imagePaths,
  });

  @override
  String toString() {
    return 'Product{id: $id, type: $type, code: $code, name: $name, description: $description, size: $size, color: $color, packing: $packing, rate: $rate, Meter: $meter, imagePaths: $imagePaths}';
  }


  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString() ?? json['_id'].toString(),
      type: json['type'].toString(),
      code: json['code'].toString(),
      designNo: json['designNo'].toString(),
      name: json['name'].toString(),
      description: json['description'].toString(),
      size: json['size'].toString(),
      color: json['color'].toString(),
      packing: json['packing'].toString(),
      rate: int.tryParse(json['rate'].toString()) ?? 0,
      meter: json['meter'].toString(),
      imagePaths: (json['imagePaths'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Product copyWith({
    String? id,
    String? type,
    String? code,
    String? designNo,
    String? name,
    String? description,
    String? size,
    String? color,
    String? packing,
    int? rate,
    String? meter,
    List<String>? imagePaths,
  }) {
    return Product(
      id: id ?? this.id,
      type: type ?? this.type,
      code: code ?? this.code,
      designNo: designNo ?? this.designNo,
      name: name ?? this.name,
      description: description ?? this.description,
      size: size ?? this.size,
      color: color ?? this.color,
      packing: packing ?? this.packing,
      rate: rate ?? this.rate,
      meter: meter ?? this.meter,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }
}
