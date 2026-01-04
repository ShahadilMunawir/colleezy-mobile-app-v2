import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../services/api_service.dart';

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
  final _individualPaymentController = TextEditingController();
  final _durationController = TextEditingController();
  final _amountPerPeriodController = TextEditingController(text: '0.00');
  final _durationPeriodController = TextEditingController(text: '0.00');
  final _percentageController = TextEditingController();
  String _collectPeriod = 'Monthly';
  bool _commissionYes = false;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _groupNameController.dispose();
    _startingDateController.dispose();
    _totalAmountController.dispose();
    _individualPaymentController.dispose();
    _durationController.dispose();
    _amountPerPeriodController.dispose();
    _durationPeriodController.dispose();
    _percentageController.dispose();
    super.dispose();
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
                  placeholder: 'Total Amount (eg: \$10.00)',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                // Individual Payment
                _buildLabel('Individual Payment'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _individualPaymentController,
                  placeholder: 'Individual payment',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                // Duration
                _buildLabel('Duration'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _durationController,
                  placeholder: 'Duration',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                // Amount Per Period
                _buildLabel('Amount Per Period'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _amountPerPeriodController,
                  placeholder: '0.00',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                // Collect Period & Duration (Period) - Side by side
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Collect Period'),
                          const SizedBox(height: 8),
                          _buildDropdownField(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Duration (Period)'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _durationPeriodController,
                            placeholder: '0.00',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                    const SizedBox(height: 32),
                    // Lottery Rules Section
                    _buildLotteryRulesSection(),
                    if (_commissionYes) ...[
                      const SizedBox(height: 16),
                      // Percentage Section
                      _buildPercentageField(),
                    ],
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textTertiary,
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
          filled: true,
          fillColor: Color(0xFF141414),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: _startingDateController,
        readOnly: true,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
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
          filled: true,
          fillColor: Color(0xFF141414),
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
            firstDate: DateTime.now(),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() {
              _startingDateController.text =
                  '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
            });
          }
        },
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: _collectPeriod,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Color(0xFF141414),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textTertiary,
            size: 24,
          ),
        ),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
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
      ),
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
          'Percentage',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE0DED9),
            fontFamily: 'DM Sans',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: _percentageController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFFE0DED9),
              fontFamily: 'DM Sans',
            ),
            decoration: InputDecoration(
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
              filled: true,
              fillColor: const Color(0xFF141414),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate required fields
    if (_groupNameController.text.trim().isEmpty) {
      _showError('Please enter a group name');
      return;
    }

    if (_startingDateController.text.trim().isEmpty) {
      _showError('Please select a starting date');
      return;
    }

    if (_totalAmountController.text.trim().isEmpty) {
      _showError('Please enter total amount');
      return;
    }

    if (_durationController.text.trim().isEmpty) {
      _showError('Please enter duration');
      return;
    }

    if (_amountPerPeriodController.text.trim().isEmpty) {
      _showError('Please enter amount per period');
      return;
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
      final amountPerPeriod = double.tryParse(_amountPerPeriodController.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;

      // Map collection period
      String collectionPeriod = 'monthly';
      if (_collectPeriod.toLowerCase() == 'weekly') {
        collectionPeriod = 'weekly';
      } else if (_collectPeriod.toLowerCase() == 'monthly') {
        collectionPeriod = 'monthly';
      }

      // Create group via API
      final result = await _apiService.createGroup(
        name: _groupNameController.text.trim(),
        startingDate: startingDate,
        totalAmount: totalAmount,
        duration: duration,
        amountPerPeriod: amountPerPeriod,
        collectionPeriod: collectionPeriod,
      );

      if (result != null && mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group created successfully!'),
            backgroundColor: Color(0xFF2D7A4F),
          ),
        );
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

