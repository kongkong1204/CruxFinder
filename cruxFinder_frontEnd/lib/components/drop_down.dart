// lib/components/drop_down.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:crux_finder/styles/colors.dart';
import 'package:crux_finder/styles/fonts.dart';

class drop_down extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? initialValue;
  final ValueChanged<String> onChanged;

  const drop_down({
    super.key,
    required this.title,
    required this.items,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<drop_down> createState() => _drop_downState();
}

class _drop_downState extends State<drop_down> {
  late String selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue ?? widget.items.first;
  }

  void _showCupertinoPicker() {
    int selectedIndex = widget.items.indexOf(selectedValue);
    if (selectedIndex < 0) selectedIndex = 0;

    final fixedExtentController = FixedExtentScrollController(
      initialItem: selectedIndex,
    );

    String tempSelectedValue = selectedValue;

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Container(
          height: 300,
          color: AppColors.light.lightest,
          child: Column(
            children: [
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFE5E5EA),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text(
                        '완료',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          selectedValue = tempSelectedValue;
                        });
                        widget.onChanged(selectedValue);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: fixedExtentController,
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    tempSelectedValue = widget.items[index];
                  },
                  children: widget.items
                      .map(
                        (item) => Center(
                      child: Text(
                        item,
                        style: AppFonts.light.m.copyWith(
                          color: AppColors.dark.darkest
                        ),
                      ),
                    ),
                  )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
            style : AppFonts.bold.h4.copyWith(
                color : AppColors.dark.darkest
            )
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showCupertinoPicker,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.signature.darkest,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            selectedValue,
                            style : AppFonts.bold.h4.copyWith(
                                color : AppColors.dark.darkest
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Image.asset(
                        'assets/icons/arrow_down.png'
                      )
                    ],
                  ),
                ),
                Container(
                  height: 1.5,
                  color: AppColors.signature.darkest,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
