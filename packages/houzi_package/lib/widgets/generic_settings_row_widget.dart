import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:houzi_package/files/app_preferences/app_preferences.dart';
import 'package:houzi_package/widgets/generic_text_widget.dart';

class NewGenericWidgetRow extends StatelessWidget {
  final String icon;
  final String text;
  final String icon2;
  final void Function() onTap;
  final bool? removeDecoration;
  final EdgeInsetsGeometry? padding;

  const NewGenericWidgetRow({
    Key? key,
    required this.icon,
    required this.text,
    required this.icon2,
    required this.onTap,
    this.padding = const EdgeInsets.only(top: 15.0, bottom: 15.0, left: 10.0, right: 10.0),
    this.removeDecoration = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: (removeDecoration ?? false) ? null : null,
      child: GestureDetector(
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            padding: padding,
            child: Row(
              children: [
                SvgPicture.asset(icon),
                Padding(
                  padding: const EdgeInsets.only(left: 20,right: 20),
                  child: GenericTextWidget(
                    text,
                    style: AppThemePreferences().appTheme.settingOptionsTextStyle,
                  ),
                ),
                const Spacer(),
                SvgPicture.asset(icon2),
              ],
            ),
          ),
        ),
        onTap: onTap,
      ),

    );
  }
}

class GenericWidgetRow extends StatelessWidget {
  final IconData iconData;
  final String text;
  final void Function() onTap;
  final bool? removeDecoration;
  final EdgeInsetsGeometry? padding;

  const GenericWidgetRow({
    Key? key,
    required this.iconData,
    required this.text,
    required this.onTap,
    this.padding = const EdgeInsets.only(top: 20.0, bottom: 10.0),
    this.removeDecoration = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: (removeDecoration ?? false) ? null : AppThemePreferences.dividerDecoration(),
      child: InkWell(
        child: Container(
          padding: padding,
          child: Row(
            children: [
              Icon(
                iconData,
                color: AppThemePreferences().appTheme.iconsColor,
                size: AppThemePreferences.settingsIconSize,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20,right: 20),
                child: GenericTextWidget(
                  text,
                  style: AppThemePreferences().appTheme.settingOptionsTextStyle,
                ),
              ),
            ],
          ),
        ),
        onTap: onTap,
      ),

    );
  }
}

class GenericSettingsWidget extends StatelessWidget {
  final String headingText;
  final String? headingSubTitleText;
  final Widget body;
  final bool removeDecoration;
  final bool enableTopDecoration;
  final bool enableBottomDecoration;

  const GenericSettingsWidget({
    Key? key,
    required this.headingText,
    required this.body,
    this.headingSubTitleText,
    this.removeDecoration = false,
    this.enableTopDecoration = false,
    this.enableBottomDecoration = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: removeDecoration ? null : AppThemePreferences.dividerDecoration(
        bottom: enableBottomDecoration,
        top: enableTopDecoration,
      ),
      // decoration: AppThemePreferences.dividerDecoration(top: enableTopDecoration),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeadingWidget(text: headingText),
          if(headingSubTitleText != null && headingSubTitleText!.isNotEmpty )
            HeadingSubTitleWidget(text: headingSubTitleText!),
          body,
        ],
      ),
    );
  }
}

class HeadingWidget extends StatelessWidget {
  final String text;
  
  const HeadingWidget({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GenericTextWidget(
      text,
      style: AppThemePreferences().appTheme.settingHeadingTextStyle,
      strutStyle: StrutStyle(height: AppThemePreferences.genericTextHeight),
    );
  }
}

class HeadingSubTitleWidget extends StatelessWidget {
  final String text;
  
  const HeadingSubTitleWidget({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 3),
      child: GenericTextWidget(
        text,
        style: AppThemePreferences().appTheme.settingHeadingSubTitleTextStyle,
        strutStyle: StrutStyle(height: AppThemePreferences.genericTextHeight),
      ),
    );
  }
}