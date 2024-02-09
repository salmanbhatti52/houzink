import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:houzi_package/common/constants.dart';
import 'package:houzi_package/files/theme_service_files/theme_storage_manager.dart';
import 'package:houzi_package/models/article.dart';
import 'package:houzi_package/models/property_detail_page_widget.dart';
import 'package:houzi_package/pages/property_details_related_pages/property_detail_page_widgets/pd_contact_information.dart';
import 'package:houzi_package/pages/property_details_related_pages/property_detail_page_widgets/pd_address.dart';
import 'package:houzi_package/pages/property_details_related_pages/property_detail_page_widgets/pd_address_detail.dart';
import 'package:houzi_package/pages/property_details_related_pages/property_detail_page_widgets/pd_description.dart';
import 'package:houzi_package/pages/property_details_related_pages/property_detail_page_widgets/pd_enquire_info.dart';
import 'package:houzi_package/pages/property_details_related_pages/property_detail_page_widgets/pd_features.dart';
import 'package:houzi_package/pages/property_details_related_pages/property_detail_page_widgets/pd_features_details.dart';
import 'package:houzi_package/pages/property_details_related_pages/property_detail_page_widgets/pd_floor_plans.dart';
import 'package:houzi_package/pages/property_details_related_pages/property_detail_page_widgets/pd_images.dart';
import 'package:houzi_package/pages/property_details_related_pages/property_detail_page_widgets/pd_related_listing.dart';
import 'package:houzi_package/pages/property_details_related_pages/property_detail_page_widgets/pd_setup_tour.dart';
import 'package:houzi_package/pages/property_details_related_pages/property_detail_page_widgets/pd_static_map_address.dart';
import 'package:houzi_package/pages/property_details_related_pages/property_detail_page_widgets/pd_status_and_price.dart';
import 'package:houzi_package/pages/property_details_related_pages/property_detail_page_widgets/pd_sub_listing.dart';
import 'package:houzi_package/pages/property_details_related_pages/property_detail_page_widgets/pd_title.dart';
import 'package:houzi_package/pages/property_details_related_pages/property_detail_page_widgets/pd_valued_features.dart';
import 'package:houzi_package/pages/property_details_related_pages/property_detail_page_widgets/pd_virtual_tour.dart';
import 'package:houzi_package/pages/property_details_related_pages/property_detail_page_widgets/pd_watch_video.dart';
import 'package:houzi_package/widgets/review_related_widgets/reviews_widget.dart';

typedef PropertyDetailsPageWidgetsListener = void Function(Map<String, dynamic> propertyDetailsPageDataMap, bool dataLoaded);
typedef PropertyPageWidgetsHook = Widget? Function(BuildContext context, Article article, String hook);

class PropertyDetailsPageWidgets extends StatefulWidget {
  Article article;
  final propertyDetailsPageData;
  final propertyID;
  final String heroId;
  final bool fromEagerLoading;
  final latestArticleData;
  final bool latestArticleDataIsReady;
  final Map<String, dynamic> realtorInfoMap;
  final List<dynamic> realtorInfoList;
  PropertyDetailsPageWidgetsListener? propertyDetailsPageWidgetsListener;
  PropertyPageWidgetsHook? widgetsHook;


  PropertyDetailsPageWidgets({
    required this.article,
    this.propertyDetailsPageData,
    this.propertyID,
    required this.heroId,
    this.fromEagerLoading = false,
    this.latestArticleData,
    this.latestArticleDataIsReady = false,
    required this.realtorInfoMap,
    required this.realtorInfoList,
    this.propertyDetailsPageWidgetsListener,
    this.widgetsHook,
  });

  @override
  State<PropertyDetailsPageWidgets> createState() =>
      _PropertyDetailsPageWidgetsState();
}

class _PropertyDetailsPageWidgetsState
    extends State<PropertyDetailsPageWidgets> {
  Article? _article;
  Map propertyDetailsPageMap = {};

  int? tempRealtorId;
  String tempRealtorThumbnail = '';
  String tempRealtorEmail = '';
  String tempRealtorName = '';
  String tempRealtorPhone = "";
  String tempRealtorMobile = "";
  String tempRealtorWhatsApp = "";
  String tempRealtorLink = "";

  String totalRating = "";
  String _articleLink = "";

  String agentDisplayOption = "";
  bool isRefreshing = false;
  bool refreshWidgets = false;

  Map<String, dynamic> realtorInfoMap = {};
  List<String> imageUrlsList = [];
  List<dynamic> realtorInfoList = [];

  String dummyImage = "https://images.wallpaperscraft.com/image/surface_dark_background_texture_50754_1920x1080.jpg";

  String type = "";
  String _title = "";
  String postModifiedGmt = "";

  bool _isNativeAdLoaded = false;
  NativeAd? _nativeAd;

  List<dynamic> propertyDetailPageConfigList = [];

  bool isPropertyDetailPageWidgetItem = false;
  PropertyDetailPageWidgetItem? propertyDetailPageWidgetItem;

  @override
  void initState() {
    super.initState();

    if(widget.propertyDetailsPageData is PropertyDetailPageWidgetItem){
      propertyDetailPageWidgetItem = widget.propertyDetailsPageData;
      isPropertyDetailPageWidgetItem = true;
    } else if (widget.propertyDetailsPageData is! Map) {
      propertyDetailsPageMap = widget.propertyDetailsPageData.toJson();
    } else {
      propertyDetailsPageMap = widget.propertyDetailsPageData;
    }

    if (SHOW_ADS_PROPERTY_PAGE && checkCondition(ADS_PROPERTY_PROFILE)) {
      setUpNativeAd();
    }


    if (widget.article != null) {
      _initializeArticleData(widget.article);
    }
    if (widget.fromEagerLoading) {
      loadArticleData(widget.article);
    }


  }

  _initializeArticleData(Article article) {
    setState(() {
      _article = article;
      _articleLink = _article!.link!;
      imageUrlsList = _article!.imageList!;
      postModifiedGmt = _article!.modifiedGmt!;
    });
  }

  loadArticleData(Article article) {
    setState(() {
      _article = article;
    });

      if (_articleLink.isEmpty) {
        _articleLink = article.link!;
      }
      type = article.type!;
      _title = article.title!;
      if (postModifiedGmt.isEmpty) {
        postModifiedGmt = article.modifiedGmt!;
      }

      setState(() {
        refreshWidgets = true;
      });
  }

  notifyDataIsLoaded({bool sendNoData = false}) {
    Map<String, dynamic> dataMap = {};
    Map<String, dynamic> realtorInfoMap = {
      tempRealtorIdKey: tempRealtorId,
      tempRealtorEmailKey: tempRealtorEmail,
      tempRealtorThumbnailKey: tempRealtorThumbnail,
      tempRealtorNameKey: tempRealtorName,
      tempRealtorLinkKey: tempRealtorLink,
      tempRealtorMobileKey: tempRealtorMobile,
      tempRealtorWhatsAppKey: tempRealtorWhatsApp,
      tempRealtorPhoneKey: tempRealtorPhone,
    };
    if (sendNoData) {
      dataMap = {};
    } else {
      dataMap = realtorInfoMap;
    }
    widget.propertyDetailsPageWidgetsListener!(dataMap, true);
  }

  @override
  dispose() {
    super.dispose();
    if (checkCondition(ADS_PROPERTY_PROFILE) && _nativeAd != null) {
      _nativeAd!.dispose();
    }
  }
  bool checkCondition(String value) {
    if (propertyDetailsPageMap[WIDGET_ENABLED_PROPERTY_PROFILE] == true &&
        propertyDetailsPageMap[WIDGET_TYPE_PROPERTY_PROFILE] == value) {
      return true;
    }
    return false;
  }

  setUpNativeAd() {
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

  @override
  Widget build(BuildContext context) {
    if (widget.latestArticleDataIsReady) {
      _article = widget.latestArticleData;
      loadArticleData(_article!);
      notifyDataIsLoaded(sendNoData: true);
    }

    if ((checkCondition(CONTACT_INFORMATION_PROPERTY_PROFILE) || checkCondition(BUTTON_GRID_PROPERTY_PROFILE)) &&
        realtorInfoMap.isEmpty && widget.realtorInfoMap != null && widget.realtorInfoMap.isNotEmpty) {
      realtorInfoMap.addAll(widget.realtorInfoMap);

      tempRealtorId = realtorInfoMap[tempRealtorIdKey];
      tempRealtorName = realtorInfoMap[tempRealtorNameKey] ?? "";
      tempRealtorEmail = realtorInfoMap[tempRealtorEmailKey] ?? "";
      tempRealtorThumbnail = realtorInfoMap[tempRealtorThumbnailKey] ?? "";
      tempRealtorPhone = realtorInfoMap[tempRealtorPhoneKey] ?? "";
      tempRealtorMobile = realtorInfoMap[tempRealtorMobileKey] ?? "";
      tempRealtorWhatsApp = realtorInfoMap[tempRealtorWhatsAppKey] ?? "";
      tempRealtorLink = realtorInfoMap[tempRealtorLinkKey] ?? "";
    }

    if ((checkCondition(CONTACT_INFORMATION_PROPERTY_PROFILE)) &&
        realtorInfoList.isEmpty && widget.realtorInfoList != null &&
        widget.realtorInfoList.isNotEmpty) {
      realtorInfoList.addAll(widget.realtorInfoList);
    }

    return Column(
      children: [
        if (checkCondition(IMAGES_PROPERTY_PROFILE))
          widget.widgetsHook!(context, _article!, IMAGES_PROPERTY_PROFILE) ??
              PropertyDetailPageImages(
                article: _article!,
                heroId: widget.heroId,
              ),
        if (checkCondition(TITLE_PROPERTY_PROFILE))
          widget.widgetsHook!(context, _article!, TITLE_PROPERTY_PROFILE) ??
              PropertyDetailPageTitle(article: _article!),
        if (checkCondition(ADDRESS_PROPERTY_PROFILE))
          widget.widgetsHook!(context, _article!, ADDRESS_PROPERTY_PROFILE) ??
              PropertyDetailPageAddress(article: _article!),
        if (checkCondition(STATUS_AND_PRICE_PROPERTY_PROFILE))
          widget.widgetsHook!(context, _article!, STATUS_AND_PRICE_PROPERTY_PROFILE) ??
              PropertyDetailPageStatusAndPrice(article: _article!),
        if (_isNativeAdLoaded &&
            SHOW_ADS_PROPERTY_PAGE &&
            checkCondition(ADS_PROPERTY_PROFILE))
          Container(
            padding: const EdgeInsets.only(left: 20, right: 20),
            height: 70,
            child: AdWidget(ad: _nativeAd!),
          ),
        if (checkCondition(VALUED_FEATURES_PROPERTY_PROFILE))
          widget.widgetsHook!(context, _article!, VALUED_FEATURES_PROPERTY_PROFILE) ??
              PropertyDetailPageValuedFeatured(article: _article!),
        if (checkCondition(FEATURES_DETAILS_PROPERTY_PROFILE))
          widget.widgetsHook!(context, _article!, FEATURES_DETAILS_PROPERTY_PROFILE) ??
              PropertyDetailPageFeaturesDetail(
                article: _article!,
                title: propertyDetailsPageMap[WIDGET_TITLE_PROPERTY_PROFILE],
              ),
        if (checkCondition(FEATURES_PROPERTY_PROFILE))
          widget.widgetsHook!(context, _article!, FEATURES_PROPERTY_PROFILE) ??
              PropertyDetailPageFeatures(
                article: _article!,
                title: propertyDetailsPageMap[WIDGET_TITLE_PROPERTY_PROFILE],
              ),
        if (checkCondition(DESCRIPTION_PROPERTY_PROFILE))
          widget.widgetsHook!(context, _article!, DESCRIPTION_PROPERTY_PROFILE) ??
              PropertyDetailPageDescription(
                article: _article!,
                title: propertyDetailsPageMap[WIDGET_TITLE_PROPERTY_PROFILE],
              ),
        if (checkCondition(ADDRESS_INFO_PROPERTY_PROFILE))
          widget.widgetsHook!(context, _article!, ADDRESS_INFO_PROPERTY_PROFILE) ??
              PropertyDetailPageAddressDetail(
                article: _article!,
                title: propertyDetailsPageMap[WIDGET_TITLE_PROPERTY_PROFILE],
                imageUrlsList: imageUrlsList,
              ),
        if (checkCondition(MAP_PROPERTY_PROFILE))
          widget.widgetsHook!(context, _article!, MAP_PROPERTY_PROFILE) ??
              PropertyDetailPageStaticMapAddress(
                article: _article!,
                imageUrlsList: imageUrlsList,
              ),
        if (checkCondition(FLOOR_PLANS_PROPERTY_PROFILE))
          widget.widgetsHook!(context, _article!, FLOOR_PLANS_PROPERTY_PROFILE) ??
              PropertyDetailPageFloorPlans(
                article: _article!,
                title: propertyDetailsPageMap[WIDGET_TITLE_PROPERTY_PROFILE],
              ),
        if (checkCondition(MULTI_UNITS_PROPERTY_PROFILE))
          widget.widgetsHook!(context, _article!, MULTI_UNITS_PROPERTY_PROFILE) ??
              PropertyDetailPageSubListing(
                article: _article!,
                title: propertyDetailsPageMap[WIDGET_TITLE_PROPERTY_PROFILE],
                widgetViewType: propertyDetailsPageMap[WIDGET_VIEW_TYPE_PROPERTY_PROFILE],
              ),
        if (checkCondition(CONTACT_INFORMATION_PROPERTY_PROFILE))
          widget.widgetsHook!(context, _article!, CONTACT_INFORMATION_PROPERTY_PROFILE) ??
              PropertyDetailPageContactInformation(
                article: _article!,
                title: propertyDetailsPageMap[WIDGET_TITLE_PROPERTY_PROFILE],
                realtorInfoList: realtorInfoList,
                realtorInfoMap: realtorInfoMap,
              ),
        // if (checkCondition(BUTTON_GRID_PROPERTY_PROFILE))
        //   widget.widgetsHook(_article, BUTTON_GRID_PROPERTY_PROFILE) ??
        //       PropertyDetailPageOptions(
        //         article: _article,
        //         title: propertyDetailsPageMap[WIDGET_TITLE_PROPERTY_PROFILE],
        //         realtorInfoList: realtorInfoList,
        //         realtorInfoMap: realtorInfoMap,
        //       ),
        if (checkCondition(ENQUIRE_INFO_PROPERTY_PROFILE))
          widget.widgetsHook!(context, _article!, ENQUIRE_INFO_PROPERTY_PROFILE) ??
              PropertyDetailPageEnquireInfo(
                article: _article!,
                title: propertyDetailsPageMap[WIDGET_TITLE_PROPERTY_PROFILE],
                realtorInfoMap: widget.realtorInfoMap,
              ),
        if (checkCondition(SETUP_TOUR_PROPERTY_PROFILE))
          widget.widgetsHook!(context, _article!, SETUP_TOUR_PROPERTY_PROFILE) ??
              PropertyDetailPageSetupTour(
                article: _article!,
                title: propertyDetailsPageMap[WIDGET_TITLE_PROPERTY_PROFILE],
                realtorInfoMap: widget.realtorInfoMap,
              ),
        if (checkCondition(WATCH_VIDEO_PROPERTY_PROFILE))
          widget.widgetsHook!(context, _article!, WATCH_VIDEO_PROPERTY_PROFILE) ??
              PropertyDetailPageWatchVideo(
                article: _article!,
                title: propertyDetailsPageMap[WIDGET_TITLE_PROPERTY_PROFILE],
              ),
        if (checkCondition(VIRTUAL_TOUR_PROPERTY_PROFILE))
          widget.widgetsHook!(context, _article!, VIRTUAL_TOUR_PROPERTY_PROFILE) ??
              PropertyDetailPageVirtualTour(
                article: _article!,
                title: propertyDetailsPageMap[WIDGET_TITLE_PROPERTY_PROFILE],
              ),
        if (checkCondition(REVIEWS_PROPERTY_PROFILE) && SHOW_REVIEWS)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ReviewsWidget(
              fromProperty: true,
              idForReviews: widget.propertyID,
              totalRating: getRating(_article!.propertyInfo!.houzezTotalRating),
              link: _article!.link == null || _article!.link!.isEmpty ? _articleLink : _article!.link,
              title: _article!.title == null || _article!.title!.isEmpty ? _title : _article!.title,
              type: _article!.type == null || _article!.type!.isEmpty ? type : _article!.type,
              titleFromPropertyDetailsPage: propertyDetailsPageMap[WIDGET_TITLE_PROPERTY_PROFILE],
            ),
          ),
        if (checkCondition(RELATED_POSTS_PROPERTY_PROFILE))
          widget.widgetsHook!(context, _article!, RELATED_POSTS_PROPERTY_PROFILE) ??
              PropertyDetailPageRelatedListing(
                propertyID: widget.propertyID,
                title: propertyDetailsPageMap[WIDGET_TITLE_PROPERTY_PROFILE],
                widgetViewType: propertyDetailsPageMap[WIDGET_VIEW_TYPE_PROPERTY_PROFILE],
              ),
      ],
    );
  }

  String? getRating(dynamic rating){
    if (rating != null && rating is String && rating.isNotEmpty) {
      double? tempTotalRating = double.tryParse(rating);
      if(tempTotalRating != null){
        return tempTotalRating.toStringAsFixed(0);
      }
    }
    return null;
  }
}