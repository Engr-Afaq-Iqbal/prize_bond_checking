// lib/models/draw_model.dart
// Represents a prize bond draw result stored in Firestore.
// Collection: 'draws'

class DrawModel {
  final String id;
  final int denomination;
  final int drawNumber;
  final DateTime drawDate;
  final String city;
  final List<String> winningNumbers;

  // PDF fields — set when admin uploads a PDF to Firebase Storage
  final String? pdfUrl;          // Firebase Storage public download URL
  final String? pdfName;         // Original filename chosen by admin
  final DateTime? pdfUploadedAt; // Timestamp of upload
  final String? pdfStoragePath;  // Storage path (e.g. draw_results/750/98.pdf) — used for deletion
  final int? pdfFileSize;        // File size in bytes

  // Local cache
  final String? localPdfPath;    // Device path if user already downloaded it

  final DateTime createdAt;
  final String uploadedBy; // Admin UID

  const DrawModel({
    required this.id,
    required this.denomination,
    required this.drawNumber,
    required this.drawDate,
    required this.city,
    required this.winningNumbers,
    this.pdfUrl,
    this.pdfName,
    this.pdfUploadedAt,
    this.pdfStoragePath,
    this.pdfFileSize,
    this.localPdfPath,
    required this.createdAt,
    required this.uploadedBy,
  });

  // ── Firestore → DrawModel ──────────────────────────────────────────────────

  factory DrawModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return DrawModel(
      id: docId,
      denomination: (data['denomination'] as num?)?.toInt() ?? 0,
      drawNumber: (data['drawNumber'] as num?)?.toInt() ?? 0,
      drawDate: (data['drawDate'] as dynamic).toDate() as DateTime,
      city: data['city'] as String? ?? '',
      winningNumbers:
          List<String>.from(data['winningNumbers'] as List? ?? []),
      pdfUrl: data['pdfUrl'] as String?,
      pdfName: data['pdfName'] as String?,
      pdfUploadedAt: data['pdfUploadedAt'] != null
          ? DateTime.tryParse(data['pdfUploadedAt'] as String)
          : null,
      pdfStoragePath: data['pdfStoragePath'] as String?,
      pdfFileSize: (data['pdfFileSize'] as num?)?.toInt(),
      localPdfPath: null, // always null from Firestore; set by OfflineCacheService
      createdAt: (data['createdAt'] as dynamic).toDate() as DateTime,
      uploadedBy: data['uploadedBy'] as String? ?? '',
    );
  }

  // ── DrawModel → Firestore ──────────────────────────────────────────────────

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
      'pdfStoragePath': pdfStoragePath,
      'pdfFileSize': pdfFileSize,
      'createdAt': createdAt,
      'uploadedBy': uploadedBy,
    };
  }

  // ── DrawModel → Hive local JSON ────────────────────────────────────────────

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
      'pdfStoragePath': pdfStoragePath,
      'pdfFileSize': pdfFileSize,
      'localPdfPath': localPdfPath,
      'createdAt': createdAt.toIso8601String(),
      'uploadedBy': uploadedBy,
    };
  }

  // ── Hive local JSON → DrawModel ────────────────────────────────────────────

  factory DrawModel.fromLocalJson(Map<String, dynamic> json) {
    return DrawModel(
      id: json['id'] as String,
      denomination: (json['denomination'] as num).toInt(),
      drawNumber: (json['drawNumber'] as num).toInt(),
      drawDate: DateTime.parse(json['drawDate'] as String),
      city: json['city'] as String,
      winningNumbers:
          List<String>.from(json['winningNumbers'] as List? ?? []),
      pdfUrl: json['pdfUrl'] as String?,
      pdfName: json['pdfName'] as String?,
      pdfUploadedAt: json['pdfUploadedAt'] != null
          ? DateTime.tryParse(json['pdfUploadedAt'] as String)
          : null,
      pdfStoragePath: json['pdfStoragePath'] as String?,
      pdfFileSize: (json['pdfFileSize'] as num?)?.toInt(),
      localPdfPath: json['localPdfPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      uploadedBy: json['uploadedBy'] as String? ?? '',
    );
  }

  // ── Immutable copy ─────────────────────────────────────────────────────────

  DrawModel copyWith({
    String? localPdfPath,
    String? pdfUrl,
    String? pdfStoragePath,
    int? pdfFileSize,
  }) {
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
      pdfStoragePath: pdfStoragePath ?? this.pdfStoragePath,
      pdfFileSize: pdfFileSize ?? this.pdfFileSize,
      localPdfPath: localPdfPath ?? this.localPdfPath,
      createdAt: createdAt,
      uploadedBy: uploadedBy,
    );
  }
}
