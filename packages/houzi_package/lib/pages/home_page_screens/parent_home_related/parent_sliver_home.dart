import 'package:flutter/material.dart';
import 'package:houzi_package/files/app_preferences/app_preferences.dart';
import 'package:houzi_package/pages/home_page_screens/parent_home_related/parent_home.dart';
import 'package:houzi_package/pages/home_page_screens/parent_home_related/home_screen_widgets/home_screen_listing_widgets/generic_home_screen_listings.dart';
import 'package:houzi_package/pages/home_page_screens/parent_home_related/home_screen_widgets/home_screen_sliver_app_bar_widgets/home_screen_sliver_app_bar_widget.dart';
import 'package:houzi_package/widgets/custom_widgets/refresh_indicator_widget.dart';

class ParentSliverHome extends ParentHome {
  const ParentSliverHome({Key? key}) : super(key: key);

  @override
  ParentSliverHomeState createState() => ParentSliverHomeState();
}

class ParentSliverHomeState<T extends ParentSliverHome>
    extends ParentHomeState<T> {
  @override
  void initState() {
    super.initState();
    debugPrint(
        "Zainnnnnnnnnnnnnnnnnnnnnnnnnnnnn, I'm here in ParentSliverHomeState");
  }

  Widget getSliverAppBarWidget() {
    return HomeScreenSliverAppBarWidget(
      onLeadingIconPressed: () =>
          super.parentHomeScaffoldKey.currentState!.openEndDrawer(),
      selectedCity: getSelectedCity(),
      selectedStatusIndex: getSelectedStatusIndex(),
      homeScreenSliverAppBarListener: ({filterDataMap}) {
        if (filterDataMap != null && filterDataMap.isNotEmpty) {
          updateData(filterDataMap);
        }
      },
    );
  }

  @override
  Widget getListingsWidget(dynamic item) {
    return HomeScreenListingsWidget(
      homeScreenData: item,
      refresh: super.needToRefresh,
      homeScreenListingsWidgetListener: (bool errorOccur, bool dataRefresh) {
        if (mounted) {
          setState(() {
            errorWhileDataLoading = errorOccur;
            needToRefresh = dataRefresh;
          });
        }
      },
    );
  }

  @override
  Widget getBodyWidget() {
    return RefreshIndicatorWidget(
      color: AppThemePreferences().appTheme.primaryColor,
      edgeOffset: 200.0,
      onRefresh: () async => super.onRefresh(),
      child: Stack(
        children: [
          CustomScrollView(
            slivers: <Widget>[
              /// Home Screen Sliver App Bar Widget
              getSliverAppBarWidget(),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  childCount: 1,
                  (BuildContext context, int index) {
                    // return Column(
                    //   children: [
                    //     ButtonWidget(
                    //       text: "Expire Token",
                    //       onPressed: () async {
                    //         // print("Expiring Token.....................");
                    //         // Map _userLoginInfo = HiveStorageManager.readUserLoginInfoData();
                    //         // // print("_userLoginInfo: $_userLoginInfo");
                    //         // if (_userLoginInfo.isNotEmpty) {
                    //         //   _userLoginInfo["token"] = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL3Byb3B0aXNnaC5jb20iLCJpYXQiOjE2Nzc3NzA3OTgsIm5iZiI6MTY3Nzc3MDc5OCwiZXhwIjoxNjc4Mzc1NTk4LCJkYXRhIjp7InVzZXIiOnsiaWQiOiIzOSJ9fX0.q-0il8idwk0tPD3KH77uyuiJ-fXICX0kTszChnB5Wk8";
                    //         //   HiveStorageManager.storeUserLoginInfoData(_userLoginInfo);
                    //         // }
                    //       },
                    //     ),
                    //     Column(
                    //       crossAxisAlignment: CrossAxisAlignment.start,
                    //       mainAxisSize: MainAxisSize.min,
                    //       children: homeConfigList.map((item) {
                    //         return getListingsWidget(item);
                    //       }).toList(),
                    //     )
                    //   ],
                    // );

                    return Container(
                      color: const Color(0xFFC5EEFD),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 10
                              // Set the border color to blue
                              // Set the border width
                              ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(
                                25.0), // Set the top left border radius
                            topRight: Radius.circular(
                                25.0), // Set the top right border radius
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: homeConfigList.map((item) {
                            return getListingsWidget(item);
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (errorWhileDataLoading) super.getInternetConnectionErrorWidget(),
        ],
      ),
    );
  }
}
