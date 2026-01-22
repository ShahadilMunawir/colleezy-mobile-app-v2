import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'all_dues_screen.dart';
import '../../utils/responsive.dart';

class HistoryScreen extends StatefulWidget {
  final Function(VoidCallback)? onVisible;

  const HistoryScreen({super.key, this.onVisible});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  String? _selectedDate;
  int? _selectedGroupId;
  String? _selectedGroupName;
  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _groups = [];
  List<String> _availableDates = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Register refresh callback with parent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onVisible?.call(refreshData);
    });
  }

  @override
  void didUpdateWidget(HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-register callback if it changed
    if (widget.onVisible != oldWidget.onVisible) {
      widget.onVisible?.call(refreshData);
    }
  }

  /// Public method to refresh data - called when navigating to this screen
  Future<void> refreshData() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadGroups(),
      _loadTransactions(),
    ]);
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await _apiService.getGroups();
      if (mounted) {
        setState(() {
          _groups = groups;
        });
      }
    } catch (e) {
      print('Error loading groups: $e');
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Build filter parameters
      String? startDate;
      String? endDate;
      
      if (_selectedDate != null && _selectedDate != 'All Dates') {
        // Parse selected date and create date range for that day
        try {
          final date = DateFormat('MMM d, yyyy').parse(_selectedDate!);
          startDate = DateFormat('yyyy-MM-dd').format(date);
          endDate = DateFormat('yyyy-MM-dd').format(date);
        } catch (e) {
          // If parsing fails, try other formats
          print('Error parsing date: $e');
        }
      }

      final transactions = await _apiService.getAllTransactions(
        groupId: _selectedGroupId,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        // Extract unique dates and sort them (using transaction_date)
        final dates = transactions
            .map((t) {
              final transactionDate = t['transaction_date'] as String?;
              if (transactionDate != null) {
                try {
                  final date = DateTime.parse(transactionDate);
                  return DateFormat('MMM d, yyyy').format(date);
                } catch (e) {
                  return null;
                }
              }
              return null;
            })
            .whereType<String>()
            .toSet()
            .toList();
        
        dates.sort((a, b) {
          try {
            final dateA = DateFormat('MMM d, yyyy').parse(a);
            final dateB = DateFormat('MMM d, yyyy').parse(b);
            return dateB.compareTo(dateA); // Most recent first
          } catch (e) {
            return 0;
          }
        });

        setState(() {
          _allTransactions = transactions;
          _availableDates = ['All Dates', ...dates];
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


  List<Map<String, dynamic>> get _filteredTransactions {
    List<Map<String, dynamic>> filtered = List.from(_allTransactions);

    // Filter by date (using transaction_date)
    if (_selectedDate != null && _selectedDate != 'All Dates') {
      try {
        final selectedDate = DateFormat('MMM d, yyyy').parse(_selectedDate!);
        filtered = filtered.where((t) {
          final transactionDateStr = t['transaction_date'] as String?;
          if (transactionDateStr != null) {
            try {
              final transactionDate = DateTime.parse(transactionDateStr);
              return DateFormat('yyyy-MM-dd').format(transactionDate) ==
                  DateFormat('yyyy-MM-dd').format(selectedDate);
            } catch (e) {
              return false;
            }
          }
          return false;
        }).toList();
      } catch (e) {
        print('Error filtering by date: $e');
      }
    }

    // Filter by group
    if (_selectedGroupId != null) {
      filtered = filtered.where((t) {
        return t['kuri_group_id'] == _selectedGroupId;
      }).toList();
    }

    // Sort by date (most recent first, using transaction_date)
    filtered.sort((a, b) {
      final dateA = a['transaction_date'] as String?;
      final dateB = b['transaction_date'] as String?;
      if (dateA != null && dateB != null) {
        try {
          return DateTime.parse(dateB).compareTo(DateTime.parse(dateA));
        } catch (e) {
          return 0;
        }
      }
      return 0;
    });

    return filtered;
  }

  Map<String, List<Map<String, dynamic>>> get _groupedTransactions {
    final grouped = <String, List<Map<String, dynamic>>>{};
    
    for (var transaction in _filteredTransactions) {
      final transactionDateStr = transaction['transaction_date'] as String?;
      if (transactionDateStr != null) {
        try {
          final date = DateTime.parse(transactionDateStr);
          final dateKey = DateFormat('MMMM d, yyyy').format(date);
          
          if (!grouped.containsKey(dateKey)) {
            grouped[dateKey] = [];
          }
          grouped[dateKey]!.add(transaction);
        } catch (e) {
          print('Error grouping transaction: $e');
        }
      }
    }

    // Sort dates (most recent first)
    final sortedDates = grouped.keys.toList()..sort((a, b) {
      try {
        final dateA = DateFormat('MMMM d, yyyy').parse(a);
        final dateB = DateFormat('MMMM d, yyyy').parse(b);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });

    final sortedGrouped = <String, List<Map<String, dynamic>>>{};
    for (var date in sortedDates) {
      sortedGrouped[date] = grouped[date]!;
    }

    return sortedGrouped;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
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
              ),
              child: Padding(
                padding: responsive.paddingFromLTRB(20, 16, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'History',
                      style: TextStyle(
                        fontSize: responsive.fontSize(24),
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEFEEEC),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllDuesScreen(),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.people_outline,
                        color: Color(0xFF2D7A4F),
                        size: responsive.width(20),
                      ),
                      label: Text(
                        'All Dues',
                        style: TextStyle(
                          fontSize: responsive.fontSize(14),
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D7A4F),
                          fontFamily: 'DM Sans',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Filters
            Padding(
              padding: responsive.paddingAll(20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterDropdown(
                      context: context,
                      value: _selectedDate,
                      hint: 'Date',
                      items: _availableDates,
                      onChanged: (value) {
                        setState(() {
                          _selectedDate = value;
                        });
                        _loadTransactions();
                      },
                    ),
                  ),
                  SizedBox(width: responsive.spacing(12)),
                  Expanded(
                    child: _buildGroupFilterDropdown(context),
                  ),
                ],
              ),
            ),
            // Transactions List
            Expanded(
              child: _buildTransactionsList(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupFilterDropdown(BuildContext context) {
    final responsive = Responsive(context);
    final groupItems = ['All Groups', ..._groups.map((g) => g['name'] as String).toList()];
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF232220),
        borderRadius: BorderRadius.circular(responsive.radius(12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGroupName,
          isExpanded: true,
          padding: responsive.paddingSymmetric(horizontal: 16, vertical: 14),
          hint: Text(
            'Group',
            style: TextStyle(
              fontSize: responsive.fontSize(15),
              fontWeight: FontWeight.w400,
              color: Color(0xFFA5A5A5),
              fontFamily: 'DM Sans',
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFFA5A5A5),
            size: responsive.width(24),
          ),
          style: TextStyle(
            fontSize: responsive.fontSize(15),
            fontWeight: FontWeight.w400,
            color: Color(0xFFD0CDC6),
            fontFamily: 'DM Sans',
          ),
          dropdownColor: const Color(0xFF232220),
          items: groupItems.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              if (value == 'All Groups') {
                _selectedGroupId = null;
                _selectedGroupName = null;
              } else {
                final group = _groups.firstWhere((g) => g['name'] == value);
                _selectedGroupId = group['id'] as int;
                _selectedGroupName = value;
              }
            });
            _loadTransactions();
          },
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required BuildContext context,
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final responsive = Responsive(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF232220),
        borderRadius: BorderRadius.circular(responsive.radius(12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          padding: responsive.paddingSymmetric(horizontal: 16, vertical: 14),
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: responsive.fontSize(15),
              fontWeight: FontWeight.w400,
              color: Color(0xFFA5A5A5),
              fontFamily: 'DM Sans',
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFFA5A5A5),
            size: responsive.width(24),
          ),
          style: TextStyle(
            fontSize: responsive.fontSize(15),
            fontWeight: FontWeight.w400,
            color: Color(0xFFD0CDC6),
            fontFamily: 'DM Sans',
          ),
          dropdownColor: const Color(0xFF232220),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTransactionsList(BuildContext context) {
    final responsive = Responsive(context);
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
              style: TextStyle(
                color: Colors.red,
                fontSize: responsive.fontSize(14),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: responsive.spacing(16)),
            ElevatedButton(
              onPressed: () {
                _loadTransactions();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D7A4F),
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    final grouped = _groupedTransactions;

    if (grouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: responsive.width(64),
              color: Color(0xFFA5A5A5),
            ),
            SizedBox(height: responsive.spacing(16)),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: responsive.fontSize(18),
                fontWeight: FontWeight.w600,
                color: Color(0xFFF2F2F2),
              ),
            ),
            SizedBox(height: responsive.spacing(8)),
            Text(
              'Transactions will appear here when money is collected',
              style: TextStyle(
                fontSize: responsive.fontSize(14),
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
      onRefresh: () async {
        await _loadTransactions();
      },
      color: const Color(0xFF2D7A4F),
      child: ListView(
        padding: responsive.paddingSymmetric(horizontal: 20),
        children: _buildTransactionSections(context, grouped),
      ),
    );
  }

  List<Widget> _buildTransactionSections(BuildContext context, Map<String, List<Map<String, dynamic>>> grouped) {
    final responsive = Responsive(context);
    List<Widget> sections = [];

    grouped.forEach((date, transactions) {
      sections.add(
        Padding(
          padding: EdgeInsets.only(bottom: responsive.spacing(16), top: responsive.spacing(8)),
          child: Text(
            date,
            style: TextStyle(
              fontSize: responsive.fontSize(16),
              fontWeight: FontWeight.w600,
              color: Color(0xFFA5A5A5),
              fontFamily: 'DM Sans',
            ),
          ),
        ),
      );

      for (var transaction in transactions) {
        final memberName = transaction['member_name'] as String? ?? 'Unknown';
        final groupName = transaction['group_name'] as String? ?? 'Unknown Group';
        final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
        final status = transaction['status'] as String? ?? 'collected';
        final dueAmount = (transaction['due_amount'] as num?)?.toDouble() ?? 0.0;

        sections.add(
          _buildTransactionCard(
            context: context,
            name: memberName,
            group: groupName,
            amount: amount,
            status: status,
            dueAmount: dueAmount,
          ),
        );
        sections.add(SizedBox(height: responsive.spacing(12)));
      }
    });

    return sections;
  }

  Widget _buildTransactionCard({
    required BuildContext context,
    required String name,
    required String group,
    required double amount,
    required String status,
    required double dueAmount,
  }) {
    final responsive = Responsive(context);
    return Container(
      width: double.infinity,
      padding: responsive.paddingAll(20),
      decoration: BoxDecoration(
        color: Color(0xFF232220),
        borderRadius: BorderRadius.circular(responsive.radius(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: responsive.fontSize(18),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'DM Sans',
                  ),
                ),
                SizedBox(height: responsive.spacing(4)),
                Text(
                  group,
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFA5A5A5),
                    fontFamily: 'DM Sans',
                  ),
                ),
                if (dueAmount > 0) ...[
                  SizedBox(height: responsive.spacing(4)),
                  Text(
                    'Due: ₹${dueAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFEF4444),
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: responsive.fontSize(18),
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D7A4F),
                  fontFamily: 'DM Sans',
                ),
              ),
              if (status == 'partially_collected') ...[
                SizedBox(height: responsive.spacing(4)),
                Container(
                  padding: responsive.paddingSymmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFEF4444).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(responsive.radius(4)),
                  ),
                  child: Text(
                    'Partial',
                    style: TextStyle(
                      fontSize: responsive.fontSize(10),
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

}
