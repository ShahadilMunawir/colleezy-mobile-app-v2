import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../theme/app_colors.dart';

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
  final _numberOfMembersController = TextEditingController();
  final _individualPaymentController = TextEditingController();
  final _durationController = TextEditingController();
  final _amountPerPeriodController = TextEditingController(text: '0.00');
  final _durationPeriodController = TextEditingController(text: '0.00');
  String _collectPeriod = 'Monthly';

  @override
  void dispose() {
    _groupNameController.dispose();
    _startingDateController.dispose();
    _totalAmountController.dispose();
    _numberOfMembersController.dispose();
    _individualPaymentController.dispose();
    _durationController.dispose();
    _amountPerPeriodController.dispose();
    _durationPeriodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.background,
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
                    color: AppColors.textPrimary,
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
                ),
                const SizedBox(height: 24),
                // Number of Members
                _buildLabel('Number of Members'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _numberOfMembersController,
                  placeholder: 'Number of members (eg: 20 people)',
                ),
                const SizedBox(height: 24),
                // Individual Payment
                _buildLabel('Individual Payment'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _individualPaymentController,
                  placeholder: 'Individual payment',
                ),
                const SizedBox(height: 24),
                // Duration
                _buildLabel('Duration'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _durationController,
                  placeholder: 'Duration',
                ),
                const SizedBox(height: 24),
                // Amount Per Period
                _buildLabel('Amount Per Period'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _amountPerPeriodController,
                  placeholder: '0.00',
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                    const SizedBox(height: 32),
                    // Add People Button
                    _buildAddPeopleButton(),
                    const SizedBox(height: 24),
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
        color: AppColors.textPrimary,
        fontFamily: 'DM Sans',
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
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
          fillColor: Colors.white,
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
          fillColor: Colors.white,
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
          fillColor: Colors.white,
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

  Widget _buildAddPeopleButton() {
    return InkWell(
      onTap: () {
        // Handle add people action
      },
      borderRadius: BorderRadius.circular(12),
      child: DottedBorder(
        color: AppColors.textTertiary,
        strokeWidth: 1.5,
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        dashPattern: const [5, 3],
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_add,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Add People',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  fontFamily: 'DM Sans',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Handle save logic here
            Navigator.of(context).pop();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
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
    );
  }
}

