import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/criteria_model.dart';
import '../../../../data/models/supplier_model.dart';
import '../../../../data/models/evaluation_model.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../blocs/evaluation/evaluation_bloc.dart';
import '../../../blocs/evaluation/evaluation_event.dart';
import '../../../blocs/evaluation/evaluation_state.dart';

class EvaluationPage extends StatefulWidget {
  const EvaluationPage({super.key});

  @override
  State<EvaluationPage> createState() => _EvaluationPageState();
}

class _EvaluationPageState extends State<EvaluationPage> {
  final Map<int, Map<int, TextEditingController>> _controllers = {};
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    context.read<EvaluationBloc>().add(const EvaluationLoadRequested());
  }

  @override
  void dispose() {
    for (final row in _controllers.values) {
      for (final ctrl in row.values) {
        ctrl.dispose();
      }
    }
    super.dispose();
  }

  bool get _isOwner {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated && authState.user.role == 'owner';
  }

  void _initControllers(
    List<SupplierModel> suppliers,
    List<CriteriaModel> criterias,
    List<EvaluationModel> evaluations,
  ) {
    for (final supplier in suppliers) {
      if (!_controllers.containsKey(supplier.id)) {
        _controllers[supplier.id] = {};
      }
      for (final criteria in criterias) {
        if (!_controllers[supplier.id]!.containsKey(criteria.id)) {
          final existing = evaluations.firstWhere(
            (e) => e.supplierId == supplier.id && e.criterionId == criteria.id,
            orElse: () => EvaluationModel(
              id: 0,
              supplierId: supplier.id,
              criterionId: criteria.id,
              actualValue: 0,
            ),
          );
          _controllers[supplier.id]![criteria.id] = TextEditingController(
            text: existing.actualValue == 0
                ? ''
                : existing.actualValue.toStringAsFixed(0),
          );
        }
      }
    }
  }

  void _onSave(List<SupplierModel> suppliers, List<CriteriaModel> criterias) {
    final List<Map<String, dynamic>> evaluations = [];
    for (final supplier in suppliers) {
      for (final criteria in criterias) {
        final val = _controllers[supplier.id]?[criteria.id]?.text ?? '0';
        evaluations.add({
          'supplier_id': supplier.id,
          'criterion_id': criteria.id,
          'actual_value': double.tryParse(val) ?? 0,
        });
      }
    }
    context.read<EvaluationBloc>().add(
          EvaluationBulkSaveRequested(evaluations: evaluations),
        );
    setState(() => _isDirty = false);
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _isOwner;

    return BlocListener<EvaluationBloc, EvaluationState>(
      listener: (context, state) {
        if (state is EvaluationSaveSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Matriks berhasil disimpan!'),
              backgroundColor: const Color(0xFF2DD4BF),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        if (state is EvaluationSaveError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      child: SafeArea(
        child: BlocBuilder<EvaluationBloc, EvaluationState>(
          builder: (context, state) {
            if (state is EvaluationLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is EvaluationError) {
              return _ErrorView(
                message: state.message,
                onRetry: () => context
                    .read<EvaluationBloc>()
                    .add(const EvaluationLoadRequested()),
              );
            }

            List<SupplierModel> suppliers = [];
            List<CriteriaModel> criterias = [];
            List<EvaluationModel> evaluations = [];
            bool isSaving = false;

            if (state is EvaluationLoaded) {
              suppliers = state.suppliers;
              criterias = state.criterias;
              evaluations = state.evaluations;
            } else if (state is EvaluationSaving) {
              suppliers = state.suppliers;
              criterias = state.criterias;
              evaluations = state.evaluations;
              isSaving = true;
            } else if (state is EvaluationSaveSuccess) {
              suppliers = state.suppliers;
              criterias = state.criterias;
              evaluations = state.evaluations;
            } else if (state is EvaluationSaveError) {
              suppliers = state.suppliers;
              criterias = state.criterias;
              evaluations = state.evaluations;
            }

            if (suppliers.isNotEmpty && criterias.isNotEmpty) {
              _initControllers(suppliers, criterias, evaluations);
            }

            return Column(
              children: [
                _EvaluationHeader(
                  isSaving: isSaving,
                  isDirty: _isDirty,
                  isOwner: isOwner,
                  onSave: isOwner && suppliers.isNotEmpty && criterias.isNotEmpty
                      ? () => _onSave(suppliers, criterias)
                      : null,
                ),
                Expanded(
                  child: suppliers.isEmpty || criterias.isEmpty
                      ? const _EmptyView()
                      : _MatrixContent(
                          suppliers: suppliers,
                          criterias: criterias,
                          controllers: _controllers,
                          isOwner: isOwner,
                          onChanged: () {
                            if (!_isDirty) setState(() => _isDirty = true);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EvaluationHeader extends StatelessWidget {
  final bool isSaving;
  final bool isDirty;
  final bool isOwner;
  final VoidCallback? onSave;

  const _EvaluationHeader({
    required this.isSaving,
    required this.isDirty,
    required this.isOwner,
    required this.onSave,
  });

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
                'Matriks Penilaian',
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
                      'Matriks Penilaian',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Isi nilai aktual tiap supplier per kriteria.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isOwner)
                GestureDetector(
                  onTap: isSaving ? null : onSave,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSaving
                          ? Colors.white24
                          : isDirty
                              ? AppTheme.primary
                              : const Color(0xFF2DD4BF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.save_outlined,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                isDirty ? 'Simpan*' : 'Simpan',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
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

class _MatrixContent extends StatelessWidget {
  final List<SupplierModel> suppliers;
  final List<CriteriaModel> criterias;
  final Map<int, Map<int, TextEditingController>> controllers;
  final bool isOwner;
  final VoidCallback onChanged;

  const _MatrixContent({
    required this.suppliers,
    required this.criterias,
    required this.controllers,
    required this.isOwner,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOwner
                  ? const Color(0xFF2DD4BF).withOpacity(0.08)
                  : Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isOwner
                    ? const Color(0xFF2DD4BF).withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isOwner ? Icons.info_outline : Icons.visibility_outlined,
                  color: isOwner ? const Color(0xFF2DD4BF) : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isOwner
                        ? 'Isi nilai aktual masing-masing supplier pada setiap kriteria, lalu tekan Simpan.'
                        : 'Anda hanya dapat melihat data matriks penilaian.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOwner
                          ? const Color(0xFF2DD4BF)
                          : Colors.orange,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ...suppliers.asMap().entries.map((entry) {
            final index = entry.key;
            final supplier = entry.value;
            final kode = 'A${index + 1}';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              kode,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          supplier.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: criterias.asMap().entries.map((cEntry) {
                        final criteria = cEntry.value;
                        final isBenefit = criteria.type == 'benefit';
                        final ctrl = controllers[supplier.id]?[criteria.id] ??
                            TextEditingController();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            criteria.code,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            criteria.name,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${isBenefit ? 'Benefit' : 'Cost'} · Skala ${criteria.weightInput.toInt()}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: ctrl,
                                  enabled: isOwner,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isOwner
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    filled: !isOwner,
                                    fillColor: !isOwner
                                        ? AppTheme.background
                                        : Colors.white,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: AppTheme.divider),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: AppTheme.divider),
                                    ),
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: AppTheme.divider),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: AppTheme.primary, width: 1.5),
                                    ),
                                  ),
                                  onChanged: isOwner ? (_) => onChanged() : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

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
              child: Icon(Icons.grid_on_outlined,
                  size: 40, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Data belum lengkap',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pastikan supplier dan kriteria sudah ditambahkan terlebih dahulu.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

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
                    horizontal: 20, vertical: 12),
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