import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../report/presentation/cubit/report_cubit.dart';
import '../../../report/data/models/report_model.dart';

class DriverReportPage extends StatelessWidget {
  const DriverReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
              ReportCubit()
                ..updateRole('driver')
                ..fetchReport(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            const CustomAppBar(title: 'Driver Reports & Analytics'),
            Expanded(
              child: BlocBuilder<ReportCubit, ReportState>(
                builder: (context, state) {
                  // Debug widget to show current state
                  print(
                    '🔍 DriverReportPage: Current state is ${state.runtimeType}',
                  );

                  if (state is ReportLoading) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Loading driver report data...',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is ReportError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading driver report',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<ReportCubit>().fetchReport();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: [
                        // Debug info widget
                        // Container(
                        //   margin: const EdgeInsets.all(16),
                        //   padding: const EdgeInsets.all(16),
                        //   decoration: BoxDecoration(
                        //     color: Colors.blue[50],
                        //     borderRadius: BorderRadius.circular(8),
                        //     border: Border.all(color: Colors.blue[200]!),
                        //   ),
                        //   child: Column(
                        //     crossAxisAlignment: CrossAxisAlignment.start,
                        //     children: [
                        //       Text(
                        //         'Driver Report Debug:',
                        //         style: TextStyle(
                        //           fontWeight: FontWeight.bold,
                        //           color: Colors.blue[700],
                        //         ),
                        //       ),
                        //       const SizedBox(height: 8),
                        //       Text('State: ${state.runtimeType}'),
                        //       Text(
                        //         'Role: ${context.read<ReportCubit>().selectedRole}',
                        //       ),
                        //       Text(
                        //         'From Date: ${DateFormat('yyyy-MM-dd').format(context.read<ReportCubit>().fromDate)}',
                        //       ),
                        //       Text(
                        //         'To Date: ${DateFormat('yyyy-MM-dd').format(context.read<ReportCubit>().toDate)}',
                        //       ),
                        //       const SizedBox(height: 12),
                        //       Row(
                        //         children: [
                        //           Expanded(
                        //             child: ElevatedButton(
                        //               onPressed: () {
                        //                 context.read<ReportCubit>().testCubit();
                        //               },
                        //               child: const Text('Test Cubit'),
                        //             ),
                        //           ),
                        //           const SizedBox(width: 8),
                        //           Expanded(
                        //             child: ElevatedButton(
                        //               onPressed: () {
                        //                 context
                        //                     .read<ReportCubit>()
                        //                     .fetchReport();
                        //               },
                        //               child: const Text('Fetch Report'),
                        //             ),
                        //           ),
                        //         ],
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        const DateRangeFilterCard(),
                        if (state is ReportLoaded) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                const SummaryCard(),
                                const SizedBox(height: 20),
                                const StatisticsGrid(),
                                const SizedBox(height: 20),
                                const PerformanceChart(),
                              ],
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 100),
                          const Center(
                            child: Text(
                              'Select date range to view driver reports',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DateRangeFilterCard extends StatelessWidget {
  const DateRangeFilterCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportCubit, ReportState>(
      builder: (context, state) {
        final cubit = context.read<ReportCubit>();
        final fromDate = cubit.fromDate;
        final toDate = cubit.toDate;

        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.date_range, color: Colors.blue[600], size: 24),
                    const SizedBox(width: 12),
                    Text(
                      "Date Range Filter",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateField(context, 'From Date', fromDate, (
                        date,
                      ) {
                        if (date != null) {
                          cubit.updateDateRange(date, toDate);
                        }
                      }),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateField(context, 'To Date', toDate, (
                        date,
                      ) {
                        if (date != null) {
                          cubit.updateDateRange(fromDate, date);
                        }
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final now = DateTime.now();
                          cubit.updateDateRange(
                            now.subtract(const Duration(days: 7)),
                            now,
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Last 7 Days'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final now = DateTime.now();
                          cubit.updateDateRange(
                            now.subtract(const Duration(days: 30)),
                            now,
                          );
                        },
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('Last 30 Days'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    DateTime date,
    Function(DateTime?) onDateSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
            );
            onDateSelected(selectedDate);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportCubit, ReportState>(
      builder: (context, state) {
        if (state is! ReportLoaded) return const SizedBox.shrink();

        final report = state.report;
        if (report is! DriverReportModel) return const SizedBox.shrink();

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[600]!, Colors.blue[800]!],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_shipping,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Driver Summary',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          'Total Assigned',
                          report.assignedOrders.toString(),
                          Icons.assignment,
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          'On The Way',
                          report.onTheWayOrders.toString(),
                          Icons.local_shipping,
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          'Delivered',
                          report.deliveredOrders.toString(),
                          Icons.check_circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class StatisticsGrid extends StatelessWidget {
  const StatisticsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportCubit, ReportState>(
      builder: (context, state) {
        if (state is! ReportLoaded) return const SizedBox.shrink();

        final report = state.report;
        if (report is! DriverReportModel) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driver Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard(
                  'Assigned Orders',
                  report.assignedOrders.toString(),
                  Icons.assignment,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Started Orders',
                  report.startedOrders.toString(),
                  Icons.play_arrow,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Completed Orders',
                  report.completedOrders.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatCard(
                  'On The Way',
                  report.onTheWayOrders.toString(),
                  Icons.local_shipping,
                  Colors.indigo,
                ),
                _buildStatCard(
                  'Delivered',
                  report.deliveredOrders.toString(),
                  Icons.done_all,
                  Colors.teal,
                ),
                _buildStatCard(
                  'Success Rate',
                  '${((report.completedOrders / report.assignedOrders) * 100).toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.green,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class PerformanceChart extends StatelessWidget {
  const PerformanceChart({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportCubit, ReportState>(
      builder: (context, state) {
        if (state is! ReportLoaded) return const SizedBox.shrink();

        final report = state.report;
        if (report is! DriverReportModel) return const SizedBox.shrink();

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.blue[600], size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Driver Performance Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildProgressBar(
                  'Assigned Orders',
                  report.assignedOrders,
                  report.assignedOrders,
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildProgressBar(
                  'Started Orders',
                  report.startedOrders,
                  report.assignedOrders,
                  Colors.orange,
                ),
                const SizedBox(height: 12),
                _buildProgressBar(
                  'Completed Orders',
                  report.completedOrders,
                  report.assignedOrders,
                  Colors.green,
                ),
                const SizedBox(height: 12),
                _buildProgressBar(
                  'On The Way Orders',
                  report.onTheWayOrders,
                  report.assignedOrders,
                  Colors.indigo,
                ),
                const SizedBox(height: 12),
                _buildProgressBar(
                  'Delivered Orders',
                  report.deliveredOrders,
                  report.assignedOrders,
                  Colors.teal,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(String label, int value, int maxValue, Color color) {
    final percentage = maxValue > 0 ? (value / maxValue) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '$value / $maxValue',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        Text(
          '${(percentage * 100).toStringAsFixed(1)}%',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
