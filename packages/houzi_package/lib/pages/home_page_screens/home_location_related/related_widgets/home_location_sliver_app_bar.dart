import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:houzi_package/files/app_preferences/app_preferences.dart';
import 'package:houzi_package/files/generic_methods/utility_methods.dart';
import 'package:houzi_package/files/hooks_files/hooks_configurations.dart';
import 'package:houzi_package/pages/home_page_screens/home_location_related/related_widgets/home_location_search_bar.dart';
import 'package:houzi_package/pages/home_page_screens/home_location_related/related_widgets/home_location_search_type_widget.dart';
import 'package:houzi_package/pages/home_page_screens/home_location_related/related_widgets/home_location_top_bar.dart';

import '../../../../common/constants.dart';
import '../../../../files/hive_storage_files/hive_storage_manager.dart';
import '../../../../widgets/generic_text_widget.dart';
import '../../../home_screen_drawer_menu_pages/favorites.dart';
import '../../../home_screen_drawer_menu_pages/user_related/user_signin.dart';

class HomeLocationSliverAppBarWidget extends StatefulWidget {
  final int selectedStatusIndex;
  final Function() onLeadingIconPressed;

  const HomeLocationSliverAppBarWidget({
    Key? key,
    required this.selectedStatusIndex,
    required this.onLeadingIconPressed,
  }) : super(key: key);

  @override
  State<HomeLocationSliverAppBarWidget> createState() =>
      _HomeLocationSliverAppBarWidgetState();
}

class _HomeLocationSliverAppBarWidgetState
    extends State<HomeLocationSliverAppBarWidget> {
  bool isCollapsed = false;
  bool isStretched = true;
  bool increasePadding = true;
  bool reducePadding = false;
  double extendedHeight = 80.0;
  double padding = 10.0;
  double currentHeight = 0.0;
  double previousHeight = 0.0;

  AddPlusButtonInBottomBarHook addPlusButtonHook =
      HooksConfigurations.addPlusButtonInBottomBarHook;
  HomeSliverAppBarBodyHook? homeSliverAppBarBodyHook =
      HooksConfigurations.homeSliverAppBarBodyHook;
  Map<String, dynamic>? sliverBodyMap;
  Widget? sliverBodyWidget;

  @override
  void initState() {
    if (homeSliverAppBarBodyHook != null) {
      sliverBodyMap = homeSliverAppBarBodyHook!(context);
    }

    if (sliverBodyMap != null && sliverBodyMap!.isNotEmpty) {
      // set extended height of Sliver App Bar
      if (sliverBodyMap!.containsKey("height") &&
          sliverBodyMap!["height"] is double) {
        extendedHeight = extendedHeight + sliverBodyMap!["height"];
      }
      // get the body widget of Sliver App Bar
      if (sliverBodyMap!.containsKey("widget") &&
          sliverBodyMap!["widget"] is Widget?) {
        sliverBodyWidget = sliverBodyMap!["widget"];
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: const Color(0xFFC5EEFD),
          statusBarIconBrightness:
              AppThemePreferences().appTheme.statusBarIconBrightness,
          statusBarBrightness:
              AppThemePreferences().appTheme.statusBarBrightness),
      backgroundColor: const Color(0xFFC5EEFD),
      pinned: true,
      leadingWidth: 140,
      expandedHeight: 50,
      leading: Padding(
        padding: const EdgeInsets.only(left: 15),
        child: Image.asset(
          AppThemePreferences.logoIconImagePath,
        ),
      ),
      actions: [
        Row(
          children: [
            defaultAddButton() ?? Container(),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Favorites(
                      showAppBar: true,
                      favoritesPageListener: (String closeOption) {
                        if (closeOption == CLOSE) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                );
              },
              child:
                  SvgPicture.asset(AppThemePreferences.drawerFavoriteImagePath),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Tooltip(
                message: MaterialLocalizations.of(context).openAppDrawerTooltip,
                child: GestureDetector(
                  onTap: () {
                    widget.onLeadingIconPressed();
                  },
                  child:
                      SvgPicture.asset(AppThemePreferences.drawerMenuImagePath),
                ),
              ),
            ),
          ],
        ),
      ],

      //TODO: HOME LOCATION SEARCH BAR WIDGET

      // flexibleSpace: LayoutBuilder(
      //     builder: (BuildContext context, BoxConstraints constraints) {
      //       isCollapsed = constraints.biggest.height ==  MediaQuery.of(context).padding.top + kToolbarHeight ? true : false;
      //       isStretched = constraints.biggest.height ==  MediaQuery.of(context).padding.top + extendedHeight ? true : false;
      //       currentHeight = constraints.maxHeight;
      //       if(previousHeight < currentHeight){
      //         increasePadding = false;
      //         reducePadding = true;
      //         previousHeight = currentHeight;
      //       }
      //       if(previousHeight > currentHeight){
      //         increasePadding = true;
      //         reducePadding = false;
      //         previousHeight = currentHeight;
      //       }
      //       if(isCollapsed){
      //         padding = 60;
      //         increasePadding = false;
      //         reducePadding = true;
      //       }
      //       if(isStretched){
      //         padding = 10;
      //         increasePadding = true;
      //         reducePadding = false;
      //       }
      //
      //       if(increasePadding){
      //         double temp = padding + (constraints.maxHeight) / 100;
      //         if(temp <= 60){
      //           padding = temp;
      //         }else{
      //           temp = temp - (temp - 60);
      //           padding = temp;
      //         }
      //       }
      //       if(reducePadding){
      //         double temp = padding - (constraints.maxHeight) / 100;
      //         if(temp >= 10){
      //           padding = temp;
      //         }else{
      //           temp = temp + (10 - temp);
      //           padding = temp;
      //         }
      //       }
      //
      //       return FlexibleSpaceBar(
      //         centerTitle: false,
      //         titlePadding: EdgeInsets.only(left: UtilityMethods.isRTL(context) ? 10 : padding, bottom: 10, right: UtilityMethods.isRTL(context) ? padding : 10),
      //         title: const HomeLocationSearchBarWidget(),
      //         // TODO : HOME TAB BAR RENT OR SALE WIDGET
      //         // background: Column(
      //         //   children: [
      //         //     HomeLocationTopBarWidget(),
      //         //     HomeLocationSearchTypeWidget(
      //         //       homeLocationSearchTypeWidgetListener: (String selectedItem, String selectedItemSlug){
      //         //         // Do something here
      //         //       }
      //         //     ),
      //         //     if (sliverBodyWidget != null) sliverBodyWidget!,
      //         //   ],
      //         // ),
      //       );
      //     }),
      elevation: 0,
    );
  }

  Widget? defaultAddButton() {
    //First we'll check if showing add button is allowed, then we'll check if the bottom tab bar design
    //is not design 2. then we'll check if hook is returning some widget.
    if (SHOW_BOTTOM_NAV_BAR_ADD_BTN &&
        BOTTOM_NAVIGATION_BAR_DESIGN != DESIGN_02) {
      Widget? widgetFromHook = addPlusButtonHook(context);
      return widgetFromHook ??
          Container(
            width: 108,
            height: 30,
            decoration: BoxDecoration(
              color: AppThemePreferences().appTheme.backgroundColor,
              borderRadius: BorderRadius.circular(100),
            ),
            child: GestureDetector(
              onTap: () {
                UtilityMethods.navigateToRoute(
                  context: context,
                  builder: (context) => HiveStorageManager.isUserLoggedIn()
                      ? UtilityMethods.navigateToAddPropertyPage(
                          navigateToQuickAdd: true)
                      : UserSignIn(
                          (String closeOption) {
                            if (closeOption == CLOSE) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                      AppThemePreferences.addPropertyButtonImagePath),
                  const SizedBox(width: 5),
                  GenericTextWidget(
                    UtilityMethods.getLocalizedString('Add Property'),
                    strutStyle: const StrutStyle(forceStrutHeight: true),
                    style: TextStyle(
                      fontSize: AppThemePreferences.tagFontSize,
                      color: AppThemePreferences().appTheme.primaryColor,
                      fontWeight: AppThemePreferences.tagFontWeight,
                    ),
                    // style: AppThemePreferences().appTheme.tagTextStyle,
                  ),
                ],
              ),
            ),
          );
    }
    return null;
  }
}
