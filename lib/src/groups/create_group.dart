import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../services/api_service.dart';
import 'group_details.dart';
import '../../utils/responsive.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _startingDateController = TextEditingController();
  final _individualTotalContributionController = TextEditingController();
  final _numberOfMembersController = TextEditingController();
  final _contributionFrequencyController = TextEditingController(); // For custom days input
  final _chittiDurationController = TextEditingController(); // Auto-calculated (read-only)
  final _individualCollectionPerPeriodController = TextEditingController(); // Auto-calculated (read-only)
  final _totalChittiAmountController = TextEditingController(); // Auto-calculated (read-only)
  int _calculatedNumberOfPeriods = 0; // Store number of periods for backend
  final _percentageController = TextEditingController();
  final _cashCommissionController = TextEditingController();
  String _contributionFrequency = 'Monthly'; // Selected frequency option
  bool _commissionYes = false;
  String _commissionType = 'percentage'; // 'percentage' or 'cash'
  bool _joinAsMember = true; // Whether creator wants to join as a member
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _groupNameController.dispose();
    _startingDateController.dispose();
    _individualTotalContributionController.dispose();
    _numberOfMembersController.dispose();
    _contributionFrequencyController.dispose();
    _chittiDurationController.dispose();
    _individualCollectionPerPeriodController.dispose();
    _totalChittiAmountController.dispose();
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

  String? _validateIndividualTotalContribution(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Individual Total Contribution is required';
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
    // Recalculate auto-calculated fields
    _calculateAutoFields();
    return null;
  }

  String? _validateContributionFrequency(String? value) {
    // Only validate if custom is selected
    if (_contributionFrequency == 'Custom') {
      if (value == null || value.trim().isEmpty) {
        return 'Please enter number of days';
      }
      final days = int.tryParse(value.trim());
      if (days == null) {
        return 'Please enter a valid number of days';
      }
      if (days <= 0) {
        return 'Frequency must be at least 1 day';
      }
      if (days > 365) {
        return 'Frequency cannot exceed 365 days';
      }
    }
    return null;
  }
  
  // Get frequency in days based on selected option
  double? _getFrequencyInDays() {
    switch (_contributionFrequency) {
      case 'Daily':
        return 1.0;
      case 'Twice a day':
        return 0.5; // 2 collections per day = 0.5 days between collections
      case 'Weekly':
        return 7.0;
      case 'Every 15 days':
        return 15.0;
      case 'Monthly':
        return 30.0;
      case 'Custom':
        final days = int.tryParse(_contributionFrequencyController.text.trim());
        return days?.toDouble();
      default:
        return null;
    }
  }

  // Calculate auto-calculated fields: Chitti Duration, Individual Collection Per Period, Total Chitti Amount
  // Based on the example: Individual Total = ₹20,000, Frequency = 15 days, Members = 10
  // Result: Collection Per Period = ₹1,000, Duration = 10 Months, Total = ₹2,00,000
  // Logic: If we collect ₹1,000 every 15 days, in 10 months (300 days) = 20 periods = ₹20,000
  void _calculateAutoFields() {
    final individualTotalText = _individualTotalContributionController.text;
    final numberOfMembersText = _numberOfMembersController.text;
    final frequencyDays = _getFrequencyInDays();
    
    if (individualTotalText.isNotEmpty && numberOfMembersText.isNotEmpty && frequencyDays != null) {
      final individualTotal = double.tryParse(individualTotalText.replaceAll(RegExp(r'[^\d.]'), ''));
      final numberOfMembers = int.tryParse(numberOfMembersText);
      
      if (individualTotal != null && individualTotal > 0 &&
          numberOfMembers != null && numberOfMembers > 0 &&
          frequencyDays > 0) {
        
        // Calculate Total Chitti Amount = Individual Total Contribution * Number of Members
        final totalChittiAmount = individualTotal * numberOfMembers;
        _totalChittiAmountController.text = '₹${_formatCurrency(totalChittiAmount)}';
        
        // Calculate Individual Collection Per Period
        // Strategy: Find a reasonable per-period amount that divides evenly
        // We'll calculate based on a target duration (e.g., 10 months = 300 days)
        // For 15-day frequency: 300 days / 15 = 20 periods
        // Individual Collection Per Period = Individual Total / 20 = ₹1,000
        
        // Target duration: approximately 10 months (300 days)
        final targetDays = 300.0;
        final targetPeriods = (targetDays / frequencyDays).round();
        final safeTargetPeriods = targetPeriods > 0 ? targetPeriods : 1;
        
        // Calculate per period amount
        double individualCollectionPerPeriod = individualTotal / safeTargetPeriods;
        
        // Round to nearest 100 for cleaner numbers (e.g., ₹1,000 instead of ₹1,050)
        individualCollectionPerPeriod = (individualCollectionPerPeriod / 100).round() * 100.0;
        
        // Ensure minimum of ₹100
        if (individualCollectionPerPeriod < 100) {
          individualCollectionPerPeriod = 100.0;
        }
        
        // Recalculate actual periods based on rounded amount
        final actualPeriods = (individualTotal / individualCollectionPerPeriod).ceil();
        _calculatedNumberOfPeriods = actualPeriods; // Store for backend
        
        // Calculate actual duration in months
        final actualDays = actualPeriods * frequencyDays;
        final durationMonths = actualDays / 30.0;
        
        // Update fields (only show the amount, no frequency text)
        _individualCollectionPerPeriodController.text = '₹${_formatCurrency(individualCollectionPerPeriod)}';
        _chittiDurationController.text = '${durationMonths.toStringAsFixed(1)} Months';
        
      } else {
        _clearAutoCalculatedFields();
      }
    } else {
      _clearAutoCalculatedFields();
    }
  }
  
  void _clearAutoCalculatedFields() {
    _chittiDurationController.clear();
    _individualCollectionPerPeriodController.clear();
    _totalChittiAmountController.clear();
    _calculatedNumberOfPeriods = 0;
  }
  
  String _formatCurrency(double amount) {
    // Format with commas for thousands
    final parts = amount.toStringAsFixed(0).split('.');
    final integerPart = parts[0];
    String formatted = '';
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count == 3) {
        formatted = ',' + formatted;
        count = 0;
      }
      formatted = integerPart[i] + formatted;
      count++;
    }
    return formatted;
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
    // Recalculate auto-calculated fields
    _calculateAutoFields();
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
    // Check against total chitti amount if set
    final totalChittiText = _totalChittiAmountController.text;
    if (totalChittiText.isNotEmpty) {
      final totalChittiAmount = double.tryParse(totalChittiText.replaceAll(RegExp(r'[^\d.]'), ''));
      if (totalChittiAmount != null && amount >= totalChittiAmount) {
        return 'Must be less than total chitti amount';
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
    final responsive = Responsive(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(responsive.radius(30)),
          topRight: Radius.circular(responsive.radius(30)),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: EdgeInsets.only(top: responsive.spacing(12), bottom: responsive.spacing(8)),
            width: responsive.width(40),
            height: responsive.height(4),
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(responsive.radius(2)),
            ),
          ),
          // Header
          Padding(
            padding: responsive.paddingSymmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create New Group',
                  style: TextStyle(
                    fontSize: responsive.fontSize(18),
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE0DED9),
                    fontFamily: 'DM Sans',
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: AppColors.textPrimary,
                    size: responsive.width(24),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Form content
          Expanded(
            child: SingleChildScrollView(
              padding: responsive.paddingSymmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Group Name
                _buildLabel(context, 'Group Name'),
                SizedBox(height: responsive.spacing(8)),
                _buildTextField(
                  context: context,
                  controller: _groupNameController,
                  placeholder: 'Friends 15-Day Chitti',
                  validator: _validateGroupName,
                ),
                SizedBox(height: responsive.spacing(24)),
                // Start Date
                _buildLabel(context, 'Start Date'),
                SizedBox(height: responsive.spacing(8)),
                _buildDateField(context),
                SizedBox(height: responsive.spacing(24)),
                // Number of Members
                _buildLabel(context, 'Number of Members'),
                SizedBox(height: responsive.spacing(8)),
                _buildTextField(
                  context: context,
                  controller: _numberOfMembersController,
                  placeholder: '10',
                  keyboardType: TextInputType.number,
                  validator: _validateNumberOfMembers,
                  onChanged: (_) => _calculateAutoFields(),
                ),
                SizedBox(height: responsive.spacing(24)),
                // Individual Total Contribution
                _buildLabel(context, 'Individual Total Contribution'),
                SizedBox(height: responsive.spacing(8)),
                _buildTextField(
                  context: context,
                  controller: _individualTotalContributionController,
                  placeholder: '₹20,000',
                  keyboardType: TextInputType.number,
                  validator: _validateIndividualTotalContribution,
                  onChanged: (_) => _calculateAutoFields(),
                ),
                SizedBox(height: responsive.spacing(24)),
                // Contribution Frequency
                _buildLabel(context, 'Contribution Frequency'),
                SizedBox(height: responsive.spacing(8)),
                _buildContributionFrequencyField(context),
                SizedBox(height: responsive.spacing(24)),
                // Chitti Duration
                _buildLabel(context, 'Chitti Duration'),
                SizedBox(height: responsive.spacing(8)),
                _buildTextField(
                  context: context,
                  controller: _chittiDurationController,
                  placeholder: '10 Months',
                  readOnly: true,
                ),
                SizedBox(height: responsive.spacing(24)),
                // Individual Collection Per Period
                _buildLabel(context, 'Individual Collection Per Period'),
                SizedBox(height: responsive.spacing(8)),
                _buildTextField(
                  context: context,
                  controller: _individualCollectionPerPeriodController,
                  placeholder: '₹1,000',
                  readOnly: true,
                ),
                SizedBox(height: responsive.spacing(24)),
                // Total Chitti Amount
                _buildLabel(context, 'Total Chitti Amount'),
                SizedBox(height: responsive.spacing(8)),
                _buildTextField(
                  context: context,
                  controller: _totalChittiAmountController,
                  placeholder: '₹2,00,000',
                  readOnly: true,
                ),
                SizedBox(height: responsive.spacing(24)),
                // Collect Period (hidden but kept for API compatibility)
                // _buildLabel(context, 'Collect Period'),
                // SizedBox(height: responsive.spacing(8)),
                // _buildDropdownField(context),
                    SizedBox(height: responsive.spacing(32)),
                    // Lottery Rules Section
                    _buildLotteryRulesSection(context),
                    if (_commissionYes) ...[
                      SizedBox(height: responsive.spacing(16)),
                      // Percentage Section
                      _buildPercentageField(context),
                    ],
                    SizedBox(height: responsive.spacing(32)),
                    // Join as Member Section
                    _buildJoinAsMemberSection(context),
                    SizedBox(height: responsive.spacing(32)),
                    // Save Button
                    _buildSaveButton(context),
                    SizedBox(height: responsive.spacing(20)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    final responsive = Responsive(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: responsive.fontSize(14),
        fontWeight: FontWeight.w600,
        color: Color(0xFFE0DED9),
        fontFamily: 'DM Sans',
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    void Function(String)? onChanged,
  }) {
    final responsive = Responsive(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      onChanged: onChanged,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: TextStyle(
        fontSize: responsive.fontSize(15),
        fontWeight: FontWeight.w400,
        color: Color(0xFFE0DED9),
        fontFamily: 'DM Sans',
      ),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(
          color: AppColors.textTertiary,
          fontSize: responsive.fontSize(15),
          fontWeight: FontWeight.w400,
          fontFamily: 'DM Sans',
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.radius(12)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.radius(12)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.radius(12)),
          borderSide: BorderSide(color: Color(0xFF2D7A4F), width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.radius(12)),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.radius(12)),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        errorStyle: TextStyle(
          color: Colors.red,
          fontSize: responsive.fontSize(12),
          fontFamily: 'DM Sans',
        ),
        filled: true,
        fillColor: const Color(0xFF141414),
        contentPadding: responsive.paddingSymmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildContributionFrequencyField(BuildContext context) {
    final responsive = Responsive(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _contributionFrequency,
          dropdownColor: const Color(0xFF2A2A2A),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.radius(12)),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.radius(12)),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(responsive.radius(12)),
              borderSide: BorderSide(color: Color(0xFF2D7A4F), width: 1),
            ),
            filled: true,
            fillColor: const Color(0xFF141414),
            contentPadding: responsive.paddingSymmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textTertiary,
            size: responsive.width(24),
          ),
          style: TextStyle(
            fontSize: responsive.fontSize(15),
            fontWeight: FontWeight.w400,
            color: Color(0xFFE0DED9),
            fontFamily: 'DM Sans',
          ),
          items: ['Daily', 'Twice a day', 'Weekly', 'Every 15 days', 'Monthly', 'Custom'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _contributionFrequency = newValue;
                if (newValue != 'Custom') {
                  _contributionFrequencyController.clear();
                }
                _calculateAutoFields();
              });
            }
          },
        ),
        if (_contributionFrequency == 'Custom') ...[
          SizedBox(height: responsive.spacing(12)),
          _buildTextField(
            context: context,
            controller: _contributionFrequencyController,
            placeholder: 'Enter number of days',
            keyboardType: TextInputType.number,
            validator: _validateContributionFrequency,
            onChanged: (_) => _calculateAutoFields(),
          ),
        ],
      ],
    );
  }

  Widget _buildDateField(BuildContext context) {
    final responsive = Responsive(context);
    return TextFormField(
      controller: _startingDateController,
      readOnly: true,
      validator: (value) => _validateStartingDate(),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: TextStyle(
        fontSize: responsive.fontSize(15),
        fontWeight: FontWeight.w400,
        color: Color(0xFFE0DED9),
        fontFamily: 'DM Sans',
      ),
      decoration: InputDecoration(
        hintText: '01 Feb 2026',
        hintStyle: TextStyle(
          color: AppColors.textTertiary,
          fontSize: responsive.fontSize(15),
          fontWeight: FontWeight.w400,
          fontFamily: 'DM Sans',
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.radius(12)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.radius(12)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.radius(12)),
          borderSide: BorderSide(color: Color(0xFF2D7A4F), width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.radius(12)),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.radius(12)),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        errorStyle: TextStyle(
          color: Colors.red,
          fontSize: responsive.fontSize(12),
          fontFamily: 'DM Sans',
        ),
        filled: true,
        fillColor: const Color(0xFF141414),
        contentPadding: responsive.paddingSymmetric(
          horizontal: 16,
          vertical: 16,
        ),
        suffixIcon: Icon(
          Icons.calendar_today,
          color: AppColors.textTertiary,
          size: responsive.width(20),
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
            // Format as "01 Feb 2026"
            final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
            _startingDateController.text =
                '${picked.day.toString().padLeft(2, '0')} ${months[picked.month - 1]} ${picked.year}';
          });
        }
      },
    );
  }

  Widget _buildLotteryRulesSection(BuildContext context) {
    final responsive = Responsive(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lottery Rules',
          style: TextStyle(
            fontSize: responsive.fontSize(18),
            fontWeight: FontWeight.w700,
            color: Color(0xFFE0DED9),
            fontFamily: 'DM Sans',
          ),
        ),
        SizedBox(height: responsive.spacing(16)),
        Text(
          'Commission',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w600,
            color: Color(0xFFE0DED9),
            fontFamily: 'DM Sans',
          ),
        ),
        SizedBox(height: responsive.spacing(12)),
        Row(
          children: [
            Expanded(
              child: _buildToggleSwitch(
                context: context,
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
    required BuildContext context,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final responsive = Responsive(context);
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w400,
            color: Color(0xFFE0DED9),
            fontFamily: 'DM Sans',
          ),
        ),
        SizedBox(width: responsive.spacing(8)),
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

  Widget _buildPercentageField(BuildContext context) {
    final responsive = Responsive(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Commission Type',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w600,
            color: Color(0xFFE0DED9),
            fontFamily: 'DM Sans',
          ),
        ),
        SizedBox(height: responsive.spacing(12)),
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
                  padding: responsive.paddingSymmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _commissionType == 'percentage'
                        ? const Color(0xFF2D7A4F)
                        : const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(responsive.radius(12)),
                    border: Border.all(
                      color: _commissionType == 'percentage'
                          ? const Color(0xFF2D7A4F)
                          : const Color(0xFF3A3A3A),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Percentage',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFE0DED9),
                        fontFamily: 'DM Sans',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: responsive.spacing(12)),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _commissionType = 'cash';
                  });
                },
                child: Container(
                  padding: responsive.paddingSymmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _commissionType == 'cash'
                        ? const Color(0xFF2D7A4F)
                        : const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(responsive.radius(12)),
                    border: Border.all(
                      color: _commissionType == 'cash'
                          ? const Color(0xFF2D7A4F)
                          : const Color(0xFF3A3A3A),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Cash',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
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
        SizedBox(height: responsive.spacing(16)),
        // Input field based on commission type
        if (_commissionType == 'percentage')
          TextFormField(
            controller: _percentageController,
            keyboardType: TextInputType.number,
            validator: _validatePercentage,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: TextStyle(
              fontSize: responsive.fontSize(15),
              fontWeight: FontWeight.w400,
              color: Color(0xFFE0DED9),
              fontFamily: 'DM Sans',
            ),
            decoration: InputDecoration(
              hintText: 'Enter percentage (1-100)',
              hintStyle: TextStyle(
                color: Color(0xFFA5A5A5),
                fontSize: responsive.fontSize(15),
                fontWeight: FontWeight.w400,
                fontFamily: 'DM Sans',
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: responsive.spacing(16), right: responsive.spacing(8)),
                child: Text(
                  '%',
                  style: TextStyle(
                    fontSize: responsive.fontSize(15),
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFE0DED9),
                    fontFamily: 'DM Sans',
                  ),
                ),
              ),
              prefixIconConstraints: BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsive.radius(12)),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsive.radius(12)),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsive.radius(12)),
                borderSide: BorderSide(color: Color(0xFF2D7A4F), width: 1),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsive.radius(12)),
                borderSide: BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsive.radius(12)),
                borderSide: BorderSide(color: Colors.red, width: 1),
              ),
              errorStyle: TextStyle(
                color: Colors.red,
                fontSize: responsive.fontSize(12),
                fontFamily: 'DM Sans',
              ),
              filled: true,
              fillColor: const Color(0xFF141414),
              contentPadding: responsive.paddingSymmetric(
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
            style: TextStyle(
              fontSize: responsive.fontSize(15),
              fontWeight: FontWeight.w400,
              color: Color(0xFFE0DED9),
              fontFamily: 'DM Sans',
            ),
            decoration: InputDecoration(
              hintText: 'Enter amount (e.g., 10.00)',
              hintStyle: TextStyle(
                color: Color(0xFFA5A5A5),
                fontSize: responsive.fontSize(15),
                fontWeight: FontWeight.w400,
                fontFamily: 'DM Sans',
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: responsive.spacing(16), right: responsive.spacing(8)),
                child: Text(
                  '₹',
                  style: TextStyle(
                    fontSize: responsive.fontSize(15),
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFE0DED9),
                    fontFamily: 'DM Sans',
                  ),
                ),
              ),
              prefixIconConstraints: BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsive.radius(12)),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsive.radius(12)),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsive.radius(12)),
                borderSide: BorderSide(color: Color(0xFF2D7A4F), width: 1),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsive.radius(12)),
                borderSide: BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsive.radius(12)),
                borderSide: BorderSide(color: Colors.red, width: 1),
              ),
              errorStyle: TextStyle(
                color: Colors.red,
                fontSize: responsive.fontSize(12),
                fontFamily: 'DM Sans',
              ),
              filled: true,
              fillColor: const Color(0xFF141414),
              contentPadding: responsive.paddingSymmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildJoinAsMemberSection(BuildContext context) {
    final responsive = Responsive(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Membership',
          style: TextStyle(
            fontSize: responsive.fontSize(18),
            fontWeight: FontWeight.w700,
            color: Color(0xFFE0DED9),
            fontFamily: 'DM Sans',
          ),
        ),
        SizedBox(height: responsive.spacing(12)),
        Text(
          'Do you want to join this group as a member?',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w400,
            color: Color(0xFFA5A5A5),
            fontFamily: 'DM Sans',
          ),
        ),
        SizedBox(height: responsive.spacing(16)),
        Row(
          children: [
            Expanded(
              child: _buildToggleSwitch(
                context: context,
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
          SizedBox(height: responsive.spacing(12)),
          Container(
            padding: responsive.paddingAll(12),
            decoration: BoxDecoration(
              color: Color(0xFF141414),
              borderRadius: BorderRadius.circular(responsive.radius(8)),
              border: Border.all(
                color: Color(0xFF2D7A4F),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Color(0xFF2D7A4F),
                  size: responsive.width(20),
                ),
                SizedBox(width: responsive.spacing(12)),
                Expanded(
                  child: Text(
                    'You will be the owner only. No money collection from you.',
                    style: TextStyle(
                      fontSize: responsive.fontSize(13),
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
      // Parse starting date (format: DD MMM YYYY, e.g., "01 Feb 2026")
      final dateText = _startingDateController.text.trim();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final dateParts = dateText.split(' ');
      if (dateParts.length != 3) {
        throw Exception('Invalid date format. Expected format: DD MMM YYYY (e.g., 01 Feb 2026)');
      }
      final day = int.parse(dateParts[0]);
      final monthName = dateParts[1];
      final year = int.parse(dateParts[2]);
      final monthIndex = months.indexOf(monthName);
      if (monthIndex == -1) {
        throw Exception('Invalid month name');
      }
      final startingDate = DateTime(year, monthIndex + 1, day);

      // Parse numeric values
      final individualTotalContribution = double.tryParse(_individualTotalContributionController.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
      final numberOfMembers = int.tryParse(_numberOfMembersController.text) ?? 0;
      final frequencyDays = _getFrequencyInDays();
      if (frequencyDays == null || frequencyDays <= 0) {
        throw Exception('Invalid contribution frequency. Please select a valid frequency.');
      }
      
      // Validate custom frequency if selected
      if (_contributionFrequency == 'Custom') {
        final customError = _validateContributionFrequency(_contributionFrequencyController.text);
        if (customError != null) {
          throw Exception(customError);
        }
      }
      
      // Calculate total chitti amount
      final totalAmount = individualTotalContribution * numberOfMembers;
      
      // Use calculated number of periods for duration (backend expects periods, not months)
      final duration = _calculatedNumberOfPeriods;
      if (duration == 0) {
        throw Exception('Duration calculation failed. Please check your inputs.');
      }
      
      // Calculate amount per period from auto-calculated field
      final collectionPerPeriodText = _individualCollectionPerPeriodController.text.replaceAll(RegExp(r'[^\d.]'), '');
      final amountPerPeriod = double.tryParse(collectionPerPeriodText) ?? 0.0;
      if (amountPerPeriod == 0) {
        throw Exception('Amount per period calculation failed. Please check your inputs.');
      }

      // Map collection period based on frequency days
      String collectionPeriod = 'monthly';
      if (frequencyDays <= 1) {
        collectionPeriod = 'weekly'; // Daily/twice daily maps to weekly for backend
      } else if (frequencyDays <= 14) {
        collectionPeriod = 'weekly';
      } else {
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
        frequencyInDays: frequencyDays.toDouble(), // Send actual frequency in days
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

  Widget _buildSaveButton(BuildContext context) {
    final responsive = Responsive(context);
    return SizedBox(
      width: double.infinity,
      height: responsive.height(56),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsive.radius(12)),
          ),
          disabledBackgroundColor: const Color(0xFF9CA3AF),
        ),
        child: _isLoading
            ? SizedBox(
                width: responsive.width(24),
                height: responsive.height(24),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Save',
                style: TextStyle(
                  fontSize: responsive.fontSize(16),
                  fontWeight: FontWeight.w700,
                  fontFamily: 'DM Sans',
                ),
              ),
      ),
    );
  }
}

