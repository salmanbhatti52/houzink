import 'package:flutter/material.dart';
import 'package:houzi_package/common/constants.dart';
import 'package:houzi_package/files/app_preferences/app_preferences.dart';
import 'package:houzi_package/files/hive_storage_files/hive_storage_manager.dart';
import 'package:houzi_package/models/dynamic_item.dart';
import 'package:houzi_package/widgets/add_property_widgets/multi_units_property_picker.dart';
import 'package:houzi_package/widgets/add_property_widgets/multi_units_widget.dart';
import 'package:houzi_package/widgets/generic_text_field_widgets/text_field_widget.dart';
import 'package:houzi_package/widgets/header_widget.dart';
import 'package:houzi_package/widgets/light_button_widget.dart';

import 'package:houzi_package/files/generic_methods/utility_methods.dart';

typedef PropertySubListingPageListener = void Function(
  List<Map<String, dynamic>> multiUnitsList,
  String ListingIDs,
);

class PropertySubListingPage extends StatefulWidget{

  final GlobalKey<FormState>? formKey;
  final Map<String, dynamic>? propertyInfoMap;
  final PropertySubListingPageListener? propertySubListingPageListener;

  const PropertySubListingPage({
    Key? key,
    this.formKey,
    this.propertyInfoMap,
    this.propertySubListingPageListener,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => PropertySubListingPageState();

}

class PropertySubListingPageState extends State<PropertySubListingPage> {

  String userRole = "";
  String selectedListingsIDs = "";
  final List<DynamicItem> _multiUnitsList = [];
  final _listingIDsTextController = TextEditingController();


  @override
  void initState() {
    super.initState();

    userRole = HiveStorageManager.getUserRole();

    if(userRole == ROLE_ADMINISTRATOR){
      String houzez_version = HiveStorageManager.readHouzezVersion() ?? "";
      if(houzez_version.isNotEmpty){
        // Remove '.' from version (2.6.1 => 261)
        if(houzez_version.contains(".")){
          houzez_version = houzez_version.replaceAll(".", "");
        }

        int temp_houzez_version = int.tryParse(houzez_version) ?? -1;
        if(temp_houzez_version != -1 && temp_houzez_version >= 260){
          if(mounted){
            setState(() {
              SHOW_MULTI_UNITS_ID_FIELD = true;
            });
          }
        }
      }
    }

    if(widget.propertyInfoMap != null && widget.propertyInfoMap!.isNotEmpty){

      if(widget.propertyInfoMap!.containsKey(ADD_PROPERTY_FAVE_MULTI_UNITS_IDS) &&
          widget.propertyInfoMap![ADD_PROPERTY_FAVE_MULTI_UNITS_IDS] != null &&
          widget.propertyInfoMap![ADD_PROPERTY_FAVE_MULTI_UNITS_IDS].isNotEmpty){
        _listingIDsTextController.text = widget.propertyInfoMap![ADD_PROPERTY_FAVE_MULTI_UNITS_IDS];
        selectedListingsIDs = widget.propertyInfoMap![ADD_PROPERTY_FAVE_MULTI_UNITS_IDS];
      }

      if(widget.propertyInfoMap!.containsKey(ADD_PROPERTY_FAVE_MULTI_UNITS) &&
          widget.propertyInfoMap![ADD_PROPERTY_FAVE_MULTI_UNITS] != null &&
          widget.propertyInfoMap![ADD_PROPERTY_FAVE_MULTI_UNITS] is List &&
          widget.propertyInfoMap![ADD_PROPERTY_FAVE_MULTI_UNITS].isNotEmpty){
        List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(widget.propertyInfoMap![ADD_PROPERTY_FAVE_MULTI_UNITS]);
        if(list.isNotEmpty){
          for(int i = 0; i < list.length; i++){
            var item = list[i];
            _multiUnitsList.add(
              DynamicItem(
                key: "Key$i",
                dataMap: item,
              ),
            );
          }
        }else{
          initializeData();
        }
      }
    }else{
      initializeData();
    }
  }

  initializeData(){
    if(mounted) {
      setState(() {
        _multiUnitsList.add(DynamicItem(
          key: "Key0",
          dataMap: {
            faveMUTitle: "",
            faveMUPrice: "",
            faveMUPricePostfix: "",
            faveMUBeds: "",
            faveMUBaths: "",
            faveMUSize: "",
            faveMUSizePostfix: "",
            faveMUType: "",
            faveMUAvailabilityDate: "",
          },
        ));
      });
    }
  }

  @override
  void dispose() {
    _listingIDsTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Form(
          key: widget.formKey,
          child: Column(
            children: [
              subListingsTextWidget(),
              addListingIDsWidget(),
              _multiUnitsList.isNotEmpty
                  ? Column(
                      children: _multiUnitsList.map((floorPlanElement) {
                        int itemIndex = _multiUnitsList.indexOf(floorPlanElement);
                        return GenericMultiUnitsWidget(
                          index: itemIndex,
                          dataMap: floorPlanElement.dataMap!,
                          genericMultiUnitsWidgetListener: (int index, Map<String, dynamic> itemDataMap, bool removeItem) {
                            if (removeItem) {
                              if (mounted) {
                                setState(() {
                                  _multiUnitsList.removeAt(index);
                                });
                              }
                            } else {
                              if (mounted) {
                                setState(() {
                                  _multiUnitsList[index].dataMap = itemDataMap;
                                });
                              }
                            }

                            updateDataMap();
                          },
                        );
                      }).toList(),
                    )
                  : Container(),
              addNewElevatedButton(),
            ],
          ),
        ),
      ),
    );
  }

  updateDataMap(){
    List<Map<String, dynamic>> list = [];
    for(var item in _multiUnitsList){
      list.add(item.dataMap!);
    }

    widget.propertySubListingPageListener!(list, selectedListingsIDs);
  }

  Widget subListingsTextWidget() {
    return HeaderWidget(
      text: UtilityMethods.getLocalizedString("sub_listings"),//AppLocalizations.of(context).sub_listings,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      alignment: Alignment.topLeft,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppThemePreferences().appTheme.dividerColor!),
        ),
      ),
    );
  }

  Widget addNewElevatedButton(){
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: lightButtonWidget(
          text: UtilityMethods.getLocalizedString("add_new"),//AppLocalizations.of(context).add_new,
          fontSize: AppThemePreferences.buttonFontSize,
          onPressed: (){
            if(mounted) {
              setState(() {
                _multiUnitsList.add(DynamicItem(
                  key: _multiUnitsList.isNotEmpty
                      ? "Key${_multiUnitsList.length}"
                      : "Key0",
                  dataMap: {
                    faveMUTitle: "",
                    faveMUPrice: "",
                    faveMUPricePostfix: "",
                    faveMUBeds: "",
                    faveMUBaths: "",
                    faveMUSize: "",
                    faveMUSizePostfix: "",
                    faveMUType: "",
                    faveMUAvailabilityDate: "",
                  },
                ));
              });
            }
          }
      ),
    );
  }

  Widget addListingIDsWidget(){
    return !SHOW_MULTI_UNITS_ID_FIELD
        ? Container()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(top: 20.0),
                child: TextFormFieldWidget(
                  textFieldPadding: const EdgeInsets.only(bottom: 10),
                  labelText: UtilityMethods.getLocalizedString("Listing IDs"),
                  hintText:
                      UtilityMethods.getLocalizedString("Listing IDs Hint"),
                  additionalHintText: UtilityMethods.getLocalizedString(
                      "Listing IDs Additional Hint"),
                  keyboardType: TextInputType.text,
                  controller: _listingIDsTextController,
                  onChanged: (listingIDs) {
                    if (listingIDs != null) {
                      if (mounted)
                        setState(() {
                          selectedListingsIDs = listingIDs;
                          if (selectedListingsIDs.contains(" ")) {
                            selectedListingsIDs =
                                selectedListingsIDs.replaceAll(" ", "");
                          }
                        });
                      updateDataMap();
                    }
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20.0),
                child: lightButtonWidget(
                    text:
                        UtilityMethods.getLocalizedString("Select Properties"),
                    fontSize: AppThemePreferences.buttonFontSize,
                    onPressed: () {
                      FocusScope.of(context).requestFocus(FocusNode());
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return PropertyPickerMultiSelectDialogWidget(
                            title: UtilityMethods.getLocalizedString("select"),
                            selectedItems: selectedListingsIDs,
                            propertyPickerMultiSelectDialogWidgetListener:
                                (List<String> _selectedItemsList) {
                              if (_selectedItemsList.isNotEmpty) {
                                String tempSelectedListingsIDs = "";
                                for (var item in _selectedItemsList) {
                                  if (tempSelectedListingsIDs.isEmpty) {
                                    tempSelectedListingsIDs = item;
                                  } else {
                                    tempSelectedListingsIDs =
                                        tempSelectedListingsIDs + "," + item;
                                  }
                                }
                                if (tempSelectedListingsIDs.isNotEmpty) {
                                  setState(() {
                                    selectedListingsIDs =
                                        tempSelectedListingsIDs.replaceAll(
                                            " ", "");
                                    _listingIDsTextController.text =
                                        selectedListingsIDs;
                                  });
                                  updateDataMap();
                                }
                              }
                            },
                          );
                        },
                      );
                    }),
              ),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 20),
                      decoration:
                          AppThemePreferences.dividerDecoration(bottom: true),
                      child: Center(child: LabelWidget("OR")),
                    ),
                  ),
                ],
              ),
            ],
          );
  }
}