import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:houzi_package/common/constants.dart';
import 'package:houzi_package/files/app_preferences/app_preferences.dart';
import 'package:houzi_package/widgets/generic_text_field_widgets/text_field_widget.dart';

// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../files/generic_methods/utility_methods.dart';

typedef GenericAdditionalDetailsWidgetListener = void Function(
    int index, Map<String, dynamic> dataMap, bool remove);

class GenericAdditionalDetailsWidget extends StatefulWidget{

  final int index;
  final Map<String, dynamic> dataMap;
  final GenericAdditionalDetailsWidgetListener genericAdditionalDetailsWidgetListener;

  const GenericAdditionalDetailsWidget({
    Key? key,
    required this.index,
    required this.dataMap,
    required this.genericAdditionalDetailsWidgetListener,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => GenericAdditionalDetailsWidgetState();

}

class GenericAdditionalDetailsWidgetState extends State<GenericAdditionalDetailsWidget> {

  Map<String, dynamic> tempDataMap = {};

  final _additionalDetailsTitleTextController = TextEditingController();
  final _additionalDetailsValueTextController = TextEditingController();

  @override
  void dispose() {
    if(_additionalDetailsTitleTextController != null )_additionalDetailsTitleTextController.dispose();
    if(_additionalDetailsValueTextController != null )_additionalDetailsValueTextController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    if (widget.dataMap != null && !(mapEquals(widget.dataMap, tempDataMap))) {
      _additionalDetailsTitleTextController.text = widget.dataMap[faveAdditionalFeatureTitle];
      _additionalDetailsValueTextController.text = widget.dataMap[faveAdditionalFeatureValue];
      tempDataMap = widget.dataMap;
    }

    return addAdditionalFeatureInformation();
  }

  Widget addAdditionalFeatureInformation(){
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 5, child: addAdditionalFeatureTitle()),
          Expanded(flex: 5, child: addAdditionalFeatureValue()),
        ],
      ),
    );
  }

  Widget addAdditionalFeatureTitle(){
    return TextFormFieldWidget(
      padding: const EdgeInsets.fromLTRB(20, 20, 10, 0),
      labelText: UtilityMethods.getLocalizedString("title"),
      hintText: UtilityMethods.getLocalizedString("additional_feature_title_hint"),
      controller: _additionalDetailsTitleTextController,
      onChanged: (title){
        widget.dataMap[faveAdditionalFeatureTitle]  = title;
        updateDataMap();
      },
    );
  }

  Widget addAdditionalFeatureValue(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 0.0, 5.0, 0.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LabelWidget(UtilityMethods.getLocalizedString("value")),
              IconButton(
                onPressed: (){
                  widget.genericAdditionalDetailsWidgetListener(widget.index, widget.dataMap, true);
                  if(mounted) {
                    setState(() {});
                  }
                },
                padding: const EdgeInsets.all(0.0),
                icon: Icon(
                  Icons.cancel_outlined,
                  color: AppThemePreferences.errorColor,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.all(0.0),
          child: TextFormFieldWidget(
            textFieldPadding: const EdgeInsets.all(0.0),
            controller: _additionalDetailsValueTextController,
            hintText: UtilityMethods.getLocalizedString("additional_feature_value_hint"),
            onChanged: (value){
              widget.dataMap[faveAdditionalFeatureValue]  = value;
              updateDataMap();
            },
          ),
        ),
      ],
    );
  }

  updateDataMap(){
    widget.genericAdditionalDetailsWidgetListener(
        widget.index, widget.dataMap, false);
  }
}