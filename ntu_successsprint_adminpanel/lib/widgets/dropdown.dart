import 'package:flutter/material.dart';
import 'package:ntu_successsprint_adminpanel/constant.dart';

class DropdownContainer extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const DropdownContainer({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          border: Border.all(color: primaryColor),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButton<String>(
          isExpanded: true,
          underline: const SizedBox(),
          dropdownColor: Colors.white,
          icon: Icon(Icons.arrow_drop_down, color: primaryColor),
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(color: Colors.black),
          ),
          onChanged: onChanged,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Tooltip(
                message: item, // Shows full text on hover
                waitDuration:
                    const Duration(milliseconds: 500), // Optional delay
                child: Text(
                  item,
                  style: const TextStyle(
                    color: Colors.black,
                    overflow: TextOverflow.ellipsis, // Keeps text short
                  ),
                  maxLines: 1, // Ensures text does not wrap
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
