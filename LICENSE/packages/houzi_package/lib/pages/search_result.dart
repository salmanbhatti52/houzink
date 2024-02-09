import 'dart:io';

import 'package:animate_icons/animate_icons.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:houzi_package/blocs/property_bloc.dart';
import 'package:houzi_package/common/constants.dart';
import 'package:houzi_package/files/app_preferences/app_preferences.dart';
import 'package:houzi_package/files/hive_storage_files/hive_storage_manager.dart';
import 'package:houzi_package/files/item_design_files/item_design_notifier.dart';
import 'package:houzi_package/files/user_log_provider.dart';
import 'package:houzi_package/models/article.dart';
import 'package:houzi_package/models/property_meta_data.dart';
import 'package:houzi_package/widgets/no_internet_error_widget.dart';
import 'package:houzi_package/widgets/search_result_widgets/map_prop_list_widget.dart';
import 'package:houzi_package/widgets/search_result_widgets/search_results_builder_widget.dart';
import 'package:houzi_package/widgets/search_result_widgets/search_bar_widget.dart';
import 'package:houzi_package/widgets/search_result_widgets/sliding_panel_widget.dart';
import 'package:houzi_package/widgets/search_result_widgets/top_container_widget.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:houzi_package/files/theme_service_files/theme_storage_manager.dart';
import 'package:houzi_package/files/generic_methods/utility_methods.dart';


typedef SearchPageListener = void Function(Map<String, dynamic> filterDataMap, String closeOption);

class SearchResult extends StatefulWidget {
  final SearchPageListener? searchPageListener;
  final Map<String, dynamic>? dataInitializationMap;
  final Map<String, dynamic>? searchRelatedData;
  final bool hasBottomNavigationBar;
  final bool fetchFeatured;
  final bool fetchSubListing;
  final String subListingIds;

  const SearchResult({
    Key? key,
    this.searchPageListener,
    this.dataInitializationMap,
    this.searchRelatedData,
    this.hasBottomNavigationBar = false,
    this.fetchFeatured = false,
    this.fetchSubListing = false,
    this.subListingIds = "",
  }) : super(key: key);

  @override
  State<SearchResult> createState() => SearchResultState();
}

class SearchResultState extends State<SearchResult> {

  int selectedMarkerId = -1;

  int? _totalResults;
  int page = 1;
  int perPage = 16;

  double _opacity = SHOW_MAP_INSTEAD_FILTER ? 0.0 : 1.0;
  double _mapPropertiesOpacity = SHOW_MAP_INSTEAD_FILTER ? 1.0 : 0.0;

  bool _zoomToAllLocations = false;
  bool _snapCameraToSelectedIndex = false;
  bool _isAtBottom = false;
  bool refreshing = true;

  bool isAgent = false;
  bool isAgency = false;
  bool isAuthor = false;
  bool isLoggedIn = false;

  bool hasInternet = true;
  bool canSaveSearch = true;

  var realtorId;
  String realtorName = "";

  Map<String, dynamic> mapFromFilterScreen = {};
  Map<String, dynamic> filteredDataMap = {};
  Map<String, dynamic> chipsSearchDataMap = {};

  bool _infiniteStop = false;
  bool _isPaginationFree = true;
  bool _showMapWaitingWidget = false;

  bool _isNativeAdLoaded = false;
  List nativeAdList = [];

  List filterChipsRelatedList = [];

  PageController? carouselPageController;
  PanelController? _panelController;
  AnimateIconController mapListAnimateIconController = AnimateIconController();

  final PropertyBloc _propertyBloc = PropertyBloc();
  final List<dynamic> _filteredArticlesList = [];
  Future<List<dynamic>>? _futureFilteredArticles;

  bool carouselPageAnimateInProgress = false;


  @override
  void initState() {
    super.initState();

    _panelController = PanelController();
    mapListAnimateIconController = AnimateIconController();
    carouselPageController = PageController(viewportFraction: 0.9);

    //setUpBannerAd();
    if(SHOW_ADS_ON_LISTINGS){
      setUpNativeAd();
    }

    if(Provider.of<UserLoggedProvider>(context,listen: false).isLoggedIn!){
      if(mounted){
        setState(() {
          isLoggedIn = true;
        });
      }
    }

    if (widget.searchRelatedData != null && widget.searchRelatedData!.isNotEmpty) {
      if (widget.searchRelatedData!.containsKey(REALTOR_SEARCH_TYPE)) {
        if(mounted) {
          setState(() {
            if (widget.searchRelatedData![REALTOR_SEARCH_TYPE] == REALTOR_SEARCH_TYPE_AGENT) {
              isAgent = true;
            } else if (widget.searchRelatedData![REALTOR_SEARCH_TYPE] == REALTOR_SEARCH_TYPE_AGENCY) {
              isAgency = true;
            } else if (widget.searchRelatedData![REALTOR_SEARCH_TYPE] == REALTOR_SEARCH_TYPE_AUTHOR) {
              isAuthor = true;
            }
            realtorId = widget.searchRelatedData![REALTOR_SEARCH_ID];
            realtorName = widget.searchRelatedData![REALTOR_SEARCH_NAME] ?? "";
          });
        }
      }
      // if (widget.searchRelatedData.containsKey(AGENT_ID) ||
      //     widget.searchRelatedData.containsKey(AGENCY_ID) ||
      //     widget.searchRelatedData.containsKey(AUTHOR_ID)) {
      //   if (widget.searchRelatedData.containsKey(AGENT_ID)) {
      //     if(mounted){
      //       setState(() {
      //         isAgent = true;
      //         realtorId = widget.searchRelatedData[AGENT_ID];
      //       });
      //     }
      //   }
      //   if (widget.searchRelatedData.containsKey(AGENCY_ID)) {
      //     if(mounted){
      //       setState(() {
      //         isAgency = true;
      //         realtorId = widget.searchRelatedData[AGENCY_ID];
      //       });
      //     }
      //   }
      //   if (widget.searchRelatedData.containsKey(AUTHOR_ID)) {
      //     if(mounted){
      //       setState(() {
      //         isAuthor = true;
      //         realtorId = widget.searchRelatedData[AUTHOR_ID];
      //       });
      //     }
      //   }
      // }
      else {
        mapFromFilterScreen = widget.searchRelatedData ?? {};
      }
    } else {
      mapFromFilterScreen = widget.dataInitializationMap ?? {};
    }

    doSearch();
  }

  @override
  void dispose() {
    // _nativeAd.dispose();
    // _bannerAd.dispose();

    for (NativeAd ad in nativeAdList) {
      ad.dispose();
    }
    super.dispose();
    // _controller.removeListener(_scrollListener);
  }

  @override
  Widget build(BuildContext context) {

    _filteredArticlesList.removeWhere((element) => element is AdWidget);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: AppThemePreferences().appTheme.statusBarIconBrightness,
      ),
      child: WillPopScope(
        onWillPop: () {
          widget.searchPageListener!(HiveStorageManager.readFilterDataInfo(), CLOSE);
          return Future.value(true);
        },
        child: Consumer<ItemDesignNotifier>(
          builder: (context, itemDesignNotifier, child){
            return Scaffold(
              body: hasInternet == false
                  ? Center(child: NoInternetConnectionErrorWidget(onPressed: () => checkInternetAndSearch()))
                  : Stack(alignment: Alignment.topCenter, children: <Widget>[
                      SlidingPanelWidget(
                      zoomToAllLocations: _zoomToAllLocations,
                      panelController: _panelController,
                      filteredArticlesList: _filteredArticlesList,
                      showWaitingWidget: _showMapWaitingWidget,
                      selectedArticleIndex: selectedMarkerId,

                      snapCameraToSelectedIndex: _snapCameraToSelectedIndex,
                      listener: ({zoomToAllLocations ,opacity, mapPropListOpacity, coordinatesMap, selectedMarkerPropertyId, showWaitingWidget, sliderPosition, snapCameraToSelectedIndex}) {
                          if(mounted) {
                            setState(() {
                              if(zoomToAllLocations != null){
                                _zoomToAllLocations = zoomToAllLocations;
                              }

                              if(mapPropListOpacity != null){
                                _mapPropertiesOpacity = mapPropListOpacity;
                              }

                              if(opacity != null){
                                _opacity = opacity;
                              }

                              if (sliderPosition != null && sliderPosition <= 0.5) {
                                SHOW_MAP_INSTEAD_FILTER
                                    ? mapListAnimateIconController.animateToStart()
                                    : mapListAnimateIconController.animateToEnd();
                              }

                              if (sliderPosition != null && sliderPosition > 0.8) {
                                SHOW_MAP_INSTEAD_FILTER
                                    ? mapListAnimateIconController.animateToEnd()
                                    : mapListAnimateIconController.animateToStart();
                              }

                              if(showWaitingWidget != null){
                                _showMapWaitingWidget = showWaitingWidget;
                              }

                              if(coordinatesMap != null && coordinatesMap.isNotEmpty){
                                if(mounted) {
                                  setState(() {
                                    //MAP_IMPROVES_BY_ADIL - when it was from search in this area, we should zoom to all locations.
                                    _zoomToAllLocations = true;
                                    page = 1;
                                    _totalResults = null;
                                    _infiniteStop = false;
                                    _isAtBottom = false;
                                    filteredDataMap.clear();
                                    mapFromFilterScreen = HiveStorageManager.readFilterDataInfo() ?? {};
                                    mapFromFilterScreen.addAll(coordinatesMap);
                                    filteredDataMap[SEARCH_LOCATION] = "true";
                                    filteredDataMap[USE_RADIUS] = "on";

                                    refreshing = true;
                                    doSearch();
                                  });
                                }

                                fetchFilteredArticles(
                                  page,
                                  perPage,
                                  filteredDataMap,
                                );


                              }


                              if(selectedMarkerPropertyId != null){
                                if (selectedMarkerPropertyId != -1) {
                                  int index = _filteredArticlesList.indexWhere((
                                      element) {
                                    int tempId = element.id;
                                    return selectedMarkerPropertyId == tempId;
                                  });

                                  if (index != -1 &&
                                      index != selectedMarkerId) {

                                    selectedMarkerId = index;

                                    int currentPage = carouselPageController!
                                        .page!.toInt();
                                    if (currentPage != index) {
                                      this.carouselPageAnimateInProgress = true;
                                      carouselPageController!.animateToPage(
                                        index,
                                        duration: const Duration(
                                            milliseconds: 500),
                                        curve: Curves.ease,
                                      ).then((value) {
                                        this.carouselPageAnimateInProgress =
                                        false;
                                      });
                                      // carouselPageController!.jumpToPage(index);
                                    }
                                  }
                                } else {

                                  selectedMarkerId = -1;
                                }
                              }

                              if(snapCameraToSelectedIndex != null){
                                _snapCameraToSelectedIndex = snapCameraToSelectedIndex;
                              }
                            });
                          }
                  },
                  panelBuilder: (panelScrollController) {
                    panelScrollController.addListener(() {
                      if(panelScrollController.position.pixels == panelScrollController.position.maxScrollExtent){
                        // print("Reached at bottom........");
                        if(!_isAtBottom){
                          _isAtBottom = true;
                          if(!_infiniteStop && _isPaginationFree){
                            // print("Reached at bottom........");
                            setState(() {
                              _isPaginationFree = false;
                              page += 1;
                              filteredDataMap[SEARCH_RESULTS_CURRENT_PAGE] = '$page';
                              _futureFilteredArticles =
                                  fetchFilteredArticles(page, perPage, filteredDataMap, fetchSubListing: widget.fetchSubListing);
                            });
                            // print("Page: $page........");
                            _isAtBottom = false;
                          }
                        }
                      }
                    });

                    return SearchResultBuilderWidget(
                      futureFilteredArticles: _futureFilteredArticles,
                      totalResults: _totalResults,
                      panelScrollController: panelScrollController,
                      isNativeAdLoaded: _isNativeAdLoaded,
                      nativeAdList: nativeAdList,
                      itemDesignNotifier: itemDesignNotifier,
                      onPropArticleTap: _onPropertyArticleTap,
                      hasBottomNavigationBar: widget.hasBottomNavigationBar,
                      refreshing: refreshing,
                      isAtBottom: _isAtBottom,
                      infiniteStop: _infiniteStop,
                      listener: ({performSearch, totalResults}) {
                        if(mounted) {
                          setState(() {
                            if(totalResults != null){
                              _totalResults = totalResults;
                            }

                            if(performSearch != null && performSearch){
                              loadSearchProperties();
                            }
                          });
                        }
                      },
                    );
                  },
                ),
                TopContainerWidget(opacity: _opacity),
                SearchResultsSearchBarWidget(
                  opacity: _opacity,
                  isLoggedIn: isLoggedIn,
                  canSaveSearch: canSaveSearch,
                  filteredDataMap: filteredDataMap,
                  chipsSearchDataMap: chipsSearchDataMap,
                  filterChipsRelatedList: filterChipsRelatedList,
                  mapListAnimateIconController: mapListAnimateIconController,
                  onBackPressed: onBackPressed,
                  listener: ({showPanel, onRefresh, canSave}) {
                    if(mounted) {
                      setState(() {
                        if(showPanel != null){
                          if(showPanel){
                            _panelController!.animatePanelToPosition(1.0);
                            _opacity = 1.0;
                          }else{
                            _panelController!.animatePanelToPosition(0.0);
                            _opacity = 0.0;
                          }
                        }
                        if(onRefresh != null && onRefresh){
                          loadSearchProperties();
                        }
                        if(canSave != null){
                          canSaveSearch = canSave;
                        }
                      });
                    }
                  },
                ),
                MapPropertiesWidget(
                  opacity: _opacity,
                  carouselOpacity: _mapPropertiesOpacity,
                  carouselPageController: carouselPageController!,
                  itemDesignNotifier: itemDesignNotifier,
                  onPropArticleTap: _onPropertyArticleTap,
                  propArticlesList: _filteredArticlesList,
                  listener: ({currentPage}) {
                    if (mounted && currentPage != null && !carouselPageAnimateInProgress) {

                      setState(() {

                        if (selectedMarkerId != currentPage) {
                          print("MapPropertiesWidget():: changing from $selectedMarkerId to $currentPage");

                          selectedMarkerId = currentPage;
                          // enableCameraMovement = true;
                          _snapCameraToSelectedIndex = true;
                        }
                      });

                    }
                  },
                ),
              ],
              ),
            );
          },
        ),
      ),

    );
  }

  void loadSearchProperties(){
    page = 1;
    _totalResults = null;
    _infiniteStop = false;
    _isAtBottom = false;
    filteredDataMap.clear();
    mapFromFilterScreen = HiveStorageManager.readFilterDataInfo() ?? {};
    refreshing = true;
    doSearch();
  }

  void onBackPressed(){
    widget.searchPageListener!(HiveStorageManager.readFilterDataInfo() ?? {}, CLOSE);
  }

  void _onPropertyArticleTap(Article item, int propId, String heroId){
    if (item.propertyInfo!.requiredLogin) {
      isLoggedIn
          ? UtilityMethods.navigateToPropertyDetailPage(
        context: context,
        article: item,
        propertyID: propId,
        heroId: heroId,
      )
          : UtilityMethods.navigateToLoginPage(context, false);
    } else {
      UtilityMethods.navigateToPropertyDetailPage(
        context: context,
        article: item,
        propertyID: propId,
        heroId: heroId,
      );
    }
  }

  checkInternetAndSearch(){
    if(mounted){
      setState(() {
        refreshing = true;
      });
    }
    doSearch();
  }



  void doSearch() {
    filterChipsRelatedList.clear();
    chipsSearchDataMap.clear();

    if(mounted) {
      setState(() {
        canSaveSearch = true;
      });
    }

    // if (widget.fetchFeatured) {
    //   mapFromFilterScreen[showFeaturedKey] = true;
    //   filteredDataMap[SEARCH_RESULTS_FEATURED] = 1;
    //   filterChipsRelatedList.add({
    //     FEATURED_CHIP_KEY:
    //         UtilityMethods.getLocalizedString(FEATURED_CHIP_VALUE),
    //   });
    //
    //   filterChipsRelatedList = [
    //     {PROPERTY_TYPE : ["All"]},
    //     {PROPERTY_STATUS : ["All"]},
    //     {FEATURED_CHIP_KEY : UtilityMethods.getLocalizedString(FEATURED_CHIP_VALUE)},
    //   ];
    //   chipsSearchDataMap = {
    //     PROPERTY_TYPE : ["All"],
    //     PROPERTY_TYPE_SLUG : ["all"],
    //     PROPERTY_STATUS : ["All"],
    //     PROPERTY_STATUS_SLUG : ["all"],
    //   };
    // }else
    if(isAgent || isAgency || isAuthor){
      filterChipsRelatedList = [
        {PROPERTY_TYPE : ["All"]},
        {PROPERTY_STATUS : ["All"]},
        {
          REALTOR_CHIP_KEY : "${UtilityMethods.getLocalizedString(widget.searchRelatedData![REALTOR_SEARCH_TYPE])} : $realtorName",
        },
      ];

    }else {
      if (widget.fetchFeatured) {
        mapFromFilterScreen[showFeaturedKey] = true;
        filteredDataMap[SEARCH_RESULTS_FEATURED] = 1;
      }
      if (mapFromFilterScreen.isNotEmpty) {
        if (mapFromFilterScreen.containsKey(BEDROOMS)
            && mapFromFilterScreen[BEDROOMS] != null &&
            mapFromFilterScreen[BEDROOMS].isNotEmpty) {
          String tempBedroomString = '';
          List<String> tempBedroomStringList = List<String>.from(
              mapFromFilterScreen[BEDROOMS]);
          if (tempBedroomStringList.isNotEmpty) {
            if (tempBedroomStringList.contains("6+")) {
              tempBedroomStringList.remove("6+");
              tempBedroomStringList.add("6");
            }
            tempBedroomString = tempBedroomStringList.join(',');
          }
          filteredDataMap[SEARCH_RESULTS_BEDROOMS] = tempBedroomString;
          filterChipsRelatedList.add({
            BEDROOMS: tempBedroomString,
          });
          // chipsSearchDataMap[BEDROOMS] = tempBedroomString.split(",");
          List<String> chipsSearchDataList = tempBedroomString.split(",");
          if(chipsSearchDataList.contains("6")){
            int index = chipsSearchDataList.indexWhere((element) => element == "6");
            if(index!=-1) {
              chipsSearchDataList[index] = "6+";
            }
          }
          chipsSearchDataMap[BEDROOMS] = chipsSearchDataList;

        }

        if (mapFromFilterScreen.containsKey(BATHROOMS) &&
            mapFromFilterScreen[BATHROOMS] != null
            && mapFromFilterScreen[BATHROOMS].isNotEmpty) {
          String tempBathroomString = '';
          List<String> tempBathroomStringList = List<String>.from(
              mapFromFilterScreen[BATHROOMS]);
          if (tempBathroomStringList.isNotEmpty) {
            if (tempBathroomStringList.contains("6+")) {
              tempBathroomStringList.remove("6+");
              tempBathroomStringList.add("6");
            }
            tempBathroomString = tempBathroomStringList.join(',');
          }
          filteredDataMap[SEARCH_RESULTS_BATHROOMS] = tempBathroomString;
          filterChipsRelatedList.add({
            BATHROOMS: tempBathroomString,
          });
          // chipsSearchDataMap[BATHROOMS] = tempBathroomString.split(",");
          List<String> chipsSearchDataList = tempBathroomString.split(",");
          if(chipsSearchDataList.contains("6")){
            int index = chipsSearchDataList.indexWhere((element) => element == "6");
            if(index != -1) {
              chipsSearchDataList[index] = "6+";
            }
          }
          chipsSearchDataMap[BATHROOMS] = chipsSearchDataList;
        }

        if (filteredDataMap.containsKey(SEARCH_RESULTS_BEDROOMS) ||
            filteredDataMap.containsKey(SEARCH_RESULTS_BATHROOMS)) {
          filteredDataMap[SEARCH_RESULTS_BEDS_BATHS_CRITERIA] = "IN";
        }

        filteredDataMap.remove(SEARCH_RESULTS_STATUS);
        if (mapFromFilterScreen.containsKey(PROPERTY_STATUS_SLUG) &&
            mapFromFilterScreen[PROPERTY_STATUS_SLUG] != null &&
            mapFromFilterScreen[PROPERTY_STATUS_SLUG].isNotEmpty) {
          var status = List<String>.from(mapFromFilterScreen[PROPERTY_STATUS_SLUG]);
          var nonEmpty = status.where((element) =>
          element.isNotEmpty && element != "all").toList();
          filteredDataMap[SEARCH_RESULTS_STATUS] = nonEmpty;
          chipsSearchDataMap[PROPERTY_STATUS_SLUG] = nonEmpty;
        }else{
          chipsSearchDataMap[PROPERTY_STATUS_SLUG] = ["all"];
        }

        if (mapFromFilterScreen.containsKey(PROPERTY_STATUS) &&
            mapFromFilterScreen[PROPERTY_STATUS] != null &&
            mapFromFilterScreen[PROPERTY_STATUS].isNotEmpty) {
          var status = List<String>.from(mapFromFilterScreen[PROPERTY_STATUS]);
          var nonEmpty = status.where((element) => element.isNotEmpty).toList();
          // var nonEmpty = status.where((element) => element.isNotEmpty && element != "All").toList();
          filterChipsRelatedList.add({
            PROPERTY_STATUS: nonEmpty,
          });
          chipsSearchDataMap[PROPERTY_STATUS] = nonEmpty;
        } else {
          filterChipsRelatedList.add({
            PROPERTY_STATUS: ["All"],
          });
          chipsSearchDataMap[PROPERTY_STATUS] = ["All"];
        }

        if (mapFromFilterScreen.containsKey(PROPERTY_TYPE) &&
            mapFromFilterScreen[PROPERTY_TYPE] != null &&
            mapFromFilterScreen[PROPERTY_TYPE].isNotEmpty) {
          /// For SearchFilterChips
          List tempPropertyTypeList = [];
          List tempPropertyTypeSlugsList = [];
          tempPropertyTypeList = mapFromFilterScreen[PROPERTY_TYPE] ?? [];
          tempPropertyTypeSlugsList = mapFromFilterScreen[PROPERTY_TYPE_SLUG] ?? [];
          if(tempPropertyTypeSlugsList != null && tempPropertyTypeSlugsList.isNotEmpty){
            String itemSlug = tempPropertyTypeSlugsList[0];
            Term? obj = UtilityMethods.getPropertyMetaDataObjectWithSlug(dataType: PROPERTY_TYPE, slug: itemSlug);
            if(obj != null && obj.parent != 0){
              Term? parentObj = UtilityMethods.getPropertyMetaDataObjectWithId(dataType: PROPERTY_TYPE, id: obj.parent!);
              tempPropertyTypeList.insert(0, parentObj!.name);
              tempPropertyTypeSlugsList.insert(0, parentObj.slug);
            }
          }

          // print("tempPropertyTypeSlugsList: $tempPropertyTypeSlugsList");
          chipsSearchDataMap[PROPERTY_TYPE] = tempPropertyTypeList;
          chipsSearchDataMap[PROPERTY_TYPE_SLUG] = tempPropertyTypeSlugsList;

          filterChipsRelatedList.add({
            PROPERTY_TYPE: tempPropertyTypeList,
          });
        } else {
          filterChipsRelatedList.add({
            PROPERTY_TYPE: ["All"],
          });
          chipsSearchDataMap[PROPERTY_TYPE] = ["All"];
        }

        if (mapFromFilterScreen.containsKey(PROPERTY_LABEL) &&
            mapFromFilterScreen[PROPERTY_LABEL] != null &&
            mapFromFilterScreen[PROPERTY_LABEL].isNotEmpty) {
          var type = List<String>.from(mapFromFilterScreen[PROPERTY_LABEL]);
          var nonEmpty = type.where((element) => element.isNotEmpty).toList();
          // var nonEmpty = type.where((element) => element.isNotEmpty && element != "All").toList();
          filterChipsRelatedList.add({
            PROPERTY_LABEL: nonEmpty,
          });
          chipsSearchDataMap[PROPERTY_LABEL] = nonEmpty;
        }



        if (mapFromFilterScreen.containsKey(PROPERTY_FEATURES) &&
            mapFromFilterScreen[PROPERTY_FEATURES] != null &&
            mapFromFilterScreen[PROPERTY_FEATURES].isNotEmpty) {
          var type = List<String>.from(mapFromFilterScreen[PROPERTY_FEATURES]);
          var nonEmpty = type.where((element) => element.isNotEmpty).toList();
          // var nonEmpty = type.where((element) => element.isNotEmpty && element != "All").toList();
          filterChipsRelatedList.add({
            PROPERTY_FEATURES: nonEmpty,
          });
          chipsSearchDataMap[PROPERTY_FEATURES] = nonEmpty;
        }



        if (mapFromFilterScreen.containsKey(PROPERTY_TYPE_SLUG) &&
            mapFromFilterScreen[PROPERTY_TYPE_SLUG] != null &&
            mapFromFilterScreen[PROPERTY_TYPE_SLUG].isNotEmpty) {
          var propertyTypeSlug = mapFromFilterScreen[PROPERTY_TYPE_SLUG];

          var type = propertyTypeSlug is String ? [propertyTypeSlug] : List<String>.from(propertyTypeSlug);
          var nonEmpty = type.where((element) =>
          element.isNotEmpty && element != "all").toList();

          //If a sub-type is selected we need to remove its parent type from slugs.
          //that's because if we're looking for 'home' which is sub-type of 'residential'
          //we don't want to fetch home + residential (villas, apartment, etc)
          //instead we only want to fetch home.
          //if only residential is selected, then we want to fetch all (depend on server logic)

          if (nonEmpty.isNotEmpty && nonEmpty.length > 1) {
            List<dynamic> propertyTypeList = mapFromFilterScreen[PROPERTY_TYPE];
            Map<String, dynamic>? propertyDataMap = HiveStorageManager.readPropertyTypesMapData();
            if (propertyDataMap != null && propertyDataMap.isNotEmpty) {
              List<String> keys = propertyDataMap.keys.toList();

              //Find the index of parent category in property type list.
              //and then remove the item at same index from slug list.
              for(var item in propertyTypeList){
                if(keys.contains(item)){
                  Term? obj = UtilityMethods.getPropertyMetaDataObjectWithItemName(dataType: PROPERTY_TYPE, name: item);
                  if(obj != null){
                    nonEmpty.removeWhere((element) => element == obj.slug);
                  }
                }
              }
            }
          }
          // debugPrint("slugs List: $nonEmpty");
          filteredDataMap[SEARCH_RESULTS_TYPE] = nonEmpty;
        }

        if (mapFromFilterScreen.containsKey(PROPERTY_LABEL_SLUG) &&
            mapFromFilterScreen[PROPERTY_LABEL_SLUG] != null &&
            mapFromFilterScreen[PROPERTY_LABEL_SLUG].isNotEmpty) {
          filteredDataMap[SEARCH_RESULTS_LABEL] =
          mapFromFilterScreen[PROPERTY_LABEL_SLUG];
          chipsSearchDataMap[PROPERTY_LABEL_SLUG] = mapFromFilterScreen[PROPERTY_LABEL_SLUG];
        }

        if (mapFromFilterScreen.containsKey(CITY_SLUG) &&
            mapFromFilterScreen[CITY_SLUG] != null &&
            mapFromFilterScreen[CITY_SLUG].isNotEmpty) {

          var temp = mapFromFilterScreen[CITY_SLUG];
          var tempSlugList = [];

          chipsSearchDataMap[CITY_SLUG] = mapFromFilterScreen[CITY_SLUG];

          if (temp is List) {
            tempSlugList = List<String>.from(temp);
          } else if (temp is String) {
            tempSlugList = [temp];
          }
          filteredDataMap[SEARCH_RESULTS_LOCATION] = tempSlugList.where((element) => element != "all").toList();

        }

        if (mapFromFilterScreen.containsKey(PROPERTY_AREA_SLUG) &&
            mapFromFilterScreen[PROPERTY_AREA_SLUG] != null &&
            mapFromFilterScreen[PROPERTY_AREA_SLUG].isNotEmpty) {
          var areas = List<String>.from(mapFromFilterScreen[PROPERTY_AREA_SLUG]);
          var nonEmpty = areas.where((element) =>
          element.isNotEmpty && element != "all").toList();
          filteredDataMap[SEARCH_RESULTS_AREA] = nonEmpty;
          chipsSearchDataMap[PROPERTY_AREA_SLUG] = nonEmpty;
        }

        if (mapFromFilterScreen.containsKey(PROPERTY_KEYWORD) &&
            mapFromFilterScreen[PROPERTY_KEYWORD] != null &&
            mapFromFilterScreen[PROPERTY_KEYWORD].isNotEmpty) {
          filteredDataMap[SEARCH_RESULTS_KEYWORD] =
          mapFromFilterScreen[PROPERTY_KEYWORD];
          filterChipsRelatedList.add({
            PROPERTY_KEYWORD: mapFromFilterScreen[PROPERTY_KEYWORD],
          });

          chipsSearchDataMap[PROPERTY_KEYWORD] = mapFromFilterScreen[PROPERTY_KEYWORD];
        }

        if (mapFromFilterScreen.containsKey(PROPERTY_COUNTRY_SLUG) &&
            mapFromFilterScreen[PROPERTY_COUNTRY_SLUG] != null &&
            mapFromFilterScreen[PROPERTY_COUNTRY_SLUG].isNotEmpty) {
          var countries = List<String>.from(mapFromFilterScreen[PROPERTY_COUNTRY_SLUG]);
          var nonEmpty = countries.where((element) =>
          element.isNotEmpty && element != "all").toList();
          filteredDataMap[SEARCH_RESULTS_COUNTRY] = nonEmpty;
          chipsSearchDataMap[PROPERTY_COUNTRY_SLUG] = nonEmpty;
        }

        if (mapFromFilterScreen.containsKey(PROPERTY_STATE_SLUG) &&
            mapFromFilterScreen[PROPERTY_STATE_SLUG] != null &&
            mapFromFilterScreen[PROPERTY_STATE_SLUG].isNotEmpty) {
          var states = List<String>.from(mapFromFilterScreen[PROPERTY_STATE_SLUG]);
          var nonEmpty = states.where((element) =>
          element.isNotEmpty && element != "all").toList();
          filteredDataMap[SEARCH_RESULTS_STATE] = nonEmpty;
          chipsSearchDataMap[PROPERTY_STATE_SLUG] = nonEmpty;
        }

        if (mapFromFilterScreen.containsKey(PROPERTY_FEATURES_SLUG) &&
            mapFromFilterScreen[PROPERTY_FEATURES_SLUG] != null &&
            mapFromFilterScreen[PROPERTY_FEATURES_SLUG].isNotEmpty) {
          var features = List<String>.from(mapFromFilterScreen[PROPERTY_FEATURES_SLUG]);
          var nonEmpty = features.where((element) =>
          element.isNotEmpty && element != "all").toList();
          filteredDataMap[SEARCH_RESULTS_FEATURES] = nonEmpty;
          chipsSearchDataMap[PROPERTY_FEATURES_SLUG] = nonEmpty;
        }

        if (mapFromFilterScreen.containsKey(AREA_MAX) &&
            mapFromFilterScreen[AREA_MAX] != null) {
          var temp = mapFromFilterScreen[AREA_MAX];
          if (temp != null && temp.isNotEmpty) {
            filteredDataMap[SEARCH_RESULTS_MAX_AREA] = mapFromFilterScreen[AREA_MAX];
            chipsSearchDataMap[AREA_MAX] = mapFromFilterScreen[AREA_MAX];
            // filterChipsRelatedList.add({
            //   AREA_MAX : mapFromFilterScreen[AREA_MAX],
            // });
          }
        }

        if (mapFromFilterScreen.containsKey(AREA_MIN) &&
            mapFromFilterScreen[AREA_MIN] != null) {
          var temp = mapFromFilterScreen[AREA_MIN];
          if (temp != null && temp.isNotEmpty) {
            filteredDataMap[SEARCH_RESULTS_MIN_AREA] =
            mapFromFilterScreen[AREA_MIN];
            chipsSearchDataMap[AREA_MIN] = mapFromFilterScreen[AREA_MIN];
            // filterChipsRelatedList.add({
            //   AREA_MIN : mapFromFilterScreen[AREA_MIN],
            // });
          }
        }

        if (mapFromFilterScreen.containsKey(PRICE_MIN) &&
            mapFromFilterScreen[PRICE_MIN] != null) {
          var temp = mapFromFilterScreen[PRICE_MIN];
          if (temp != null && temp.isNotEmpty) {
            filteredDataMap[SEARCH_RESULTS_MIN_PRICE] =
            mapFromFilterScreen[PRICE_MIN];
            chipsSearchDataMap[PRICE_MIN] = mapFromFilterScreen[PRICE_MIN];
            // filterChipsRelatedList.add({
            //   PRICE_MIN : mapFromFilterScreen[PRICE_MIN],
            // });
          }
        }

        if (mapFromFilterScreen.containsKey(PRICE_MAX) &&
            mapFromFilterScreen[PRICE_MAX] != null) {
          var temp = mapFromFilterScreen[PRICE_MAX];
          if (temp != null && temp.isNotEmpty) {
            filteredDataMap[SEARCH_RESULTS_MAX_PRICE] =
            mapFromFilterScreen[PRICE_MAX];
            chipsSearchDataMap[PRICE_MAX] = mapFromFilterScreen[PRICE_MAX];
            // filterChipsRelatedList.add({
            //   PRICE_MAX : mapFromFilterScreen[PRICE_MAX],
            // });
          }
        }

        if (mapFromFilterScreen.containsKey(LATITUDE) &&
            mapFromFilterScreen[LATITUDE] != null) {
          var temp = mapFromFilterScreen[LATITUDE];
          chipsSearchDataMap[LATITUDE] = mapFromFilterScreen[LATITUDE];
          if (temp != null && temp.isNotEmpty) {
            filteredDataMap[LATITUDE] = temp;
          }
        }
        if (mapFromFilterScreen.containsKey(RADIUS) &&
            mapFromFilterScreen[RADIUS] != null) {
          var temp = mapFromFilterScreen[RADIUS];

          chipsSearchDataMap[RADIUS] = mapFromFilterScreen[RADIUS];

          if (temp != null && temp.isNotEmpty) {
            filteredDataMap[RADIUS] = temp;
          }
        }
        if (mapFromFilterScreen.containsKey(LONGITUDE) &&
            mapFromFilterScreen[LONGITUDE] != null) {
          var temp = mapFromFilterScreen[LONGITUDE];

          chipsSearchDataMap[LONGITUDE] = mapFromFilterScreen[LONGITUDE];

          if (temp != null && temp.isNotEmpty) {
            filteredDataMap[LONGITUDE] = temp;
          }
        }
        if (mapFromFilterScreen.containsKey(USE_RADIUS) &&
            mapFromFilterScreen[USE_RADIUS] != null) {
          var temp = mapFromFilterScreen[USE_RADIUS];

          chipsSearchDataMap[USE_RADIUS] = mapFromFilterScreen[USE_RADIUS];
          chipsSearchDataMap[SEARCH_LOCATION] = mapFromFilterScreen[SEARCH_LOCATION];

          if (temp != null && temp.isNotEmpty) {
            if (temp == "on") {
              filteredDataMap[USE_RADIUS] = mapFromFilterScreen[USE_RADIUS];
              filteredDataMap[SEARCH_LOCATION] = mapFromFilterScreen[SEARCH_LOCATION];
            }
          }
        }

        if (mapFromFilterScreen.containsKey(PROPERTY_CUSTOM_FIELDS) &&
            mapFromFilterScreen[PROPERTY_CUSTOM_FIELDS] != null
            && mapFromFilterScreen[PROPERTY_CUSTOM_FIELDS].isNotEmpty) {
          Map tempMap = mapFromFilterScreen[PROPERTY_CUSTOM_FIELDS];

          chipsSearchDataMap[PROPERTY_CUSTOM_FIELDS] = mapFromFilterScreen[PROPERTY_CUSTOM_FIELDS];

          tempMap.forEach((key, value) {
            String dataKey = "$SEARCH_RESULTS_CUSTOM_FIELDS[$key]";
            if (value is Map) {
              List tempList = [];
              value.forEach((key, value) {
                tempList.add(key);
              });
              String tempDataKey = "$dataKey[]";
              filteredDataMap[tempDataKey] = tempList;
              filterChipsRelatedList.add({
                tempDataKey: tempList,
              });
            } else {
              filteredDataMap[dataKey] = value;
              filterChipsRelatedList.add({
                dataKey: value,
              });
            }
          });
        }

        if (mapFromFilterScreen.containsKey(AREA_MIN) &&
            mapFromFilterScreen.containsKey(AREA_MAX)) {
          filterChipsRelatedList.add({
            AREA_MAX: "${mapFromFilterScreen[AREA_MIN]} - ${mapFromFilterScreen[AREA_MAX]}",
          });
        }

        if (mapFromFilterScreen.containsKey(PRICE_MIN) &&
            mapFromFilterScreen.containsKey(PRICE_MAX)) {
          filterChipsRelatedList.add({
            PRICE_MAX: "${mapFromFilterScreen[PRICE_MIN]} - ${mapFromFilterScreen[PRICE_MAX]}",
          });
        }

        if (mapFromFilterScreen.containsKey(showFeaturedKey) &&
            mapFromFilterScreen[showFeaturedKey] != null) {
          if(mapFromFilterScreen[showFeaturedKey]){
            filteredDataMap[SEARCH_RESULTS_FEATURED] = 1;
            filterChipsRelatedList.add({
              FEATURED_CHIP_KEY : UtilityMethods.getLocalizedString(FEATURED_CHIP_VALUE),
            });
          }
        }
        if (mapFromFilterScreen.containsKey(PROPERTY_AREA) &&
            mapFromFilterScreen[PROPERTY_AREA] != null &&
            mapFromFilterScreen[PROPERTY_AREA].isNotEmpty) {
          var type = List<String>.from(mapFromFilterScreen[PROPERTY_AREA]);
          var nonEmpty = type.where((element) => element.isNotEmpty).toList();
          // var nonEmpty = type.where((element) => element.isNotEmpty && element != "All").toList();
          filterChipsRelatedList.add({
            PROPERTY_AREA: nonEmpty,
          });
          chipsSearchDataMap[PROPERTY_AREA] = nonEmpty;
        }

        if (mapFromFilterScreen.containsKey(CITY) &&
            mapFromFilterScreen[CITY] != null &&
            mapFromFilterScreen[CITY].isNotEmpty) {
          var temp = mapFromFilterScreen[CITY];

          chipsSearchDataMap[CITY] = mapFromFilterScreen[CITY];

          if (temp != null && temp.isNotEmpty) {
            // if (temp != null && temp.isNotEmpty && temp != "All") {
            filterChipsRelatedList.add({
              CITY: mapFromFilterScreen[CITY],
            });
          }
        }

        if (mapFromFilterScreen.containsKey(PROPERTY_STATE) &&
            mapFromFilterScreen[PROPERTY_STATE] != null &&
            mapFromFilterScreen[PROPERTY_STATE].isNotEmpty) {
          var type = List<String>.from(mapFromFilterScreen[PROPERTY_STATE]);
          var nonEmpty = type.where((element) => element.isNotEmpty).toList();
          // var nonEmpty = type.where((element) => element.isNotEmpty && element != "All").toList();
          filterChipsRelatedList.add({
            PROPERTY_STATE: nonEmpty,
          });
          chipsSearchDataMap[PROPERTY_STATE] = nonEmpty;
        }

        if (mapFromFilterScreen.containsKey(PROPERTY_COUNTRY) &&
            mapFromFilterScreen[PROPERTY_COUNTRY] != null &&
            mapFromFilterScreen[PROPERTY_COUNTRY].isNotEmpty) {
          var type = List<String>.from(mapFromFilterScreen[PROPERTY_COUNTRY]);
          var nonEmpty = type.where((element) => element.isNotEmpty).toList();
          // var nonEmpty = type.where((element) => element.isNotEmpty && element != "All").toList();
          filterChipsRelatedList.add({
            PROPERTY_COUNTRY: nonEmpty,
          });
          chipsSearchDataMap[PROPERTY_COUNTRY] = nonEmpty;
        }
        //if we've area in the map, the upper hierarchy doesn't matter,
        //same goes for city, ie if we've city, then state or country
        //don't matter. so remove higher key, if lower is available.
        if (filteredDataMap.containsKey(SEARCH_RESULTS_AREA)) {
          //remove city, state and country
          filteredDataMap.remove(SEARCH_RESULTS_LOCATION);
          filteredDataMap.remove(SEARCH_RESULTS_STATE);
          filteredDataMap.remove(SEARCH_RESULTS_COUNTRY);
        }

        if (filteredDataMap.containsKey(SEARCH_RESULTS_LOCATION)) {
          //remove state and country
          filteredDataMap.remove(SEARCH_RESULTS_STATE);
          filteredDataMap.remove(SEARCH_RESULTS_COUNTRY);
        }
        if (filteredDataMap.containsKey(SEARCH_RESULTS_STATE)) {
          //remove country
          filteredDataMap.remove(SEARCH_RESULTS_COUNTRY);
        }


        filteredDataMap[SEARCH_RESULTS_CURRENT_PAGE] = '$page';

        filteredDataMap[SEARCH_RESULTS_PER_PAGE] = '${16}';
      } else if (mapFromFilterScreen.isEmpty) {
        filterChipsRelatedList = [
          {PROPERTY_STATUS : ["All"]},
          {PROPERTY_TYPE : ["All"]},
        ];
        chipsSearchDataMap = {
          PROPERTY_STATUS : ["All"],
          PROPERTY_STATUS_SLUG : ["all"],
          PROPERTY_TYPE : ["All"],
          PROPERTY_TYPE_SLUG : ["all"],
        };
      }
    }


    print("SearchResults filteredDataMap: $filteredDataMap");
    // print("SearchResults searchRelatedData: ${widget.searchRelatedData}");
    // print("SearchResults filterChipsRelatedList: $filterChipsRelatedList");
    // print("SearchResults chipsSearchDataMap: $chipsSearchDataMap");

    _futureFilteredArticles = fetchFilteredArticles(
      page,
      perPage,
      filteredDataMap,
      fetchSubListing: widget.fetchSubListing,
    );
  }

  Future<List<dynamic>> fetchFilteredArticles(
    int page,
    perPage,
    Map<String, dynamic> dataMap, {
    bool fetchSubListing = false,
  }) async {
    dataMap["page"] = "$page";
    dataMap["per_page"] = "$perPage";
    print('Map: $dataMap');
    int count = 0;
    bool internetAvailable = false;

    if(isAgent || isAgency || isAuthor || fetchSubListing){
      List<dynamic> tempList = [];
      if(isAgent) {
        tempList = await _propertyBloc.fetchPropertiesByAgentList(realtorId, page, perPage);
      } else if(isAgency) {
        tempList = await _propertyBloc.fetchPropertiesByAgencyList(realtorId, page, perPage);
      } else if(isAuthor) {
        tempList = await _propertyBloc.fetchAllProperties('any', page, perPage, realtorId);
      } else if (fetchSubListing) {
        tempList = await _propertyBloc.fetchMultipleArticles(widget.subListingIds);
      }

      if(tempList == null || (tempList.isNotEmpty && tempList[0] == null) || (tempList.isNotEmpty && tempList[0].runtimeType == Response)){
        internetAvailable = false;
      }else {
        internetAvailable = true;
        if(refreshing) {
          _filteredArticlesList.clear();
        }
        _filteredArticlesList.addAll(tempList);
        count = _filteredArticlesList.length;
      }
    }else {
      Map<String, dynamic> tempList = await _propertyBloc.fetchFilteredArticles(dataMap);
      if(tempList == null || tempList.containsKey('response')){
        internetAvailable = false;

      }else {
        internetAvailable = true;
        if(refreshing) {
          _filteredArticlesList.clear();
        }
        _filteredArticlesList.addAll(tempList["result"]);
        count = tempList["count"];
      }
    }

    if(mounted) setState(() {
      if (_filteredArticlesList.length % perPage != 0) {
        _infiniteStop = true;
      }

      hasInternet = internetAvailable;
      _zoomToAllLocations = true;

      _isAtBottom = false;
      refreshing = false;
      _totalResults = count;
      _isPaginationFree = true;
    });

    Future.delayed(Duration(milliseconds: 100), (){
      if(mounted) setState(() {
        _snapCameraToSelectedIndex = false;
        _showMapWaitingWidget = false;
        selectedMarkerId = -1;
      });
    });

    Map<String,dynamic> tempFilterDataMap = HiveStorageManager.readFilterDataInfo() ?? {};
    tempFilterDataMap[SEARCH_COUNT] = _totalResults;
    HiveStorageManager.storeFilterDataInfo(map: tempFilterDataMap);
    widget.searchPageListener!(HiveStorageManager.readFilterDataInfo() ?? {}, "");

    return _filteredArticlesList;
  }

  // setUpBannerAd(){
  //   _bannerAd = BannerAd(
  //       size: AdSize.banner,
  //       adUnitId: GoogleAdWidget.bannerAdUnitId,
  //       listener: BannerAdListener(onAdLoaded: (_) {
  //         setState(() {
  //           _isBannerAdReady = true;
  //         });
  //       }, onAdFailedToLoad: (ad, LoadAdError error) {
  //         print("Failed to Load A Banner Ad: ${error.message}");
  //         _isBannerAdReady = false;
  //         ad.dispose();
  //       }),
  //       request: AdRequest()
  //   );
  //
  //   _bannerAd.load();
  // }

  setUpNativeAd() {
    String themeMode = ThemeStorageManager.readData(THEME_MODE_INFO) ?? LIGHT_THEME_MODE;
    bool isDarkMode = false;
    if (themeMode == DARK_THEME_MODE) {
      isDarkMode = true;
    }
    NativeAdListener nativeAdListener = NativeAdListener(
      onAdLoaded: (ad) {
        nativeAdList.add(ad);
        if(nativeAdList.length == 5){
          _isNativeAdLoaded = true;
          if(mounted){
            setState(() {});
          }
        }
        // print("nativeAdList.length: ${nativeAdList.length}");
      },
      onAdFailedToLoad: (ad, error) {
        // Releases an ad resource when it fails to load
        ad.dispose();
        if (kDebugMode) {
          print('Ad load failed (code=${error.code} message=${error.message})');
        }
      },
    );
    for (int i = 0; i < 5; i++) {
      NativeAd _nativeAd = NativeAd(
        customOptions: {"isDarkMode": isDarkMode},
        adUnitId: Platform.isAndroid ? ANDROID_NATIVE_AD_ID : IOS_NATIVE_AD_ID,
        factoryId: 'listTile',
        request: const AdRequest(),
        listener: nativeAdListener,
      );

      _nativeAd.load();
    }
  }

}