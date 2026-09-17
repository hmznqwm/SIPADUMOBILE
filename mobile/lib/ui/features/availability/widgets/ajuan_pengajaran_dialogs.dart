// File: ajuan_pengajaran_dialogs.dart
// Deskripsi: Facade & export bundle untuk semua bottom sheet & dialog pengajuan jam mengajar (Dosen, KaProdi, Dekan, Admin).

import 'package:flutter/material.dart';

import '../../../../data/models/ajuan_pengajaran_model.dart';
import 'dialogs/banding_and_reject_bottom_sheets.dart';
import 'dialogs/conflict_check_bottom_sheet.dart';
import 'dialogs/detail_ajuan_bottom_sheet.dart';
import 'dialogs/edit_ajuan_bottom_sheet.dart';

// Export all individual modular bottom sheets
export 'dialogs/banding_and_reject_bottom_sheets.dart';
export 'dialogs/conflict_check_bottom_sheet.dart';
export 'dialogs/detail_ajuan_bottom_sheet.dart';
export 'dialogs/edit_ajuan_bottom_sheet.dart';

/// Facade class untuk backward compatibility seluruh caller
class AjuanPengajaranDialogs {
  /// Menampilkan modal Detail Lengkap Ajuan Pengajaran
  static void showDetailDialog({
    required BuildContext context,
    required AjuanPengajaranModel ajuan,
    required String currentRole,
    required VoidCallback onRefresh,
  }) {
    DetailAjuanBottomSheet.show(
      context: context,
      ajuan: ajuan,
      currentRole: currentRole,
      onRefresh: onRefresh,
    );
  }

  /// Menampilkan Form Edit / Sesuaikan Ajuan (Untuk Dosen, KaProdi, Dekan, dan Admin)
  static void showEditDialog({
    required BuildContext context,
    required AjuanPengajaranModel ajuan,
    required String currentRole,
    required Function(AjuanPengajaranModel) onSaved,
  }) {
    EditAjuanBottomSheet.showEditDialog(
      context: context,
      ajuan: ajuan,
      currentRole: currentRole,
      onSaved: onSaved,
    );
  }

  /// Menampilkan Form Tambah Ajuan Baru (Untuk Dosen)
  static void showCreateDialog({
    required BuildContext context,
    required String dosenId,
    required String dosenNama,
    required String fakultasNama,
    required String jurusanNama,
    required Function(AjuanPengajaranModel) onCreated,
  }) {
    EditAjuanBottomSheet.showCreateDialog(
      context: context,
      dosenId: dosenId,
      dosenNama: dosenNama,
      fakultasNama: fakultasNama,
      jurusanNama: jurusanNama,
      onCreated: onCreated,
    );
  }

  /// Menampilkan Dialog Hasil Cek Bentrok Gedung & Ruang (Keluar dari Bawah / Bottom Sheet Modern)
  static void showConflictCheckDialog({
    required BuildContext context,
    required AjuanPengajaranModel ajuan,
  }) {
    ConflictCheckBottomSheet.show(
      context: context,
      ajuan: ajuan,
    );
  }

  /// Menampilkan Dialog Ajukan Banding Jadwal (Keluar dari Bawah / Bottom Sheet Modern)
  static void showBandingDialog({
    required BuildContext context,
    required AjuanPengajaranModel ajuan,
    required Function(String alasan, String? prefHari, String? prefJam) onConfirmBanding,
  }) {
    BandingAndRejectBottomSheets.showBandingDialog(
      context: context,
      ajuan: ajuan,
      onConfirmBanding: onConfirmBanding,
    );
  }

  /// Menampilkan Dialog Tolak / Permintaan Revisi (Keluar dari Bawah / Bottom Sheet Modern)
  static void showRejectDialog({
    required BuildContext context,
    required AjuanPengajaranModel ajuan,
    required String role,
    required Function(String alasan) onConfirmReject,
  }) {
    BandingAndRejectBottomSheets.showRejectDialog(
      context: context,
      ajuan: ajuan,
      role: role,
      onConfirmReject: onConfirmReject,
    );
  }
}
