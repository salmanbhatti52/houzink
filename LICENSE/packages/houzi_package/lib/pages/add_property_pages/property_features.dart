import 'package:flutter/material.dart';
import 'package:houzi_package/common/constants.dart';
import 'package:houzi_package/files/app_preferences/app_preferences.dart';
import 'package:houzi_package/files/generic_methods/utility_methods.dart';
import 'package:houzi_package/files/hive_storage_files/hive_storage_manager.dart';
import 'package:houzi_package/widgets/generic_text_widget.dart';
import 'package:houzi_package/widgets/header_widget.dart';

typedef PropertyFeaturesPageListener = void Function(Map<String, dynamic> _dataMap);

class PropertyFeatures extends StatefulWidget{
  final Map<String, dynamic>? propertyInfoMap;
  final PropertyFeaturesPageListener? propertyFeaturesPageListener;

  PropertyFeatures({
    this.propertyInfoMap,
    this.propertyFeaturesPageListener,
  });

  @override
  State<StatefulWidget> createState() => PropertyFeaturesState();
}

class PropertyFeaturesState extends State<PropertyFeatures> {

  List<dynamic> _propertyFeaturesMetaDataList = [];
  List<dynamic> _selectedPropertyFeaturesList = [];

  Map<String, dynamic> dataMap = {};

  @override
  void initState() {
    super.initState();

    Map? tempMap = widget.propertyInfoMap;
    if(tempMap != null){
      if(tempMap.containsKey(ADD_PROPERTY_FEATURES_LIST)){
        _selectedPropertyFeaturesList = tempMap[ADD_PROPERTY_FEATURES_LIST] ?? [];
      }
    }

    _propertyFeaturesMetaDataList = HiveStorageManager.readPropertyFeaturesMetaData() ?? [];
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Card(
        color: AppThemePreferences().appTheme.backgroundColor,
        child: Column(
          children: [
            featuresTextWidget(),
            featuresCheckBoxListWidget(),
          ],
        ),
      ),
    );
  }

  Widget featuresTextWidget() {
    return HeaderWidget(
      text: UtilityMethods.getLocalizedString("features"),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      alignment: Alignment.topLeft,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppThemePreferences().appTheme.dividerColor!),
        ),
      ),
    );
  }

  Widget featuresCheckBoxListWidget(){
    return _propertyFeaturesMetaDataList.isEmpty
        ? Container()
        : Container(
            padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _propertyFeaturesMetaDataList.length,
              itemBuilder: (context, index) {
                var item = _propertyFeaturesMetaDataList;
                return CheckboxListTile(
                  title: GenericTextWidget(
                      UtilityMethods.getLocalizedString(item[index].name)),
                  activeColor: Theme.of(context).primaryColor,
                  value: _selectedPropertyFeaturesList.contains(item[index].id)
                      ? true
                      : false,
                  onChanged: (bool? value) {
                    if (_selectedPropertyFeaturesList.contains(item[index].id)) {
                      if(mounted) setState(() {
                        _selectedPropertyFeaturesList.remove(item[index].id);
                      });
                    } else {
                      if(mounted) setState(() {
                        _selectedPropertyFeaturesList.add(item[index].id);
                      });
                    }
                    if (_selectedPropertyFeaturesList.isNotEmpty) {
                      if(mounted) setState(() {
                        dataMap[ADD_PROPERTY_FEATURES_LIST] =
                            _selectedPropertyFeaturesList;
                      });
                      widget.propertyFeaturesPageListener!(dataMap);
                    }
                  },
                );
              },
            ),
          );
  }
}