// lib/View/Admin/AdminDashboard/admin_dashboard_screen.dart
// Full Admin Dashboard - replaces the empty AdminDashboard widget
// Shows stats, draw management, and upload controls

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../Admin/AllUsers/all_users.dart';
import '../../../Controllers/AdminControllers/admin_draw_controller.dart';
import '../../../Controllers/AuthControllers/auth_controller.dart';
import '../../../Models/draw_model.dart';
import '../DrawManagement/create_draw_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminDrawController ctrl = Get.put(AdminDrawController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3C40),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Dashboard',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('National Savings Pakistan',
                style: TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'View Users',
            onPressed: () => Get.to(() => CustomerListScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Get.find<AuthController>().signOut(),
          ),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            await ctrl.loadDraws();
            await ctrl.loadStats();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── STATS CARDS ─────────────────────────────────────────────
                _buildStatsRow(ctrl),
                const SizedBox(height: 20),

                // ── UPLOAD BUTTON ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Get.to(() => CreateDrawScreen()),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload New Draw Result',
                        style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A3C40),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── DRAWS LIST ──────────────────────────────────────────────
                const Text('All Draw Results',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 12),

                ctrl.allDraws.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('No draws uploaded yet.',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ctrl.allDraws.length,
                        itemBuilder: (_, i) =>
                            _AdminDrawCard(draw: ctrl.allDraws[i]),
                      ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatsRow(AdminDrawController ctrl) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Users',
            value: ctrl.totalUsers.value.toString(),
            icon: Icons.people,
            color: const Color(0xFF4CAF9A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Saved Bonds',
            value: ctrl.totalSavedBonds.value.toString(),
            icon: Icons.savings,
            color: const Color(0xFFF5C842),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Draws',
            value: ctrl.totalDraws.value.toString(),
            icon: Icons.emoji_events,
            color: const Color(0xFF1A3C40),
          ),
        ),
      ],
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ── Admin Draw Card ────────────────────────────────────────────────────────────
class _AdminDrawCard extends StatelessWidget {
  final DrawModel draw;

  const _AdminDrawCard({required this.draw});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AdminDrawController>();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Denomination badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3C40).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Rs. ${draw.denomination}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A3C40))),
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: () => ctrl.confirmDeleteDraw(draw),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Draw #${draw.drawNumber}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.grey),
                Text(draw.city,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(width: 12),
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: Colors.grey),
                Text(
                  DateFormat('MMM dd, yyyy').format(draw.drawDate),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Winners count
            Text(
              '${draw.winningNumbers.length} winning numbers',
              style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            // PDF indicator
            if (draw.pdfUrl != null) ...[
              const SizedBox(height: 4),
              const Row(
                children: [
                  Icon(Icons.picture_as_pdf, size: 14, color: Colors.red),
                  SizedBox(width: 4),
                  Text('PDF attached',
                      style: TextStyle(fontSize: 12, color: Colors.red)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
