import 'package:intl/intl.dart';

/// Helper untuk format tanggal dari API.
/// API mengembalikan string tanpa timezone (e.g. "2026-05-31 05:45:49")
/// yang sebenarnya adalah UTC — harus dikonversi ke waktu lokal (WIB UTC+7).
class DateFormatter {
  static final _fmt = DateFormat("d MMM yyyy 'pukul' HH.mm", 'id');

  static String format(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      DateTime dt;
      if (raw.endsWith('Z') || raw.contains('+')) {
        // Sudah ada info timezone
        dt = DateTime.parse(raw).toLocal();
      } else {
        // Tidak ada timezone → asumsi UTC, konversi ke lokal
        dt = DateTime.parse('${raw.replaceAll(' ', 'T')}Z')
            .add(const Duration(hours: 7));
      }
      return _fmt.format(dt);
    } catch (_) {
      return raw;
    }
  }
}
