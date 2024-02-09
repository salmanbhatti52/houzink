import 'dart:convert';
import 'dart:math';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:houzi_package/blocs/property_bloc.dart';
import 'package:houzi_package/common/constants.dart';
import 'package:houzi_package/files/configurations/app_configurations.dart';
import 'package:houzi_package/files/generic_methods/general_notifier.dart';
import 'package:houzi_package/files/hive_storage_files/hive_storage_manager.dart';
import 'package:houzi_package/files/user_log_provider.dart';
import 'package:houzi_package/l10n/string_extension.dart';
import 'package:houzi_package/models/article.dart';
import 'package:houzi_package/models/drawer.dart';
import 'package:houzi_package/models/home_config.dart';
import 'package:houzi_package/models/property_detail_page_config.dart';
import 'package:houzi_package/models/property_meta_data.dart';
import 'package:houzi_package/pages/app_settings_pages/about.dart';
import 'package:houzi_package/pages/app_settings_pages/dark_mode_setting.dart';
import 'package:houzi_package/pages/app_settings_pages/language_settings.dart';
import 'package:houzi_package/pages/filter_page.dart';
import 'package:houzi_package/pages/home_screen_drawer_menu_pages/user_related/user_signin.dart';
import 'package:houzi_package/pages/property_details_page.dart';
import 'package:houzi_package/pages/search_result.dart';
import 'package:html/parser.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:houzi_package/pages/app_settings_pages/web_page.dart';

typedef NavigateToSearchResultScreenListener = void Function({Map<String, dynamic>? filterDataMap});
typedef AppTrackingPermissionCallback = void Function({String? status});
typedef PriceFormatterHook = String? Function(String propertyPrice, String firstPrice);
typedef CompactPriceFormatterHook = String? Function(String inputPrice);
typedef HidePriceHook = bool Function();
typedef DrawerHeaderHook = Widget? Function(
    BuildContext context,
    String appName,
    String appIconPath,
    String? userProfileName,
    String? userProfileImageUrl,
);
typedef ProfileHook = List<Widget> Function(BuildContext context);


class UtilityMethods{
  // Platform messages are asynchronous, so we initialize in an async method.
  static Future<void> initTrackingPermissionAndInitializeMobileAds(AppTrackingPermissionCallback trackingCallback) async {
    final TrackingStatus status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (trackingCallback != null) {
      trackingCallback(status:'$status');
    }
    // If the system can show an authorization request dialog
    if (status == TrackingStatus.notDetermined) {
      // Show a custom explainer dialog before the system dialog
      //await showCustomTrackingDialog(context);
      // Wait for dialog popping animation
      //await Future.delayed(const Duration(milliseconds: 200));
      // Request system's tracking authorization dialog
      final TrackingStatus status =
      await AppTrackingTransparency.requestTrackingAuthorization();
      if (trackingCallback != null) {
        trackingCallback(status:'$status');
      }
    }

    final uuid = await AppTrackingTransparency.getAdvertisingIdentifier();
    print("AppTrackingTransparency status: $status and UUID: $uuid");
    await MobileAds.instance.initialize();
  }

  static bool validateURL(String? url){
    if(url == null || url.isEmpty){
      return false;
    }
    bool isURLValid = Uri.parse(url).isAbsolute;
    return isURLValid;
  }

  static String getLocalizedString(String key,{List? inputWords}){
    if(inputWords == null){
      String translated = key.localisedString([]) ?? key;
      // print(translated);
      if(translated == null || translated == "null") {
        return key;
      }
      return key.localisedString([]) ?? key;
    } else {
      String translated = key.localisedString(inputWords) ?? key;
      if(translated == null || translated == "null") {
        return key;
      }
      return key.localisedString(inputWords) ?? key;
    }

  }

  static bool isRTL(BuildContext context) {
    return Bidi.isRtlLanguage(Localizations.localeOf(context).languageCode);
  }

  static String toTitleCase(String inputString){
    return inputString.replaceAll(RegExp(' +'), ' ').split(" ").map((str) => toCapitalized(str)).join(" ");
  }

  static String toCapitalized(String inputString) {
    return inputString.isNotEmpty ?'${inputString[0].toUpperCase()}${inputString.substring(1)}':'';
  }

  static String stripHtmlIfNeeded(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
  }

  static String makePriceCompact(String inputPrice, {bool priceOnly =  false}){
    CompactPriceFormatterHook compactPriceFormatterHook = compactPriceFormatter;
    String? price = compactPriceFormatterHook(inputPrice);
    if (price != null) {
      return price;
    } else {
      String compactPrice = '';
      String postfix = '';
      String additionalCharacter = '';
      String defaultCurrency = HiveStorageManager.readDefaultCurrencyInfoData() ?? '\$';

      RegExp pattern = RegExp(r"\b(\d+(\.\d+)?)(M|K)\b");
      // print('1. Input Price: $inputPrice');
      /// Return Input Price If already in Compact State
      if (pattern.hasMatch(inputPrice)) {
        return inputPrice;
      }

      // print("Input Price: $inputPrice");
      /// Remove Currency from Input Price
      if(inputPrice.contains(defaultCurrency)) {
        inputPrice = inputPrice.replaceAll(defaultCurrency, '');
        // inputPrice = inputPrice.split(defaultCurrency)[1];
      }
      /// Remove ',' from Input Price
      if(inputPrice.contains(',')) {
        inputPrice = inputPrice.replaceAll(',', '');
      }
      /// Separate Postfix from Input Price
      if(inputPrice.contains('/')){
        postfix = inputPrice.split('/')[1];
        inputPrice = inputPrice.split('/')[0];
      }
      /// Round of Input Price to One Digit
      if (inputPrice.contains('.')) {
        var priceDouble = double.tryParse(inputPrice);
        if (priceDouble == null) return inputPrice;

        inputPrice = priceDouble.toStringAsFixed(0);
      }

      if(inputPrice.contains('+')){
        inputPrice = inputPrice.split('+')[0];
        additionalCharacter = "+";
      }
      if(inputPrice.contains('|')){
        inputPrice = inputPrice.split('|')[0];
      }


      // print('2. Input Price: $inputPrice');
      /// Make the Input Price Compact
      var priceDouble = double.tryParse(inputPrice);
      if (priceDouble == null) return inputPrice;
      compactPrice = NumberFormat.compact().format(priceDouble);

      if (priceOnly) {
        return compactPrice;
      }
      ///  Add Currency Symbol to Input Price
      if(defaultCurrency != null && defaultCurrency.isNotEmpty){
        compactPrice = setCurrencyPosition(compactPrice);
      }
      ///  Add PostFix to Input Price
      if(postfix != null && postfix.isNotEmpty){
        compactPrice = '$compactPrice/$postfix';
      }
      if(additionalCharacter != null && additionalCharacter.isNotEmpty){
        compactPrice = '$compactPrice$additionalCharacter';
      }

      return compactPrice;
    }

  }

  static String formatPrice(String inputPrice){
    String compactPrice = '';
    String postfix = '';
    String additionalCharacter = '';
    String defaultCurrency = HiveStorageManager.readDefaultCurrencyInfoData() ?? '\$';
    RegExp pattern = RegExp(r"\b(\d+(\.\d+)?)(M|K)\b");
    // print('1. Input Price: $inputPrice');
    /// Return Input Price If already in Compact State
    if (pattern.hasMatch(inputPrice)) {
      return inputPrice;
    }

    /// Return Input Price If already in Compact State
    if (pattern.hasMatch(inputPrice)) {
      return inputPrice;
    }

    /// Remove Currency from Input Price
    if (inputPrice.contains(defaultCurrency)) {
      inputPrice = inputPrice.replaceAll(defaultCurrency, '');
      // inputPrice = inputPrice.split(defaultCurrency)[1];
    }

    /// Remove ',' from Input Price
    if (inputPrice.contains(',')) {
      inputPrice = inputPrice.replaceAll(',', '');
    }

    /// Separate Postfix from Input Price
    if (inputPrice.contains('/')) {
      postfix = inputPrice.split('/')[1];
      inputPrice = inputPrice.split('/')[0];
    }

    if (inputPrice.contains('+')) {
      inputPrice = inputPrice.split('+')[0];
      additionalCharacter = "+";
    }
    if(inputPrice.contains('|')){
      inputPrice = inputPrice.split('|')[0];
    }

    /// Round of Input Price to One Digit
    if (inputPrice.contains('.')) {
      inputPrice = inputPrice.replaceAll('.', '');
    }

    // print('2. Input Price: $inputPrice');
    /// Make the Input Price Compact
    compactPrice = inputPrice;

    double? tempPrice = double.tryParse(compactPrice);
    if (tempPrice != null) {
      var numberFormat = getNumberFormat();
      compactPrice = numberFormat.format(tempPrice.round()).toString();
    }

    ///  Add Currency Symbol to Input Price
    if (defaultCurrency != null && defaultCurrency.isNotEmpty) {
      compactPrice = setCurrencyPosition(compactPrice);
    }

    ///  Add PostFix to Input Price
    if (postfix != null && postfix.isNotEmpty) {
      compactPrice = '$compactPrice/$postfix';
    }
    if (additionalCharacter != null && additionalCharacter.isNotEmpty) {
      compactPrice = '$compactPrice$additionalCharacter';
    }

    return compactPrice;
  }

  static String priceFormatter(String propertyPrice, String firstPrice) {
    PriceFormatterHook priceFormatterHook = priceFormat;
    String? price = priceFormatterHook(propertyPrice, firstPrice);
    if (price != null) {
      return price;
    } else {
      String _propertyPrice = "";
      String _firstPrice = "";
      String _finalPrice = "";

      if (_propertyPrice != null && propertyPrice.isNotEmpty) {
        _propertyPrice = propertyPrice;
        _propertyPrice = formatPrice(_propertyPrice);
      }
      if (firstPrice != null && firstPrice.isNotEmpty) {
        _firstPrice = firstPrice;
        _firstPrice = formatPrice(_firstPrice);
      }

      _finalPrice = _firstPrice != null && _firstPrice.isNotEmpty
          ? _firstPrice
          : _propertyPrice;

      return _finalPrice;
    }

  }

  static int getCleanPriceForSorting(String propertyPrice) {
    int price = int.tryParse(propertyPrice.replaceAll(RegExp(r'[^\d]+'), '')) ?? 0;
    return price;
  }

  static String setCurrencyPosition(String price){
    String defaultCurrency = HiveStorageManager.readDefaultCurrencyInfoData() ?? '\$';
    if (CURRENCY_POSITION == "after") {
      return price = "$price $defaultCurrency";
    } else {
      return price = "$defaultCurrency$price";
    }
  }

  static NumberFormat getNumberFormat(){
    NumberFormat? numberFormat;
    if(THOUSAND_SEPARATOR == ",") {
      numberFormat =  NumberFormat("#$THOUSAND_SEPARATOR###$DECIMAL_POINT_SEPARATOR##");
    } else if(THOUSAND_SEPARATOR == ".") {
      numberFormat = NumberFormat.currency(locale: 'eu',customPattern: '#$DECIMAL_POINT_SEPARATOR###', decimalDigits: 0);

    } else if(THOUSAND_SEPARATOR == " ") {
      numberFormat = NumberFormat.currency(locale: 'fr',customPattern: '#,###', decimalDigits: 0);
    }
    return numberFormat!;
  }


  static void navigateToRoute({
    required context,
    required WidgetBuilder builder
  }){
    Route pageRoute = MaterialPageRoute(builder: builder);
    Navigator.push(context, pageRoute);

  }

  static void navigateToRouteByReplacement({
    required context,
    required WidgetBuilder builder
  }){
    Route pageRoute = MaterialPageRoute(builder: builder);
    Navigator.pushReplacement(context, pageRoute);
  }

  static void navigateToRouteByPushAndRemoveUntil({
    required context,
    required WidgetBuilder builder
  }){
    Route pageRoute = MaterialPageRoute(builder: builder);
    Navigator.pushAndRemoveUntil(context, pageRoute, (route) => false);
    // Navigator.of(context).pushAndRemoveUntil(pageRoute, (Route<dynamic> route) => false);
  }



  static void navigateToSearchResultScreen({
    required BuildContext context,
    Map<String, dynamic>? dataInitializationMap,
    Map<String, dynamic>? searchRelatedData,
    final NavigateToSearchResultScreenListener? navigateToSearchResultScreenListener,
  }){
    builder(context) => SearchResult(
      dataInitializationMap: dataInitializationMap ?? {},
      searchRelatedData: searchRelatedData ?? {},
      searchPageListener: (Map<String, dynamic> map, String closeOption){
        if(closeOption == CLOSE){
          Navigator.of(context).pop();
          navigateToSearchResultScreenListener!(filterDataMap: HiveStorageManager.readFilterDataInfo());
        }
      },
    );
    UtilityMethods.navigateToRoute(context: context, builder: builder);
  }

  static Future<Map<String, dynamic>> convertArticleToMap(int propertyId,int userId, PropertyBloc propertyBloc) async {
    List<dynamic> propertyTypesList = [];
    List<dynamic> propertyLabelList = [];
    List<dynamic> propertyStatusList = [];
    List<dynamic> propertyFeaturesList = [];

    propertyTypesList = HiveStorageManager.readPropertyTypesMetaData();
    propertyLabelList = HiveStorageManager.readPropertyLabelsMetaData();
    propertyStatusList = HiveStorageManager.readPropertyStatusMetaData();
    propertyFeaturesList = HiveStorageManager.readPropertyFeaturesMetaData();


    final response = await propertyBloc.fetchSingleArticle(propertyId, forEditing: true);
    Map<String, dynamic> dataMapForUpdateProperty = {};
    if (response == null || response.isEmpty) {
      print("list of single article is null or empty");
    } else {
      Article article = response[0];
      List<dynamic> propertyImagesList = article.imageList ?? [];
      String propertyTitle = article.title ?? "";
      String propertyVideo = article.video ?? "";
      String featuredImageId = "${article.featuredImageId}";
      String content = UtilityMethods.stripHtmlIfNeeded(article.content ?? "");
      String propertyType = article.propertyInfo!.propertyType ?? "";
      int intPropertyType;
      String propertyStatus = article.propertyInfo!.propertyStatus ?? "";
      int intPropertyStatus;
      String propertyLabel = article.propertyInfo!.propertyLabel ?? "";
      int intPropertyLabel;
      String propertyFirstPrice = article.propertyInfo!.firstPrice ?? "";
      String propertyPrice = article.propertyInfo!.price ?? "";
      List<dynamic> agencyList = article.propertyInfo!.agencyList ?? [];
      List<dynamic> agentList = article.propertyInfo!.agentList ?? [];
      // print("agentList: $agentList");
      String agentDisplayOption = article.propertyInfo!.agentDisplayOption ?? "";
      String propertyPricePostfix = article.propertyInfo!.pricePostfix ?? "";
      String propertySecondPrice = article.propertyInfo!.secondPrice ?? "";
      Map<String, dynamic> propertyCustomFieldsMap = article.propertyInfo!.customFieldsMapForEditing ?? {};
      String propertyBedrooms = article.features!.bedrooms ?? "";
      String propertyBathrooms = article.features!.bathrooms ?? "";
      String propertyLandArea = article.features!.landArea ?? "";
      String propertyGarage = article.features!.garage ?? "";
      String propertyGarageSize = article.features!.garageSize ?? "";
      String propertyYearBuilt = article.features!.yearBuilt ?? "";
      String propertyBuildingAreaUnit = article.features!.buildingAreaUnit ?? "";
      String propertyLandAreaUnit = article.features!.landAreaUnit ?? "";
      List<dynamic> propertyFeaturesListFromArticle = article.features!.featuresList ?? [];
      List<dynamic> propertyImagesIdList = article.features!.imagesIdList ?? [];
      String propertyAddress = article.address!.address ?? "";
      String propertyCountry = article.address!.country ?? "";
      String propertyState = article.address!.state ?? "";
      String propertyCity = article.address!.city ?? "";
      String propertyArea = article.address!.area ?? "";
      String propertyPostalCode = article.address!.postalCode ?? "";
      String propertyLat = article.address!.lat ?? "";
      String propertyLong = article.address!.long ?? "";
      String multiUnitsListingIDs = article.features!.multiUnitsListingIDs ?? "";
      String propertyVirtualTourLink = article.propertyInfo!.propertyVirtualTourLink ?? "";
      List<dynamic> floorPlansList = article.features!.floorPlansList ?? [];
      List<dynamic> additionalDetailsList = article.features!.additionalDetailsList ?? [];
      List<dynamic> multiUnitsList = article.features!.multiUnitsList ?? [];
      bool isFeatured = article.propertyInfo!.isFeatured ?? false;
      bool isLoginRequired = article.propertyInfo!.requiredLogin;
      String isFeaturedStr = isFeatured ? "1" : "0";
      String isLoginRequiredStr = isLoginRequired ? "1" : "0";

      int comparedValueForType = getIDS(propertyTypesList, propertyType);
      int comparedValueForLabel = getIDS(propertyLabelList, propertyLabel);
      int comparedValueForStatus = getIDS(propertyStatusList, propertyStatus);
      var listOfFeatures = getIdsForFeatures(propertyFeaturesList, propertyFeaturesListFromArticle);
      intPropertyType = comparedValueForType;
      intPropertyLabel = comparedValueForLabel;
      intPropertyStatus = comparedValueForStatus;

      if (propertyPrice == "") {
        propertyPrice = propertyFirstPrice;
      }
      String featuredImageIndex = "0";
      for (int i = 0; i < propertyImagesIdList.length; i++) {

        if(featuredImageId == propertyImagesIdList[i]) {
          featuredImageIndex = "$i";
        }
      }

      dataMapForUpdateProperty = {
        UPDATE_PROPERTY_ID: '$propertyId',
        ADD_PROPERTY_ACTION: ADD_PROPERTY_ACTION_UPDATE,
        ADD_PROPERTY_USER_ID: '$userId',
        ADD_PROPERTY_USER_HAS_NO_MEMBERSHIP: 'no',
        //ADD_PROPERTY_CURRENCY : '\$',
        //ADD_PROPERTY_MULTI_UNITS : '${0}',
        ADD_PROPERTY_FLOOR_PLANS_ENABLE: '0',
        ADD_PROPERTY_TITLE: propertyTitle,
        ADD_PROPERTY_DESCRIPTION: content,
        ADD_PROPERTY_TYPE: [intPropertyType],
        ADD_PROPERTY_STATUS: [intPropertyStatus],
        ADD_PROPERTY_LABELS: [intPropertyLabel],
        ADD_PROPERTY_TYPE_NAMES_LIST: [propertyType],
        ADD_PROPERTY_LABEL_NAMES_LIST: [propertyLabel],
        ADD_PROPERTY_STATUS_NAMES_LIST: [propertyStatus],
        ADD_PROPERTY_PRICE: propertyPrice,
        ADD_PROPERTY_PRICE_POSTFIX: propertyPricePostfix,
        ADD_PROPERTY_PRICE_PREFIX: '',
        //ADD_PROPERTY_PRICE_PREFIX : 'prop_price_prefix',
        ADD_PROPERTY_SECOND_PRICE: propertySecondPrice,
        ADD_PROPERTY_VIDEO_URL: propertyVideo,
        ADD_PROPERTY_BEDROOMS: propertyBedrooms,
        ADD_PROPERTY_BATHROOMS: propertyBathrooms,
        ADD_PROPERTY_SIZE: propertyLandArea,
        ADD_PROPERTY_SIZE_PREFIX: propertyLandAreaUnit,
        ADD_PROPERTY_LAND_AREA: '',
        //ADD_PROPERTY_LAND_AREA : 'prop_land_area',
        ADD_PROPERTY_LAND_AREA_PREFIX: '',
        //ADD_PROPERTY_LAND_AREA_PREFIX : 'prop_land_area_prefix',
        ADD_PROPERTY_GARAGE: propertyGarage,
        ADD_PROPERTY_GARAGE_SIZE: propertyGarageSize,
        ADD_PROPERTY_YEAR_BUILT: propertyYearBuilt,
        ADD_PROPERTY_FEATURES_LIST: listOfFeatures,
        ADD_PROPERTY_VIRTUAL_TOUR: propertyVirtualTourLink,
        ADD_PROPERTY_FAVE_PROPERTY_MAP: '',
        ADD_PROPERTY_FLOOR_PLANS: getFloorPlansList(floorPlansList),
        ADD_PROPERTY_ADDITIONAL_FEATURES: getAdditionalDetailsList(additionalDetailsList),
        ADD_PROPERTY_FAVE_MULTI_UNITS: getMultiUnitsList(multiUnitsList),
        // ADD_PROPERTY_FAVE_PROPERTY_MAP: 'fave_property_map',
        UPDATE_PROPERTY_IMAGES: propertyImagesList,
        // ADD_PROPERTY_PROPERTY_ID: 'property_id',
        ADD_PROPERTY_IMAGE_IDS: propertyImagesIdList,
        ADD_PROPERTY_FEATURED_IMAGE_ID: featuredImageId,
        ADD_PROPERTY_FEATURED_IMAGE_LOCAL_INDEX: featuredImageIndex,
        ADD_PROPERTY_FAVE_AGENT_DISPLAY_OPTION: agentDisplayOption,
        ADD_PROPERTY_FAVE_AGENT: agentList,
        ADD_PROPERTY_FAVE_AGENCY: agencyList,
        ADD_PROPERTY_MAKE_PROPERTY_FEATURED: isFeaturedStr,
        ADD_PROPERTY_USER_LOGGED_IN_TO_VIEW: isLoginRequiredStr,
      };

      if(propertyAddress != null && propertyAddress.isNotEmpty){
        dataMapForUpdateProperty[ADD_PROPERTY_MAP_ADDRESS] = propertyAddress;
      }
      if(SHOW_COUNTRY_NAME_FIELD && propertyCountry != null && propertyCountry.isNotEmpty){
        dataMapForUpdateProperty[ADD_PROPERTY_COUNTRY] = propertyCountry;
      }
      if(SHOW_STATE_COUNTY_FIELD && propertyState != null && propertyState.isNotEmpty){
        dataMapForUpdateProperty[ADD_PROPERTY_STATE_OR_COUNTY] = propertyState;
      }
      if(SHOW_LOCALITY_FIELD && propertyCity != null && propertyCity.isNotEmpty){
        dataMapForUpdateProperty[ADD_PROPERTY_CITY] = propertyCity;
      }
      if(SHOW_NEIGHBOURHOOD_FIELD && propertyArea != null && propertyArea.isNotEmpty){
        dataMapForUpdateProperty[ADD_PROPERTY_AREA] = propertyArea;
      }
      if(propertyPostalCode != null && propertyPostalCode.isNotEmpty){
        dataMapForUpdateProperty[ADD_PROPERTY_POSTAL_CODE] = propertyPostalCode;
      }
      if(propertyLat != null && propertyLat.isNotEmpty){
        dataMapForUpdateProperty[ADD_PROPERTY_LATITUDE] = propertyLat;
      }
      if(propertyLong != null && propertyLong.isNotEmpty){
        dataMapForUpdateProperty[ADD_PROPERTY_LONGITUDE] = propertyLong;
      }
      if(multiUnitsListingIDs != null && multiUnitsListingIDs.isNotEmpty){
        dataMapForUpdateProperty[ADD_PROPERTY_FAVE_MULTI_UNITS_IDS] = multiUnitsListingIDs;
      }

      if(propertyCustomFieldsMap!=null && propertyCustomFieldsMap.isNotEmpty){
        propertyCustomFieldsMap.forEach((key, value) {
          Map<String,dynamic> map = {key:value};
          dataMapForUpdateProperty.addAll(map);
        });
      }

    }

    return dataMapForUpdateProperty;

  }

  static int getIDS(List<dynamic> inputList, String inputString) {
    int itemId = -1;
    if (inputList == null || inputList.isEmpty || inputString == null) {
      return -1;
    } else {
      for (int i = 0; i < inputList.length; i++) {
        if (inputString == inputList[i].name) {
          itemId = inputList[i].id;
        }
      }
      return itemId;
    }


  }

  static List<int> getIdsForFeatures(List<dynamic> propertyFeaturesList,
      List<dynamic> propertyFeaturesListFromArticle) {
    List<int> featuresList = [];
    if ((propertyFeaturesList == null || propertyFeaturesList.isEmpty) &&
        (propertyFeaturesListFromArticle == null ||
            propertyFeaturesListFromArticle.isEmpty)) {
      return featuresList;
    } else {
      for (int i = 0; i < propertyFeaturesList.length; i++) {
        String tempName = propertyFeaturesList[i].name;
        int tempId = propertyFeaturesList[i].id;
        for (int i = 0; i < propertyFeaturesListFromArticle.length; i++) {
          if (propertyFeaturesListFromArticle[i] == tempName) {
            featuresList.add(tempId);
          }
        }
      }
    }
    return featuresList;
  }

  static List<Map<String, dynamic>> getFloorPlansList(List<dynamic> list){
    if(list != null && list.isNotEmpty){
      List<Map<String, dynamic>> floorPlanList = [];
      for(var floorPlanElement in list){
        floorPlanList.add({
          favePlanTitle : floorPlanElement.title,
          favePlanRooms : floorPlanElement.rooms,
          favePlanBathrooms : floorPlanElement.bathrooms,
          favePlanPrice : floorPlanElement.price,
          favePlanPricePostFix : floorPlanElement.pricePostFix,
          favePlanSize : floorPlanElement.size,
          favePlanImage : floorPlanElement.image,
          favePlanDescription : floorPlanElement.description,
        });
      }
      return floorPlanList;
    }

    return [];
  }

  static List<Map<String, dynamic>> getAdditionalDetailsList(List<dynamic> list){
    if(list != null && list.isNotEmpty){
      List<Map<String, dynamic>> additionalDetailsList = [];
      for(var additionalDetailElement in list){
        additionalDetailsList.add({
          faveAdditionalFeatureTitle : additionalDetailElement.title,
          faveAdditionalFeatureValue : additionalDetailElement.value,
        });
      }
      return additionalDetailsList;
    }

    return [];
  }

  static List<Map<String, dynamic>> getMultiUnitsList(List<dynamic> list){
    if(list != null && list.isNotEmpty){
      List<Map<String, dynamic>> multiUnitsList = [];
      for(var multiUnitsElement in list){
        multiUnitsList.add({
          faveMUTitle : multiUnitsElement.title,
          faveMUBeds : multiUnitsElement.bedrooms,
          faveMUBaths : multiUnitsElement.bathrooms,
          faveMUPrice : multiUnitsElement.price,
          faveMUPricePostfix : multiUnitsElement.pricePostfix,
          faveMUSizePostfix : multiUnitsElement.sizePostfix,
          faveMUSize : multiUnitsElement.size,
          faveMUType : multiUnitsElement.type,
          faveMUAvailabilityDate : multiUnitsElement.availabilityDate,
        });
      }
      return multiUnitsList;
    }

    return [];
  }



  static Map<String,dynamic> iconMap = {};
  static getIconsMap() {
    iconMap["Bedrooms"] = Icons.king_bed_outlined;
    iconMap["Bathrooms"] = Icons.bathtub_outlined;
    iconMap["Garage"] = Icons.garage_outlined;
    iconMap["Gym"] = Icons.fitness_center_outlined;
    iconMap["Property Size"] = Icons.square_foot_outlined;
    iconMap["Year Built"] = Icons.calendar_today;
    iconMap["Air Conditioning"]= Icons.ac_unit_outlined;
    iconMap["Broadband"] = Icons.router_outlined;
    iconMap["WiFi"] = Icons.router_outlined;
    iconMap["Intercom"] = Icons.phone_in_talk_outlined;
    iconMap["Pay Tv"] = Icons.tv_outlined;
    iconMap["TV Cable"] = Icons.tv_outlined;
    iconMap["Pool"] = Icons.pool_outlined;
    iconMap["Swimming Pool"] = Icons.pool_outlined;
    iconMap["Security System"] = Icons.security_outlined;
    iconMap["Microwave"] = Icons.microwave;
    iconMap["Refrigerator"] = Icons.kitchen;
    iconMap["Washer"] = Icons.local_laundry_service;
    iconMap["Elevator"] = Icons.elevator;
    iconMap["Sliding Doors"] = Icons.door_sliding;
    iconMap["Security"] = Icons.security_outlined;
    iconMap["Fitted Kitchen"] = Icons.kitchen;
    iconMap["Guest Washroom"] = Icons.bathroom;
    iconMap["Laundry"] = Icons.local_laundry_service;
    iconMap["Washing Machine"] = Icons.local_laundry_service;
    iconMap["Bar"] = Icons.local_bar;
    iconMap["Fence"] = Icons.fence;
    iconMap["Heat Extractor"] = Icons.heat_pump;
    iconMap["Stove"] = Icons.date_range;
    iconMap["Lawn"] = Icons.grass;
    iconMap["Automated Gate"] = Icons.door_sliding;
    iconMap["Balcony"] = Icons.balcony;
    iconMap["Parking"] = Icons.garage_rounded;
    iconMap["for-rent"] = Icons.vpn_key_outlined;
    iconMap["for-sale"]= Icons.real_estate_agent_outlined;
    iconMap["commercial"]= Icons.storefront_outlined;
    iconMap["residential"]= Icons.apartment_outlined;
    iconMap["farmhouse"]= Icons.gite;
    iconMap["Window Coverings"]= Icons.roller_shades;
    return iconMap;
  }

  static String cleanContent(String content, {bool decodeComponent = false}) {
    if (content.contains("<p>")) {
      content = content.replaceAll("<p>", "").trim();
    }
    if (content.contains("</p>")) {
      content = content.replaceAll("</p>", "").trim();
    }
    var unescape = HtmlUnescape();
    content = unescape.convert(content).toString();
    if (content.contains("\\<.*?\\>")) {
      content = content.replaceAll("\\<.*?\\>", "").trim();
    }
    content = parseHtmlString(content,decodeComponent: decodeComponent);
    return content;
  }

  static String parseHtmlString(String htmlString,{bool decodeComponent = false}) {
    final document = parse(htmlString);
    String parsedString = parse(document.body!.text).documentElement!.text;
    if(parsedString.contains("%3A")){
      parsedString = parsedString.replaceAll("%3A", ":");
    }
    if(parsedString.contains("%2F")){
      parsedString = parsedString.replaceAll("%2F", "/");
    }
    if(decodeComponent){
      parsedString = Uri.decodeComponent(parsedString);
    }

    return parsedString;
  }

  static String chkRoleValueAndConvertToOption(String roleValue) {
    if (roleValue == ROLE_ADMINISTRATOR) {
      return ROLE_ADMINISTRATOR_CAPITAL;
    } else if (roleValue == USER_ROLE_HOUZEZ_AGENT_VALUE) {
      return USER_ROLE_HOUZEZ_AGENT_OPTION;
    } else if (roleValue == USER_ROLE_HOUZEZ_AGENCY_VALUE) {
      return USER_ROLE_HOUZEZ_AGENCY_OPTION;
    } else if (roleValue == USER_ROLE_HOUZEZ_OWNER_VALUE) {
      return USER_ROLE_HOUZEZ_OWNER_OPTION;
    } else if (roleValue == USER_ROLE_HOUZEZ_BUYER_VALUE) {
      return USER_ROLE_HOUZEZ_BUYER_OPTION;
    } else if (roleValue == USER_ROLE_HOUZEZ_SELLER_VALUE) {
      return USER_ROLE_HOUZEZ_SELLER_OPTION;
    } else if (roleValue == USER_ROLE_HOUZEZ_MANAGER_VALUE) {
      return USER_ROLE_HOUZEZ_MANAGER_OPTION;
    } else {
      return "";
    }
  }

  static String getSearchKey(subType) {
    if (subType == propertyTypeDataType) {
      return SEARCH_RESULTS_TYPE;
    } else if (subType == propertyStatusDataType) {
      return SEARCH_RESULTS_STATUS;
    } else if (subType == propertyFeatureDataType) {
      return SEARCH_RESULTS_FEATURES;
    } else if (subType == propertyLabelDataType) {
      return SEARCH_RESULTS_LABEL;
    } else if (subType == propertyStateDataType) {
      return SEARCH_RESULTS_STATE;
    } else if (subType == propertyAreaDataType) {
      return SEARCH_RESULTS_AREA;
    } else if (subType == propertyCityDataType) {
      return SEARCH_RESULTS_LOCATION;
    }

    return subType;
  }

  static String getSearchItemNameFilterKey(subType) {
    if (subType == propertyTypeDataType) {
      return PROPERTY_TYPE;
    } else if (subType == propertyStatusDataType) {
      return PROPERTY_STATUS;
    } else if (subType == propertyFeatureDataType) {
      return PROPERTY_FEATURES;
    } else if (subType == propertyLabelDataType) {
      return PROPERTY_LABEL;
    } else if (subType == propertyStateDataType) {
      return PROPERTY_STATE;
    } else if (subType == propertyAreaDataType) {
      return PROPERTY_AREA;
    } else if (subType == propertyCityDataType) {
      return CITY;
    } else if (subType == propertyCountryDataType) {
      return PROPERTY_COUNTRY;
    }

    return subType;
  }

  static String getSearchItemSlugFilterKey(subType) {
    if (subType == propertyTypeDataType) {
      return PROPERTY_TYPE_SLUG;
    } else if (subType == propertyStatusDataType) {
      return PROPERTY_STATUS_SLUG;
    } else if (subType == propertyFeatureDataType) {
      return PROPERTY_FEATURES_SLUG;
    } else if (subType == propertyLabelDataType) {
      return PROPERTY_LABEL_SLUG;
    } else if (subType == propertyStateDataType) {
      return PROPERTY_STATE_SLUG;
    } else if (subType == propertyAreaDataType) {
      return PROPERTY_AREA_SLUG;
    } else if (subType == propertyCityDataType) {
      return CITY_SLUG;
    } else if (subType == propertyCountryDataType) {
      return PROPERTY_COUNTRY_SLUG;
    }

    return subType;
  }

  static List getSubTypeItemRelatedList(String subtype, List subTypeValuesList) {
    List subTypeItemRelatedSlugsList = [];
    List subTypeItemRelatedNameList = [];
    List dataList = getPropertyMetaDataList(dataType: subtype) ?? [];
    if(dataList.isNotEmpty){
      for(var item in subTypeValuesList){
        if(item != allString && item != userSelectedString){
          var tempItem = dataList.firstWhereOrNull((element) => element.slug == item);
          if(tempItem != null){
            subTypeItemRelatedSlugsList.add(item);
            subTypeItemRelatedNameList.add(tempItem.name);
          }
        }
      }
    }

    return [subTypeItemRelatedSlugsList, subTypeItemRelatedNameList];
  }

  static Map<String, dynamic> convertMap(Map<dynamic, dynamic> inputMap){
    Map<String, dynamic> convertedMap =  <String, dynamic>{};
    if(inputMap.isNotEmpty){
      for (dynamic type in inputMap.keys) {
        convertedMap[type.toString()] = inputMap[type];
      }
    }
    return convertedMap;
  }

  static MaterialColor getMaterialColor(String hexValue){
    int? colorValue;

    if(hexValue.contains("#")){
      colorValue = int.parse(hexValue.substring(1), radix: 16);
    }

    Map<int, Color> colorCodes = {
      50: Color(colorValue!).withAlpha((255.0 * 0.1).round()),
      100: Color(colorValue).withAlpha((255.0 * 0.2).round()),
      200: Color(colorValue).withAlpha((255.0 * 0.3).round()),
      300: Color(colorValue).withAlpha((255.0 * 0.4).round()),
      400: Color(colorValue).withAlpha((255.0 * 0.5).round()),
      500: Color(colorValue).withAlpha((255.0 * 0.6).round()),
      600: Color(colorValue).withAlpha((255.0 * 0.7).round()),
      700: Color(colorValue).withAlpha((255.0 * 0.8).round()),
      800: Color(colorValue).withAlpha((255.0 * 0.9).round()),
      900: Color(colorValue).withAlpha((255.0 * 1.0).round()),
    };

    MaterialColor materialColor = MaterialColor(colorValue, colorCodes);
    return materialColor;
  }

  static Color getColorFromString(String hexValue){
    int? colorValue;
    if(hexValue.contains("#")){
      colorValue = int.parse(hexValue.substring(1), radix: 16);
    }
    return Color(colorValue!);
  }

  static IconData fromJsonToIconData(String jsonString) {
    Map<String, dynamic> map = jsonDecode(jsonString);
    return IconData(
      map['codePoint'],
      fontFamily: map['fontFamily'],
      fontPackage: map['fontPackage'],
      matchTextDirection: map['matchTextDirection'],
    );
  }

  static String getPlacesApiLockedCountriesFormattedString(String countriesString){
    String formattedString = '';
    if(countriesString != null && countriesString.isNotEmpty){
      if(countriesString.contains(",")){
        List tempList = countriesString.split(",");
        if(tempList.length > 1){
          for(int i = 0; i < (tempList.length); i++){
            if(tempList[i].isNotEmpty){
              formattedString = formattedString + "country:" + tempList[i];
              if((tempList.length) != (i+1)){
                formattedString = formattedString + "|";
              }
            }
          }
        }else{
          if(tempList[0].isNotEmpty){
            formattedString = formattedString + "country:" + tempList[0];
          }
        }
      }else{
        formattedString = formattedString + "country:" + countriesString;
      }
    }

    formattedString = formattedString.replaceAll(" ", "");

    return formattedString;
  }

  static userLogOut({
    required context,
    required WidgetBuilder builder
}){
    Provider.of<UserLoggedProvider>(context,listen: false).loggedOut();
    HiveStorageManager.deleteUserLoginInfoData();
    GeneralNotifier().publishChange(GeneralNotifier.USER_LOGGED_OUT);
    UtilityMethods.navigateToRouteByPushAndRemoveUntil(context: context, builder: builder);
  }

  static bool checkRTLDirectionality(Locale locale) {
    return Bidi.isRtlLanguage(locale.languageCode);
  }

  static saveHomeConfigFile(Map appConfigurationsData) {
    final homeConfig = homeConfigFromJson(json.encode(appConfigurationsData));
    List<dynamic> homeConfigList = homeConfig.homeLayout ?? [];
    if(homeConfigList.isNotEmpty) {
      HiveStorageManager.storeHomeConfigListData(json.encode(homeConfigList));
    }
  }

  static List<dynamic> readHomeConfigFile(){
    List<dynamic> homeConfigList = [];
    String homeConfigData = HiveStorageManager.readHomeConfigListData() ?? "";
    if(homeConfigData.isNotEmpty){
      homeConfigList = jsonDecode(homeConfigData);
    }
    return homeConfigList;
  }

  static saveDrawerConfigFile(Map appConfigurationsData) {
    final drawerConfig = drawerLayoutConfigFromJson(json.encode(appConfigurationsData));
    List<dynamic> drawerConfigList = drawerConfig.drawerLayout!;
    HiveStorageManager.storeDrawerConfigListData(json.encode(drawerConfigList));
  }

  static List<dynamic> readDrawerConfigFile(){
    List<dynamic> drawerConfigList = [];
    String drawerConfigData = HiveStorageManager.readDrawerConfigListData() ?? "";
    if(drawerConfigData.isNotEmpty){
      drawerConfigList = jsonDecode(drawerConfigData);
    }
    return drawerConfigList;
  }

  static saveFilterPageConfigFile(Map appConfigurationsData) {
    // List<dynamic> filterPageConfigElementsList = FilterPageElement.decode(appConfigurationsData[searchPageLayoutConfiguration]);
    List<dynamic> filterPageConfigElementsList = appConfigurationsData[searchPageLayoutConfiguration];
    HiveStorageManager.storeFilterConfigListData(json.encode(filterPageConfigElementsList));
  }

  static savePropertyDetailPageConfigFile(Map appConfigurationsData) {
    final propertyDetailPageConfig = propertyDetailPageLayoutFromJson(json.encode(appConfigurationsData));
    List<dynamic> propertyDetailPageConfigList = propertyDetailPageConfig.propertyDetailPageLayout!;
    HiveStorageManager.storePropertyDetailConfigListData(json.encode(propertyDetailPageConfigList));
  }

  static storeOrUpdateRecentSearches(Map dataMap){
    List recentSearchesList = [];
    recentSearchesList = HiveStorageManager.readRecentSearchesInfo() ?? [];

    /// Save only 10 recent searches
    if(recentSearchesList != null && recentSearchesList.length > 10){
      recentSearchesList.removeLast();
    }

    if (recentSearchesList == null || recentSearchesList.isEmpty) {
      if(dataMap != null){
        recentSearchesList.add(dataMap);
      }
    } else {
      recentSearchesList.insert(0, dataMap);
    }

    HiveStorageManager.storeRecentSearchesInfo(infoList: recentSearchesList);
    GeneralNotifier().publishChange(GeneralNotifier.RECENT_DATA_UPDATE);
  }

  static var drawerItemsList;
  static var widgetItem;
  static var propertyItem;
  static var termItem;
  static var agentItem;
  static var agencyItem;
  static var languageNameAndCode;
  static var defaultLanguageCode;
  static var defaultHomePage;
  static var defaultCountryCode;
  static var settingsOption;
  static var profileItem;
  static var homeRightBarButtonWidget;
  static var markerTitle;
  static var markerIcon;
  static var customMapMarker;
  static var priceFormat;
  static var compactPriceFormatter;
  static var textFormFieldCustomizationHook;
  static var textFormFieldWidgetHook;
  static var customSegmentedControlHook;
  static var drawerHeaderHook;
  static var hidePriceHook;
  static var hideEmptyTerm;

  static void setHooks(Map<String, dynamic> hooksMap) {
    if(hooksMap != null && hooksMap.isNotEmpty) {
      if (hooksMap.containsKey("propertyDetailPageIcons") &&
          hooksMap["propertyDetailPageIcons"] != null &&
          hooksMap["propertyDetailPageIcons"].isNotEmpty) {
        iconMap.addAll(hooksMap["propertyDetailPageIcons"]);
      }

      if (hooksMap.containsKey("elegantHomeTermsIcons") &&
          hooksMap["elegantHomeTermsIcons"] != null &&
          hooksMap["elegantHomeTermsIcons"].isNotEmpty) {
        iconMap.addAll(hooksMap["elegantHomeTermsIcons"]);
      }

      if (hooksMap.containsKey("headers") &&
          hooksMap["headers"] != null &&
          hooksMap["headers"].isNotEmpty) {
        HiveStorageManager.storeSecurityKeyMapData(hooksMap["headers"]);
      }

      if (hooksMap.containsKey("drawerItems") && hooksMap["drawerItems"] != null) {
        drawerItemsList = hooksMap["drawerItems"];
      }

      if (hooksMap.containsKey("widgetItems") && hooksMap["widgetItems"] != null) {
        widgetItem = hooksMap["widgetItems"];
      }

      if (hooksMap.containsKey("propertyItem") && hooksMap["propertyItem"] != null) {
        propertyItem = hooksMap["propertyItem"];
      }

      if (hooksMap.containsKey("termItem") && hooksMap["termItem"] != null) {
        termItem = hooksMap["termItem"];
      }

      if (hooksMap.containsKey("agentItem") && hooksMap["agentItem"] != null) {
        agentItem = hooksMap["agentItem"];
      }

      if (hooksMap.containsKey("agencyItem") && hooksMap["agencyItem"] != null) {
        agencyItem = hooksMap["agencyItem"];
      }

      if (hooksMap.containsKey("languageNameAndCode") && hooksMap["languageNameAndCode"] != null) {
        languageNameAndCode = hooksMap["languageNameAndCode"];
      }

      if (hooksMap.containsKey("defaultLanguageCode") && hooksMap["defaultLanguageCode"] != null) {
        defaultLanguageCode = hooksMap["defaultLanguageCode"];
      }

      if (hooksMap.containsKey("defaultHomePage") && hooksMap["defaultHomePage"] != null) {
        defaultHomePage = hooksMap["defaultHomePage"];
      }

      if (hooksMap.containsKey("defaultCountryCode") && hooksMap["defaultCountryCode"] != null) {
        defaultCountryCode = hooksMap["defaultCountryCode"];
      }

      if (hooksMap.containsKey("settingsOption") && hooksMap["settingsOption"] != null) {
        settingsOption = hooksMap["settingsOption"];
      }

      if (hooksMap.containsKey("profileItem") && hooksMap["profileItem"] != null) {
        profileItem = hooksMap["profileItem"];
      }

      if (hooksMap.containsKey("homeRightBarButtonWidget") && hooksMap["homeRightBarButtonWidget"] != null) {
        homeRightBarButtonWidget = hooksMap["homeRightBarButtonWidget"];
      }

      if (hooksMap.containsKey("markerTitle") && hooksMap["markerTitle"] != null) {
        markerTitle = hooksMap["markerTitle"];
      }

      if (hooksMap.containsKey("markerIcon") && hooksMap["markerIcon"] != null) {
        markerIcon = hooksMap["markerIcon"];
      }
      if (hooksMap.containsKey("customMapMarker") && hooksMap["customMapMarker"] != null) {
        customMapMarker = hooksMap["customMapMarker"];
      }

      if (hooksMap.containsKey("priceFormatter") && hooksMap["priceFormatter"] != null) {
        priceFormat = hooksMap["priceFormatter"];
      }

      if (hooksMap.containsKey("compactPriceFormatter") && hooksMap["compactPriceFormatter"] != null) {
        compactPriceFormatter = hooksMap["compactPriceFormatter"];
      }

      if (hooksMap.containsKey("textFormFieldCustomizationHook") && hooksMap["textFormFieldCustomizationHook"] != null) {
        textFormFieldCustomizationHook = hooksMap["textFormFieldCustomizationHook"];
      }

      if (hooksMap.containsKey("textFormFieldWidgetHook") && hooksMap["textFormFieldWidgetHook"] != null) {
        textFormFieldWidgetHook = hooksMap["textFormFieldWidgetHook"];
      }

      if (hooksMap.containsKey("customSegmentedControlHook") && hooksMap["customSegmentedControlHook"] != null) {
        customSegmentedControlHook = hooksMap["customSegmentedControlHook"];
      }

      if (hooksMap.containsKey("drawerHeaderHook") && hooksMap["drawerHeaderHook"] != null) {
        drawerHeaderHook = hooksMap["drawerHeaderHook"];
      }

      if (hooksMap.containsKey("hidePriceHook") && hooksMap["hidePriceHook"] != null) {
        hidePriceHook = hooksMap["hidePriceHook"];
      }
      if (hooksMap.containsKey("hideEmptyTerm") && hooksMap["hideEmptyTerm"] != null) {
        hideEmptyTerm = hooksMap["hideEmptyTerm"];
      }

    }
  }

  static updateTouchBaseDataAndConfigurations(Map<String, dynamic> touchBaseDataMap){
    String? stringValueHolder;
    /// Store TouchBase Data Map in Hive
    HiveStorageManager.storePropertyMetaData(touchBaseDataMap);
    GeneralNotifier().publishChange(GeneralNotifier.FILTER_DATA_LOADING_COMPLETE);

    enableOrDisableFields(touchBaseDataMap);

    /// Store Houzez Version in Hive
    stringValueHolder = getStringItemValueFromMap(
      inputMap: touchBaseDataMap,
      key: HOUZEZ_VERSION_KEY,
    );
    if(stringValueHolder != null){
      HiveStorageManager.storeHouzezVersion(stringValueHolder);
    }

    /// Update Config in Hive
    if(ENABLE_API_CONFIG) {
      Map? mapValueHolder;
      Map<String, dynamic> newConfigMap = {};

      if(FETCH_DEV_API_CONFIG && touchBaseDataMap.containsKey(DEV_MOBILE_APP_CONFIG_KEY)){
        mapValueHolder = getMapItemValueFromMap(
          inputMap: touchBaseDataMap,
          key: DEV_MOBILE_APP_CONFIG_KEY,
        );
      }else{
        mapValueHolder = getMapItemValueFromMap(
          inputMap: touchBaseDataMap,
          key: MOBILE_APP_CONFIG_KEY,
        );
      }

      if(mapValueHolder != null && mapValueHolder.isNotEmpty){
        newConfigMap = convertMap(mapValueHolder);
      }
      
      if(newConfigMap.isNotEmpty){
        String? oldConfigJson = HiveStorageManager.readAppConfigurations();

        if(oldConfigJson == null || oldConfigJson.isEmpty){
          updateAppConfigurationsInStorage(newConfigMap);
        }else{
          int? oldConfigVersion;
          int? newConfigVersion;
          Map<String, dynamic> oldConfigMap = convertMap(jsonDecode(oldConfigJson));
          // Get Old Config version
          oldConfigVersion = getIntegerItemValueFromMap(
            inputMap: oldConfigMap,
            key: versionApiConfiguration,
          );
          // Get New Config version
          newConfigVersion = getIntegerItemValueFromMap(
            inputMap: newConfigMap,
            key: versionApiConfiguration,
          );
          // check condition for updating App Configurations
          if(oldConfigVersion != null && newConfigVersion != null &&
              oldConfigVersion != newConfigVersion){
            updateAppConfigurationsInStorage(newConfigMap);
          }
        }
      }
    }
  }

  static enableOrDisableFields(Map touchBaseDataMap){
    /// Enable/Disable Register PhoneNumber on SignUp
    if(touchBaseDataMap.containsKey(SIGNUP_REGISTER_MOBILE_KEY) &&
        touchBaseDataMap[SIGNUP_REGISTER_MOBILE_KEY] != null){
      if(touchBaseDataMap[SIGNUP_REGISTER_MOBILE_KEY] == "1"){
        SHOW_SIGNUP_ENTER_PHONE_FIELD = true;
      }else{
        SHOW_SIGNUP_ENTER_PHONE_FIELD = false;
      }
    }

    /// Enable/Disable Register First Name on SignUp
    if(touchBaseDataMap.containsKey(SIGNUP_REGISTER_FIRST_NAME_KEY) &&
        touchBaseDataMap[SIGNUP_REGISTER_FIRST_NAME_KEY] != null){
      if(touchBaseDataMap[SIGNUP_REGISTER_FIRST_NAME_KEY] == "1"){
        SHOW_SIGNUP_ENTER_FIRST_NAME_FIELD = true;
      }else{
        SHOW_SIGNUP_ENTER_FIRST_NAME_FIELD = false;
      }
    }

    /// Enable/Disable Register Last Name on SignUp
    if(touchBaseDataMap.containsKey(SIGNUP_REGISTER_LAST_NAME_KEY) &&
        touchBaseDataMap[SIGNUP_REGISTER_LAST_NAME_KEY] != null){
      if(touchBaseDataMap[SIGNUP_REGISTER_LAST_NAME_KEY] == "1"){
        SHOW_SIGNUP_ENTER_LAST_NAME_FIELD = true;
      }else{
        SHOW_SIGNUP_ENTER_LAST_NAME_FIELD = false;
      }
    }

    /// Enable/Disable Password Field on SignUp
    if(touchBaseDataMap.containsKey(SIGNUP_ENABLE_PASSWORD_KEY) &&
        touchBaseDataMap[SIGNUP_ENABLE_PASSWORD_KEY] != null){
      if(touchBaseDataMap[SIGNUP_ENABLE_PASSWORD_KEY] == "yes"){
        SHOW_SIGNUP_PASSWORD_FIELD = true;
      }else{
        SHOW_SIGNUP_PASSWORD_FIELD = false;
      }
    }
  }

  static updateAppConfigurationsInStorage(Map<String, dynamic> newConfigMap){
    List? listValueHolder;
    int? integerValueHolder;
    bool booleanValueHolder = false;

    // Store New Config File
    HiveStorageManager.storeAppConfigurations(jsonEncode(newConfigMap));
    
    // Get & Store New Config Version
    integerValueHolder = getIntegerItemValueFromMap(
      inputMap: newConfigMap,
      key: versionApiConfiguration,
    );
    if(integerValueHolder != null){
      HiveStorageManager.storeHouziVersion(integerValueHolder);
    }

    listValueHolder = getListItemValueFromMap(
      inputMap: newConfigMap,
      key: homePageLayoutConfiguration,
    );
    if(listValueHolder != null){
      saveHomeConfigFile(newConfigMap);
    }

    listValueHolder = getListItemValueFromMap(
      inputMap: newConfigMap,
      key: drawerMenuLayoutConfiguration,
    );
    if(listValueHolder != null){
      saveDrawerConfigFile(newConfigMap);
    }

    listValueHolder = getListItemValueFromMap(
      inputMap: newConfigMap,
      key: searchPageLayoutConfiguration,
    );
    if(listValueHolder != null){
      saveFilterPageConfigFile(newConfigMap);
    }

    listValueHolder = getListItemValueFromMap(
      inputMap: newConfigMap,
      key: propertyDetailsPageLayoutConfiguration,
    );
    if(listValueHolder != null){
      savePropertyDetailPageConfigFile(newConfigMap);
    }

    integerValueHolder = getIntegerItemValueFromMap(
      inputMap: newConfigMap,
      key: totalSearchTypeOptionsApiConfiguration,
    );
    if(integerValueHolder != null){
      defaultSearchTypeSwitchOptions = integerValueHolder;
    }

    /// Show/Hide Request Demo on Profile
    booleanValueHolder = getBooleanItemValueFromMap(
      inputMap: newConfigMap,
      key: SHOW_REQUEST_DEMO_KEY,
    );
    SHOW_REQUEST_DEMO = booleanValueHolder;

    /// Show/Hide Add Property on Profile
    booleanValueHolder = getBooleanItemValueFromMap(
      inputMap: newConfigMap,
      key: SHOW_ADD_PROPERTY_KEY,
    );
    SHOW_ADD_PROPERTY = booleanValueHolder;

    /// Show/Hide Theme Related Options on Settings
    booleanValueHolder = getBooleanItemValueFromMap(
      inputMap: newConfigMap,
      key: SHOW_THEME_RELTAED_SETTINGS_KEY,
    );
    SHOW_THEME_RELATED_SETTINGS = booleanValueHolder;

    /// Read Default Home Config
    if(newConfigMap.containsKey(defaultHomeApiConfiguration) &&
        newConfigMap[defaultHomeApiConfiguration] != null){
      final DefaultHomePageHook defaultHomePageHook = defaultHomePage;
      String newHome = defaultHomePageHook();
      if(newHome.isEmpty) {
        newHome = newConfigMap[defaultHomeApiConfiguration] ?? "";
      }
      if(newHome.isNotEmpty){
        String? oldHome = HiveStorageManager.readSelectedHomeOption();
        if(oldHome == null || oldHome.isEmpty || oldHome != newHome){
          HiveStorageManager.storeSelectedHomeOption(newHome);
          GeneralNotifier().publishChange(GeneralNotifier.HOME_DESIGN_MODIFIED);
        }
      }
    }

    GeneralNotifier().publishChange(GeneralNotifier.APP_CONFIGURATIONS_UPDATED);
    if (SHOW_ADS) {
      UtilityMethods.initTrackingPermissionAndInitializeMobileAds(({status}) { });
    }
  }



  static List? getPropertyMetaDataList({required String dataType}){
    List dataTypeList = [];
    if(dataType == propertyTypeDataType){
      dataTypeList = HiveStorageManager.readPropertyTypesMetaData() ?? [];
    }else if(dataType == propertyCityDataType){
      dataTypeList = HiveStorageManager.readCitiesMetaData() ?? [];
    }else if(dataType == propertyLabelDataType){
      dataTypeList = HiveStorageManager.readPropertyLabelsMetaData() ?? [];
    }else if(dataType == propertyStatusDataType){
      dataTypeList = HiveStorageManager.readPropertyStatusMetaData() ?? [];
    }else if(dataType == propertyAreaDataType){
      dataTypeList = HiveStorageManager.readPropertyAreaMetaData() ?? [];
    }else if(dataType == propertyFeatureDataType){
      dataTypeList = HiveStorageManager.readPropertyFeaturesMetaData() ?? [];
    }else if(dataType == propertyStateDataType){
      dataTypeList = HiveStorageManager.readPropertyStatesMetaData() ?? [];
    }else if(dataType == propertyCountryDataType){
      dataTypeList = HiveStorageManager.readPropertyCountriesMetaData() ?? [];
    }

    return dataTypeList;
  }

  static storePropertyMetaDataList({
    required String dataType,
    required List<dynamic> metaDataList,
    Map? metaDataMap,
  }){
    if(dataType == propertyTypeDataType){
      HiveStorageManager.storePropertyTypesMetaData(metaDataList);
      if(metaDataMap != null && metaDataMap.isNotEmpty) {
        HiveStorageManager.storePropertyTypesMapData(metaDataMap);
      }
    }else if(dataType == propertyCityDataType){
      HiveStorageManager.storeCitiesMetaData(metaDataList);
    }else if(dataType == propertyLabelDataType){
      HiveStorageManager.storePropertyLabelsMetaData(metaDataList);
    }else if(dataType == propertyStatusDataType){
      HiveStorageManager.storePropertyStatusMetaData(metaDataList);
      if(metaDataMap != null && metaDataMap.isNotEmpty) {
        HiveStorageManager.storePropertyStatusMapData(metaDataMap);
      }
    }else if(dataType == propertyAreaDataType){
      HiveStorageManager.storePropertyAreaMetaData(metaDataList);
    }else if(dataType == propertyFeatureDataType){
      HiveStorageManager.storePropertyFeaturesMetaData(metaDataList);
    }else if(dataType == propertyStateDataType){
      HiveStorageManager.storePropertyStatesMetaData(metaDataList);
    }else if(dataType == propertyCountryDataType){
      HiveStorageManager.storePropertyCountriesMetaData(metaDataList);
    }
  }

  static String getPropertyMetaDataItemNameWithSlug({
    required String dataType,
    required String slug,
  }){
    List dataList = getPropertyMetaDataList(dataType: dataType) ?? [];
    if(dataList.isNotEmpty) {
      Term? item = dataList.firstWhereOrNull((element) => (element is Term && element.slug == slug));

      if (item != null) {
        return item.name ?? "";
      }
    }
    return "";
  }

  static Term? getPropertyMetaDataObjectWithSlug({
    required String dataType,
    required String slug,
  }){

    List? dataList = getPropertyMetaDataList(dataType: dataType);
    if(dataList != null && dataList.isNotEmpty) {
      Term? item = dataList.firstWhereOrNull((element) => (element is Term && element.slug == slug));
      if (item != null) {
        return item;
      }
    }
    return null;
  }

  static Term? getPropertyMetaDataObjectWithId({
    required String dataType,
    required int id,
  }){
    List? dataList = getPropertyMetaDataList(dataType: dataType) ?? [];
    if(dataList != null && dataList.isNotEmpty) {
      Term? item = dataList.firstWhereOrNull((element) => (element is Term && element.id == id));

      if (item != null) {
        return item;
      }
    }
    return null;
  }

  static Term? getPropertyMetaDataObjectWithItemName({
    required String dataType,
    required String name,
  }){
    List dataList = getPropertyMetaDataList(dataType: dataType) ?? [];
    if(dataList != null && dataList.isNotEmpty) {
      Term? item = dataList.firstWhereOrNull((element) => (element is Term && element.name == name));

      if (item != null) {
        return item;
      }
    }
    return null;
  }

  static Map<String, dynamic> getParentAndChildCategorizedMap({required List<dynamic> metaDataList}) {
    List<dynamic> parentCategoryList = [];
    List<dynamic> subCategoryList = [];
    Map<String, dynamic> categorizedDataMap = {};

    /// Get Parent Categories List
    for(var item in metaDataList){
      if (item.parent == 0) {
        parentCategoryList.add(item);
      }
    }

    // print("metaDataList[0].name: ${metaDataList[0].name}");
    //
    // print("Length of metaDataList: ${metaDataList.length}");
    // print("Length of parentCategoryList: ${parentCategoryList.length}");

    /// Get sub Categories List if there is any...
    if (parentCategoryList.length != metaDataList.length) {
      /// Get sub Categories List against each parent
      for(var parentElement in parentCategoryList){
        for(var dataElement in metaDataList){
          if (parentElement.id == dataElement.parent) {
            subCategoryList.add(dataElement);
          }
        }
        categorizedDataMap[parentElement.name] = subCategoryList;
        subCategoryList = [];
      }
    }

    return categorizedDataMap;
  }

  static String getStaticMapUrl({
    required String lat,
    required String lng,
    double? zoomValue = 16,
    double? width = 400,
    double? height = 100,
    String? markerColor = "red",
  }){
    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$lat,$lng&'
        'zoom=${zoomValue!.toInt()}&'
        'size=${width!.toInt()}x${height!.toInt()}&'
        'markers=color:$markerColor%7C$lat,$lng&'
        'key=$GOOGLE_MAP_API_KEY';
  }

  static MaterialPageRoute FilterPageRoute({Map<String, dynamic>? dataMap}){
    MaterialPageRoute filterPageRoute = MaterialPageRoute(
        builder: (context) => FilterPage(
          mapInitializeData: dataMap!,
          filterPageListener: (Map<String, dynamic> dataMap, String closeOption) {
            if (closeOption == DONE) {
              Navigator.pop(context);
            } else if(closeOption == CLOSE){
              Navigator.pop(context);
            }
          },
        ),
    );
    return filterPageRoute;
  }

  static MaterialPageRoute SearchPageRoute({
    Map<String, dynamic>? dataInitMap,
    Map<String, dynamic>? searchRelatedMap,
  }){
    MaterialPageRoute searchPageRoute = MaterialPageRoute(
      builder: (context) => SearchResult(
        dataInitializationMap: dataInitMap,
        searchRelatedData: searchRelatedMap,
        searchPageListener: (Map<String, dynamic> map, String closeOption){
          if(closeOption == CLOSE){
            Navigator.of(context).pop();
          }
        },
      ),
    );
    return searchPageRoute;
  }

  static MaterialPageRoute AboutPageRoute(){
    MaterialPageRoute? pageRoute;
    SHOW_DEMO_CONFIGURATIONS ? pageRoute = MaterialPageRoute(builder: (context) => About()) : 
    pageRoute = MaterialPageRoute(builder: (context) =>
        WebPage(COMPANY_URL, UtilityMethods.getLocalizedString("about")));
    return pageRoute;
  }

  static MaterialPageRoute DarkModeSettingsPageRoute(){
    MaterialPageRoute pageRoute = MaterialPageRoute(builder: (context) => DarkModeSettings());
    return pageRoute;
  }

  static MaterialPageRoute LanguageSettingsPageRoute(){
    MaterialPageRoute pageRoute = MaterialPageRoute(builder: (context) => LanguageSettings());
    return pageRoute;
  }

  static MaterialPageRoute PrivacyPolicyPageRoute(){
    MaterialPageRoute pageRoute = MaterialPageRoute(builder: (context) =>
        WebPage(APP_PRIVACY_URL, UtilityMethods.getLocalizedString("privacy_policy")));
    return pageRoute;
  }

  static MaterialPageRoute TermsAndConditionsPageRoute(){
    MaterialPageRoute pageRoute = MaterialPageRoute(builder: (context) =>
        WebPage(APP_TERMS_URL, UtilityMethods.getLocalizedString("terms_and_conditions")));
    return pageRoute;
  }

  static GenericPageRouter({
    required buildContext,
    required String routeKeyword,
    Map<String, dynamic>? dataMap,
  }) {
    Route? pageRoute;

    if (routeKeyword == FILTER_SCREEN_ROUTE_TAG) {
      Map<String, dynamic>? filterDataMap = {};
      if (dataMap != null &&
          dataMap.containsKey(FILTER_PAGE_SCREEN_DATA_MAP_KEY) &&
          dataMap[FILTER_PAGE_SCREEN_DATA_MAP_KEY] != null) {
        filterDataMap = dataMap[FILTER_PAGE_SCREEN_DATA_MAP_KEY];
      }
      pageRoute = FilterPageRoute(dataMap: filterDataMap);
    } else if (routeKeyword == SEARCH_SCREEN_ROUTE_TAG) {
      Map<String, dynamic>? searchPageDataInitMap = {};
      Map<String, dynamic>? searchPageRelatedDataMap = {};

      // if(dataMap != null){
      //   if(dataMap.containsKey(SEARCH_PAGE_SCREEN_DATA_INIT_MAP_KEY) &&
      //       dataMap[SEARCH_PAGE_SCREEN_DATA_INIT_MAP_KEY] != null){
      //     searchPageDataInitMap = dataMap[SEARCH_PAGE_SCREEN_DATA_INIT_MAP_KEY];
      //   }
      //   if(dataMap.containsKey(SEARCH_PAGE_SCREEN_RELATED_DATA_MAP_KEY) &&
      //       dataMap[SEARCH_PAGE_SCREEN_RELATED_DATA_MAP_KEY] != null){
      //     searchPageRelatedDataMap = dataMap[SEARCH_PAGE_SCREEN_RELATED_DATA_MAP_KEY];
      //   }
      // }
      pageRoute = SearchPageRoute(
        dataInitMap: searchPageDataInitMap,
        searchRelatedMap: searchPageRelatedDataMap,
      );
    } else if (routeKeyword == ABOUT_SCREEN_ROUTE_TAG) {
      pageRoute = AboutPageRoute();
    } else if (routeKeyword == THEME_SETTING_SCREEN_ROUTE_TAG) {
      pageRoute = DarkModeSettingsPageRoute();
    } else if (routeKeyword == LANGUAGE_SETTING_SCREEN_ROUTE_TAG) {
      pageRoute = LanguageSettingsPageRoute();
    } else if (routeKeyword == PRIVACY_POLICY_SCREEN_ROUTE_TAG) {
      pageRoute = PrivacyPolicyPageRoute();
    } else if (routeKeyword == TERMS_AND_CONDITIONS_SCREEN_ROUTE_TAG) {
      pageRoute = TermsAndConditionsPageRoute();
    }

    if (pageRoute != null) {
      Navigator.push(buildContext, pageRoute);
    } else {
      print("GENERIC_METHODS[GenericPageRouter()] => No Page Route found...");
    }
  }
  /// check if the string contains only numbers
  static bool isNumeric(String str) {
    RegExp _numeric = RegExp(r'^-?[0-9]+$');
    return _numeric.hasMatch(str);
  }

  /// check if the string contains only characters
  static bool isText(String str) {
    RegExp text = RegExp(r'^-?[A-Za-z]+$');
    return text.hasMatch(str);
  }

  static Future<bool> locationPermissionsHandling(bool permissionStatus) async {
    bool permissionGranted = permissionStatus;
    if (permissionGranted) {
      return true;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      permissionGranted = true;
    }
    else if (permission == LocationPermission.deniedForever) {
      permissionGranted = false;
    } else {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        permissionGranted = true;
      } else {
        permissionGranted = false;
      }
    }

    return permissionGranted;
  }

  static Future<Map<String, dynamic>> getMapForNearByProperties() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    Map<String, dynamic> dataMap = {
      LATITUDE: position.latitude.toString(),
      LONGITUDE: position.longitude.toString(),
      RADIUS: "20",
      SEARCH_LOCATION: true,
      USE_RADIUS: "on",
    };
    return dataMap;
  }

  static navigateToPropertyDetailPage({
    required BuildContext context,
    int? propertyID,
    Article? article,
    String? heroId,
    String? permaLink,
  }) {
    navigateToRoute(
      context: context,
      builder: (context) => PropertyDetailsPage(
        article: article,
        propertyID: propertyID,
        heroId: heroId,
        permaLink: permaLink,
      ),
    );
  }

  static navigateToLoginPage(BuildContext context, bool fromBottomNavigator) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserSignIn(
          (String closeOption) {
            if (closeOption == CLOSE) {
              Navigator.pop(context);
            }
          },
          fromBottomNavigator: fromBottomNavigator,
        ),
      ),
    );
  }

  static String? getDesignValue(String? design){
    if(design != null && design.isNotEmpty){
      if(design.contains("Design # ")){
        design = design.replaceAll("Design # ", "design_");
      }

      return design;
    }

    return null;
  }

  static bool getBooleanItemValueFromMap({required Map inputMap, required String key, bool defaultValue=false}){
    if(inputMap.containsKey(key) && inputMap[key] is bool){
      return  inputMap[key];
    }

    return defaultValue;
  }

  static String? getStringItemValueFromMap({required Map inputMap, required String key}){
    if(inputMap.containsKey(key) && inputMap[key] != null &&
        inputMap[key] is String && inputMap[key].isNotEmpty){
      return inputMap[key];
    }

    return null;
  }

  static int? getIntegerItemValueFromMap({required Map inputMap, required String key}){
    if(inputMap.containsKey(key) && inputMap[key] != null &&
        inputMap[key] is int){
      return inputMap[key];
    }

    return null;
  }

  static List? getListItemValueFromMap({required Map inputMap, required String key}){
    if(inputMap.containsKey(key) && inputMap[key] != null &&
        inputMap[key] is List && inputMap[key].isNotEmpty){
      return inputMap[key];
    }

    return null;
  }

  static Map? getMapItemValueFromMap({required Map inputMap, required String key}){
    if(inputMap.containsKey(key) && inputMap[key] != null &&
        inputMap[key] is Map && inputMap[key].isNotEmpty){
      return inputMap[key];
    }

    return null;
  }

  static dynamic getItemValueFromMap({required Map inputMap, required String key}){
    if(inputMap.containsKey(key) && inputMap[key] != null){
      return inputMap[key];
    }

    return null;
  }

  static String getStringValueFromDynamicItem({required dynamic item}){
    if(item != null){
      if(item is List && item.isNotEmpty){
        return item[0];
      }else if(item is String){
        return item;
      }
    }

    return "";
  }

  /// Returns true if 'inputItem' is not null and non-empty String.
  static bool isValidString(dynamic inputItem){
    if(inputItem is String && inputItem.isNotEmpty){
      return true;
    }
    return false;
  }

  static getRandomNumber({int? maxRange}){
    return Random().nextInt(maxRange ?? 1000);
  }

  static String getTimeAgoFormat({required String? time, String? locale = 'en'}) {
    if (time != null && time.isNotEmpty) {
      DateTime dt = DateTime.parse(time + "z");
      String lang = HiveStorageManager.readLanguageSelection() ?? "en";
      initializeLocaleForTimeAgo();
      return timeago.format(dt, locale: lang);
    }
    return "";
  }

  static initializeLocaleForTimeAgo() {
    timeago.setLocaleMessages('ar', timeago.ArMessages());
    timeago.setLocaleMessages('az', timeago.AzMessages());
    timeago.setLocaleMessages('ca', timeago.CaMessages());
    timeago.setLocaleMessages('cs', timeago.CsMessages());
    timeago.setLocaleMessages('da', timeago.DaMessages());
    timeago.setLocaleMessages('de', timeago.DeMessages());
    timeago.setLocaleMessages('dv', timeago.DvMessages());
    timeago.setLocaleMessages('en', timeago.EnMessages());
    timeago.setLocaleMessages('es', timeago.EsMessages());
    timeago.setLocaleMessages('et', timeago.EtMessages());
    timeago.setLocaleMessages('fa', timeago.FaMessages());
    timeago.setLocaleMessages('fi', timeago.FiMessages());
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    timeago.setLocaleMessages('gr', timeago.GrMessages());
    timeago.setLocaleMessages('he', timeago.HeMessages());
    timeago.setLocaleMessages('he', timeago.HeMessages());
    timeago.setLocaleMessages('hi', timeago.HiMessages());
    timeago.setLocaleMessages('hu', timeago.HuMessages());
    timeago.setLocaleMessages('id', timeago.IdMessages());
    timeago.setLocaleMessages('it', timeago.ItMessages());
    timeago.setLocaleMessages('ja', timeago.JaMessages());
    timeago.setLocaleMessages('km', timeago.KmMessages());
    timeago.setLocaleMessages('ko', timeago.KoMessages());
    timeago.setLocaleMessages('ku', timeago.KuMessages());
    timeago.setLocaleMessages('mn', timeago.MnMessages());
    timeago.setLocaleMessages('nl', timeago.NlMessages());
    timeago.setLocaleMessages('pl', timeago.PlMessages());
    timeago.setLocaleMessages('ro', timeago.RoMessages());
    timeago.setLocaleMessages('ru', timeago.RuMessages());
    timeago.setLocaleMessages('rw', timeago.RwMessages());
    timeago.setLocaleMessages('sv', timeago.SvMessages());
    timeago.setLocaleMessages('ta', timeago.TaMessages());
    timeago.setLocaleMessages('th', timeago.ThMessages());
    timeago.setLocaleMessages('tr', timeago.TrMessages());
    timeago.setLocaleMessages('uk', timeago.UkMessages());
    timeago.setLocaleMessages('ur', timeago.UrMessages());
    timeago.setLocaleMessages('vi', timeago.ViMessages());
    timeago.setLocaleMessages('zh', timeago.ZhMessages());
  }


}