import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _selectedDate = '21/12/2025';
  String? _selectedGroup = 'Group';

  // Sample transaction data grouped by date
  final Map<String, List<Map<String, dynamic>>> _transactions = {
    'December 21': [
      {
        'name': 'Stephanie Sharkey',
        'group': 'Hilite Group',
        'amount': 2991.32,
      },
      {
        'name': 'Stephanie Sharkey',
        'group': 'Home kuri',
        'amount': 1322.97,
      },
      {
        'name': 'Stephanie Sharkey',
        'group': 'Office kuri',
        'amount': 2406.85,
      },
      {
        'name': 'Stephanie Sharkey',
        'group': 'Group 101',
        'amount': 1815.59,
      },
      {
        'name': 'Stephanie Sharkey',
        'group': 'Home kuri',
        'amount': 348.12,
      },
      {
        'name': 'Stephanie Sharkey',
        'group': 'Office kuri',
        'amount': 6196.98,
      },
    ],
  };

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
                    const Expanded(
                      child: Text(
                        'History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEFEEEC),
                          fontFamily: 'DM Sans',
                        ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        // Handle menu action
                      },
                    ),
                  ],
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
                      items: ['21/12/2025', '20/12/2025', '19/12/2025'],
                      onChanged: (value) {
                        setState(() {
                          _selectedDate = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFilterDropdown(
                      value: _selectedGroup,
                      hint: 'Group',
                      items: ['Group', 'Hilite Group', 'Home kuri', 'Office kuri'],
                      onChanged: (value) {
                        setState(() {
                          _selectedGroup = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Transactions List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: _buildTransactionSections(),
              ),
            ),
          ],
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

  List<Widget> _buildTransactionSections() {
    List<Widget> sections = [];
    
    _transactions.forEach((date, transactions) {
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
        sections.add(
          _buildTransactionCard(
            name: transaction['name'],
            group: transaction['group'],
            amount: transaction['amount'],
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
              ],
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D7A4F),
              fontFamily: 'DM Sans',
            ),
          ),
        ],
      ),
    );
  }
}
