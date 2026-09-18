// File: user_model.dart
// Deskripsi: Model data pengguna aplikasi (Dosen, Kajur, Dekan, Admin).
// Fungsi: Menyimpan identitas pengguna, hak akses role, jurusan, fakultas, status prioritas dosen, photo profile, dan token autentikasi.

class UserModel {
  final String id;
  final String nama;
  final String email;
  final String role; // 'dosen', 'kajur', 'dekan', 'admin'
  final String jurusanId;
  final String jurusanNama;
  final String fakultasNama;
  final String? matkulNama;
  final bool isPriority;
  final String? token;
  final String? avatarPath;

  const UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    required this.jurusanId,
    required this.jurusanNama,
    required this.fakultasNama,
    this.matkulNama,
    this.isPriority = false,
    this.token,
    this.avatarPath,
  });

  UserModel copyWith({
    String? id,
    String? nama,
    String? email,
    String? role,
    String? jurusanId,
    String? jurusanNama,
    String? fakultasNama,
    String? matkulNama,
    bool? isPriority,
    String? token,
    String? avatarPath,
  }) {
    return UserModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      role: role ?? this.role,
      jurusanId: jurusanId ?? this.jurusanId,
      jurusanNama: jurusanNama ?? this.jurusanNama,
      fakultasNama: fakultasNama ?? this.fakultasNama,
      matkulNama: matkulNama ?? this.matkulNama,
      isPriority: isPriority ?? this.isPriority,
      token: token ?? this.token,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final String email = json['email']?.toString().trim() ?? '';
    final String id = json['id']?.toString().trim() ?? '';
    String role = json['role']?.toString().toLowerCase().trim() ?? '';
    if (role.isEmpty) {
      if (id.toUpperCase().startsWith('ADM')) {
        role = 'admin';
      } else if (id.toUpperCase().startsWith('DKN')) {
        role = 'dekan';
      } else if (id.toUpperCase().startsWith('KJR')) {
        role = 'kajur';
      } else {
        role = 'dosen';
      }
    }

    final String rawId = json['id']?.toString().trim() ?? '';
    final String resolvedId = rawId.isNotEmpty ? rawId : (id.isNotEmpty ? id : 'DSN001');

    return UserModel(
      id: resolvedId,
      nama: json['nama']?.toString() ?? (role == 'admin' ? 'Administrator' : 'Pengguna'),
      email: email,
      role: role,
      jurusanId: json['jurusanId']?.toString() ?? json['jurusan_id']?.toString() ?? (role == 'admin' ? 'GLOBAL' : 'JUR001'),
      jurusanNama: json['jurusanNama']?.toString() ?? json['jurusan_nama']?.toString() ?? (role == 'admin' ? 'Administrator Sistem' : 'Teknik Informatika'),
      fakultasNama: json['fakultasNama']?.toString() ?? json['fakultas_nama']?.toString() ?? (role == 'admin' ? 'Universitas' : 'Fakultas Sains & Teknologi'),
      matkulNama: json['matkulNama']?.toString() ?? json['matkul_nama']?.toString(),
      isPriority: json['isPriority'] == true || json['isPriority'] == 1 || json['is_priority'] == 1 || json['is_priority'] == true,
      token: json['token']?.toString(),
      avatarPath: json['avatarPath']?.toString() ?? json['avatar_path']?.toString() ?? json['photoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'role': role,
      'jurusanId': jurusanId,
      'jurusanNama': jurusanNama,
      'fakultasNama': fakultasNama,
      'matkulNama': matkulNama,
      'isPriority': isPriority,
      'token': token,
      'avatarPath': avatarPath,
    };
  }
}
