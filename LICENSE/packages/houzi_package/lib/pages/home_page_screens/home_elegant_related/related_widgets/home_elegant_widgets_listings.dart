import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:houzi_package/blocs/property_bloc.dart';
import 'package:houzi_package/common/constants.dart';
import 'package:houzi_package/dataProvider/locale_provider.dart';
import 'package:houzi_package/files/app_preferences/app_preferences.dart';
import 'package:houzi_package/files/generic_methods/general_notifier.dart';
import 'package:houzi_package/files/generic_methods/utility_methods.dart';
import 'package:houzi_package/files/hive_storage_files/hive_storage_manager.dart';
import 'package:houzi_package/files/theme_service_files/theme_storage_manager.dart';
import 'package:houzi_package/pages/home_screen_drawer_menu_pages/all_agency.dart';
import 'package:houzi_package/pages/home_screen_drawer_menu_pages/all_agents.dart';
import 'package:houzi_package/pages/search_result.dart';
import 'package:houzi_package/widgets/generic_text_widget.dart';
import 'package:houzi_package/widgets/header_widget.dart';
import 'package:houzi_package/pages/home_page_screens/parent_home_related/home_screen_widgets/home_screen_properties_related_widgets/explore_properties_widget.dart';
import 'package:houzi_package/pages/home_page_screens/parent_home_related/home_screen_widgets/home_screen_properties_related_widgets/latest_featured_properties_widget/properties_carousel_list_widget.dart';
import 'package:houzi_package/pages/home_page_screens/parent_home_related/home_screen_widgets/home_screen_realtors_related_widgets/home_screen_realtors_list_widget.dart';
import 'package:houzi_package/pages/home_page_screens/parent_home_related/home_screen_widgets/home_screen_recent_searches_widget/home_screen_recent_searches_widget.dart';
import 'package:houzi_package/widgets/type_status_row_widget.dart';
import 'package:provider/provider.dart';


typedef HomeElegantListingsWidgetListener = void Function(bool errorWhileLoading, bool refreshData);

class HomeElegantListingsWidget extends StatefulWidget {
  final homeScreenData;
  final bool refresh;
  final HomeElegantListingsWidgetListener? homeScreen02ListingsWidgetListener;

  HomeElegantListingsWidget({
    this.homeScreenData,
    this.refresh = false,
    this.homeScreen02ListingsWidgetListener,
  });

  @override
  State<HomeElegantListingsWidget> createState() => _HomeElegantListingsWidgetState();
}

class _HomeElegantListingsWidgetState extends State<HomeElegantListingsWidget> {

  int page = 1;

  String arrowDirection = " >";

  bool isDataLoaded = false;
  bool noDataReceived = false;
  bool _isNativeAdLoaded = false;
  bool permissionGranted = false;

  NativeAd? _nativeAd;

  List<dynamic> homeScreenList = [];

  Map homeConfigMap = {};
  Map<String, dynamic>setRouteRelatedDataMap = {};


  Future<List<dynamic>>? _futureHomeScreenList;

  VoidCallback? generalNotifierLister;

  final PropertyBloc _propertyBloc = PropertyBloc();


  @override
  void initState() {
    super.initState();

    generalNotifierLister = () {
      if (GeneralNotifier().change == GeneralNotifier.CITY_DATA_UPDATE) {
        if(homeConfigMap[sectionTypeKey] == allPropertyKey &&
            homeConfigMap[subTypeKey] == propertyCityDataType){
          setState(() {
            Map map = HiveStorageManager.readSelectedCityInfo();

            if(homeConfigMap[subTypeValueKey] != map[CITY_ID].toString()){
              homeScreenList = [];
              isDataLoaded = false;
              noDataReceived = false;
              if (map[CITY_ID] != null) {
                homeConfigMap[subTypeValueKey] = map[CITY_ID].toString();
              } else {
                homeConfigMap[subTypeValueKey] = "";
              }

              homeConfigMap[titleKey] = "";
              if(map[CITY] != null && map[CITY].isNotEmpty && map[CITY_ID] != null){
                homeConfigMap[titleKey] = UtilityMethods.getLocalizedString(
                    "latest_properties_in_city",inputWords: [map[CITY]]);
              }
              else{
                homeConfigMap[titleKey] = UtilityMethods.getLocalizedString("latest_properties");
              }

              loadData();
            }
          });
        }else if(homeConfigMap[sectionTypeKey] == propertyKey && homeConfigMap[subTypeKey] == propertyCityDataType &&
            homeConfigMap[subTypeValueKey] == userSelectedString){
          setState(() {
            Map map = HiveStorageManager.readSelectedCityInfo() ?? {};

            homeScreenList = [];
            isDataLoaded = false;
            noDataReceived = false;
            homeConfigMap[titleKey] = "";

            if(map[CITY] != null && map[CITY].isNotEmpty && map[CITY_ID] != null){
              homeConfigMap[titleKey] = UtilityMethods.getLocalizedString(
                  "latest_properties_in_city",inputWords: [map[CITY]]);
            }
            else{
              homeConfigMap[titleKey] = UtilityMethods.getLocalizedString("latest_properties");
            }

            loadData();
          });
        }

      } else if(GeneralNotifier().change == GeneralNotifier.RECENT_DATA_UPDATE &&
          homeConfigMap[sectionTypeKey] == recentSearchKey){
        setState(() {
          homeScreenList.clear();
          List tempList = HiveStorageManager.readRecentSearchesInfo() ?? [];
          if(tempList.isNotEmpty){
            homeScreenList.addAll(tempList);
          }
          setState(() {
            isDataLoaded = true;
          });
        });
      } else if(GeneralNotifier().change == GeneralNotifier.TOUCH_BASE_DATA_LOADED &&
          homeConfigMap[sectionTypeKey] != adKey &&
          homeConfigMap[sectionTypeKey] != recentSearchKey){
        if(mounted){
          setState(() {
            loadData();
            widget.homeScreen02ListingsWidgetListener!(false, false);
          });
        }
      }
    };

    GeneralNotifier().addListener(generalNotifierLister!);
  }

  @override
  void dispose() {
    super.dispose();

    if(_nativeAd != null){
      _nativeAd!.dispose();
    }
    homeScreenList = [];
    homeConfigMap = {};
    if (generalNotifierLister != null) {
      GeneralNotifier().removeListener(generalNotifierLister!);
    }
  }

  setUpNativeAd() {
    print("CALLING ADS");
    String themeMode = ThemeStorageManager.readData(THEME_MODE_INFO) ?? LIGHT_THEME_MODE;
    bool isDarkMode = false;
    if (themeMode == DARK_THEME_MODE) {
      isDarkMode = true;
    }
    _nativeAd = NativeAd(
      customOptions: {"isDarkMode": isDarkMode},
      adUnitId: Platform.isAndroid ? ANDROID_NATIVE_AD_ID : IOS_NATIVE_AD_ID,
      factoryId: 'homeNativeAd',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isNativeAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (kDebugMode) {
            print(
              'Ad load failed (code=${error.code} message=${error.message})',
            );
          }
        },
      ),
    );

    _nativeAd!.load();
  }

  loadData() {
    _futureHomeScreenList = fetchRelatedList(context, page);
    _futureHomeScreenList!.then((value) {
      if (value == null || value.isEmpty) {
        noDataReceived = true;
      } else {
        if(value[0].runtimeType == Response){
          // print("Generic Home Listing (Error Code): ${value[0].statusCode}");
          // print("Generic Home Listing (Error Msg): ${value[0].statusMessage}");
          noDataReceived = true;
          widget.homeScreen02ListingsWidgetListener!(true, false);
        }else{
          homeScreenList = value;
          isDataLoaded = true;
        }
      }

      if(mounted){
        setState(() {});
      }

      return null;
    });
  }

  Future<List<dynamic>> fetchRelatedList(BuildContext context, int page) async {
    List<dynamic> tempList = [];
    setRouteRelatedDataMap = {};
    if (homeConfigMap[showNearbyKey] ?? false) {
      permissionGranted = await UtilityMethods.locationPermissionsHandling(permissionGranted);
    }
    try {
      /// Fetch featured properties
      if (homeConfigMap[sectionTypeKey] == featuredPropertyKey) {
        tempList = await _propertyBloc.fetchFeaturedArticles(page);
      }

      /// Fetch All_properties (old)
      else if (homeConfigMap[sectionTypeKey] == allPropertyKey &&
          homeConfigMap[subTypeKey] != propertyCityDataType) {
        String key = UtilityMethods.getSearchKey(homeConfigMap[subTypeKey] ?? "");
        String value = homeConfigMap[subTypeValueKey] ?? "";
        Map<String, dynamic> dataMap = {};
        if(value.isNotEmpty && value != allString){
          dataMap = {key: value};
        }
        Map<String, dynamic> tempMap = await _propertyBloc.fetchFilteredArticles(dataMap);
        tempList.addAll(tempMap["result"]);
      }

      /// Fetch latest and city selected properties (old)
      else if (homeConfigMap[sectionTypeKey] == allPropertyKey &&
          homeConfigMap[subTypeKey] == propertyCityDataType) {
        Map map = HiveStorageManager.readSelectedCityInfo();
        if (map.isNotEmpty && map[CITY_ID] != null) {
          homeConfigMap[subTypeValueKey] = map[CITY_ID].toString();
          if (homeConfigMap[titleKey] != "Please Select") {
            homeConfigMap[titleKey] = "";
            homeConfigMap[titleKey] = UtilityMethods.getLocalizedString(
                "latest_properties_in_city",inputWords: [map[CITY]]);
          }
        }
        if (homeConfigMap[subTypeValueKey] == userSelectedString || homeConfigMap[subTypeValueKey] == ""
            || homeConfigMap[subTypeValueKey] == allString) {
          tempList = await _propertyBloc.fetchLatestArticles(page);
        } else {
          int id = int.parse(homeConfigMap[subTypeValueKey]);
          tempList = await _propertyBloc.fetchPropertiesInCityList(id, page, 16);
        }
      }

      /// Fetch Properties
      else if (homeConfigMap[sectionTypeKey] == propertyKey) {
        Map<String, dynamic> dataMap = {};

        if(homeConfigMap[subTypeKey] == propertyCityDataType &&
            homeConfigMap[subTypeValueKey] == userSelectedString) {

          Map map = HiveStorageManager.readSelectedCityInfo();
          if (map.isNotEmpty && map[CITY_ID] != null) {
            if (homeConfigMap[titleKey] != "Please Select") {
              homeConfigMap[titleKey] = "";
              homeConfigMap[titleKey] = UtilityMethods.getLocalizedString(
                  "latest_properties_in_city", inputWords: [map[CITY]]);
            }
            String citySlug = map[CITY_SLUG] ?? "";
            if (citySlug.isNotEmpty) {
              dataMap[SEARCH_RESULTS_LOCATION] = citySlug;
              setRouteRelatedDataMap[CITY_SLUG] = map[CITY_SLUG] ?? "";
              setRouteRelatedDataMap[CITY] = map[CITY] ?? "";
            }
          }else{
            setRouteRelatedDataMap[CITY] = allCapString;
          }
        }

        if(homeConfigMap.containsKey(searchApiMapKey) && homeConfigMap.containsKey(searchRouteMapKey) &&
            (homeConfigMap[searchApiMapKey] != null) && (homeConfigMap[searchRouteMapKey] != null)){
          dataMap.addAll(homeConfigMap[searchApiMapKey]);
          setRouteRelatedDataMap.addAll(homeConfigMap[searchRouteMapKey]);
        }
        else if(homeConfigMap.containsKey(subTypeListKey) && homeConfigMap.containsKey(subTypeValueListKey) &&
            (homeConfigMap[subTypeListKey] != null && homeConfigMap[subTypeListKey].isNotEmpty) &&
            (homeConfigMap[subTypeValueListKey] != null && homeConfigMap[subTypeValueListKey].isNotEmpty)){
          List subTypeList = homeConfigMap[subTypeListKey];
          List subTypeValueList = homeConfigMap[subTypeValueListKey];
          for(var item in subTypeList){
            if(item != allString){
              String searchKey = UtilityMethods.getSearchKey(item);
              String searchItemNameFilterKey = UtilityMethods.getSearchItemNameFilterKey(item);
              String searchItemSlugFilterKey = UtilityMethods.getSearchItemSlugFilterKey(item);
              List value = UtilityMethods.getSubTypeItemRelatedList(item, subTypeValueList);
              if(value.isNotEmpty && value[0].isNotEmpty) {
                dataMap[searchKey] = value[0];
                setRouteRelatedDataMap[searchItemSlugFilterKey] = value[0];
                setRouteRelatedDataMap[searchItemNameFilterKey] = value[1];
              }
            }
          }
        }
        else{
          String key = UtilityMethods.getSearchKey(homeConfigMap[subTypeKey]);
          String searchItemNameFilterKey = UtilityMethods.getSearchItemNameFilterKey(homeConfigMap[subTypeKey]);
          String searchItemSlugFilterKey = UtilityMethods.getSearchItemSlugFilterKey(homeConfigMap[subTypeKey]);
          String value = homeConfigMap[subTypeValueKey] ?? "";
          if(value.isNotEmpty && value != allString && value != userSelectedString){
            dataMap = {key: [value]};
            String itemName = UtilityMethods.getPropertyMetaDataItemNameWithSlug(dataType: homeConfigMap[subTypeKey], slug: value);
            setRouteRelatedDataMap[searchItemSlugFilterKey] = [value];
            setRouteRelatedDataMap[searchItemNameFilterKey] = [itemName];
          }
        }

        if(homeConfigMap[showFeaturedKey] ?? false){
          dataMap[SEARCH_RESULTS_FEATURED] = 1;
          setRouteRelatedDataMap[showFeaturedKey] = true;
        }

        if (homeConfigMap[showNearbyKey] ?? false) {
          if (permissionGranted) {
            Map<String, dynamic> dataMapForNearby = {};
            dataMapForNearby = await UtilityMethods.getMapForNearByProperties();
            dataMap.addAll(dataMapForNearby);
            setRouteRelatedDataMap.addAll(dataMapForNearby);
          } else {
            return [];
          }
        }
        //
        // print("sectionType: ${homeConfigMap[titleKey]}");
        // print("dataMap: $dataMap");
        // print("setRouteRelatedDataMap: $setRouteRelatedDataMap");

        Map<String, dynamic> tempMap = await _propertyBloc.fetchFilteredArticles(dataMap);
        if(tempMap["result"] != null){
          tempList.addAll(tempMap["result"]);
        }
      }


      /// Fetch realtors list
      else if (homeConfigMap[sectionTypeKey] == agenciesKey ||
          homeConfigMap[sectionTypeKey] == agentsKey) {
        if (homeConfigMap[subTypeKey] == REST_API_AGENT_ROUTE) {
          tempList = await _propertyBloc.fetchAllAgentsInfoList(page, 16);
        } else {
          tempList = await _propertyBloc.fetchAllAgenciesInfoList(page, 16);
        }
      }


      /// Fetch Terms
      else if (homeConfigMap[sectionTypeKey] == termKey) {
        if(homeConfigMap.containsKey(subTypeListKey) &&
            (homeConfigMap[subTypeListKey] != null &&
                homeConfigMap[subTypeListKey].isNotEmpty)){
          List subTypeList = homeConfigMap[subTypeListKey];
          if(subTypeList.length == 1 && subTypeList[0] == allString){
            Map<String, dynamic> tempMap = {};
            tempMap = removeRedundantLocationTermsKeys(allTermsList);
            setRouteRelatedDataMap.addAll(tempMap);
            tempList = await _propertyBloc.fetchTermData(allTermsList);
          }else{
            if(subTypeList.contains(allString)){
              subTypeList.remove(allString);
            }
            Map<String, dynamic> tempMap = {};
            tempMap = removeRedundantLocationTermsKeys(subTypeList);
            setRouteRelatedDataMap.addAll(tempMap);
            tempList = await _propertyBloc.fetchTermData(subTypeList);
          }
        }else{
          if(homeConfigMap[subTypeKey] != null && homeConfigMap[subTypeKey].isNotEmpty){
            if(homeConfigMap[subTypeKey] == allString){
              Map<String, dynamic> tempMap = {};
              tempMap = removeRedundantLocationTermsKeys(allTermsList);
              setRouteRelatedDataMap.addAll(tempMap);
              tempList = await _propertyBloc.fetchTermData(allTermsList);
            }else{
              var item = homeConfigMap[subTypeKey] ?? "";
              String key = UtilityMethods.getSearchItemNameFilterKey(item);
              setRouteRelatedDataMap[key] = [allCapString];
              tempList = await _propertyBloc.fetchTermData(homeConfigMap[subTypeKey]);
            }
          }
        }
      }

      /// Fetch taxonomies
      else if (homeConfigMap[sectionTypeKey] == termWithIconsTermKey) {
        tempList = [1];
      }

      else {
        tempList = [];
      }
    } on SocketException {
      throw 'No Internet connection';
    }
    return tempList;
  }

  Map<String, dynamic> removeRedundantLocationTermsKeys(List subTypeList){
    Map<String, dynamic> tempMap = {};
    for(var item in subTypeList){
      String key = UtilityMethods.getSearchItemNameFilterKey(item ?? "");
      tempMap[key] = [allCapString];
    }
    List<String> keysList = tempMap.keys.toList();
    if(keysList.isNotEmpty) {
      List<String> intersectionKeysList = locationRelatedList.toSet().intersection((keysList.toSet())).toList();
      if (intersectionKeysList.isNotEmpty && intersectionKeysList.length > 1) {
        for (int i = 1; i < intersectionKeysList.length; i++) {
          String key = intersectionKeysList[i];
          tempMap.remove(key);
        }
      }
    }

    return tempMap;
  }

  setRouteToNavigate() async {
    StatefulWidget Function(dynamic context)? route;

    if (homeConfigMap[sectionTypeKey] == featuredPropertyKey) {
      route = getSearchResultPath(onlyFeatured: true);
    }
    else if (homeConfigMap[sectionTypeKey] == allPropertyKey &&
        homeConfigMap[subTypeKey] != propertyCityDataType) {
      Map<String, dynamic> dataMap = {
        UtilityMethods.getSearchKey(homeConfigMap[subTypeKey]): "",
      };
      route = getSearchResultPath(map: dataMap);
    } else if (homeConfigMap[sectionTypeKey] == propertyKey) {
      route = getSearchResultPath(
        onlyFeatured: setRouteRelatedDataMap[showFeaturedKey] != null
            && setRouteRelatedDataMap[showFeaturedKey] is bool
            && setRouteRelatedDataMap[showFeaturedKey]
            ? true
            : false,
        map: setRouteRelatedDataMap,
      );
    } else if (homeConfigMap[sectionTypeKey] == termKey) {
      route = getSearchResultPath(map: setRouteRelatedDataMap);
    } else if (homeConfigMap[subTypeKey] == agenciesKey) {
      route = (context) => AllAgency();
    } else if (homeConfigMap[subTypeKey] == agentsKey) {
      route = (context) => AllAgents();
    } else if (homeConfigMap[sectionTypeKey] == allPropertyKey &&
        homeConfigMap[subTypeKey] == propertyCityDataType) {
      Map<String, dynamic> dataMap = {};
      Map cityInfoMap = HiveStorageManager.readSelectedCityInfo() ?? {};
      if (cityInfoMap.isNotEmpty && cityInfoMap[CITY_ID] != null) {
        dataMap[CITY_SLUG] = cityInfoMap[CITY_SLUG] ?? "";
        dataMap[CITY] = cityInfoMap[CITY] ?? "";
      }else{
        dataMap[CITY] = allCapString;
      }
      route = getSearchResultPath(map: dataMap);
    } else {
      route = null;
    }
    navigateToRoute(route);
  }

  getSearchResultPath({Map<String, dynamic>? map, bool onlyFeatured = false}){
    return (context) => SearchResult(
      dataInitializationMap: onlyFeatured ? null : map,
      fetchFeatured: onlyFeatured,
      searchPageListener: (Map<String, dynamic> map, String closeOption) {
        if(closeOption.isEmpty){
          GeneralNotifier().publishChange(GeneralNotifier.FILTER_DATA_LOADING_COMPLETE);
        }
        if (closeOption == CLOSE) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  navigateToRoute(WidgetBuilder? builder) {
    if (builder != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: builder,
        ),
      );
    }
  }

  bool needToLoadData(Map oldDataMap, Map newDataMap){
    if(oldDataMap[sectionTypeKey] != newDataMap[sectionTypeKey] ||
        oldDataMap[subTypeKey] != newDataMap[subTypeKey] ||
        oldDataMap[subTypeValueKey] != newDataMap[subTypeValueKey]){
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.homeScreenData != homeConfigMap) {
      // Make sure new Home item is Map
      var newHomeConfigMap = widget.homeScreenData;
      if (newHomeConfigMap is! Map) {
        newHomeConfigMap = widget.homeScreenData.toJson();
      }

      if (!(mapEquals(newHomeConfigMap, homeConfigMap))) {
        if (homeConfigMap[sectionTypeKey] != newHomeConfigMap[sectionTypeKey] &&
            newHomeConfigMap[sectionTypeKey] == recentSearchKey) {
          homeScreenList.clear();
          List tempList = HiveStorageManager.readRecentSearchesInfo() ?? [];
          if(tempList.isNotEmpty) homeScreenList.addAll(tempList);
        } else if (
        // homeConfigMap[sectionTypeKey] != newHomeConfigMap[sectionTypeKey] &&
        newHomeConfigMap[sectionTypeKey] == adKey && SHOW_ADS_ON_HOME && !_isNativeAdLoaded) {
          setUpNativeAd();
        } else if (needToLoadData(homeConfigMap, newHomeConfigMap)){
          // Update Home Item
          homeConfigMap = newHomeConfigMap;
          loadData();
          // widget.refresh = true;
        }

        // Update Home Item
        homeConfigMap = newHomeConfigMap;
      }
    }
    

    if(widget.refresh && homeConfigMap[sectionTypeKey] != adKey && homeConfigMap[sectionTypeKey] != recentSearchKey ){
      homeScreenList = [];
      isDataLoaded = false;
      noDataReceived = false;
      // loadData();
      // widget.refresh = false;
    }

    return Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          if (homeConfigMap[sectionTypeKey] == allPropertyKey &&
          homeConfigMap[subTypeKey] == propertyCityDataType) {
            Map map = HiveStorageManager.readSelectedCityInfo();
            if (map.isNotEmpty && map[CITY_ID] != null) {
              homeConfigMap[subTypeValueKey] = map[CITY_ID].toString();
              if (homeConfigMap[titleKey] != "Please Select") {
                homeConfigMap[titleKey] = "";
                homeConfigMap[titleKey] = UtilityMethods.getLocalizedString(
                    "latest_properties_in_city",
                    inputWords: [map[CITY]]);
              }
            }
          }

          if(homeConfigMap[sectionTypeKey] == recentSearchKey && homeScreenList.isNotEmpty){
            homeScreenList.removeWhere((element) => element is! Map);
          }

          return noDataReceived
              ? Container()
              : Column(
                  children: [
                    if(homeConfigMap[sectionTypeKey] != adKey && homeScreenList.isNotEmpty) Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 7,
                            child: Home02HeaderWidget(
                              text: UtilityMethods.getLocalizedString(homeConfigMap[titleKey]),
                              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 15.0),
                            ),
                          ),
                          if(homeConfigMap[sectionTypeKey] != recentSearchKey &&
                              homeConfigMap[sectionTypeKey] != termWithIconsTermKey)
                            Expanded(child: Container()),
                          if(homeConfigMap[sectionTypeKey] != recentSearchKey &&
                              homeConfigMap[sectionTypeKey] != termWithIconsTermKey)
                            Expanded(
                                flex: 2,
                                child: GestureDetector(
                                  onTap: () {
                                    setRouteToNavigate();
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.only(left : UtilityMethods.isRTL(context) ? 20 : 0,right: UtilityMethods.isRTL(context) ? 0 : 20,top: 5),
                                    child: GenericTextWidget(
                                      UtilityMethods.getLocalizedString("see_all") + arrowDirection,
                                      style: AppThemePreferences().appTheme.readMoreTextStyle,
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    if (homeConfigMap[sectionTypeKey] == termWithIconsTermKey) TermWithIconsWidget(),
                    if(homeConfigMap[sectionTypeKey] == recentSearchKey) HomeScreenRecentSearchesWidget(
                        recentSearchesInfoList: HiveStorageManager.readRecentSearchesInfo() ?? [],
                        listingView: homeConfigMap[sectionListingViewKey] ?? homeScreenWidgetsListingCarouselView,
                      ),
                    if(homeConfigMap[sectionTypeKey] == adKey && SHOW_ADS_ON_HOME && _isNativeAdLoaded) Container(
                        padding: const EdgeInsets.only(left: 10,right: 10),
                        height: 50,
                        child: AdWidget(ad: _nativeAd!),
                      ),
                    if (homeConfigMap[sectionTypeKey] == allPropertyKey ||
                        homeConfigMap[sectionTypeKey] == propertyKey ||
                        homeConfigMap[sectionTypeKey] == featuredPropertyKey)
                      if (isDataLoaded)
                        PropertiesListingGenericWidget(
                            propertiesList: homeScreenList,
                            design: UtilityMethods.getDesignValue(homeConfigMap[designKey]) ?? DESIGN_01,
                            listingView: homeConfigMap[sectionListingViewKey] ?? homeScreenWidgetsListingCarouselView,
                        )
                      else genericLoadingWidgetForCarousalWithShimmerEffect(context),
                    if (homeConfigMap[sectionTypeKey] == termKey)
                      if (isDataLoaded)
                        ExplorePropertiesWidget(
                          design: UtilityMethods.getDesignValue(homeConfigMap[designKey]),
                          propertiesData: homeScreenList,
                          listingView: homeConfigMap[sectionListingViewKey] ?? homeScreenWidgetsListingCarouselView,
                          explorePropertiesWidgetListener: ({filterDataMap}) {
                            if (filterDataMap != null && filterDataMap.isNotEmpty) {

                            }
                          },
                        )
                      else genericLoadingWidgetForCarousalWithShimmerEffect(context),
                    if (homeConfigMap[sectionTypeKey] == REST_API_AGENCY_ROUTE ||
                        homeConfigMap[sectionTypeKey] == REST_API_AGENT_ROUTE)
                      if (isDataLoaded && homeScreenList.isNotEmpty && homeScreenList[0] is List) RealtorListingsWidget(
                          listingView: homeConfigMap[sectionListingViewKey] ?? homeScreenWidgetsListingCarouselView,
                          tag: homeConfigMap[subTypeKey] == REST_API_AGENT_ROUTE
                              ? AGENTS_TAG
                              : AGENCIES_TAG,
                          realtorInfoList: homeScreenList[0],
                        )
                      else genericLoadingWidgetForCarousalWithShimmerEffect(context),
                  ],
          );
    });
  }


}
