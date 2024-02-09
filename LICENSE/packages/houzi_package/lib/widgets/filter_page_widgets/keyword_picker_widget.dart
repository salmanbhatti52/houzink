import 'package:flutter/material.dart';
import 'package:houzi_package/files/app_preferences/app_preferences.dart';
import 'package:houzi_package/widgets/generic_text_widget.dart';

import 'package:houzi_package/files/generic_methods/utility_methods.dart';

typedef  KeywordPickerWidgetListener = void Function(String keywordString);

class KeywordPickerWidget extends StatefulWidget{
  final String pickerTitle;
  final String pickerType;
  final Icon pickerIcon;
  final TextEditingController textEditingController;
  final KeywordPickerWidgetListener keywordPickerWidgetListener;

  const KeywordPickerWidget({
    Key? key,
    required this.pickerTitle,
    required this.pickerType,
    required this.pickerIcon,
    required this.textEditingController,
    required this.keywordPickerWidgetListener,
  }): super(key: key);

  @override
  State<StatefulWidget> createState() => _KeywordPickerWidgetState();

}

class _KeywordPickerWidgetState extends State<KeywordPickerWidget> {

  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(width: 1.0, color: AppThemePreferences().appTheme.dividerColor!),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0.0),
        child: Wrap(
          children:[
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: widget.pickerIcon,
                    ),
                    Expanded(
                      flex: 8,
                      child: GenericTextWidget(
                        widget.pickerTitle,
                        style: AppThemePreferences().appTheme.filterPageHeadingTitleTextStyle,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                  child: textFormFieldWidget(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget textFormFieldWidget(){
    return Container(
      margin: const EdgeInsets.only(top: 5.0),
      child: TextFormField(
        enabled: true,
        readOnly: false,
        controller: widget.textEditingController,
        decoration: AppThemePreferences.formFieldDecoration(hintText: UtilityMethods.getLocalizedString("please_enter_keyword")),
        onChanged: (keywordString){
          widget.keywordPickerWidgetListener(keywordString);
        },
      ),
    );
  }
}