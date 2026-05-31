import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_event.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../blocs/dashboard/dashboard_bloc.dart';
import '../../../blocs/dashboard/dashboard_event.dart';
import '../../../blocs/dashboard/dashboard_state.dart';
import '../../../blocs/user/user_bloc.dart';
import '../../../blocs/supplier/supplier_bloc.dart';
import '../../../blocs/criteria/criteria_bloc.dart';
import '../../../blocs/evaluation/evaluation_bloc.dart';
import '../../../blocs/decision_result/decision_result_bloc.dart';
import '../../../blocs/decision_history/decision_history_bloc.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/repositories/supplier_repository.dart';
import '../../../../data/repositories/criteria_repository.dart';
import '../../../../data/repositories/evaluation_repository.dart';
import '../../../../data/repositories/decision_history_repository.dart';
import '../user/user_page.dart';
import '../supplier/supplier_page.dart';
import '../criteria/criteria_page.dart';
import '../evaluation/evaluation_page.dart';
import '../decision_result/decision_result_page.dart';
import '../decision_history/decision_history_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
    _NavItem(icon: Icons.store_outlined, activeIcon: Icons.store, label: 'Supplier'),
    _NavItem(icon: Icons.list_alt_outlined, activeIcon: Icons.list_alt, label: 'Kriteria'),
    _NavItem(icon: Icons.grid_on_outlined, activeIcon: Icons.grid_on, label: 'Matriks Penilaian'),
    _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Hasil Keputusan'),
    _NavItem(icon: Icons.history_outlined, activeIcon: Icons.history, label: 'Riwayat Keputusan'),
    _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Manajemen Karyawan'),
  ];

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(const DashboardStatsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isOwner = authState is AuthAuthenticated &&
        authState.user.role == 'owner';

    // Filter nav items berdasarkan role
    final List<_NavItem> visibleItems = isOwner
        ? _navItems
        : _navItems
            .where((item) =>
                item.label == 'Dashboard' ||
                item.label == 'Supplier' ||
                item.label == 'Matriks Penilaian')
            .toList();

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go(AppRouter.login);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        drawer: _SideDrawer(
          selectedIndex: _selectedIndex,
          items: visibleItems,        // pakai visibleItems
          allItems: _navItems,        // untuk _buildPage tetap pakai index asli
          onItemSelected: (i) {
            setState(() => _selectedIndex = i);
            Navigator.pop(context);
          },
        ),
        body: _buildPage(_selectedIndex),
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
      return const _DashboardHome();
      case 1:
      return BlocProvider(
        create: (context) => SupplierBloc(
          supplierRepository: context.read<SupplierRepository>(),
        ),
        child: const SupplierPage(),
      );
      case 2:
      return BlocProvider(
        create: (context) => CriteriaBloc(
          criteriaRepository: context.read<CriteriaRepository>(),
        ),
        child: const CriteriaPage(),
      );
      case 3:
        return BlocProvider(
          create: (context) => EvaluationBloc(
            evaluationRepository: context.read<EvaluationRepository>(),
            supplierRepository: context.read<SupplierRepository>(),
            criteriaRepository: context.read<CriteriaRepository>(),
          ),
          child: const EvaluationPage(),
        );
      case 4:
      return BlocProvider(
        create: (context) => DecisionResultBloc(
          historyRepository: context.read<DecisionHistoryRepository>(),
          evaluationRepository: context.read<EvaluationRepository>(),
        ),
        child: const DecisionResultPage(),
      );
      case 5:
        return BlocProvider(
          create: (context) => DecisionHistoryBloc(
            historyRepository: context.read<DecisionHistoryRepository>(),
            evaluationRepository: context.read<EvaluationRepository>(),
          ),
          child: const DecisionHistoryPage(),
        );
        case 6:
        return BlocProvider(
          create: (context) => UserBloc(
            userRepository: context.read<UserRepository>(),
          ),
          child: const UserPage(),
        );
        default:
          return _PlaceholderPage(
            label: _navItems[index].label,
            icon: _navItems[index].activeIcon,
          );
      }
    }
  }

// ─── Nav Item Model ───────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

// ─── Side Drawer ──────────────────────────────────────────────────────────────

class _SideDrawer extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;
  final List<_NavItem> allItems; 
  final Function(int) onItemSelected;

  const _SideDrawer({
    required this.selectedIndex,
    required this.items,
    required this.allItems,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A1A),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/ngacoan.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'SPK Ngacoan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final realIndex = allItems.indexOf(item);
                  final isSelected = selectedIndex == realIndex;
                  return _DrawerItem(
                    item: item,
                    isSelected: isSelected,
                    onTap: () => onItemSelected(realIndex),
                  );
                },
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            _DrawerLogoutButton(),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: AppTheme.primary.withOpacity(0.3), width: 0.5)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected ? AppTheme.primary : Colors.white54,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppTheme.primary : Colors.white70,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerLogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final name = state is AuthAuthenticated ? state.user.name : 'Pengguna';
        final role = state is AuthAuthenticated
            ? _capitalize(state.user.role ?? '')
            : '';

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary.withOpacity(0.2),
                radius: 18,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (role.isNotEmpty)
                      Text(
                        role,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout_outlined, color: AppTheme.error, size: 20),
                tooltip: 'Keluar',
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            child: const Text('Keluar', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

// ─── Dashboard Home ───────────────────────────────────────────────────────────

class _DashboardHome extends StatelessWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _DashboardHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text(
                  'Ringkasan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Stat Cards dari API
                BlocBuilder<DashboardBloc, DashboardState>(
                  builder: (context, state) {
                    if (state is DashboardLoading) {
                      return const _StatCardsShimmer();
                    }

                    if (state is DashboardError) {
                      return _StatCardsError(
                        message: state.message,
                        onRetry: () => context
                            .read<DashboardBloc>()
                            .add(const DashboardStatsRequested()),
                      );
                    }

                    final stats = state is DashboardLoaded ? state.stats : null;

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Total Kriteria',
                                value: stats != null
                                    ? stats.totalCriteria.toString()
                                    : '-',
                                subtitle: 'Parameter aktif',
                                icon: Icons.format_list_bulleted,
                                iconColor: const Color(0xFF2DD4BF),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Total Supplier',
                                value: stats != null
                                    ? stats.totalSuppliers.toString()
                                    : '-',
                                subtitle: 'Mitra terdaftar',
                                icon: Icons.people_outline,
                                iconColor: const Color(0xFF2DD4BF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Rekomendasi',
                                value: stats?.topSupplier ?? '-',
                                subtitle: 'Skor EDAS tertinggi',
                                icon: Icons.emoji_events_outlined,
                                iconColor: const Color(0xFFF59E0B),
                                isSmallValue: stats?.topSupplier != null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Status Sistem',
                                value: stats != null ? stats.systemStatus : '-',
                                subtitle: stats != null
                                    ? (stats.matrixReady ? 'Siap dikalkulasi' : 'Lengkapi data')
                                    : 'Memuat...',
                                icon: Icons.show_chart,
                                iconColor: stats != null
                                    ? (stats.matrixReady
                                        ? const Color(0xFF8B5CF6)
                                        : const Color(0xFFF59E0B))
                                    : const Color(0xFF8B5CF6),
                                isSmallValue: false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                // ── Status Matriks (dari API)
                BlocBuilder<DashboardBloc, DashboardState>(
                  builder: (context, state) {
                    final isReady = state is DashboardLoaded
                        ? state.stats.matrixReady
                        : null;
                    return _MatriksStatusCard(isReady: isReady);
                  },
                ),
                const SizedBox(height: 16),

                _AlurKeputusanCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dashboard Header ─────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting = 'Selamat Pagi';
    if (hour >= 11 && hour < 15) greeting = 'Selamat Siang';
    else if (hour >= 15 && hour < 18) greeting = 'Selamat Sore';
    else if (hour >= 18) greeting = 'Selamat Malam';

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final name = state is AuthAuthenticated ? state.user.name : 'Pengguna';
        final role = state is AuthAuthenticated
            ? _capitalize(state.user.role ?? '')
            : 'Pengguna';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                  const SizedBox(width: 10),
                  Image.asset(
                    'assets/images/ngacoan.png',
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'SPK Ngacoan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  // Refresh button
                  GestureDetector(
                    onTap: () => context
                        .read<DashboardBloc>()
                        .add(const DashboardStatsRefreshed()),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.refresh_outlined,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.primary.withOpacity(0.2),
                    radius: 16,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '$greeting, $role 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Berikut ringkasan data pengambilan keputusan Anda.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

// ─── Stat Cards Shimmer (loading) ─────────────────────────────────────────────

class _StatCardsShimmer extends StatefulWidget {
  const _StatCardsShimmer();

  @override
  State<_StatCardsShimmer> createState() => _StatCardsShimmerState();
}

class _StatCardsShimmerState extends State<_StatCardsShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Column(
          children: [
            Row(children: [
              Expanded(child: _shimmerCard()),
              const SizedBox(width: 12),
              Expanded(child: _shimmerCard()),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _shimmerCard()),
              const SizedBox(width: 12),
              Expanded(child: _shimmerCard()),
            ]),
          ],
        );
      },
    );
  }

  Widget _shimmerCard() {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 10,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(_animation.value),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Spacer(),
          Container(
            height: 20,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(_animation.value),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 8,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(_animation.value * 0.6),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Cards Error ─────────────────────────────────────────────────────────

class _StatCardsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _StatCardsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.error, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Gagal memuat data. Periksa koneksi Anda.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Coba lagi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isSmallValue;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.isSmallValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallValue ? 14 : 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Matriks Status Card ──────────────────────────────────────────────────────

class _MatriksStatusCard extends StatelessWidget {
  final bool? isReady;
  const _MatriksStatusCard({this.isReady});

  @override
  Widget build(BuildContext context) {
    final ready = isReady ?? false;
    final color = ready ? const Color(0xFF2DD4BF) : const Color(0xFFF59E0B);
    final icon = ready ? Icons.calculate_outlined : Icons.warning_amber_outlined;
    final title = ready ? 'Siap Dikalkulasi' : 'Belum Siap';
    final subtitle = ready
        ? 'Data matriks sudah memenuhi syarat.'
        : 'Lengkapi data evaluasi terlebih dahulu.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Matriks',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white38,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ),
          Icon(
            ready ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            color: color,
            size: 20,
          ),
        ],
      ),
    );
  }
}

// ─── Alur Keputusan Card ──────────────────────────────────────────────────────

class _AlurKeputusanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alur Pengambilan Keputusan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
              children: [
                TextSpan(text: 'Sistem menggunakan metode '),
                TextSpan(
                  text: 'EDAS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextSpan(
                  text: ' (Evaluation Based on Distance from Average Solution). Ikuti tahapan:',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _AlurItem(number: '1', text: 'Pastikan parameter ', bold: 'Kriteria', suffix: ' sudah sesuai.'),
          const _AlurItem(number: '2', text: 'Pastikan data ', bold: 'Supplier', suffix: ' terbaru terdaftar.'),
          const _AlurItem(number: '3', text: 'Isi nilai aktual pada ', bold: 'Matriks Penilaian', suffix: '.'),
          const _AlurItem(number: '4', text: 'Jalankan komputasi di ', bold: 'Hasil Keputusan', suffix: '.'),
        ],
      ),
    );
  }
}

// ─── Alur Item ────────────────────────────────────────────────────────────────

class _AlurItem extends StatelessWidget {
  final String number;
  final String text;
  final String bold;
  final String suffix;

  const _AlurItem({
    required this.number,
    required this.text,
    required this.bold,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(right: 10, top: 1),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                children: [
                  TextSpan(text: text),
                  TextSpan(
                    text: bold,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  TextSpan(text: suffix),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Placeholder Page ─────────────────────────────────────────────────────────

class _PlaceholderPage extends StatelessWidget {
  final String label;
  final IconData icon;
  const _PlaceholderPage({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            color: const Color(0xFF1A1A1A),
            child: Row(
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
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: AppTheme.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Halaman ini belum tersedia.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}