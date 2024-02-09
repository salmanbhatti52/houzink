import 'dart:io';

import 'package:flutter/material.dart';
import 'package:houzi_package/common/constants.dart';
import 'package:houzi_package/files/app_preferences/app_preferences.dart';
import 'package:houzi_package/widgets/generic_text_widget.dart';
import 'package:houzi_package/widgets/header_widget.dart';

import 'package:houzi_package/blocs/property_bloc.dart';
import 'package:houzi_package/files/generic_methods/utility_methods.dart';
import 'package:houzi_package/files/hive_storage_files/hive_storage_manager.dart';
import 'package:houzi_package/widgets/data_loading_widget.dart';

typedef PropertyContactInformationPageListener = void Function(Map<String, dynamic> _dataMap);

class PropertyContactInformationPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => PropertyContactInformationPageState();

  final GlobalKey<FormState>? formKey;
  final Map<String, dynamic>? propertyInfoMap;
  final PropertyContactInformationPageListener? propertyContactInformationPageListener;

  PropertyContactInformationPage({
    this.formKey,
    this.propertyInfoMap,
    this.propertyContactInformationPageListener
  });

}

class PropertyContactInformationPageState extends State<PropertyContactInformationPage> {

  final PropertyBloc _propertyBloc = PropertyBloc();
  String _userRole = '';
  String? selectedValue;
  String? _selectedAgent;
  String? _selectedAgency;

  Future<List<dynamic>>? _futureAgentsList;
  Future<List<dynamic>>? _futureAgenciesList;

  List<String> realtorsList = [];

  List<dynamic> agentsInfoList = [];
  List<dynamic> agenciesInfoList = [];

  List<dynamic> agentsList = [];
  List<dynamic> agenciesList = [];

  Map<String, dynamic> dataMap = {};

  bool _showWaitingWidget = true;
  bool useAuthorInfo = false;

  int? realtorId;
  Map realtorIdStr = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    realtorsList = [
      UtilityMethods.getLocalizedString("author_info"),
      UtilityMethods.getLocalizedString("agent_info_choose_list"),
      UtilityMethods.getLocalizedString("agency_info_choose_list"),
      UtilityMethods.getLocalizedString("do_not_display"),
    ];
    if(_userRole == USER_ROLE_HOUZEZ_AGENCY_VALUE) {
      selectedValue = realtorsList[2];
    } else {
      selectedValue = realtorsList[0];
    }


    loadRemainingData();

  }

  @override
  void initState() {
    super.initState();
    _userRole = HiveStorageManager.getUserRole();

    if (_userRole == USER_ROLE_HOUZEZ_AGENCY_VALUE) {
      realtorIdStr = HiveStorageManager.readUserLoginInfoData() ?? {};
      if (realtorIdStr.isNotEmpty && realtorIdStr.containsKey(FAVE_AUTHOR_AGENCY_ID)) {
        realtorId = int.tryParse(realtorIdStr[FAVE_AUTHOR_AGENCY_ID]);
      } else {
        realtorId = HiveStorageManager.getUserId();
        useAuthorInfo = true;
      }
    }
  }

  void loadRemainingData() {
    _futureAgentsList = fetchAllAgentsInfo(1, 16);
    _futureAgentsList!.then((value) {
      if (value == null || value.isEmpty) {
      } else {
        setState(() {
          agentsInfoList = value[0];
        });

      }
      if(_userRole != USER_ROLE_HOUZEZ_AGENCY_VALUE) {
        _futureAgenciesList = fetchAllAgenciesInfo(1, 16);
        _futureAgenciesList!.then((value) {
          if (value == null || value.isEmpty) {
          } else {
            if(_userRole == USER_ROLE_HOUZEZ_AGENCY_VALUE) {
              agenciesInfoList = value;
            } else {
              agenciesInfoList = value[0];
            }

            assignValues();

          }
          return null;
        });
      } else {
        assignValues();
      }
      return null;
    });

    if (mounted) {
      setState(() {
        _showWaitingWidget = false;
      });
    }

  }

  assignValues(){
    Map? tempMap = widget.propertyInfoMap;
    if (tempMap != null) {
      if (tempMap.containsKey(ADD_PROPERTY_FAVE_AGENT_DISPLAY_OPTION)) {
        String? value = tempMap[ADD_PROPERTY_FAVE_AGENT_DISPLAY_OPTION];

        if(value != null){
          if (value == AGENCY_INFO) {
            if (mounted) {
              setState(() {
                selectedValue = realtorsList[2];
                _showWaitingWidget = false;
              });
            }
          } else if (value == AGENT_INFO) {
            if (mounted) {
              setState(() {
                selectedValue = realtorsList[1];
                _showWaitingWidget = false;
              });
            }
          } else if (value == AUTHOR_INFO) {
            if (mounted) {
              setState(() {
                selectedValue = realtorsList[0];
                _showWaitingWidget = false;
              });
            }
          } else if (value.isEmpty) {
            if (mounted) {
              setState(() {
                selectedValue = realtorsList[3];
                _showWaitingWidget = false;
              });
            }
          }
        }
      }

      if (selectedValue == realtorsList[1]) {
        if (tempMap.containsKey(ADD_PROPERTY_FAVE_AGENT) &&
            tempMap[ADD_PROPERTY_FAVE_AGENT] != null &&
            tempMap[ADD_PROPERTY_FAVE_AGENT] is List &&
            tempMap[ADD_PROPERTY_FAVE_AGENT].isNotEmpty) {
          var agentId = tempMap[ADD_PROPERTY_FAVE_AGENT][0];
          if (agentId != null) {
            _selectedAgent = agentId.toString();
          }
        }
      } else if (selectedValue == realtorsList[2]) {
        if (tempMap.containsKey(ADD_PROPERTY_FAVE_AGENCY) &&
            tempMap[ADD_PROPERTY_FAVE_AGENCY] != null &&
            tempMap[ADD_PROPERTY_FAVE_AGENCY] is List &&
            tempMap[ADD_PROPERTY_FAVE_AGENCY].isNotEmpty) {
          var agencyId = tempMap[ADD_PROPERTY_FAVE_AGENCY][0];
          if (agencyId != null) {
            _selectedAgency = agencyId.toString();
          }
        }
      }
    } else if (_userRole == USER_ROLE_HOUZEZ_AGENCY_VALUE) {
      selectedValue = realtorsList[2];
      if(useAuthorInfo && realtorId != null) {
        dataMap[ADD_PROPERTY_FAVE_AGENCY] = [realtorId.toString()];
        dataMap[ADD_PROPERTY_FAVE_AGENT_DISPLAY_OPTION] = AUTHOR_INFO;

      } else {
        dataMap[ADD_PROPERTY_FAVE_AGENCY] = [realtorIdStr[FAVE_AUTHOR_AGENCY_ID]];
        dataMap[ADD_PROPERTY_FAVE_AGENT_DISPLAY_OPTION] = AGENCY_INFO;
      }

      widget.propertyContactInformationPageListener!(dataMap);

    }
  }

  Future<List<dynamic>> fetchAllAgentsInfo(int page, int perPage) async {
    try {
      if (mounted) {
        List tempList = [];
        do {
          if (_userRole == USER_ROLE_HOUZEZ_AGENCY_VALUE) {
            if(useAuthorInfo) {
              tempList = await _propertyBloc.fetchAgencyAllAgentList(realtorId!);
            } else {
              tempList = await _propertyBloc.fetchAgencyAgentInfoList(realtorId!);
            }

          } else {
            tempList = await _propertyBloc.fetchAllAgentsInfoList(page, perPage);
          }
          agentsList.addAll(tempList);
          page++;
        } while (tempList.length >= 16);
      }
    } on SocketException {
      throw 'No Internet connection';
    }
    return agentsList;
  }

  Future<List<dynamic>> fetchAllAgenciesInfo(int page, int perPage) async {
    try {
      if (mounted) {
        List tempList = [];
        do{
          if (_userRole == USER_ROLE_HOUZEZ_AGENCY_VALUE) {
            int? agencyUserId = HiveStorageManager.getUserId();
            if(agencyUserId != null) {
              tempList = await _propertyBloc.fetchSingleAgencyInfoList(agencyUserId);
            }
          } else {
            tempList = await _propertyBloc.fetchAllAgenciesInfoList(page, perPage);
          }

          agenciesList.addAll(tempList);
          page++;
        }while(tempList.length >= 16);

      }
    } on SocketException {
      throw 'No Internet connection';
    }
    return agenciesList;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Stack(
        children :[
          Form(
            key: widget.formKey,
            child: Column(
              children: [
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      contactInformationTextWidget(),
                      questionTextWidget(),
                      contactRealtorCheckBoxListWidget(),
                      errorWidget(context),
                    ],
                  ),
                ),

              ],
            ),
          ),
          waitingWidget()
        ],
      ),
    );
  }

  Widget contactInformationTextWidget() {
    return HeaderWidget(
      text: UtilityMethods.getLocalizedString("contact_information"),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      alignment: Alignment.topLeft,
      decoration: AppThemePreferences.dividerDecoration(),
    );
  }

  Widget questionTextWidget() {
    return Container(
      alignment: Alignment.topLeft,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GenericTextWidget(
        UtilityMethods.getLocalizedString("what_information_do_you_want_to_display_in_agent_data_container"),
        textAlign: TextAlign.left,
        style: AppThemePreferences().appTheme.body01TextStyle,
      ),
    );
  }

  Widget contactRealtorCheckBoxListWidget(){
    return realtorsList.isNotEmpty
        ? Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: realtorsList.length,
              itemBuilder: (context, index) {
                var item = realtorsList;
                if (_userRole == USER_ROLE_HOUZEZ_AGENCY_VALUE && index == 0) {
                  return Container();
                } else if (index == 1 && (agentsInfoList.isEmpty)) {
                  return Container();
                } else {
                  return CheckboxListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GenericTextWidget(
                          item[index],
                          style: AppThemePreferences().appTheme.body02TextStyle,
                        ),
                        selectedValue == item[1] && index == 1 &&
                                agentsInfoList.isNotEmpty
                            ? chooseAgent()
                            : Container(),
                        selectedValue == item[2] && index == 2 &&
                                agenciesInfoList.isNotEmpty
                            ? chooseAgency()
                            : Container(),
                      ],
                    ),
                    activeColor: AppThemePreferences().appTheme.primaryColor,
                    value: selectedValue == item[index] ? true : false,
                    onChanged: (bool? value) {
                      setState(() {
                        String displayOption;
                        selectedValue = item[index];
                        if (selectedValue == item[0]) {
                          displayOption = AUTHOR_INFO;
                        } else if (selectedValue == item[1]) {
                          displayOption = AGENT_INFO;
                        } else if (selectedValue == item[2]) {
                          displayOption = AGENCY_INFO;
                        } else {
                          displayOption = "";
                        }

                        if (useAuthorInfo && displayOption == AGENCY_INFO) {
                          displayOption = AUTHOR_INFO;
                        }
                        // if(displayOption == AGENT_INFO && (agentsInfoList == null || agentsInfoList.isEmpty)) {
                        //   displayOption = AGENCY_INFO;
                        //   if(useAuthorInfo) {
                        //     displayOption = AUTHOR_INFO;
                        //   }
                        // }
                        if(mounted) setState(() {
                          dataMap[ADD_PROPERTY_FAVE_AGENT_DISPLAY_OPTION] =
                              displayOption;
                        });
                      });
                      widget.propertyContactInformationPageListener!(dataMap);
                    },
                  );
                }
              },
            ),
          )
        : Container();
  }

  Widget chooseAgent() {
    return dropDownWidget(
      value: _selectedAgent,
      list: agentsInfoList,
      onSaved: (value){
        if(value != null){
          if(mounted) setState(() {
            int id = getRealtorId(agentsInfoList, value, true);
            if(id != -1){
              _selectedAgent = id.toString();
              dataMap[ADD_PROPERTY_FAVE_AGENT] = [id];
              widget.propertyContactInformationPageListener!(dataMap);
            }
          });
        }
      },

      onChanged: (value) {
        if(value != null){
          if(mounted) setState(() {
            int id = getRealtorId(agentsInfoList, value, true);
            if(id != -1) {
              _selectedAgent = id.toString();
              dataMap[ADD_PROPERTY_FAVE_AGENT] = [id];
              widget.propertyContactInformationPageListener!(dataMap);
            }
          });
        }
      },
    );
  }

  int getRealtorId(List list, String realtorId, bool fromAgent) {
    int? id = int.tryParse(realtorId);
    if(id != null) {
      int? index;
      if (useAuthorInfo) {
        index = list.indexWhere((element) => element.id == id);
      } else {
        index = list.indexWhere((element) => element.id == id);
      }
      if (index != null && index != -1) {
        int? id;
        if (useAuthorInfo) {
          id = int.tryParse(list[index].agentId);
        } else {
          id = list[index].id;
        }

        if (id != null) {
          return id;
        }
      }
    }
    return -1;
  }

  Widget chooseAgency() {
    return dropDownWidget(
      value: _selectedAgency,
      list: agenciesInfoList,
      onSaved: (value) {
        if(value != null) {
          if(mounted) setState(() {
            int id = getRealtorId(agenciesInfoList, value, false);
            if(id != -1) {
              _selectedAgency = id.toString();
              dataMap[ADD_PROPERTY_FAVE_AGENCY] = [id];
              widget.propertyContactInformationPageListener!(dataMap);
            }
          });
        }

      },
      onChanged: (val) {
        if(val != null) {
          if(mounted) setState(() {
            int id = getRealtorId(agenciesInfoList, val, false);
            if(id != -1) {
              _selectedAgency = id.toString();
              dataMap[ADD_PROPERTY_FAVE_AGENCY] = [id];
              widget.propertyContactInformationPageListener!(dataMap);
            }
          });
        }
      },
    );
  }

  Widget errorWidget(BuildContext context) {
    return FormField<bool>(
      builder: (state) {
        if (state.errorText != null && agentsInfoList.isNotEmpty && selectedValue == realtorsList[1]){
          if (_selectedAgent == null || _selectedAgent!.isEmpty) {
            return errorMsgWidget(state.errorText!);
          }
        }
        if (state.errorText != null && agenciesInfoList.isNotEmpty && selectedValue == realtorsList[2]){
          if (_selectedAgency == null || _selectedAgency!.isEmpty) {
            return errorMsgWidget(state.errorText!);
          }
        }

        return Container();
      },
      validator: (value) {
        if (agentsInfoList.isNotEmpty && selectedValue == realtorsList[1]) {
          if (_selectedAgent == null || _selectedAgent!.isEmpty) {
            return UtilityMethods.getLocalizedString("select_agent");
          }
        }
        if (agenciesInfoList.isNotEmpty && selectedValue == realtorsList[2]) {
          if (_selectedAgency == null || _selectedAgency!.isEmpty) {
            return UtilityMethods.getLocalizedString("select_agency");
          }
        }
        return null;
      },
    );
  }

  Widget errorMsgWidget(String errorText){
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 25.0),
      child: GenericTextWidget(
        errorText,
        style: TextStyle(
          color: AppThemePreferences.errorColor,
        ),
      ),
    );
  }

  Widget dropDownWidget({
    required List list,
    String? value,
    void Function(String?)? onSaved,
    void Function(String?)? onChanged,

  }){
    return DropdownButtonFormField(
      value: value,
      isExpanded: true,
      icon: Icon(AppThemePreferences.dropDownArrowIcon),
      hint: GenericTextWidget(UtilityMethods.getLocalizedString("select")),
      onSaved: onSaved,
      items: list.map<DropdownMenuItem<String>>((item) {
        return DropdownMenuItem<String>(
          child: Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: GenericTextWidget(
                item.title,
            ),
          ),
          value: item.id.toString(),
        );
      }).toList(),
      onChanged: onChanged,
    );
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
                child: const SizedBox(
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