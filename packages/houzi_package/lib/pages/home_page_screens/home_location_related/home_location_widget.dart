import 'package:flutter/material.dart';
import 'package:houzi_package/pages/home_page_screens/home_location_related/related_widgets/home_location_sliver_app_bar.dart';
import 'package:houzi_package/pages/home_page_screens/parent_home_related/parent_sliver_home.dart';

class HomeLocation extends ParentSliverHome {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const HomeLocation({Key? key, this.scaffoldKey}) : super(key: key);

  @override
  _HomeLocationState createState() => _HomeLocationState();
}

class _HomeLocationState extends ParentSliverHomeState<HomeLocation> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("Zainnnnnnnnnnnnnnnnnnnnnnnnnnnnn, I'm here in HomeLocation");
  }

  @override
  Widget getSliverAppBarWidget() {
    print(
        "Zainnnnnnnnnnnnnnnnnnnnnnnnnnnnn, I'm being called in getSliverAppBarWidget in HomeLocation extended with ParentSliverHome ");
    return HomeLocationSliverAppBarWidget(
      onLeadingIconPressed: () {
        print(
            "Zainnnnnnnnnnnnnnnnnnnnnnnnnnnnn, I'm being called in onLeadingIconPressed ");
        widget.scaffoldKey!.currentState!.openEndDrawer();
      },
      selectedStatusIndex: super.getSelectedStatusIndex(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.scaffoldKey != null) {
      super.scaffoldKey = widget.scaffoldKey!;
    }

    return super.build(context);
  }
}
