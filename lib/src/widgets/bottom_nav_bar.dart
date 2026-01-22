import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../utils/responsive.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    return Container(
      height: responsive.height(70),
      decoration: BoxDecoration(
        color: const Color(0xFF333231),
        borderRadius: BorderRadius.circular(responsive.radius(35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: responsive.spacing(12),
            offset: Offset(0, responsive.spacing(4)),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context: context,
            svgPath: 'assets/svg/home.svg',
            index: 0,
            isSelected: selectedIndex == 0,
          ),
          _buildNavItem(
            context: context,
            svgPath: 'assets/svg/groups.svg',
            index: 1,
            isSelected: selectedIndex == 1,
          ),
          _buildNavItem(
            context: context,
            svgPath: 'assets/svg/lottery.svg',
            index: 2,
            isSelected: selectedIndex == 2,
          ),
          _buildNavItem(
            context: context,
            svgPath: 'assets/svg/history.svg',
            index: 3,
            isSelected: selectedIndex == 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required String svgPath,
    required int index,
    required bool isSelected,
  }) {
    final responsive = Responsive(context);
    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: responsive.paddingAll(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D7A4F) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: SvgPicture.asset(
          svgPath,
          width: responsive.width(28),
          height: responsive.height(28),
          colorFilter: ColorFilter.mode(
            isSelected ? Colors.white : const Color(0xFF9E9E9E),
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomNavItem({
    required BuildContext context,
    required int index,
    required bool isSelected,
  }) {
    final responsive = Responsive(context);
    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: responsive.paddingAll(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D7A4F) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
              size: responsive.width(24),
            ),
            Positioned(
              bottom: responsive.spacing(2),
              child: Text(
                '₹',
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
                  fontSize: responsive.fontSize(12),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

