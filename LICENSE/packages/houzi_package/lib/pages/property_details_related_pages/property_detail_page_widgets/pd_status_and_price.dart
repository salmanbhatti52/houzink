import 'package:flutter/material.dart';
import 'package:houzi_package/common/constants.dart';
import 'package:houzi_package/files/app_preferences/app_preferences.dart';
import 'package:houzi_package/files/generic_methods/utility_methods.dart';
import 'package:houzi_package/models/article.dart';
import 'package:houzi_package/widgets/generic_text_widget.dart';

class PropertyDetailPageStatusAndPrice extends StatefulWidget {
  final Article article;

  const PropertyDetailPageStatusAndPrice({
    Key? key,
    required this.article,
  }) : super(key: key);

  @override
  State<PropertyDetailPageStatusAndPrice> createState() => _PropertyDetailPageStatusAndPriceState();
}

class _PropertyDetailPageStatusAndPriceState extends State<PropertyDetailPageStatusAndPrice> {
  String _propertyStatus = "";
  String propertyPrice = "";
  String firstPrice = "";
  String _finalPrice = "";


  @override
  Widget build(BuildContext context) {
    _propertyStatus = widget.article.propertyInfo!.propertyStatus ?? "";
    if(_propertyStatus.isNotEmpty) {
      _propertyStatus = UtilityMethods.getLocalizedString(_propertyStatus);
    }

    if(widget.article.propertyDetailsMap is Map){
      if (widget.article.propertyDetailsMap!.containsKey(PRICE)) {
        propertyPrice = widget.article.propertyDetailsMap![PRICE] ?? "";
      }
      if (widget.article.propertyDetailsMap!.containsKey(FIRST_PRICE)) {
        firstPrice = widget.article.propertyDetailsMap![FIRST_PRICE] ?? "";
      }
    }

    HidePriceHook hidePrice = UtilityMethods.hidePriceHook;
    bool hide = hidePrice();
    if(!hide) {
      _finalPrice = UtilityMethods.priceFormatter(propertyPrice, firstPrice);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if(_propertyStatus.isNotEmpty) Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: GenericTextWidget(
              _propertyStatus,
              strutStyle: StrutStyle(height: AppThemePreferences.genericTextHeight),
              style: AppThemePreferences().appTheme.propertyDetailsPagePropertyStatusTextStyle,
            ),
          ),
          if(_finalPrice.isNotEmpty) Padding(
            padding: const EdgeInsets.only(top: 5),
            child: GenericTextWidget(
              _finalPrice,
              strutStyle: StrutStyle(height: AppThemePreferences.genericTextHeight),
              style: AppThemePreferences().appTheme.propertyDetailsPagePropertyPriceTextStyle,
            ),
          ),
        ],
      ),
    );
  }
}
