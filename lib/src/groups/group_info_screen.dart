import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';

class GroupInfoScreen extends StatefulWidget {
  final int groupId;
  final String groupName;

  const GroupInfoScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _groupData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGroupInfo();
  }

  Future<void> _loadGroupInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final group = await _apiService.getGroup(widget.groupId);
      if (mounted) {
        setState(() {
          _groupData = group;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load group details: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      body: SafeArea(
        child: Column(
          children: [
            // Minimal Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: SvgPicture.asset(
                      'assets/svg/back.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFEFEEEC),
                        BlendMode.srcIn,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      widget.groupName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEFEEEC),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D7A4F)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGroupInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D7A4F),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_groupData == null) {
      return const Center(
        child: Text(
          'No group data available',
          style: TextStyle(
            color: Color(0xFFA5A5A5),
            fontSize: 14,
          ),
        ),
      );
    }

    // Extract data
    final totalAmount = (_groupData!['total_amount'] as num?)?.toDouble() ?? 0.0;
    final amountPerPeriod = (_groupData!['amount_per_period'] as num?)?.toDouble() ?? 0.0;
    final collectionPeriod = _groupData!['collection_period'] as String? ?? 'monthly';
    final startingDate = _groupData!['starting_date'] as String?;
    final duration = _groupData!['duration'] as int?;
    final hasCommission = _groupData!['has_commission'] as bool? ?? false;
    final commissionType = _groupData!['commission_type'] as String?;
    final commissionValue = (_groupData!['commission_value'] as num?)?.toDouble();
    final finalKuriAmount = (_groupData!['final_kuri_amount'] as num?)?.toDouble();

    // Format date
    String? formattedDate;
    if (startingDate != null) {
      try {
        final date = DateTime.parse(startingDate);
        formattedDate = '${date.month}/${date.day}/${date.year}';
      } catch (e) {
        formattedDate = startingDate;
      }
    }

    // Format period
    final periodText = collectionPeriod == 'weekly' ? 'Weekly' : 'Monthly';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Total Amount - Featured
          _buildFeaturedCard(
            title: 'Total Amount',
            value: '\$${totalAmount.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 24),
          // Section Title
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFA5A5A5),
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Details Grid
          _buildDetailItem(
            label: 'Amount Per Period',
            value: '\$${amountPerPeriod.toStringAsFixed(2)}',
          ),
          if (duration != null)
            _buildDetailItem(
              label: 'Duration',
              value: '$duration ${duration == 1 ? 'period' : 'periods'}',
            ),
          _buildDetailItem(
            label: 'Collection Period',
            value: periodText,
          ),
          if (formattedDate != null)
            _buildDetailItem(
              label: 'Starting Date',
              value: formattedDate,
            ),
          if (hasCommission && commissionValue != null) ...[
            const SizedBox(height: 8),
            _buildDetailItem(
              label: 'Commission',
              value: commissionType == 'percentage'
                  ? '${commissionValue.toStringAsFixed(1)}%'
                  : '\$${commissionValue.toStringAsFixed(2)}',
              subtitle: commissionType == 'percentage' ? 'Percentage' : 'Fixed Amount',
            ),
          ],
          if (finalKuriAmount != null) ...[
            const SizedBox(height: 8),
            _buildDetailItem(
              label: 'Final Kuri Amount',
              value: '\$${finalKuriAmount.toStringAsFixed(2)}',
              subtitle: hasCommission && commissionValue != null
                  ? 'After commission'
                  : null,
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard({
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2D7A4F).withOpacity(0.15),
            const Color(0xFF2D7A4F).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2D7A4F).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7FDE68),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Color(0xFFEFEEEC),
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFA5A5A5),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEFEEEC),
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF7A7A7A),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

