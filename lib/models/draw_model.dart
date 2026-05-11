// lib/Models/draw_model.dart
// Represents a prize bond draw result stored in Firestore
// Collection: 'draws'

class DrawModel {
  final String id;             // Firestore document ID
  final int denomination;      // Bond denomination (e.g. 750)
  final int drawNumber;        // Official draw number
  final DateTime drawDate;     // Date of draw
  final String city;           // City where draw was held
  final List<String> winningNumbers;  // All winning bond numbers
  final String? pdfUrl;        // Firebase Storage URL for PDF
  final String? pdfName;       // Original filename of the uploaded PDF
  final DateTime? pdfUploadedAt; // When admin uploaded the PDF
  final String? localPdfPath;  // Local path if downloaded offline
  final DateTime createdAt;    // When admin uploaded this
  final String uploadedBy;     // Admin UID who uploaded

  DrawModel({
    required this.id,
    required this.denomination,
    required this.drawNumber,
    required this.drawDate,
    required this.city,
    required this.winningNumbers,
    this.pdfUrl,
    this.pdfName,
    this.pdfUploadedAt,
    this.localPdfPath,
    required this.createdAt,
    required this.uploadedBy,
  });

  // Convert Firestore document to DrawModel
  factory DrawModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return DrawModel(
      id: docId,
      denomination: data['denomination'] ?? 0,
      drawNumber: data['drawNumber'] ?? 0,
      drawDate: (data['drawDate'] as dynamic).toDate(),
      city: data['city'] ?? '',
      winningNumbers: List<String>.from(data['winningNumbers'] ?? []),
      pdfUrl: data['pdfUrl'],
      pdfName: data['pdfName'],
      pdfUploadedAt: data['pdfUploadedAt'] != null
          ? DateTime.tryParse(data['pdfUploadedAt'] as String)
          : null,
      localPdfPath: null, // Always null from Firestore; set locally
      createdAt: (data['createdAt'] as dynamic).toDate(),
      uploadedBy: data['uploadedBy'] ?? '',
    );
  }

  // Convert to Map for Firestore storage
  Map<String, dynamic> toFirestore() {
    return {
      'denomination': denomination,
      'drawNumber': drawNumber,
      'drawDate': drawDate,
      'city': city,
      'winningNumbers': winningNumbers,
      'pdfUrl': pdfUrl,
      'pdfName': pdfName,
      'pdfUploadedAt': pdfUploadedAt?.toIso8601String(),
      'createdAt': createdAt,
      'uploadedBy': uploadedBy,
    };
  }

  // Convert to/from local Hive storage (for offline)
  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'denomination': denomination,
      'drawNumber': drawNumber,
      'drawDate': drawDate.toIso8601String(),
      'city': city,
      'winningNumbers': winningNumbers,
      'pdfUrl': pdfUrl,
      'pdfName': pdfName,
      'pdfUploadedAt': pdfUploadedAt?.toIso8601String(),
      'localPdfPath': localPdfPath,
      'createdAt': createdAt.toIso8601String(),
      'uploadedBy': uploadedBy,
    };
  }

  factory DrawModel.fromLocalJson(Map<String, dynamic> json) {
    return DrawModel(
      id: json['id'],
      denomination: json['denomination'],
      drawNumber: json['drawNumber'],
      drawDate: DateTime.parse(json['drawDate']),
      city: json['city'],
      winningNumbers: List<String>.from(json['winningNumbers'] ?? []),
      pdfUrl: json['pdfUrl'],
      pdfName: json['pdfName'],
      pdfUploadedAt: json['pdfUploadedAt'] != null
          ? DateTime.tryParse(json['pdfUploadedAt'] as String)
          : null,
      localPdfPath: json['localPdfPath'],
      createdAt: DateTime.parse(json['createdAt']),
      uploadedBy: json['uploadedBy'] ?? '',
    );
  }

  // Create a copy with updated fields (useful for updating localPdfPath)
  DrawModel copyWith({String? localPdfPath, String? pdfUrl}) {
    return DrawModel(
      id: id,
      denomination: denomination,
      drawNumber: drawNumber,
      drawDate: drawDate,
      city: city,
      winningNumbers: winningNumbers,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      pdfName: pdfName,
      pdfUploadedAt: pdfUploadedAt,
      localPdfPath: localPdfPath ?? this.localPdfPath,
      createdAt: createdAt,
      uploadedBy: uploadedBy,
    );
  }
}
