import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF333231),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            svgPath: 'assets/svg/home.svg',
            index: 0,
            isSelected: selectedIndex == 0,
          ),
          _buildNavItem(
            svgPath: 'assets/svg/groups.svg',
            index: 1,
            isSelected: selectedIndex == 1,
          ),
          _buildNavItem(
            svgPath: 'assets/svg/lottery.svg',
            index: 2,
            isSelected: selectedIndex == 2,
          ),
          _buildNavItem(
            svgPath: 'assets/svg/history.svg',
            index: 3,
            isSelected: selectedIndex == 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String svgPath,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D7A4F) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: SvgPicture.asset(
          svgPath,
          width: 28,
          height: 28,
          colorFilter: ColorFilter.mode(
            isSelected ? Colors.white : const Color(0xFF9E9E9E),
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomNavItem({
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
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
              size: 24,
            ),
            Positioned(
              bottom: 2,
              child: Text(
                '\$',
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
                  fontSize: 12,
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

