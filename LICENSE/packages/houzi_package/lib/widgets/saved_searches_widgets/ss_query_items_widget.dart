import 'package:flutter/material.dart';
import 'package:houzi_package/common/constants.dart';
import 'package:houzi_package/files/app_preferences/app_preferences.dart';
import 'package:houzi_package/files/generic_methods/utility_methods.dart';
import 'package:houzi_package/widgets/generic_text_widget.dart';


class QueryTermsDetailsWidget extends StatelessWidget {
  final Map<String, dynamic> queryDataMap;

  const QueryTermsDetailsWidget({
    Key? key,
    required this.queryDataMap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SavedSearchQueryDataItemRowWidget(
          label: queryDataMap[CITY] != null && queryDataMap[CITY].isNotEmpty
              ? queryDataMap[CITY]
              : "All",
          iconData: AppThemePreferences.locationIcon,
        ),
        if (queryDataMap["query_status"] != null && queryDataMap["query_status"].isNotEmpty)
          Row(
            children: [
              SavedSearchQueryItemDotWidget(),
              SavedSearchQueryDataItemRowWidget(
                label: queryDataMap["query_status"],
                iconData: AppThemePreferences.checkCircleIcon,
              ),
            ],
          ),


        if ((queryDataMap["query_status"] == null || queryDataMap["query_status"].isEmpty) &&
            (queryDataMap["query_type"] != null && queryDataMap["query_type"].isNotEmpty))
          Row(
            children: [
              SavedSearchQueryItemDotWidget(),
              SavedSearchQueryDataItemRowWidget(
                label: queryDataMap["query_type"],
                iconData: AppThemePreferences.locationCityIcon,
              ),
            ],
          ),

        if ((queryDataMap["query_status"] == null || queryDataMap["query_status"].isEmpty) &&
            (queryDataMap["query_type"] == null || queryDataMap["query_type"].isEmpty))
          Row(
            children: [
              SavedSearchQueryItemDotWidget(),
              SavedSearchQueryDataItemRowWidget(
                label: "All",
                iconData: AppThemePreferences.checkCircleIcon,
              ),

              SavedSearchQueryItemDotWidget(),
              SavedSearchQueryDataItemRowWidget(
                label: "All",
                iconData: AppThemePreferences.locationCityIcon,
              ),
            ],
          ),
      ],
    );
  }
}

class QueryFeaturesDetailsWidget extends StatelessWidget {
  final Map<String, dynamic> queryDataMap;

  const QueryFeaturesDetailsWidget({
    Key? key,
    required this.queryDataMap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 0.0,
      runSpacing: 8.0,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SavedSearchQueryDataItemRowWidget(
              label: queryDataMap[BEDROOMS] != null
                  ? queryDataMap[BEDROOMS].last
                  : UtilityMethods.getLocalizedString("any"),
              iconData: AppThemePreferences.bedIcon,
              iconPadding: EdgeInsets.only(left: 2),
            ),
            Row(
              children: [
                SavedSearchQueryItemDotWidget(),
                SavedSearchQueryDataItemRowWidget(
                  label: queryDataMap[BATHROOMS] != null
                      ? queryDataMap[BATHROOMS].last
                      : UtilityMethods.getLocalizedString("any"),
                  iconData: AppThemePreferences.bathtubIcon,
                ),
                SavedSearchQueryItemDotWidget(),
                Row(
                  children: [
                    SavedSearchQueryDataItemRowWidget(
                      label: queryDataMap[PRICE_MAX] != null && queryDataMap[PRICE_MAX].isNotEmpty
                          ? UtilityMethods.makePriceCompact(queryDataMap[PRICE_MAX])
                          : UtilityMethods.getLocalizedString("any"),
                      iconData: AppThemePreferences.priceTagIcon,
                    ),
                    if (queryDataMap[AREA_MAX] != null && queryDataMap[AREA_MAX].isNotEmpty)
                      SavedSearchQueryItemDotWidget(),
                  ],
                ),
              ],
            ),
          ],
        ),
        if (queryDataMap[AREA_MAX] != null && queryDataMap[AREA_MAX].isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SavedSearchQueryDataItemRowWidget(
                label: queryDataMap[AREA_MAX],
                iconData: AppThemePreferences.areaSizeIcon,
                iconPadding: EdgeInsets.only(left: 0.5),
              ),
            ],
          ),
      ],
    );
  }
}

class SavedSearchQueryDataItemRowWidget extends StatelessWidget {
  final String label;
  final IconData iconData;
  final EdgeInsetsGeometry? iconPadding;

  const SavedSearchQueryDataItemRowWidget({
    Key? key,
    required this.label,
    required this.iconData,
    this.iconPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IconWidget(label, iconData, padding: iconPadding),
        LabelWidget(label),
      ],
    );
  }

  IconWidget(String value, IconData icon,{EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding,
      child: Icon(
        icon,
        size: 18,
        color: value == "All" || value == UtilityMethods.getLocalizedString("any")
            ? AppThemePreferences.savedSearchDefaultIconColor
            : null,
      ),
    );
  }

  LabelWidget(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: GenericTextWidget(
        value,
        overflow: TextOverflow.clip,
        softWrap: true,
        style: AppThemePreferences().appTheme.subBody01TextStyle,
      ),
    );
  }

  DotWidget() {
    return Padding(
      padding: const EdgeInsets.only(right: 5.0),
      child: Icon(
        AppThemePreferences.dotIcon,
        size: AppThemePreferences.dotIconSize,
        color: AppThemePreferences.savedSearchDefaultIconColor,
      ),
    );
  }
}

class SavedSearchQueryItemDotWidget extends StatelessWidget {
  const SavedSearchQueryItemDotWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 5.0),
      child: Icon(
        AppThemePreferences.dotIcon,
        size: AppThemePreferences.dotIconSize,
        color: AppThemePreferences.savedSearchDefaultIconColor,
      ),
    );
  }
}
