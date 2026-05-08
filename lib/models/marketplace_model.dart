// lib/models/marketplace_model.dart
// Represents a prize bond listed for sale in the marketplace

class MarketplaceModel {
  final String id;
  final String bondNumber;    // Bond number being sold
  final int denomination;     // Bond denomination
  final double askingPrice;   // Price seller wants
  final String sellerName;    // Name of seller
  final String location;      // Seller's city
  final DateTime listedDate;  // When listed

  MarketplaceModel({
    required this.id,
    required this.bondNumber,
    required this.denomination,
    required this.askingPrice,
    required this.sellerName,
    required this.location,
    required this.listedDate,
  });

  // Convert to Map for GetStorage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bondNumber': bondNumber,
      'denomination': denomination,
      'askingPrice': askingPrice,
      'sellerName': sellerName,
      'location': location,
      'listedDate': listedDate.toIso8601String(),
    };
  }

  // Create from stored Map
  factory MarketplaceModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceModel(
      id: json['id'],
      bondNumber: json['bondNumber'],
      denomination: json['denomination'],
      askingPrice: (json['askingPrice'] as num).toDouble(),
      sellerName: json['sellerName'],
      location: json['location'],
      listedDate: DateTime.parse(json['listedDate']),
    );
  }
}
