import 'package:flutter/material.dart';
import 'package:houzi_package/files/generic_methods/utility_methods.dart';


typedef HomeRightBarButtonWidgetHook = Widget? Function(BuildContext context);

class HomeLocationTopBarWidget extends StatefulWidget {

  const HomeLocationTopBarWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<HomeLocationTopBarWidget> createState() => _HomeLocationTopBarWidgetState();
}

class _HomeLocationTopBarWidgetState extends State<HomeLocationTopBarWidget> {

  HomeRightBarButtonWidgetHook? rightBarButtonIdWidgetHook = UtilityMethods.homeRightBarButtonWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 15.0, left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          rightBarButtonIdWidgetHook!(context) ?? Container(padding: const EdgeInsets.only(top: 25.0)),
        ],
      ),
    );
  }
}