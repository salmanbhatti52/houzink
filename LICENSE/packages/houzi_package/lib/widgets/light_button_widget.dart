import 'package:flutter/material.dart';
import 'package:houzi_package/files/app_preferences/app_preferences.dart';

import 'generic_text_widget.dart';

Widget lightButtonWidget({
  String text = "",
  Color? textColor,
  Icon? icon,
  Color? color,
  required Function() onPressed,
  double fontSize = 14,
  double buttonHeight = 50.0,
  double buttonWidth = double.infinity,
  bool iconOnRightSide = false,
  bool centeredContent = false,
  ButtonStyle? buttonStyle,
}){
  return SizedBox(
    height: buttonHeight,
    width: buttonWidth,
    child: ElevatedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconOnRightSide ? Container() : Container(margin: EdgeInsets.only(left: 5),child: showIcon(icon),),
          centeredContent ? content(icon, text, fontSize, iconOnRightSide, textColor) :
          Expanded(child: content(icon, text, fontSize, iconOnRightSide, textColor)),
          iconOnRightSide ? showIcon(icon) : Container(),
        ],
      ),

      style: buttonStyle ?? ElevatedButton.styleFrom(
        elevation: 0.0, backgroundColor: color ?? AppThemePreferences().appTheme.selectedItemBackgroundColor,
        // primary: color != null ? color : AppThemePreferences().current.primaryColor,
      ),
    ),
  );
}

Widget showIcon(Icon? icon){
  if(icon == null){
    return Container();
  }
  return icon;
}

Widget content(Icon? icon, String text, double fontSize, bool rightIcon, Color? textColor){
  return Padding(
    padding: icon == null ? const EdgeInsets.only(left: 0.0) : rightIcon ? const EdgeInsets.only(right: 10.0) :
    const EdgeInsets.only(left: 10.0),
    child: GenericTextWidget(
      text,
      textAlign: TextAlign.center,
      style:
      TextStyle(
        color: textColor ?? AppThemePreferences().appTheme.selectedItemTextColor,
        fontSize: fontSize,
      ),
    ),
  );
}