import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../services/api_service.dart';
import 'group_details.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _startingDateController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _durationController = TextEditingController();
  final _numberOfMembersController = TextEditingController();
  final _individualAmountController = TextEditingController(); // Read-only, calculated field
  final _percentageController = TextEditingController();
  final _cashCommissionController = TextEditingController();
  String _collectPeriod = 'Monthly';
  bool _commissionYes = false;
  String _commissionType = 'percentage'; // 'percentage' or 'cash'
  bool _joinAsMember = true; // Whether creator wants to join as a member
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _groupNameController.dispose();
    _startingDateController.dispose();
    _totalAmountController.dispose();
    _durationController.dispose();
    _numberOfMembersController.dispose();
    _individualAmountController.dispose();
    _percentageController.dispose();
    _cashCommissionController.dispose();
    super.dispose();
  }

  // ==================== VALIDATORS ====================

  String? _validateGroupName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Group name is required';
    }
    if (value.trim().length < 3) {
      return 'Group name must be at least 3 characters';
    }
    if (value.trim().length > 50) {
      return 'Group name must be less than 50 characters';
    }
    return null;
  }

  String? _validateTotalAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Total amount is required';
    }
    final amount = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    if (amount > 1000000) {
      return 'Amount cannot exceed ₹1,000,000';
    }
    // Recalculate individual amount when total amount changes
    _calculateIndividualAmount();
    return null;
  }

  // Calculate individual amount based on total amount, duration, and number of members
  void _calculateIndividualAmount() {
    final totalText = _totalAmountController.text;
    final durationText = _durationController.text;
    final numberOfMembersText = _numberOfMembersController.text;
    
    if (totalText.isNotEmpty && durationText.isNotEmpty && numberOfMembersText.isNotEmpty) {
      final totalAmount = double.tryParse(totalText.replaceAll(RegExp(r'[^\d.]'), ''));
      final duration = int.tryParse(durationText);
      final numberOfMembers = int.tryParse(numberOfMembersText);
      
      if (totalAmount != null && duration != null && duration > 0 && 
          numberOfMembers != null && numberOfMembers > 0) {
        final individualAmount = totalAmount / (duration * numberOfMembers);
        _individualAmountController.text = individualAmount.toStringAsFixed(2);
      } else {
        _individualAmountController.clear();
      }
    } else {
      _individualAmountController.clear();
    }
  }

  String? _validateDuration(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Duration is required';
    }
    final duration = int.tryParse(value.trim());
    if (duration == null) {
      return 'Please enter a valid number';
    }
    if (duration <= 0) {
      return 'Duration must be at least 1 month';
    }
    if (duration > 120) {
      return 'Duration cannot exceed 10 years (120 months)';
    }
    // Recalculate individual amount when duration changes
    _calculateIndividualAmount();
    return null;
  }

  String? _validateNumberOfMembers(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Number of members is required';
    }
    final numberOfMembers = int.tryParse(value.trim());
    if (numberOfMembers == null) {
      return 'Please enter a valid number';
    }
    if (numberOfMembers <= 0) {
      return 'Number of members must be at least 1';
    }
    if (numberOfMembers > 100) {
      return 'Number of members cannot exceed 100';
    }
    // Recalculate individual amount when number of members changes
    _calculateIndividualAmount();
    return null;
  }

  String? _validatePercentage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Percentage is required';
    }
    final percentage = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
    if (percentage == null) {
      return 'Please enter a valid percentage';
    }
    if (percentage <= 0) {
      return 'Percentage must be greater than 0';
    }
    if (percentage > 100) {
      return 'Percentage cannot exceed 100%';
    }
    return null;
  }

  String? _validateCashCommission(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Commission amount is required';
    }
    final amount = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    // Check against total amount if set
    final totalText = _totalAmountController.text;
    if (totalText.isNotEmpty) {
      final totalAmount = double.tryParse(totalText.replaceAll(RegExp(r'[^\d.]'), ''));
      if (totalAmount != null && amount >= totalAmount) {
        return 'Must be less than total amount';
      }
    }
    return null;
  }

  String? _validateStartingDate() {
    if (_startingDateController.text.trim().isEmpty) {
      return 'Starting date is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Create New Group',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE0DED9),
                    fontFamily: 'DM Sans',
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Form content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Group Name
                _buildLabel('Group Name'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _groupNameController,
                  placeholder: 'Group Name',
                  validator: _validateGroupName,
                ),
                const SizedBox(height: 24),
                // Starting Date
                _buildLabel('Starting Date'),
                const SizedBox(height: 8),
                _buildDateField(),
                const SizedBox(height: 24),
                // Total Amount
                _buildLabel('Total Amount'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _totalAmountController,
                  placeholder: 'Total Amount (eg: ₹10.00)',
                  keyboardType: TextInputType.number,
                  validator: _validateTotalAmount,
                  onChanged: (_) => _calculateIndividualAmount(),
                ),
                const SizedBox(height: 24),
                // Duration
                _buildLabel('Duration (in months)'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _durationController,
                  placeholder: 'Duration (in months)',
                  keyboardType: TextInputType.number,
                  validator: _validateDuration,
                  onChanged: (_) => _calculateIndividualAmount(),
                ),
                const SizedBox(height: 24),
                // Number of Members
                _buildLabel('Number of Members'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _numberOfMembersController,
                  placeholder: 'Number of Members',
                  keyboardType: TextInputType.number,
                  validator: _validateNumberOfMembers,
                  onChanged: (_) => _calculateIndividualAmount(),
                ),
                const SizedBox(height: 24),
                // Individual Amount (read-only, calculated)
                _buildLabel('Individual Amount'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _individualAmountController,
                  placeholder: 'Calculated automatically',
                  keyboardType: TextInputType.number,
                  readOnly: true,
                ),
                const SizedBox(height: 24),
                // Collect Period
                _buildLabel('Collect Period'),
                const SizedBox(height: 8),
                _buildDropdownField(),
                    const SizedBox(height: 32),
                    // Lottery Rules Section
                    _buildLotteryRulesSection(),
                    if (_commissionYes) ...[
                      const SizedBox(height: 16),
                      // Percentage Section
                      _buildPercentageField(),
                    ],
                    const SizedBox(height: 32),
                    // Join as Member Section
                    _buildJoinAsMemberSection(),
                    const SizedBox(height: 32),
                    // Save Button
                    _buildSaveButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFFE0DED9),
        fontFamily: 'DM Sans',
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      onChanged: onChanged,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Color(0xFFE0DED9),
        fontFamily: 'DM Sans',
      ),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          fontFamily: 'DM Sans',
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D7A4F), width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontFamily: 'DM Sans',
        ),
        filled: true,
        fillColor: const Color(0xFF141414),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _startingDateController,
      readOnly: true,
      validator: (value) => _validateStartingDate(),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Color(0xFFE0DED9),
        fontFamily: 'DM Sans',
      ),
      decoration: InputDecoration(
        hintText: 'mm/dd/yyyy',
        hintStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          fontFamily: 'DM Sans',
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D7A4F), width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontFamily: 'DM Sans',
        ),
        filled: true,
        fillColor: const Color(0xFF141414),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        suffixIcon: const Icon(
          Icons.calendar_today,
          color: AppColors.textTertiary,
          size: 20,
        ),
      ),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)), // Allow dates up to 5 years ago
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFF2D7A4F),
                  onPrimary: Colors.white,
                  surface: Color(0xFF2A2A2A),
                  onSurface: Color(0xFFE0DED9),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            _startingDateController.text =
                '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
          });
        }
      },
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _collectPeriod,
      dropdownColor: const Color(0xFF2A2A2A),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D7A4F), width: 1),
        ),
        filled: true,
        fillColor: const Color(0xFF141414),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: AppColors.textTertiary,
        size: 24,
      ),
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Color(0xFFE0DED9),
        fontFamily: 'DM Sans',
      ),
      items: ['Monthly', 'Weekly', 'Daily'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _collectPeriod = newValue;
          });
        }
      },
    );
  }

  Widget _buildLotteryRulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lottery Rules',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE0DED9),
            fontFamily: 'DM Sans',
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Commission',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE0DED9),
            fontFamily: 'DM Sans',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildToggleSwitch(
                label: 'Yes',
                value: _commissionYes,
                onChanged: (value) {
                  setState(() {
                    _commissionYes = value;
                  });
                },
              ),
            ),            
          ],
        ),
      ],
    );
  }

  Widget _buildToggleSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFFE0DED9),
            fontFamily: 'DM Sans',
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF2D7A4F),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFF2A2A2A),
        ),
      ],
    );
  }

  Widget _buildPercentageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Commission Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE0DED9),
            fontFamily: 'DM Sans',
          ),
        ),
        const SizedBox(height: 12),
        // Commission Type Selector
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _commissionType = 'percentage';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _commissionType == 'percentage'
                        ? const Color(0xFF2D7A4F)
                        : const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _commissionType == 'percentage'
                          ? const Color(0xFF2D7A4F)
                          : const Color(0xFF3A3A3A),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Percentage',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFE0DED9),
                        fontFamily: 'DM Sans',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _commissionType = 'cash';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _commissionType == 'cash'
                        ? const Color(0xFF2D7A4F)
                        : const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _commissionType == 'cash'
                          ? const Color(0xFF2D7A4F)
                          : const Color(0xFF3A3A3A),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Cash',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFE0DED9),
                        fontFamily: 'DM Sans',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Input field based on commission type
        if (_commissionType == 'percentage')
          TextFormField(
            controller: _percentageController,
            keyboardType: TextInputType.number,
            validator: _validatePercentage,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFFE0DED9),
              fontFamily: 'DM Sans',
            ),
            decoration: InputDecoration(
              hintText: 'Enter percentage (1-100)',
              hintStyle: const TextStyle(
                color: Color(0xFFA5A5A5),
                fontSize: 15,
                fontWeight: FontWeight.w400,
                fontFamily: 'DM Sans',
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 16, right: 8),
                child: Text(
                  '%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFE0DED9),
                    fontFamily: 'DM Sans',
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2D7A4F), width: 1),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              errorStyle: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontFamily: 'DM Sans',
              ),
              filled: true,
              fillColor: const Color(0xFF141414),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          )
        else
          TextFormField(
            controller: _cashCommissionController,
            keyboardType: TextInputType.number,
            validator: _validateCashCommission,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFFE0DED9),
              fontFamily: 'DM Sans',
            ),
            decoration: InputDecoration(
              hintText: 'Enter amount (e.g., 10.00)',
              hintStyle: const TextStyle(
                color: Color(0xFFA5A5A5),
                fontSize: 15,
                fontWeight: FontWeight.w400,
                fontFamily: 'DM Sans',
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 16, right: 8),
                child: Text(
                  '₹',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFE0DED9),
                    fontFamily: 'DM Sans',
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2D7A4F), width: 1),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              errorStyle: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontFamily: 'DM Sans',
              ),
              filled: true,
              fillColor: const Color(0xFF141414),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildJoinAsMemberSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Membership',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE0DED9),
            fontFamily: 'DM Sans',
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Do you want to join this group as a member?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFFA5A5A5),
            fontFamily: 'DM Sans',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildToggleSwitch(
                label: 'Join as Member',
                value: _joinAsMember,
                onChanged: (value) {
                  setState(() {
                    _joinAsMember = value;
                  });
                },
              ),
            ),
          ],
        ),
        if (!_joinAsMember) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF2D7A4F),
                width: 1,
              ),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.info_outline,
                  color: Color(0xFF2D7A4F),
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You will be the owner only. No money collection from you.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFE0DED9),
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleSave() async {
    // Validate form fields
    if (!_formKey.currentState!.validate()) {
      _showError('Please fix the errors above');
      return;
    }

    // Additional validation for commission fields (only when commission is enabled)
    if (_commissionYes) {
      if (_commissionType == 'percentage') {
        final percentageError = _validatePercentage(_percentageController.text);
        if (percentageError != null) {
          _showError(percentageError);
          return;
        }
      } else if (_commissionType == 'cash') {
        final cashError = _validateCashCommission(_cashCommissionController.text);
        if (cashError != null) {
          _showError(cashError);
          return;
        }
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse starting date (format: MM/DD/YYYY)
      final dateParts = _startingDateController.text.split('/');
      if (dateParts.length != 3) {
        throw Exception('Invalid date format');
      }
      final startingDate = DateTime(
        int.parse(dateParts[2]),
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
      );

      // Parse numeric values
      final totalAmount = double.tryParse(_totalAmountController.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
      final duration = int.tryParse(_durationController.text) ?? 0;
      final numberOfMembers = int.tryParse(_numberOfMembersController.text) ?? 0;
      // Calculate amount per period from total amount, duration, and number of members
      final amountPerPeriod = (duration > 0 && numberOfMembers > 0) 
          ? totalAmount / (duration * numberOfMembers) 
          : 0.0;

      // Map collection period
      String collectionPeriod = 'monthly';
      if (_collectPeriod.toLowerCase() == 'weekly') {
        collectionPeriod = 'weekly';
      } else if (_collectPeriod.toLowerCase() == 'monthly') {
        collectionPeriod = 'monthly';
      }

      // Handle commission
      bool hasCommission = _commissionYes;
      String? commissionType;
      double? commissionValue;
      
      if (hasCommission) {
        commissionType = _commissionType;
        if (_commissionType == 'percentage') {
          final percentageText = _percentageController.text.trim();
          if (percentageText.isNotEmpty) {
            commissionValue = double.tryParse(percentageText.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
          }
        } else if (_commissionType == 'cash') {
          final cashText = _cashCommissionController.text.trim();
          if (cashText.isNotEmpty) {
            commissionValue = double.tryParse(cashText.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
          }
        }
      }

      // Create group via API
      final result = await _apiService.createGroup(
        name: _groupNameController.text.trim(),
        startingDate: startingDate,
        totalAmount: totalAmount,
        duration: duration,
        numberOfMembers: numberOfMembers,
        amountPerPeriod: amountPerPeriod,
        collectionPeriod: collectionPeriod,
        hasCommission: hasCommission,
        commissionType: commissionType,
        commissionValue: commissionValue,
        joinAsMember: _joinAsMember,
      );

      if (result != null && mounted) {
        // Extract group ID and name from the result
        final groupId = result['id'] as int?;
        final groupName = result['name'] as String? ?? _groupNameController.text.trim();
        
        // Close the create group bottom sheet
        Navigator.of(context).pop(true);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group created successfully!'),
            backgroundColor: Color(0xFF2D7A4F),
          ),
        );
        
        // Navigate to the newly created group's detail page
        if (groupId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GroupDetailsScreen(
                groupId: groupId,
                groupName: groupName,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          _showError('Failed to create group. Please try again.');
        }
      }
    } catch (e) {
      print('Error creating group: $e');
      if (mounted) {
        _showError('Error creating group: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: const Color(0xFF9CA3AF),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Save',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'DM Sans',
                ),
              ),
      ),
    );
  }
}

