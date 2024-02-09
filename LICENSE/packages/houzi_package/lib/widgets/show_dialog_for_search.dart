import 'dart:io';

import 'package:flutter/material.dart';
import 'package:houzi_package/blocs/property_bloc.dart';
import 'package:houzi_package/common/constants.dart';
import 'package:houzi_package/files/app_preferences/app_preferences.dart';
import 'package:houzi_package/widgets/button_widget.dart';
import 'package:houzi_package/widgets/data_loading_widget.dart';
import 'package:houzi_package/widgets/generic_text_field_widgets/text_field_widget.dart';

import 'package:houzi_package/files/generic_methods/utility_methods.dart';
import 'package:houzi_package/models/realtor_model.dart';

typedef ShowSearchDialogPageListener = void Function(bool showDialog, Map<String, dynamic>? searchMap);

class ShowSearchDialog extends StatefulWidget {
  final ShowSearchDialogPageListener searchDialogPageListener;
  final bool fromAgent;
  final bool fromUsers;

  const ShowSearchDialog({super.key, required this.searchDialogPageListener,this.fromAgent = false, this.fromUsers = false});

  @override
  _ShowDialogState createState() => _ShowDialogState();
}

class _ShowDialogState extends State<ShowSearchDialog> {
  final PropertyBloc _propertyBloc = PropertyBloc();

  Future<List<dynamic>>? _futureCategoryList;
  Future<List<dynamic>>? _futureCityList;

  List<dynamic> _agentCityList = [];
  List<dynamic> _agentCategoryList = [];

  bool _showWaitingWidget = true;

  Map<String, dynamic> searchMap = {
    SEARCH_KEYWORD: "",
    AGENT_SEARCH_CITY: "",
    AGENT_SEARCH_CATEGORY: ""
  };

  @override
  void initState() {
    super.initState();
    loadMetaData();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.searchDialogPageListener(false, null);
      },
      child: Scaffold(
        backgroundColor: AppThemePreferences.searchDialogBackgroundColor,
        body: Padding(
          padding: const EdgeInsets.only(left: 30.0, right: 30),
          child: Align(
            alignment: Alignment.center,
            child: Container(
              color: AppThemePreferences().appTheme.cardColor,
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Stack(children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(7.0),
                        child: Text(
                          widget.fromUsers
                              ? UtilityMethods.getLocalizedString("find_user")
                              : widget.fromAgent
                                  ? UtilityMethods.getLocalizedString("find_agent")
                                  : UtilityMethods.getLocalizedString("find_agency"),
                          style: AppThemePreferences().appTheme.heading01TextStyle,
                        ),
                      ),
                      TextFormFieldWidget(
                        padding: const EdgeInsets.only(bottom: 10),
                        hintText: UtilityMethods.getLocalizedString("enter_keyword"),
                        onChanged: (text) {
                          if(mounted) setState(() {
                            searchMap[SEARCH_KEYWORD] = text;
                          });
                        },
                      ),
                      _agentCategoryList.isNotEmpty
                          ? dropDownWidget(
                              _agentCategoryList,
                              UtilityMethods.getLocalizedString("all_categories"),
                              AGENT_SEARCH_CATEGORY,
                            )
                          : Container(),
                      _agentCityList.isNotEmpty
                          ? dropDownWidget(
                              _agentCityList,
                              UtilityMethods.getLocalizedString("all_cities"),
                              AGENT_SEARCH_CITY,
                            )
                          : Container(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: ButtonWidget(
                          text: widget.fromUsers
                              ? UtilityMethods.getLocalizedString("find_user")
                              : widget.fromAgent
                                  ? UtilityMethods.getLocalizedString("search_agent")
                                  : UtilityMethods.getLocalizedString("search_agency"),
                          onPressed: () {
                            widget.searchDialogPageListener(false, searchMap);
                          },
                        ),
                      ),
                    ],
                  ),
                  waitingWidget(),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget dropDownWidget(List list, String hintText, String key) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 0),
            child: DropdownButtonFormField(
              icon: Icon(AppThemePreferences.dropDownArrowIcon),
              decoration: AppThemePreferences.formFieldDecoration(hintText: UtilityMethods.getLocalizedString("select")),
              items: list.map<DropdownMenuItem<String>>((item) {
                return DropdownMenuItem<String>(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Text(
                      item.name,
                    ),
                  ),
                  value: item.termId.toString(),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null && val.isNotEmpty && val != 'null') {
                  setState(() {
                    searchMap[key] = val;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<dynamic>> fetchTermData(String term) async {
    List<dynamic> termData = [];
    try {
      termData = await _propertyBloc.fetchTermData(term);
    } on SocketException {
      throw 'No Internet connection';
    }

    return termData;
  }

  void loadMetaData() {
    if(widget.fromAgent){
      _futureCityList = fetchTermData("agent_city");
      _futureCityList!.then((value) {
        setState(() {
          _agentCityList = value;
        });

        if (_agentCityList == null || _agentCityList.isEmpty) {
          AgentMetaData agentMetaDataCity = AgentMetaData(name: "All Cities", termId: null);
          setState(() {
            _agentCityList.insert(0, agentMetaDataCity);
          });

        }


        return null;
      });

      _futureCategoryList = fetchTermData("agent_category");
      _futureCategoryList!.then((value) {
        if(value !=null && value.isNotEmpty){
          _agentCategoryList.clear();
          _agentCategoryList.addAll(value);
        }
        AgentMetaData agentMetaDataCategory = AgentMetaData(name: "All Categories", termId: null);
        _agentCategoryList.insert(0, agentMetaDataCategory);

        setState(() {
        });





        setState(() {
          _showWaitingWidget = false;
        });


        return null;
      });
    }else{
      setState(() {
        _showWaitingWidget = false;
      });
    }


  }

  Widget waitingWidget() {
    return _showWaitingWidget == true
        ? Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 80,
                  height: 20,
                  child: BallBeatLoadingWidget(),
                ),
              ),
            ),
          )
        : Container();
  }
}
