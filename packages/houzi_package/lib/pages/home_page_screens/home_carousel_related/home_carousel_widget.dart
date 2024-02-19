import 'package:flutter/material.dart';
import 'package:houzi_package/pages/home_page_screens/parent_home_related/parent_sliver_home.dart';

class HomeCarousel extends ParentSliverHome {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const HomeCarousel({Key? key, this.scaffoldKey}) : super(key: key);

  @override
  _HomeCarouselState createState() => _HomeCarouselState();
}

class _HomeCarouselState extends ParentSliverHomeState<HomeCarousel> {
  @override
  void initState() {
    super.initState();
    debugPrint("Zainnnnnnnnnnnnnnnnnnnnnnnnnnnnn, I'm here in HomeCarousel");
  }
  @override
  Widget build(BuildContext context) {
    if (widget.scaffoldKey != null) {
      super.scaffoldKey = widget.scaffoldKey!;
    }

    return super.build(context);
  }
}