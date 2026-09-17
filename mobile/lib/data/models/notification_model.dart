// File: notification_model.dart
// Deskripsi: Model data untuk notifikasi sistem.
// Fungsi: Menyimpan pesan pemberitahuan kepada pengguna (seperti pengumuman jadwal, permintaan input ketersediaan, atau perubahan status).

class NotificationModel {
  final String id;
  final String judul;
  final String pesan;
  final String tipe; // 'jadwal_published', 'availability_request', 'approval', 'info', 'success'
  final DateTime timestamp;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.judul,
    required this.pesan,
    required this.tipe,
    required this.timestamp,
    this.isRead = false,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      judul: judul,
      pesan: pesan,
      tipe: tipe,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      // Support both backend field names (title/message/type) and local names (judul/pesan/tipe)
      judul: json['title']?.toString() ?? json['judul']?.toString() ?? '',
      pesan: json['message']?.toString() ?? json['pesan']?.toString() ?? '',
      tipe: json['type']?.toString() ?? json['tipe']?.toString() ?? 'info',
      timestamp: _parseTimestamp(json),
      isRead: json['is_read'] == true ||
          json['is_read'] == 1 ||
          json['is_read'] == '1' ||
          json['isRead'] == true ||
          json['isRead'] == 1 ||
          json['isRead'] == '1',
    );
  }

  static DateTime _parseTimestamp(Map<String, dynamic> json) {
    // Support backend field 'created_at' and local field 'timestamp'
    final raw = json['created_at'] ?? json['timestamp'];
    if (raw != null) {
      return DateTime.tryParse(raw.toString()) ?? DateTime.now();
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': judul,
      'message': pesan,
      'type': tipe,
      'created_at': timestamp.toIso8601String(),
      'is_read': isRead ? 1 : 0,
    };
  }
}
