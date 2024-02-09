import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:houzi_package/files/app_preferences/app_preferences.dart';

import '../generic_text_widget.dart';

Widget genericAddRoomsWidget({
  required String labelText,
  TextStyle? labelTextStyle,
  required void Function() onRemovePressed,
  required void Function() onAddPressed,
  required void Function(String) onChanged,
  void Function(String?)? onSaved,
  required String? Function(String?)? validator,
  required TextEditingController controller,
  EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(20, 20, 20, 0),
  double? givenWidth,
  TextAlign textAlign = TextAlign.start,
  EdgeInsetsGeometry labelTextPadding = const EdgeInsets.only(left: 35.0),
}){
  return Container(
    padding: padding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: labelTextPadding,
          child: GenericTextWidget(
            labelText,
            style: labelTextStyle ?? AppThemePreferences().appTheme.labelTextStyle,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: AppThemePreferences.addPropertyDetailsIconButtonSize,
                icon: Icon(
                  AppThemePreferences.removeCircleOutlinedIcon,
                ),
                onPressed: onRemovePressed,
              ),
              SizedBox(
                width: givenWidth ?? 55,
                height: 50,
                child: TextFormField(
                  textAlign: textAlign,
                  decoration: AppThemePreferences.formFieldDecoration(),
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                  onChanged: onChanged,
                  validator: validator,
                  onSaved: onSaved,
                ),
              ),
              IconButton(
                iconSize: AppThemePreferences.addPropertyDetailsIconButtonSize,
                icon: Icon(
                  AppThemePreferences.addCircleOutlinedIcon,
                ),
                onPressed: onAddPressed,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}