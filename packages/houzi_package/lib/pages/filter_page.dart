import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:houzi_package/common/constants.dart';
import 'package:houzi_package/files/hive_storage_files/hive_storage_manager.dart';
import 'package:houzi_package/pages/filter_page_widgets.dart';
import 'package:houzi_package/widgets/app_bar_widget.dart';
import 'package:houzi_package/widgets/filter_page_widgets/filter_bottom_action_bar.dart';
import 'package:houzi_package/files/generic_methods/general_notifier.dart';
import 'package:houzi_package/files/generic_methods/utility_methods.dart';
import 'package:houzi_package/models/filter_page_config.dart';

import '../files/app_preferences/app_preferences.dart';
import '../widgets/generic_text_widget.dart';

typedef FilterPageListener = void Function(
  Map<String, dynamic> filterDataMap,
  String closeOption,
);

class FilterPage extends StatefulWidget {
  final FilterPageListener filterPageListener;
  final Map<String, dynamic> mapInitializeData;
  final bool hasBottomNavigationBar;

  const FilterPage({
    super.key,
    required this.mapInitializeData,
    required this.filterPageListener,
    this.hasBottomNavigationBar = false,
  });

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  Map<String, dynamic> _dataInitializationMap = {};
  List<dynamic> filterPageConfigElementsList = [];

  VoidCallback? generalNotifierListener;

  @override
  void initState() {
    loadAndInitializeData();

    /// General Notifier Listener
    generalNotifierListener = () {
      if (GeneralNotifier().change ==
          GeneralNotifier.APP_CONFIGURATIONS_UPDATED) {
        getFilterPageConfigFile();
      }
    };

    GeneralNotifier().addListener(generalNotifierListener!);
    super.initState();
  }

  getFilterPageConfigFile() {
    var filterConfigListData =
        HiveStorageManager.readFilterConfigListData() ?? [];
    if (filterConfigListData != null && filterConfigListData.isNotEmpty) {
      filterPageConfigElementsList.clear();
      if (mounted) {
        setState(() {
          filterPageConfigElementsList =
              FilterPageElement.decode(jsonDecode(filterConfigListData));
        });
      }
    }
  }

  loadAndInitializeData() {
    getFilterPageConfigFile();
    _dataInitializationMap = widget.mapInitializeData;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        backgroundColor: AppThemePreferences().appTheme.backgroundColor,
        appBar: AppBar(
          elevation: 0,
          centerTitle: false,
          title: GenericTextWidget(
            UtilityMethods.getLocalizedString("filters"),
            style: AppThemePreferences()
                .appTheme
                .propertyDetailsPagePropertyTitleTextStyle,
          ),
          backgroundColor: AppThemePreferences().appTheme.backgroundColor,
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.close,
                  color: AppThemePreferences()
                      .appTheme
                      .primaryColor), // Cross icon
              onPressed: () {
                // HiveStorageManager.storeFilterDataInfo(
                //     map: _dataInitializationMap);
                // widget.filterPageListener(_dataInitializationMap, CLOSE);
                Navigator.of(context).pop();
              },
            ),
          ],
          // leading: GestureDetector(
          //   onTap: () {
          //     HiveStorageManager.storeFilterDataInfo(
          //         map: _dataInitializationMap);
          //     widget.filterPageListener(_dataInitializationMap, CLOSE);
          //     Navigator.of(context).pop();
          //   },
          //   child: SvgPicture.asset(
          //     AppThemePreferences.backIconImagePath,
          //     width: 20,
          //     height: 20,
          //     fit: BoxFit.scaleDown,
          //   ),
          // ),
        ),
        // appBar: AppBarWidget(
        //     appBarTitle: UtilityMethods.getLocalizedString("filters"),
        //     onBackPressed: (){
        //       HiveStorageManager.storeFilterDataInfo(map: _dataInitializationMap);
        //       widget.filterPageListener(_dataInitializationMap, CLOSE);
        //     }
        // ),
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  children: [
                    Column(
                      children: filterPageConfigElementsList
                          .map((filterPageConfigElement) {
                        return FilterPageWidgets(
                          filterPageConfigData: filterPageConfigElement,
                          mapInitializeData: _dataInitializationMap,
                          // mapInitializeData: widget.mapInitializeData,
                          filterPageWidgetsListener:
                              (Map<String, dynamic> dataMap,
                                  String closeOption) {
                            if (mounted) {
                              setState(() {
                                _dataInitializationMap.addAll(dataMap);
                                HiveStorageManager.storeFilterDataInfo(
                                    map: _dataInitializationMap);
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(
                      height: widget.hasBottomNavigationBar
                          ? kFilterPageBottomActionBarHeight +
                              kBottomNavigationBarHeight
                          : kFilterPageBottomActionBarHeight,
                    ),
                  ],
                ),
              ),
              FilterPageBottomActionBarWidget(
                dataInitializationMap: _dataInitializationMap,
                listener: widget.filterPageListener,
              ),
              // bottomPageButtonsWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
