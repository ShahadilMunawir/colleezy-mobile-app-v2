import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'chat_screen.dart';
import '../services/api_service.dart';

class MemberDetailsScreen extends StatefulWidget {
  final int groupId;
  final int memberUserId;
  final String memberName;
  final String memberRole;
  final String memberInitial;
  final Color avatarColor;
  final bool currentUserIsAgent;

  const MemberDetailsScreen({
    super.key,
    required this.groupId,
    required this.memberUserId,
    required this.memberName,
    required this.memberRole,
    required this.memberInitial,
    required this.avatarColor,
    required this.currentUserIsAgent,
  });

  @override
  State<MemberDetailsScreen> createState() => _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends State<MemberDetailsScreen> {
  final ApiService _apiService = ApiService();
  String _selectedStatus = 'collected';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dueController = TextEditingController();
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;
  double? _amountPerPeriod; // Store the group's amount_per_period

  @override
  void initState() {
    super.initState();
    _loadGroupDetails();
    _loadTransactions();
  }
  
  Future<void> _loadGroupDetails() async {
    try {
      final group = await _apiService.getGroup(widget.groupId);
      if (group != null && mounted) {
        final amountPerPeriod = (group['amount_per_period'] as num?)?.toDouble();
        setState(() {
          _amountPerPeriod = amountPerPeriod;
        });
        // Auto-fill amount if "Collected" is selected
        if (_selectedStatus == 'collected' && amountPerPeriod != null) {
          _amountController.text = amountPerPeriod.toStringAsFixed(2);
        }
      }
    } catch (e) {
      print('Error loading group details: $e');
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dueController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transactions = await _apiService.getMemberTransactions(
        groupId: widget.groupId,
        memberUserId: widget.memberUserId,
      );
      
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load transactions: ${e.toString()}';
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
            // Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF141414),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 20, 20),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: SvgPicture.asset(
                        'assets/svg/back.svg',
                        width: 32,
                        height: 32,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: widget.avatarColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          widget.memberInitial,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.memberName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEFEEEC),
                              fontFamily: 'DM Sans',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.memberRole,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFA5A5A5),
                              fontFamily: 'DM Sans',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Edit icon
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: SvgPicture.asset(
                        'assets/svg/add.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              groupName: widget.memberName,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Transactions List
            Expanded(
              child: _buildTransactionsList(),
            ),
            // Collect New Button (only for agents)
            if (widget.currentUserIsAgent)
            Container(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: IntrinsicWidth(
                  child: ElevatedButton(
                    onPressed: () {
                      _showCollectNewModal(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D7A4F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Collect New',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
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
              onPressed: _loadTransactions,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D7A4F),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Color(0xFFA5A5A5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF2F2F2),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Transactions will appear here when money is collected',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFFA5A5A5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      color: const Color(0xFF2D7A4F),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
          final dueAmount = (transaction['due_amount'] as num?)?.toDouble() ?? 0.0;
          final status = transaction['status'] as String? ?? 'collected';
          final createdAt = transaction['created_at'] as String?;
          
          // Format date
          String formattedDate = 'Unknown date';
          if (createdAt != null) {
            try {
              final date = DateTime.parse(createdAt);
              formattedDate = DateFormat('MMM d, yyyy h:mm a').format(date);
            } catch (e) {
              formattedDate = createdAt;
            }
          }
          
          // Format amount
          final formattedAmount = '\$${amount.toStringAsFixed(2)}';
          
          // Determine if completed
          final isCompleted = status == 'collected' && dueAmount == 0;
          
          return _buildTransactionCard(
            amount: amount,
            date: formattedDate,
            value: formattedAmount,
            isCompleted: isCompleted,
            status: status,
            dueAmount: dueAmount,
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard({
    required double amount,
    required String date,
    required String value,
    required bool isCompleted,
    required String status,
    required double dueAmount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF232220),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF181818),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.pending,
              color: isCompleted ? const Color(0xFF2D7A4F) : const Color(0xFFFFA500),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Amount and date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'DM Sans',
                  ),
                ),
                if (dueAmount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Due: \$${dueAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFEF4444),
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFA5A5A5),
                    fontFamily: 'DM Sans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCollectNewModal(BuildContext context) {
    // Reset form when opening modal
    setState(() {
      _selectedStatus = 'collected';
      if (_amountPerPeriod != null) {
        _amountController.text = _amountPerPeriod!.toStringAsFixed(2);
      } else {
        _amountController.clear();
      }
      _dueController.clear();
    });
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF171717),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA5A5A5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Dropdown field
                  GestureDetector(
                    onTap: () {
                      _showDropdownOptions(context, setModalState);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF232220),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedStatus == 'collected' && _amountPerPeriod != null && _amountController.text.isEmpty
                                ? 'Collected (\$${_amountPerPeriod!.toStringAsFixed(2)})'
                                : _selectedStatus.replaceAll('_', ' ').split(' ').map((word) => 
                                    word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
                                  ).join(' '),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'DM Sans',
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Conditionally show Amount and Due fields for Partially Collected
                  if (_selectedStatus == 'partially_collected') ...[
                    const SizedBox(height: 20),
                    // Amount field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Amount',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF232220),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _amountController,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D7A4F),
                              fontFamily: 'DM Sans',
                            ),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              filled: true,
                              fillColor: Color(0xFF232220),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Due field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Due',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF232220),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _dueController,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEF4444),
                              fontFamily: 'DM Sans',
                            ),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              filled: true,
                              fillColor: Color(0xFF232220),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 30),
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        // For "Collected" status, use amount_per_period if amount is not provided
                        double amount;
                        if (_selectedStatus == 'collected') {
                          if (_amountController.text.trim().isEmpty) {
                            // Use amount_per_period if available
                            if (_amountPerPeriod != null) {
                              amount = _amountPerPeriod!;
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter an amount'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                          } else {
                            amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
                            if (amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Amount must be greater than 0'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                          }
                        } else {
                          // For other statuses, require manual input
                          if (_amountController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter an amount'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
                          if (amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Amount must be greater than 0'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                        }
                        
                        // Get due amount if partially collected
                        double? dueAmount;
                        if (_selectedStatus == 'partially_collected') {
                          if (_dueController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter due amount for partially collected'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          dueAmount = double.tryParse(_dueController.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
                        }
                        
                        // Show loading
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D7A4F)),
                            ),
                          ),
                        );
                        
                        try {
                          // Map status
                          String status = 'collected';
                          if (_selectedStatus == 'partially_collected') {
                            status = 'partially_collected';
                          }
                          
                          final result = await _apiService.createTransaction(
                            groupId: widget.groupId,
                            memberUserId: widget.memberUserId,
                            amount: amount,
                            dueAmount: dueAmount,
                            status: status,
                          );
                          
                          // Close loading and modal
                          if (mounted) {
                            Navigator.pop(context); // Close loading
                            Navigator.pop(bottomSheetContext); // Close modal
                          }
                          
                          if (result != null) {
                            // Show success message
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Transaction recorded successfully!'),
                                  backgroundColor: Color(0xFF2D7A4F),
                                ),
                              );
                            }
                            
                            // Clear form
                            _amountController.clear();
                            _dueController.clear();
                            setState(() {
                              _selectedStatus = 'collected';
                            });
                            
                            // Refresh transactions
                            _loadTransactions();
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to record transaction. Please try again.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          // Close loading
                          if (mounted) Navigator.pop(context);
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D7A4F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'DM Sans',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDropdownOptions(BuildContext context, StateSetter setModalState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF171717),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFA5A5A5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildDropdownOption('Collected', setModalState, context),
              _buildDropdownOption('Partially Collected', setModalState, context),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdownOption(
    String option,
    StateSetter setModalState,
    BuildContext context,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = option.toLowerCase().replaceAll(' ', '_');
        });
        setModalState(() {});
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Text(
          option,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _selectedStatus == option.toLowerCase().replaceAll(' ', '_') ? Colors.white : const Color(0xFFA5A5A5),
            fontFamily: 'DM Sans',
          ),
        ),
      ),
    );
  }
}

