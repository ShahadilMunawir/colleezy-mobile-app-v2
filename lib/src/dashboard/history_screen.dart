import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

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
        // Extract unique dates and sort them
        final dates = transactions
            .map((t) {
              final createdAt = t['created_at'] as String?;
              if (createdAt != null) {
                try {
                  final date = DateTime.parse(createdAt);
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

    // Filter by date
    if (_selectedDate != null && _selectedDate != 'All Dates') {
      try {
        final selectedDate = DateFormat('MMM d, yyyy').parse(_selectedDate!);
        filtered = filtered.where((t) {
          final createdAt = t['created_at'] as String?;
          if (createdAt != null) {
            try {
              final transactionDate = DateTime.parse(createdAt);
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

    // Sort by date (most recent first)
    filtered.sort((a, b) {
      final dateA = a['created_at'] as String?;
      final dateB = b['created_at'] as String?;
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
      final createdAt = transaction['created_at'] as String?;
      if (createdAt != null) {
        try {
          final date = DateTime.parse(createdAt);
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: const Text(
                        'History',
                        style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                          color: Color(0xFFEFEEEC),
                    ),
                ),
              ),
            ),
            // Filters
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterDropdown(
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGroupFilterDropdown(),
                  ),
                ],
              ),
            ),
            // Transactions List
            Expanded(
              child: _buildTransactionsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupFilterDropdown() {
    final groupItems = ['All Groups', ..._groups.map((g) => g['name'] as String).toList()];
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF232220),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGroupName,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hint: const Text(
            'Group',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFFA5A5A5),
              fontFamily: 'DM Sans',
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFFA5A5A5),
            size: 24,
          ),
          style: const TextStyle(
            fontSize: 15,
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
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF232220),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hint: Text(
            hint,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFFA5A5A5),
              fontFamily: 'DM Sans',
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFFA5A5A5),
            size: 24,
          ),
          style: const TextStyle(
            fontSize: 15,
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

    final grouped = _groupedTransactions;

    if (grouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history_outlined,
              size: 64,
              color: Color(0xFFA5A5A5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No transactions found',
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
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: _buildTransactionSections(grouped),
      ),
    );
  }

  List<Widget> _buildTransactionSections(Map<String, List<Map<String, dynamic>>> grouped) {
    List<Widget> sections = [];

    grouped.forEach((date, transactions) {
      sections.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 8),
          child: Text(
            date,
            style: const TextStyle(
              fontSize: 16,
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
            name: memberName,
            group: groupName,
            amount: amount,
            status: status,
            dueAmount: dueAmount,
          ),
        );
        sections.add(const SizedBox(height: 12));
      }
    });

    return sections;
  }

  Widget _buildTransactionCard({
    required String name,
    required String group,
    required double amount,
    required String status,
    required double dueAmount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF232220),
        borderRadius: BorderRadius.circular(16),
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'DM Sans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  group,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFA5A5A5),
                    fontFamily: 'DM Sans',
                  ),
                ),
                if (dueAmount > 0) ...[
                  const SizedBox(height: 4),
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
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D7A4F),
                  fontFamily: 'DM Sans',
                ),
              ),
              if (status == 'partially_collected') ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Partial',
                    style: TextStyle(
                      fontSize: 10,
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
