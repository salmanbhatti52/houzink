import 'dart:convert';

import 'package:animate_icons/animate_icons.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:houzi_package/blocs/property_bloc.dart';
import 'package:houzi_package/common/constants.dart';
import 'package:houzi_package/files/app_preferences/app_preferences.dart';
import 'package:houzi_package/files/generic_methods/general_notifier.dart';
import 'package:houzi_package/files/generic_methods/utility_methods.dart';
import 'package:houzi_package/files/hive_storage_files/hive_storage_manager.dart';
import 'package:houzi_package/models/api_response.dart';
import 'package:houzi_package/pages/filter_page.dart';
import 'package:houzi_package/pages/home_screen_drawer_menu_pages/user_related/user_signin.dart';
import 'package:houzi_package/widgets/generic_animate_icon_widget.dart';
import 'package:houzi_package/widgets/generic_popup_menu_widgets.dart';
import 'package:houzi_package/widgets/generic_text_widget.dart';
import 'package:houzi_package/widgets/search_result_widgets/search_choice_chip_widget.dart';
import 'package:houzi_package/widgets/toast_widget.dart';

typedef SearchResultsSearchBarWidgetListener = Function({
bool? showPanel,
bool? onRefresh,
bool? canSave,
});

class SearchResultsSearchBarWidget extends StatefulWidget {
  final double opacity;
  final bool isLoggedIn;
  final bool canSaveSearch;
  final Map<String, dynamic> filteredDataMap;
  final Map<String, dynamic> chipsSearchDataMap;
  final List filterChipsRelatedList;
  final void Function()? onBackPressed;
  final AnimateIconController mapListAnimateIconController;
  final SearchResultsSearchBarWidgetListener listener;

  const SearchResultsSearchBarWidget({
    Key? key,
    required this.opacity,
    required this.isLoggedIn,
    required this.canSaveSearch,
    required this.filteredDataMap,
    required this.chipsSearchDataMap,
    required this.filterChipsRelatedList,
    required this.onBackPressed,
    required this.mapListAnimateIconController,
    required this.listener,
  }) : super(key: key);

  @override
  State<SearchResultsSearchBarWidget> createState() => _SearchResultsSearchBarWidgetState();
}

class _SearchResultsSearchBarWidgetState extends State<SearchResultsSearchBarWidget> {

  final PropertyBloc _propertyBloc = PropertyBloc();

  AnimateIconController refreshIconController = AnimateIconController();
  AnimateIconController mapListAnimateIconController = AnimateIconController();

  String nonce = "";

  @override
  void initState() {
    super.initState();
    fetchNonce();
  }

  fetchNonce() async {
    ApiResponse response = await _propertyBloc.fetchSaveSearchNonceResponse();
    if (response.success) {
      nonce = response.result;
    }
  }

  @override
  void dispose() {

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    mapListAnimateIconController = widget.mapListAnimateIconController;

    return Positioned(
      width: MediaQuery.of(context).size.width,
      top: 40.0, // 15.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 0,
                    child: IconButton(
                      onPressed: widget.onBackPressed,
                      icon: Icon(
                        AppThemePreferences.arrowBackIcon,
                        color: AppThemePreferences().appTheme.iconsColor,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 8,
                    child: GenericTextWidget(
                      UtilityMethods.getLocalizedString("search"),
                      style: AppThemePreferences().appTheme.searchBarTextStyle,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: GenericAnimateIcons(
                      startIcon: Icons.refresh_outlined,
                      endIcon: Icons.refresh_outlined,
                      size: 24.0,
                      clockwise: true,
                      controller: refreshIconController,
                      onStartIconPress: onRefreshAnimatedButtonPressed,
                      onEndIconPress: onRefreshAnimatedButtonPressed,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: GenericAnimateIcons(
                      startIcon: SHOW_MAP_INSTEAD_FILTER ? Icons.list_outlined : Icons.map_outlined,
                      endIcon: SHOW_MAP_INSTEAD_FILTER ? Icons.map_outlined : Icons.list_outlined,
                      size: 24.0,
                      clockwise: false,
                      controller: mapListAnimateIconController,
                      onStartIconPress: SHOW_MAP_INSTEAD_FILTER
                          ? onMapAnimatedButtonEndPressed
                          : onMapAnimatedButtonStartPressed,
                      onEndIconPress: SHOW_MAP_INSTEAD_FILTER
                          ? onMapAnimatedButtonStartPressed
                          : onMapAnimatedButtonEndPressed,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: GenericPopupMenuButton(
                      offset: Offset(0, 50),
                      elevation: AppThemePreferences.popupMenuElevation,
                      icon: Icon(
                        Icons.more_vert_outlined,
                        color: AppThemePreferences().appTheme.iconsColor,
                      ),
                      onSelected: (value) => onPopupOptionSelected(value),
                      itemBuilder: (context) => [
                        GenericPopupMenuItem(
                          value: OPTION_SAVE,
                          text: UtilityMethods.getLocalizedString(OPTION_SAVE),
                          iconData: Icons.bookmark_outline_outlined,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              decoration: BoxDecoration(
                color: widget.opacity < 0.6 ?  AppThemePreferences().appTheme.searchBarBackgroundColor :
                AppThemePreferences().appTheme.searchBar02BackgroundColor,
                borderRadius: BorderRadius.circular(12.0),//24.0
                // boxShadow: [opacity < 0.6 ? const BoxShadow(color: Color.fromRGBO(0, 0, 0, .25), blurRadius: 16.0) : const BoxShadow(color: Colors.transparent),],
              ),
            ),
          ),
          if(widget.opacity > 0) Opacity(
            opacity: widget.opacity,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SearchResultsChoiceChipsWidget(
                      label: "",
                      iconData: Icons.filter_alt_outlined,
                      onSelected: (value)=> navigateToFilterPage(),
                    ),

                    if(widget.filterChipsRelatedList.isNotEmpty) Row(
                      children: widget.filterChipsRelatedList.map((item) {
                        String key = item.keys.toList()[0];

                        String value = item[key] is List ? overFlowChipValue(item[key]) : item[key];
                        return GenericFilterRelatedChipWidget(
                          iconData: getFilterChipIcon(key),
                          label: UtilityMethods.getLocalizedString(value),
                          filterMap: widget.chipsSearchDataMap,
                          onTap: ()=> navigateToFilterPage(dataMap: widget.chipsSearchDataMap),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // if (_isBannerAdReady)
          //   Padding(
          //     padding: const EdgeInsets.only(top: 8.0),
          //     child: Container(
          //       height: _bannerAd.size.height.toDouble(),
          //       width: _bannerAd.size.width.toDouble(),
          //       child: AdWidget(ad: _bannerAd),
          //     ),
          //   ),
          // if (_isNativeAdLoaded)
          //   Container(
          //     height: 50,
          //
          //     child: AdWidget(ad: _nativeAd),
          //   ),
        ],
      ),
    );
  }

  bool onMapAnimatedButtonStartPressed(){
    mapListAnimateIconController.animateToEnd();
    widget.listener(showPanel: false);
    return true;
  }

  bool onMapAnimatedButtonEndPressed(){
    mapListAnimateIconController.animateToStart();
    widget.listener(showPanel: true);
    return true;
  }

  bool onRefreshAnimatedButtonPressed(){
    refreshIconController.animateToEnd();
    widget.listener(onRefresh: true);
    return true;
  }

  onPopupOptionSelected(dynamic value){
    if (value == OPTION_SAVE) {
      onSavedSearchTap();
    }
  }

  onSavedSearchTap() async {
    if (widget.isLoggedIn) {
      if(widget.canSaveSearch){
        final response = await _propertyBloc.fetchAddSavedSearch(widget.filteredDataMap, nonce);

        String tempResponseString = response.toString().split("{")[1];
        Map map = jsonDecode("{${tempResponseString.split("}")[0]}}");
        if (map["success"]) {
          _showToast(map['msg'], false);
          GeneralNotifier().publishChange(GeneralNotifier.NEW_SAVED_SEARCH_ADDED);
          widget.listener(canSave: false);
          // HiveStorageManager.storeLastSaveSearch(filteredDataMap);
        } else{
          if (map["msg"] != null) {
            _showToast(map["msg"], false);
          } else if (map["reason"] != null) {
            _showToast(map["reason"], false);
          } else {
            _showToast(UtilityMethods.getLocalizedString("error_occurred"), false);
          }

        }
      }
    }
    else{
      _showToast(UtilityMethods.getLocalizedString("you_must_login") + UtilityMethods.getLocalizedString("before_saving_search"),true);
    }
  }

  _showToast(String msg, bool forLogin) {
    !forLogin
        ? ShowToastWidget(
      buildContext: context,
      text: msg,
    )
        : ShowToastWidget(
      buildContext: context,
      showButton: true,
      buttonText: UtilityMethods.getLocalizedString("login"),
      text: msg,
      toastDuration: 4,
      onButtonPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserSignIn(
                  (String closeOption) {
                if (closeOption == CLOSE) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        );
      },
    );
  }

  navigateToFilterPage({Map? dataMap}){
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilterPage(
          mapInitializeData: dataMap != null && dataMap.isNotEmpty ?
          dataMap : HiveStorageManager.readFilterDataInfo() ?? {},
          filterPageListener: (Map<String, dynamic> map, String closeOption) {
            if (closeOption == DONE) {
              Navigator.of(context).pop();
              widget.listener(onRefresh: true);
            }else if(closeOption == CLOSE){
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }

  String overFlowChipValue(List inputList){
    String value = "";
    if(inputList.length == 1){
      value = UtilityMethods.getLocalizedString(inputList[0]);
    }else if(inputList.length == 2){
      for(int i = 0; i < inputList.length; i++){
        inputList[i] = UtilityMethods.getLocalizedString(inputList[i]);
      }
      value = inputList.join(', ');
    }
    // If we have more than two items
    else if(inputList.length > 2){
      List tempList = inputList.sublist(0, 2);
      // Localize the items
      for(int i = 0; i < tempList.length; i++){
        tempList[i] = UtilityMethods.getLocalizedString(tempList[i]);
      }
      // Make a String of items
      value = tempList.join(', ') + " ...";
    }

    return value;
  }

  IconData? getFilterChipIcon(String key){
    if(key == PROPERTY_TYPE){
      return AppThemePreferences.locationCityIcon;
    }
    if(key == PROPERTY_STATUS){
      return AppThemePreferences.checkCircleIcon;
    }
    if(key == PROPERTY_LABEL){
      return AppThemePreferences.labelIcon;
    }
    if(key == PROPERTY_FEATURES){
      return AppThemePreferences.featureChipIcon;
    }
    if(key == PROPERTY_KEYWORD){
      return AppThemePreferences.keywordCupertinoIcon;
    }
    if(key == CITY){
      return AppThemePreferences.locationIcon;
    }
    if(key == PROPERTY_COUNTRY){
      return AppThemePreferences.locationCountryIcon;
    }
    if(key == PROPERTY_STATE){
      return AppThemePreferences.locationStateIcon;
    }
    if(key == PROPERTY_AREA){
      return AppThemePreferences.locationAreaIcon;
    }
    if(key == BEDROOMS){
      return AppThemePreferences.bedIcon;
    }
    if(key == BATHROOMS){
      return AppThemePreferences.bathtubIcon;
    }
    if(key == PRICE_MIN || key == PRICE_MAX){
      return AppThemePreferences.priceTagIcon;
    }
    if(key == AREA_MIN || key == AREA_MAX){
      return AppThemePreferences.areaSizeIcon;
    }
    if(key == FEATURED_CHIP_KEY){
      return AppThemePreferences.featureChipIcon;
    }

    return null;
  }
}

class GenericFilterRelatedChipWidget extends StatelessWidget {
  final IconData? iconData;
  final String label;
  final Map filterMap;
  final void Function()? onTap;

  const GenericFilterRelatedChipWidget({
    Key? key,
    this.iconData,
    this.label = "",
    required this.filterMap,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SearchResultsChoiceChipsWidget(
      label: label,
      iconData: iconData,
      onSelected: (value) => onTap!(),
    );
  }
}
