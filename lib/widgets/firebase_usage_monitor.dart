import 'package:flutter/material.dart';
import 'package:wishlist_app/services/firebase_functions_service.dart';

/// Widget to monitor Firebase usage and show usage statistics
class FirebaseUsageMonitor extends StatefulWidget {
  const FirebaseUsageMonitor({super.key});

  @override
  State<FirebaseUsageMonitor> createState() => _FirebaseUsageMonitorState();
}

class _FirebaseUsageMonitorState extends State<FirebaseUsageMonitor> {
  final FirebaseFunctionsService _functionsService = FirebaseFunctionsService();
  Map<String, double>? _usagePercentages;
  Map<String, dynamic>? _healthStatus;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsageData();
  }

  Future<void> _loadUsageData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final percentages = await _functionsService.getUsagePercentages();
      final health = await _functionsService.getHealthStatus();

      setState(() {
        _usagePercentages = percentages;
        _healthStatus = health;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Firebase Usage Monitor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadUsageData,
                  tooltip: 'Refresh Usage Data',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              _buildErrorWidget()
            else
              _buildUsageWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.red[400],
          size: 48,
        ),
        const SizedBox(height: 8),
        Text(
          'Error loading usage data',
          style: TextStyle(color: Colors.red[400]),
        ),
        const SizedBox(height: 4),
        Text(
          _error!,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUsageWidget() {
    if (_usagePercentages == null || _healthStatus == null) {
      return const Text('No usage data available');
    }

    final status = _healthStatus!['status'] as String;
    final usage = _healthStatus!['usage'] as Map<String, dynamic>;
    final limits = _healthStatus!['limits'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status indicator
        Row(
          children: [
            Icon(
              status == 'healthy' ? Icons.check_circle : Icons.warning,
              color: status == 'healthy' ? Colors.green : Colors.orange,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              status == 'healthy' ? 'System Healthy' : 'System Warning',
              style: TextStyle(
                color: status == 'healthy' ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Usage bars
        _buildUsageBar(
          'Database Reads',
          _usagePercentages!['reads']!,
          usage['reads'],
          limits['reads'],
          Colors.blue,
        ),
        const SizedBox(height: 12),
        
        _buildUsageBar(
          'Database Writes',
          _usagePercentages!['writes']!,
          usage['writes'],
          limits['writes'],
          Colors.green,
        ),
        const SizedBox(height: 12),
        
        _buildUsageBar(
          'Cloud Functions',
          _usagePercentages!['functions']!,
          usage['functions'],
          limits['functions'],
          Colors.purple,
        ),
        const SizedBox(height: 16),

        // Warning message if approaching limits
        if (_usagePercentages!.values.any((percentage) => percentage >= 80))
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.orange[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aproximando dos limites diários. Considere reduzir o uso.',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),
        
        // Date information
        if (_healthStatus!['date'] != null)
          Text(
            'Last updated: ${_healthStatus!['date']}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  Widget _buildUsageBar(
    String label,
    double percentage,
    int current,
    int limit,
    Color color,
  ) {
    final isHighUsage = percentage >= 80;
    final displayColor = isHighUsage ? Colors.orange : color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${current.toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]},',
              )} / ${limit.toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]},',
              )}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        
        // Progress bar
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: (percentage / 100).clamp(0.0, 1.0),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: displayColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        
        // Percentage text
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 11,
            color: isHighUsage ? Colors.orange[700] : Colors.grey[600],
            fontWeight: isHighUsage ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

/// Simplified usage widget for status bar or small spaces
class FirebaseUsageBadge extends StatelessWidget {
  const FirebaseUsageBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: FirebaseFunctionsService().isApproachingLimits(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => const AlertDialog(
                title: Text('Firebase Usage'),
                content: FirebaseUsageMonitor(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning,
                  size: 14,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 4),
                Text(
                  'Usage Alert',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}