// lib/Models/market_listing_model.dart
// Represents a bond listed for sale in the marketplace
// Stored in Firestore: 'marketplace' collection

class MarketListingModel {
  final String id;
  final String sellerUid;
  final String sellerName;
  final String sellerCity;
  final String bondNumber;
  final int denomination;
  final double askingPrice;
  final DateTime listedAt;
  final bool isActive;
  final String sellerPhone; // WhatsApp / phone number for direct contact

  MarketListingModel({
    required this.id,
    required this.sellerUid,
    required this.sellerName,
    required this.sellerCity,
    required this.bondNumber,
    required this.denomination,
    required this.askingPrice,
    required this.listedAt,
    this.isActive = true,
    this.sellerPhone = '',
  });

  factory MarketListingModel.fromFirestore(
      Map<String, dynamic> data, String docId) {
    return MarketListingModel(
      id: docId,
      sellerUid: data['sellerUid'] ?? '',
      sellerName: data['sellerName'] ?? '',
      sellerCity: data['sellerCity'] ?? '',
      bondNumber: data['bondNumber'] ?? '',
      denomination: data['denomination'] ?? 0,
      askingPrice: (data['askingPrice'] as num).toDouble(),
      listedAt: (data['listedAt'] as dynamic).toDate(),
      isActive: data['isActive'] ?? true,
      sellerPhone: data['sellerPhone'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sellerUid': sellerUid,
      'sellerName': sellerName,
      'sellerCity': sellerCity,
      'bondNumber': bondNumber,
      'denomination': denomination,
      'askingPrice': askingPrice,
      'listedAt': listedAt,
      'isActive': isActive,
      'sellerPhone': sellerPhone,
    };
  }
}
