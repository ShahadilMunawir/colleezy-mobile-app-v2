import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class MemberDetailsScreen extends StatefulWidget {
  final int groupId;
  final int memberUserId;
  final String memberName;
  final String memberRole;
  final String memberInitial;
  final Color avatarColor;
  final bool currentUserIsAgent;
  final int? initialYear; // Optional: Year to auto-select when opening transaction modal
  final int? initialMonth; // Optional: Month to auto-select when opening transaction modal

  const MemberDetailsScreen({
    super.key,
    required this.groupId,
    required this.memberUserId,
    required this.memberName,
    required this.memberRole,
    required this.memberInitial,
    required this.avatarColor,
    required this.currentUserIsAgent,
    this.initialYear,
    this.initialMonth,
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
  DateTime? _groupStartingDate; // Store the group's starting_date
  DateTime? _selectedTransactionDate; // Will be set based on current month payment status
  Set<String> _fullyCollectedMonths = {}; // Set of "YYYY-MM" strings for months fully collected
  Set<String> _partialOnlyMonths = {}; // Set of "YYYY-MM" strings for months with only partial collections

  @override
  void initState() {
    super.initState();
    _loadGroupDetails();
    _loadTransactions();
    
    // If initialYear and initialMonth are provided, open the modal automatically
    if (widget.initialYear != null && widget.initialMonth != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Wait a bit for group details to load before opening modal
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _showCollectNewModal(context);
            }
          });
        }
      });
    }
  }
  
  Future<void> _loadGroupDetails() async {
    try {
      final group = await _apiService.getGroup(widget.groupId);
      if (group != null && mounted) {
        final amountPerPeriod = (group['amount_per_period'] as num?)?.toDouble();
        final startingDateStr = group['starting_date'] as String?;
        DateTime? startingDate;
        if (startingDateStr != null) {
          try {
            startingDate = DateTime.parse(startingDateStr);
          } catch (e) {
            print('Error parsing starting_date: $e');
          }
        }
        setState(() {
          _amountPerPeriod = amountPerPeriod;
          _groupStartingDate = startingDate;
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

  Future<void> _loadTransactionMonths() async {
    try {
      final monthsData = await _apiService.getMemberTransactionMonths(
        groupId: widget.groupId,
        memberUserId: widget.memberUserId,
      );
      
      if (mounted) {
        // Convert to sets of "YYYY-MM" strings for easy lookup
        final fullyCollectedSet = (monthsData['fully_collected_months'] as List? ?? [])
            .map((month) {
              final year = month['year'] as int;
              final monthNum = month['month'] as int;
              return '${year}-${monthNum.toString().padLeft(2, '0')}';
            }).toSet();
        
        final partialOnlySet = (monthsData['partial_only_months'] as List? ?? [])
            .map((month) {
              final year = month['year'] as int;
              final monthNum = month['month'] as int;
              return '${year}-${monthNum.toString().padLeft(2, '0')}';
            }).toSet();
        
        setState(() {
          _fullyCollectedMonths = fullyCollectedSet;
          _partialOnlyMonths = partialOnlySet;
          // Set default transaction date based on current month payment status and selected status
          // Only set if not already set (to preserve user selection)
          if (_selectedTransactionDate == null) {
            _selectedTransactionDate = _getDefaultTransactionDate(status: _selectedStatus);
          }
        });
      }
    } catch (e) {
      print('Error loading transaction months: $e');
      // Don't show error to user, just log it
    }
  }
  
  // Check if the selected date's month only allows partial collections
  bool _isPartialOnlyMonth(DateTime date) {
    final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    if (_partialOnlyMonths.contains(monthKey)) {
      return true;
    }
    
    // Also check if there are any partial transactions for this period
    // This is a fallback in case the months data hasn't loaded yet
    if (_groupStartingDate == null || _amountPerPeriod == null) {
      return false;
    }
    
    // Calculate period number for the selected date
    final start = _groupStartingDate!;
    int periodNumber;
    
    // For monthly groups, calculate period based on year and month difference
    final yearDiff = date.year - start.year;
    final monthDiff = date.month - start.month;
    periodNumber = yearDiff * 12 + monthDiff + 1;
    
    // Check if there are any transactions for this period
    bool hasPartialTransaction = false;
    double totalCollected = 0.0;
    
    for (var transaction in _transactions) {
      final periodNum = transaction['period_number'] as int?;
      if (periodNum == periodNumber) {
        final status = transaction['status'] as String?;
        final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
        totalCollected += amount;
        
        // If there's a partial transaction, this month only allows partial payments
        if (status == 'partially_collected') {
          hasPartialTransaction = true;
        }
      }
    }
    
    // If there are partial transactions and the period is not fully paid, only allow partial
    if (hasPartialTransaction && totalCollected < _amountPerPeriod!) {
      return true;
    }
    
    return false;
  }
  
  // Check if the current month is fully paid
  bool _isCurrentMonthFullyPaid() {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return _fullyCollectedMonths.contains(monthKey);
  }
  
  // Get default transaction date based on payment status
  // For "collected" (full payment): today if current month is not fully paid, null otherwise
  // For "partially_collected": today if current month is not fully paid, null otherwise
  DateTime? _getDefaultTransactionDate({String? status}) {
    // If current month is fully paid, don't set default date
    if (_isCurrentMonthFullyPaid()) {
      return null;
    }
    // For "collected" status, show today as default if current month is not fully paid
    if (status == 'collected' || status == null) {
      return DateTime.now();
    }
    // For partial payments, also show today as default if current month is not fully paid
    return DateTime.now();
  }
  
  // Calculate total collected for the selected period/month
  double _getTotalCollectedForPeriod(DateTime date) {
    if (_groupStartingDate == null) return 0.0;
    
    // Calculate period number for the selected date
    final start = _groupStartingDate!;
    int periodNumber;
    
    // For monthly groups, calculate period based on year and month difference
    final yearDiff = date.year - start.year;
    final monthDiff = date.month - start.month;
    periodNumber = yearDiff * 12 + monthDiff + 1;
    
    // Sum all transactions for this period
    double total = 0.0;
    for (var transaction in _transactions) {
      final periodNum = transaction['period_number'] as int?;
      if (periodNum == periodNumber) {
        final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
        total += amount;
      }
    }
    
    return total;
  }
  
  // Calculate and update due amount based on current amount input
  void _calculateDueAmount(String amountText, StateSetter setModalState) {
    if (_amountPerPeriod == null || _selectedTransactionDate == null) return;
    
    final amount = double.tryParse(amountText.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    final totalCollected = _getTotalCollectedForPeriod(_selectedTransactionDate!);
    final due = _amountPerPeriod! - (totalCollected + amount);
    
    setModalState(() {
      _dueController.text = due > 0 ? due.toStringAsFixed(2) : '0.00';
    });
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
          final transactionDate = transaction['transaction_date'] as String?;
          
          // Format date using transaction_date instead of created_at
          String formattedDate = 'Unknown date';
          if (transactionDate != null) {
            try {
              final date = DateTime.parse(transactionDate);
              formattedDate = DateFormat('MMM d, yyyy').format(date);
            } catch (e) {
              formattedDate = transactionDate;
            }
          }
          
          // Format amount
          final formattedAmount = '₹${amount.toStringAsFixed(2)}';
          
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
                    'Due: ₹${dueAmount.toStringAsFixed(2)}',
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
    // Load transaction months when opening modal first
    _loadTransactionMonths();
    
    // Reset form when opening modal
    setState(() {
      // Set default transaction date
      // If initialYear and initialMonth are provided, use them; otherwise use default logic
      if (widget.initialYear != null && widget.initialMonth != null) {
        // Use the provided year and month, set to first day of the month
        _selectedTransactionDate = DateTime(widget.initialYear!, widget.initialMonth!, 1);
        // When navigated from All Dues page, default to "partially_collected" since there's a due amount
        _selectedStatus = 'partially_collected';
      } else {
        // Default to "collected" status for normal navigation
        _selectedStatus = 'collected';
        // Set default transaction date for "collected" status
        // Show today if current month is not fully paid, else null
        _selectedTransactionDate = _getDefaultTransactionDate(status: 'collected');
      }
      
      // Check if the selected date's month only allows partial collections
      final isPartialOnly = _selectedTransactionDate != null && _isPartialOnlyMonth(_selectedTransactionDate!);
      
      // If the month only allows partial collections, update status (unless already set from All Dues navigation)
      if (isPartialOnly && widget.initialYear == null && widget.initialMonth == null) {
        _selectedStatus = 'partially_collected';
      }
      
      // Set amount field
      if (_amountPerPeriod != null && _selectedStatus == 'collected' && !isPartialOnly) {
        _amountController.text = _amountPerPeriod!.toStringAsFixed(2);
      } else if (_selectedStatus == 'partially_collected' && _selectedTransactionDate != null && _amountPerPeriod != null) {
        // Auto-populate with remaining due amount for partial payments
        final totalCollected = _getTotalCollectedForPeriod(_selectedTransactionDate!);
        final remainingDue = _amountPerPeriod! - totalCollected;
        if (remainingDue > 0) {
          _amountController.text = remainingDue.toStringAsFixed(2);
        } else {
          _amountController.clear();
        }
      } else {
        _amountController.clear();
      }
      _dueController.clear();
    });
    
    // Calculate initial due amount if partial collection and amount is set
    // Calculate due amount if status is partially_collected (either from All Dues navigation or partial-only month)
    if (_selectedStatus == 'partially_collected' && _amountPerPeriod != null && _selectedTransactionDate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
          final totalCollected = _getTotalCollectedForPeriod(_selectedTransactionDate!);
          final due = _amountPerPeriod! - (totalCollected + amount);
          _dueController.text = due > 0 ? due.toStringAsFixed(2) : '0.00';
        }
      });
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext bottomSheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF171717),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
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
                                ? 'Collected (₹${_amountPerPeriod!.toStringAsFixed(2)})'
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
                            onChanged: (value) {
                              _calculateDueAmount(value, setModalState);
                            },
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
                            readOnly: true,
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
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                color: Color(0xFFA5A5A5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Transaction Date Picker
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Collection Date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'DM Sans',
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          // Helper function to check if a date is selectable
                          // Disable dates in months that are fully collected
                          bool isDateSelectable(DateTime date) {
                            final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
                            return !_fullyCollectedMonths.contains(monthKey);
                          }
                          
                          final firstDate = _groupStartingDate ?? DateTime(2020);
                          final lastDate = DateTime.now();
                          
                          // Find a valid initial date that satisfies the predicate
                          DateTime? initialDate;
                          
                          // First, check if the currently selected date is selectable
                          if (_selectedTransactionDate != null && isDateSelectable(_selectedTransactionDate!)) {
                            initialDate = _selectedTransactionDate;
                          } else {
                            // Try to find a selectable date by going backwards from today
                            DateTime candidate = lastDate;
                            while (candidate.isAfter(firstDate) || candidate.isAtSameMomentAs(firstDate)) {
                              if (isDateSelectable(candidate)) {
                                initialDate = candidate;
                                break;
                              }
                              candidate = candidate.subtract(const Duration(days: 1));
                            }
                            
                            // If still no selectable date found, try going forward from firstDate
                            if (initialDate == null) {
                              candidate = firstDate;
                              while (candidate.isBefore(lastDate) || candidate.isAtSameMomentAs(lastDate)) {
                                if (isDateSelectable(candidate)) {
                                  initialDate = candidate;
                                  break;
                                }
                                candidate = candidate.add(const Duration(days: 1));
                              }
                            }
                          }
                          
                          // If no selectable date exists, show an error message
                          if (initialDate == null) {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                backgroundColor: const Color(0xFF232220),
                                title: const Text(
                                  'No Available Dates',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'DM Sans',
                                  ),
                                ),
                                content: const Text(
                                  'All available months already have transactions recorded.',
                                  style: TextStyle(
                                    color: Color(0xFFA5A5A5),
                                    fontFamily: 'DM Sans',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(),
                                    child: const Text(
                                      'OK',
                                      style: TextStyle(
                                        color: Color(0xFF2D7A4F),
                                        fontFamily: 'DM Sans',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }
                          
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: initialDate,
                            firstDate: firstDate,
                            lastDate: lastDate,
                            selectableDayPredicate: isDateSelectable,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: Color(0xFF2D7A4F),
                                    onPrimary: Colors.white,
                                    surface: Color(0xFF171717),
                                    onSurface: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setModalState(() {
                              _selectedTransactionDate = picked;
                              // If the selected month only allows partial collections, restrict status
                              if (_isPartialOnlyMonth(picked)) {
                                _selectedStatus = 'partially_collected';
                                // Auto-populate amount with remaining due for partial payments
                                if (_amountPerPeriod != null) {
                                  final totalCollected = _getTotalCollectedForPeriod(picked);
                                  final remainingDue = _amountPerPeriod! - totalCollected;
                                  if (remainingDue > 0) {
                                    _amountController.text = remainingDue.toStringAsFixed(2);
                                  } else {
                                    _amountController.clear();
                                  }
                                }
                              }
                              // Recalculate due amount when date changes
                              if (_selectedStatus == 'partially_collected' && _amountController.text.isNotEmpty) {
                                _calculateDueAmount(_amountController.text, setModalState);
                              }
                            });
                          }
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
                                _selectedTransactionDate != null
                                    ? DateFormat('MMM d, yyyy').format(_selectedTransactionDate!)
                                    : 'Select date',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedTransactionDate != null ? Colors.white : const Color(0xFFA5A5A5),
                                  fontFamily: 'DM Sans',
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                color: Color(0xFFA5A5A5),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
                        
                        // Get due amount if partially collected (auto-calculated)
                        double? dueAmount;
                        if (_selectedStatus == 'partially_collected') {
                          // Due amount is auto-calculated, so get it from the controller
                          dueAmount = double.tryParse(_dueController.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
                          // Ensure due amount is not negative
                          if (dueAmount < 0) {
                            dueAmount = 0.0;
                          }
                        }
                        
                        // Validate transaction date
                        // Validate that a date is selected
                        if (_selectedTransactionDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a collection date'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        final today = DateTime.now();
                        final todayDate = DateTime(today.year, today.month, today.day);
                        final selectedDate = DateTime(_selectedTransactionDate!.year, _selectedTransactionDate!.month, _selectedTransactionDate!.day);
                        
                        if (selectedDate.isAfter(todayDate)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaction date cannot be in the future'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        if (_groupStartingDate != null) {
                          final startDate = DateTime(_groupStartingDate!.year, _groupStartingDate!.month, _groupStartingDate!.day);
                          if (selectedDate.isBefore(startDate)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Transaction date cannot be before group start date (${DateFormat('MMM d, yyyy').format(_groupStartingDate!)})'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                        }
                        
                        // Validate that "collected" status is not used for partial-only months
                        if (_selectedStatus == 'collected' && _selectedTransactionDate != null && _isPartialOnlyMonth(_selectedTransactionDate!)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('This month only allows partial collections. Please select "Partially Collected" instead.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
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
                            transactionDate: _selectedTransactionDate,
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
                            
                            // Refresh transactions and transaction months
                            _loadTransactions();
                            _loadTransactionMonths();
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
                            if (mounted) {
                              Navigator.pop(context); // Close loading
                            }
                            
                            // Parse error message from API response if available
                            String errorMessage = 'Error creating transaction';
                            final errorStr = e.toString();
                            if (errorStr.contains('Transaction for period')) {
                              errorMessage = 'A transaction for this period already exists';
                            } else if (errorStr.contains('cannot be in the future')) {
                              errorMessage = 'Transaction date cannot be in the future';
                            } else if (errorStr.contains('cannot be before group start date')) {
                              errorMessage = 'Transaction date cannot be before group start date';
                            } else if (errorStr.isNotEmpty) {
                              errorMessage = errorStr;
                            }
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
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
              ),
            );
          },
        );
      },
    );
  }

  void _showDropdownOptions(BuildContext context, StateSetter setModalState) {
    // Check if the selected month only allows partial collections
    // If no date is selected, check the default date (today's date)
    DateTime? dateToCheck = _selectedTransactionDate;
    if (dateToCheck == null) {
      dateToCheck = _getDefaultTransactionDate();
    }
    final isPartialOnly = dateToCheck != null && _isPartialOnlyMonth(dateToCheck);
    
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
              // Only show "Collected" option if the month doesn't have partial-only restrictions
              if (!isPartialOnly)
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
        final newStatus = option.toLowerCase().replaceAll(' ', '_');
        setState(() {
          _selectedStatus = newStatus;
        });
        
        // Update default transaction date based on new status
        // For "collected": show today if current month is not fully paid, else null
        if (newStatus == 'collected') {
          setModalState(() {
            _selectedTransactionDate = _getDefaultTransactionDate(status: 'collected');
            _dueController.clear();
          });
        } else if (newStatus == 'partially_collected') {
          setModalState(() {
            _selectedTransactionDate = _getDefaultTransactionDate(status: 'partially_collected');
            // Auto-populate amount with remaining due for partial payments
            if (_selectedTransactionDate != null && _amountPerPeriod != null) {
              final totalCollected = _getTotalCollectedForPeriod(_selectedTransactionDate!);
              final remainingDue = _amountPerPeriod! - totalCollected;
              if (remainingDue > 0) {
                _amountController.text = remainingDue.toStringAsFixed(2);
              } else {
                _amountController.clear();
              }
            }
            // Calculate due amount
            if (_amountController.text.isNotEmpty && _selectedTransactionDate != null) {
              _calculateDueAmount(_amountController.text, setModalState);
            }
          });
        }
        
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

