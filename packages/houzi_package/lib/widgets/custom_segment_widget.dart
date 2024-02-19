import 'package:flutter/material.dart';
import 'package:houzi_package/common/constants.dart';
import 'package:houzi_package/files/app_preferences/app_preferences.dart';
import 'package:houzi_package/files/hooks_files/hooks_configurations.dart';
import 'package:houzi_package/files/generic_methods/utility_methods.dart';
import 'package:houzi_package/models/property_meta_data.dart';
import 'package:houzi_package/widgets/generic_text_widget.dart';
import 'package:houzi_package/widgets/segment_control/sliding_segmented_control.dart';
import 'package:material_segmented_control/material_segmented_control.dart';

class TabBarTitleWidget extends StatelessWidget {
  final List<dynamic> itemList;
  final int initialSelection;
  final void Function(int)? onSegmentChosen;

  const TabBarTitleWidget({
    super.key,
    required this.itemList,
    required this.initialSelection,
    required this.onSegmentChosen,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(5),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            // mainAxisAlignment: MainAxisAlignment.start,
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MaterialSegmentedControl(
                // horizontalPadding: EdgeInsets.only(left: 5,right: 5),
                children: itemList
                    .map(
                      (item) {
                        var index = itemList.indexOf(item);
                        return Container(
                          color: Colors.blue,
                          // padding:  EdgeInsets.all(10),
                          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                          child: GenericTextWidget(
                            item,
                            style: TextStyle(
                              fontSize: AppThemePreferences.tabBarTitleFontSize,
                              fontWeight:
                                  AppThemePreferences.tabBarTitleFontWeight,
                              color: initialSelection == index
                                  ? AppThemePreferences()
                                      .appTheme
                                      .selectedItemTextColor
                                  : AppThemePreferences
                                      .unSelectedItemTextColorLight,
                            ),
                          ),
                        );
                      },
                    )
                    .toList()
                    .asMap(),
                selectionIndex: initialSelection,
                unselectedColor: AppThemePreferences()
                    .appTheme
                    .unSelectedItemBackgroundColor,
                selectedColor:
                    AppThemePreferences().appTheme.selectedItemBackgroundColor!,
                borderColor: Colors.transparent,
                borderRadius: 8.0, //5.0
                verticalOffset: 8.0, // 8.0
                // onSegmentChosen: onSegmentChosen,
                onSegmentTapped: onSegmentChosen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SegmentedControlWidget extends StatefulWidget {
  final List<dynamic> itemList;
  final int selectionIndex;
  final Function(int) onSegmentChosen;
  final EdgeInsetsGeometry? padding;
  final EdgeInsets horizontalPadding;
  final double borderRadius;
  final double verticalOffset;
  final double? fontSize;
  final FontWeight? fontWeight;

  const SegmentedControlWidget({
    Key? key,
    required this.itemList,
    required this.selectionIndex,
    required this.onSegmentChosen,
    this.padding = const EdgeInsets.symmetric(horizontal: 35),
    this.horizontalPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.borderRadius = 5.0,
    this.verticalOffset = 8.0,
    this.fontSize,
    this.fontWeight,
  }) : super(key: key);

  @override
  State<SegmentedControlWidget> createState() => _SegmentedControlWidgetState();
}

class _SegmentedControlWidgetState extends State<SegmentedControlWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      // padding: const EdgeInsets.all(15),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _buildSegments(),
        ),
      ),
    );
  }

  List<Widget> _buildSegments() {
    return widget.itemList.asMap().entries.map((entry) {
      var index = entry.key;
      var item = entry.value;
      return GestureDetector(
        onTap: () {
          widget.onSegmentChosen(index);
        },
        child: Container(
          width: 119,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(
                color: widget.selectionIndex == index
                    ? Colors.blue // Selected text color
                    : Colors.grey),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: widget.selectionIndex == index
                ? AppThemePreferences().appTheme.primaryColor!
                : AppThemePreferences().appTheme.unSelectedItemBackgroundColor,
          ),
          margin: const EdgeInsets.symmetric(
              horizontal: 8), // Adjust margin as needed
          child: Center(
            child: Text(
              item.runtimeType == Term
                  ? UtilityMethods.getLocalizedString(item.name)
                  : UtilityMethods.getLocalizedString(item),
              style: TextStyle(
                fontSize:
                    widget.fontSize ?? AppThemePreferences.tabBarTitleFontSize,
                fontWeight: widget.fontWeight ??
                    AppThemePreferences.tabBarTitleFontWeight,
                color: widget.selectionIndex == index
                    ? Colors.white // Selected text color
                    : Colors.grey, // Unselected text color with opacity
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
