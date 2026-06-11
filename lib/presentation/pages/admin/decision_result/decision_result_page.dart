import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:spk_ngacoan/core/utils/date_formatter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/decision_history_model.dart';
import '../../../../data/models/decision_history_detail_model.dart';
import '../../../blocs/decision_result/decision_result_bloc.dart';
import '../../../blocs/decision_result/decision_result_event.dart';
import '../../../blocs/decision_result/decision_result_state.dart';

class DecisionResultPage extends StatefulWidget {
  const DecisionResultPage({super.key});

  @override
  State<DecisionResultPage> createState() => _DecisionResultPageState();
}

class _DecisionResultPageState extends State<DecisionResultPage> {
  @override
  void initState() {
    super.initState();
    context.read<DecisionResultBloc>().add(const DecisionResultLoadRequested());
  }

  void _showDetailDialog(
      BuildContext context, DecisionHistoryDetailModel detail) {
    showDialog(
      context: context,
      builder: (_) => _EdasStepsDialog(detail: detail),
    );
  }

  void _confirmHitungUlang(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hitung Ulang EDAS',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const Text(
          'Proses ini akan menghitung ulang seluruh data evaluasi dengan data terbaru. Lanjutkan?',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<DecisionResultBloc>()
                  .add(const DecisionResultHitungUlang());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text('Hitung Ulang'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _ResultHeader(
            onHitungUlang: () => _confirmHitungUlang(context),
          ),
          Expanded(
            child: BlocBuilder<DecisionResultBloc, DecisionResultState>(
              builder: (context, state) {
                if (state is DecisionResultLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is DecisionResultHitungLoading) {
                  return const _HitungUlangLoading();
                }

                if (state is DecisionResultError) {
                  return _ErrorView(
                    message: state.message,
                    onRetry: () => context
                        .read<DecisionResultBloc>()
                        .add(const DecisionResultLoadRequested()),
                  );
                }

                if (state is DecisionResultEmpty) {
                  return const _EmptyView();
                }

                final detail =
                    state is DecisionResultLoaded ? state.detail : null;

                if (detail == null) return const SizedBox();

                return _ResultContent(
                  detail: detail,
                  onLihatLangkah: () => _showDetailDialog(context, detail),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _ResultHeader extends StatelessWidget {
  final VoidCallback onHitungUlang;

  const _ResultHeader({required this.onHitungUlang});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.menu, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Hasil Keputusan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hasil Keputusan (EDAS)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Rekomendasi supplier terbaik menggunakan pembobotan EDAS.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onHitungUlang,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Hitung Ulang\nData Terbaru',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Main Content ─────────────────────────────────────────────────────────────

class _ResultContent extends StatelessWidget {
  final DecisionHistoryDetailModel detail;
  final VoidCallback onLihatLangkah;

  const _ResultContent({
    required this.detail,
    required this.onLihatLangkah,
  });

  String _formatDate(String? raw) {
    if (raw == null) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat("d MMM yyyy 'pukul' HH.mm", 'id').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = detail.topSupplier;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // ── Timestamp + Lihat Langkah
        Row(
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                          children: [
                            const TextSpan(text: 'Terakhir dikalkulasi: '),
                            TextSpan(
                              text: DateFormatter.format(detail.calculatedAt),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onLihatLangkah,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_outlined,
                        size: 13, color: AppTheme.textSecondary),
                    SizedBox(width: 6),
                    Text(
                      'Lihat Langkah',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Top Supplier Card
        if (top != null) _TopSupplierCard(result: top),
        const SizedBox(height: 16),

        // ── Ranking Table
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: Row(
                  children: [
                    const SizedBox(width: 28),
                    const SizedBox(width: 10),
                    _TableHeader(label: 'Kode', flex: 1),
                    _TableHeader(label: 'Nama Pemasok', flex: 3),
                    _TableHeader(
                        label: 'Score (AS)', flex: 2, align: TextAlign.right),
                  ],
                ),
              ),
              Divider(height: 1, color: AppTheme.divider),
              ...detail.rankings.asMap().entries.map((entry) {
                final index = entry.key;
                final result = entry.value;
                final isTop = result.rank == 1;
                return _RankingRow(
                  result: result,
                  isLast: index == detail.rankings.length - 1,
                  isTop: isTop,
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Top Supplier Card ────────────────────────────────────────────────────────

class _TopSupplierCard extends StatelessWidget {
  final RankingItemModel result;

  const _TopSupplierCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2DD4BF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFF2DD4BF),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'REKOMENDASI UTAMA (RANK 1)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2DD4BF),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.supplierName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    result.supplierCode,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Appraisal Score (AS)',
                style: TextStyle(fontSize: 10, color: Colors.white38),
              ),
              const SizedBox(height: 4),
              Text(
                result.appraisalScore.toStringAsFixed(4),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2DD4BF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Ranking Row ──────────────────────────────────────────────────────────────

class _RankingRow extends StatelessWidget {
  final RankingItemModel result;
  final bool isLast;
  final bool isTop;

  const _RankingRow({
    required this.result,
    required this.isLast,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    final medalColors = [
      const Color(0xFFFFD700),
      const Color(0xFFB0BEC5),
      const Color(0xFFCD7F32),
    ];
    final medalColor = result.rank <= 3
        ? medalColors[result.rank - 1]
        : AppTheme.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: isTop ? const Color(0xFF2DD4BF).withOpacity(0.04) : null,
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: AppTheme.divider, width: 0.5),
              ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded, color: medalColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: Text(
              result.supplierCode,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    result.supplierName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (isTop) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2DD4BF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF2DD4BF).withOpacity(0.3),
                      ),
                    ),
                    child: const Text('Terbaik',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2DD4BF))),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              result.appraisalScore.toStringAsFixed(4),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isTop ? const Color(0xFF2DD4BF) : AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String label;
  final int flex;
  final TextAlign align;

  const _TableHeader({
    required this.label,
    required this.flex,
    this.align = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

// ─── EDAS Steps Dialog (4 Tab) ────────────────────────────────────────────────

class _EdasStepsDialog extends StatefulWidget {
  final DecisionHistoryDetailModel detail;

  const _EdasStepsDialog({required this.detail});

  @override
  State<_EdasStepsDialog> createState() => _EdasStepsDialogState();
}

class _EdasStepsDialogState extends State<_EdasStepsDialog> {
  int _selectedTab = 0;

  final _tabs = const [
    '1. Solusi AV',
    '2. Matriks PDA',
    '3. Matriks NDA',
    '4. SP, SN & AS',
  ];

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final hasMatrices = detail.hasEdasMatrices;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Dialog Header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rumus Komputasi EDAS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Rincian nilai matriks.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Tab Bar ──────────────────────────────────────────────────────
          if (hasMatrices) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final isSelected = _selectedTab == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTab = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1A1A1A)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1A1A1A)
                              : AppTheme.divider,
                        ),
                      ),
                      child: Text(
                        _tabs[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
          ] else ...[
            const Divider(height: 1),
          ],

          // ── Tab Content ──────────────────────────────────────────────────
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: hasMatrices
                ? _buildTabContent(detail)
                : _buildFallbackRankingList(detail),
          ),

          // ── Footer ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Text(
              'Dikalkulasi: ${DateFormatter.format(detail.calculatedAt)}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(DecisionHistoryDetailModel detail) {
    switch (_selectedTab) {
      case 0:
        return _AvTab(
            avMatrix: detail.avMatrix, headers: detail.criteriaHeaders);
      case 1:
        return _MatrixTab(
          title: 'Matriks Jarak Positif dari Rata-rata (PDA)',
          rows: detail.pdaMatrix,
          headers: detail.criteriaHeaders,
        );
      case 2:
        return _MatrixTab(
          title: 'Matriks Jarak Negatif dari Rata-rata (NDA)',
          rows: detail.ndaMatrix,
          headers: detail.criteriaHeaders,
        );
      case 3:
        return _FinalTab(rows: detail.finalMatrix);
      default:
        return const SizedBox();
    }
  }

  Widget _buildFallbackRankingList(DecisionHistoryDetailModel detail) {
    // Fallback: tampilkan ranking list biasa jika EDAS matrices tidak tersedia
    final medalColors = [
      const Color(0xFFFFD700),
      const Color(0xFFB0BEC5),
      const Color(0xFFCD7F32),
    ];

    if (detail.rankings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Tidak ada data ranking.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: const [
              SizedBox(width: 28),
              SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: Text('Kode',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary)),
              ),
              Expanded(
                flex: 3,
                child: Text('Nama Pemasok',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary)),
              ),
              Text('Score (AS)',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary)),
            ],
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: detail.rankings.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final r = detail.rankings[index];
              final isTop = r.rank == 1;
              final medalColor = r.rank <= 3
                  ? medalColors[r.rank - 1]
                  : AppTheme.textSecondary;

              return Container(
                color: isTop ? const Color(0xFF2DD4BF).withOpacity(0.04) : null,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events_rounded,
                        color: medalColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: Text(r.supplierCode,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              r.supplierName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    isTop ? FontWeight.bold : FontWeight.normal,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (isTop) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2DD4BF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color:
                                      const Color(0xFF2DD4BF).withOpacity(0.3),
                                ),
                              ),
                              child: const Text('Terbaik',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2DD4BF))),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      r.appraisalScore.toStringAsFixed(4),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isTop
                            ? const Color(0xFF2DD4BF)
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Tab 1: Solusi AV ─────────────────────────────────────────────────────────

class _AvTab extends StatelessWidget {
  final List<EdasAvModel> avMatrix;
  final List<String> headers;

  const _AvTab({required this.avMatrix, required this.headers});

  @override
  Widget build(BuildContext context) {
    if (avMatrix.isEmpty) return _emptyTabContent();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nilai Solusi Rata-rata (AV) tiap Kriteria',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              border: TableBorder(
                horizontalInside:
                    BorderSide(color: AppTheme.divider, width: 0.5),
                top: BorderSide(color: AppTheme.divider),
                bottom: BorderSide(color: AppTheme.divider),
                left: BorderSide(color: AppTheme.divider),
                right: BorderSide(color: AppTheme.divider),
              ),
              defaultColumnWidth: const FixedColumnWidth(90),
              children: [
                // Header row
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
                  children: avMatrix
                      .map(
                        (av) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          child: Text(
                            av.criteriaCode,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                // Value row
                TableRow(
                  children: avMatrix
                      .map(
                        (av) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          child: Text(
                            av.avValue.toStringAsFixed(4),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 2 & 3: Matriks PDA / NDA ────────────────────────────────────────────

class _MatrixTab extends StatelessWidget {
  final String title;
  final List<EdasMatrixRowModel> rows;
  final List<String> headers;

  const _MatrixTab({
    required this.title,
    required this.rows,
    required this.headers,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return _emptyTabContent();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              border: TableBorder(
                horizontalInside:
                    BorderSide(color: AppTheme.divider, width: 0.5),
                top: BorderSide(color: AppTheme.divider),
                bottom: BorderSide(color: AppTheme.divider),
                left: BorderSide(color: AppTheme.divider),
                right: BorderSide(color: AppTheme.divider),
              ),
              defaultColumnWidth: const FixedColumnWidth(80),
              columnWidths: const {0: FixedColumnWidth(140)},
              children: [
                // Header row
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Text(
                        'Supplier',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    ...headers.map(
                      (h) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: Text(
                          h,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Data rows
                ...rows.map(
                  (row) => TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        child: Text(
                          '${row.supplierCode} - ${row.supplierName}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      ...headers.map(
                        (h) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          child: Text(
                            (row.criteriaValues[h] ?? 0.0).toStringAsFixed(4),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 4: SP, SN & AS ──────────────────────────────────────────────────────

class _FinalTab extends StatelessWidget {
  final List<EdasFinalRowModel> rows;

  const _FinalTab({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return _emptyTabContent();

    // Hitung max untuk highlight
    final maxNsp = rows.map((r) => r.nsp).reduce((a, b) => a > b ? a : b);
    final maxNss = rows.map((r) => r.nss).reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skor Akumulasi Terbobot & Hasil Akhir (AS)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              border: TableBorder(
                horizontalInside:
                    BorderSide(color: AppTheme.divider, width: 0.5),
                top: BorderSide(color: AppTheme.divider),
                bottom: BorderSide(color: AppTheme.divider),
                left: BorderSide(color: AppTheme.divider),
                right: BorderSide(color: AppTheme.divider),
              ),
              columnWidths: const {
                0: FixedColumnWidth(140),
                1: FixedColumnWidth(80),
                2: FixedColumnWidth(80),
                3: FixedColumnWidth(90),
                4: FixedColumnWidth(90),
                5: FixedColumnWidth(110),
              },
              children: [
                // Header
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
                  children: const [
                    _FinalCell(text: 'Supplier', isHeader: true),
                    _FinalCell(text: 'Score SP', isHeader: true),
                    _FinalCell(text: 'Score SN', isHeader: true),
                    _FinalCell(
                        text: 'NSP (Norm.)',
                        isHeader: true,
                        color: Color(0xFF3B82F6)),
                    _FinalCell(
                        text: 'NSS (Norm.)',
                        isHeader: true,
                        color: Color(0xFF8B5CF6)),
                    _FinalCell(
                        text: 'Appraisal Score (AS)',
                        isHeader: true,
                        color: Color(0xFF2DD4BF)),
                  ],
                ),
                // Rows
                ...rows.map(
                  (row) => TableRow(
                    children: [
                      _FinalCell(
                        text: '${row.supplierCode} - ${row.supplierName}',
                        align: TextAlign.left,
                      ),
                      _FinalCell(text: row.scoreSp.toStringAsFixed(4)),
                      _FinalCell(text: row.scoreSn.toStringAsFixed(4)),
                      _FinalCell(
                        text: row.nsp.toStringAsFixed(4),
                        color:
                            row.nsp == maxNsp ? const Color(0xFF3B82F6) : null,
                        isBold: row.nsp == maxNsp,
                      ),
                      _FinalCell(
                        text: row.nss.toStringAsFixed(4),
                        color:
                            row.nss == maxNss ? const Color(0xFF8B5CF6) : null,
                        isBold: row.nss == maxNss,
                      ),
                      _FinalCell(
                        text: row.appraisalScore.toStringAsFixed(4),
                        color: const Color(0xFF2DD4BF),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final bool isBold;
  final Color? color;
  final TextAlign align;

  const _FinalCell({
    required this.text,
    this.isHeader = false,
    this.isBold = false,
    this.color,
    this.align = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: isHeader ? 11 : 11,
          fontWeight: isHeader || isBold ? FontWeight.bold : FontWeight.normal,
          color: color ??
              (isHeader ? AppTheme.textSecondary : AppTheme.textPrimary),
        ),
      ),
    );
  }
}

// ─── Empty Tab Placeholder ────────────────────────────────────────────────────

Widget _emptyTabContent() {
  return const Padding(
    padding: EdgeInsets.all(32),
    child: Center(
      child: Text(
        'Data tidak tersedia.',
        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      ),
    ),
  );
}

// ─── Hitung Ulang Loading ─────────────────────────────────────────────────────

class _HitungUlangLoading extends StatelessWidget {
  const _HitungUlangLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: 16),
            Text(
              'Menghitung ulang EDAS...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Proses ini mungkin membutuhkan beberapa detik.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty View ───────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bar_chart_outlined,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada hasil keputusan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Lengkapi data evaluasi lalu tekan "Hitung Ulang" untuk memulai.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: AppTheme.error),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat data',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Periksa koneksi internet Anda.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Coba Lagi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
