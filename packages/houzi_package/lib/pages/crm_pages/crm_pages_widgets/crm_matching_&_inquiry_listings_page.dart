import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:houzi_package/blocs/property_bloc.dart';
import 'package:houzi_package/common/constants.dart';
import 'package:houzi_package/files/app_preferences/app_preferences.dart';
import 'package:houzi_package/files/generic_methods/utility_methods.dart';
import 'package:houzi_package/models/article.dart';
import 'package:houzi_package/pages/crm_pages/crm_pages_widgets/board_pages_widgets.dart';
import 'package:houzi_package/pages/crm_pages/crm_webservices_manager/crm_repository.dart';
import 'package:houzi_package/widgets/data_loading_widget.dart';
import 'package:houzi_package/widgets/no_result_error_widget.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

typedef CRMMatchingAndInquiryListingsListener = void Function(List<dynamic> matchListingEmailIds);

class CRMMatchingAndInquiryListings extends StatefulWidget {
  final String id;
  final CRMMatchingAndInquiryListingsListener crmMatchingAndInquiryListingsListener;

  const CRMMatchingAndInquiryListings({
    required this.id,
    required this.crmMatchingAndInquiryListingsListener,
    Key? key,
  }) : super(key: key);

  @override
  State<CRMMatchingAndInquiryListings> createState() => _CRMMatchingAndInquiryListingsState();
}

class _CRMMatchingAndInquiryListingsState extends State<CRMMatchingAndInquiryListings> {

  final CRMRepository _crmRepository = CRMRepository();
  final RefreshController _refreshController =
  RefreshController(initialRefresh: false);

  Future<List<dynamic>>? _futureCRMMatchingAndInquiry;
  List<dynamic> crmMatchingAndInquiryList = [];
  bool shouldLoadMore = true;
  bool isLoading = false;
  bool showIndicatorWidget = false;
  List<dynamic> matchListingEmailIds = [];
  int page = 1;
  int perPage = 10;

  @override
  void initState() {
    super.initState();
    loadDataFromApi();
  }

  loadDataFromApi({bool forPullToRefresh = true}) {
    if (forPullToRefresh) {
      if (isLoading) {
        return;
      }
    } else {
      if (!shouldLoadMore || isLoading) {
        _refreshController.loadComplete();
        return;
      }
    }

    setState(() {
      if (forPullToRefresh) {
        page = 1;
      } else {
        page++;
      }
      isLoading = true;
    });

    _futureCRMMatchingAndInquiry = fetchInquiryDetailMatchedFromBoard();
    if (forPullToRefresh) {
      _refreshController.refreshCompleted();
    } else {
      _refreshController.loadComplete();
    }
  }

  Future<List<dynamic>> fetchInquiryDetailMatchedFromBoard() async {
    if (page == 1) {
      setState(() {
        shouldLoadMore = true;
      });
    }
    List<dynamic> tempList = await _crmRepository.fetchInquiryDetailMatchedFromBoard(widget.id, page);
    if (tempList == null ||
        (tempList.isNotEmpty && tempList[0] == null) ||
        (tempList.isNotEmpty && tempList[0].runtimeType == Response)) {
      if (mounted) {
        setState(() {
          // isInternetConnected = false;
        });
      }
      return crmMatchingAndInquiryList;
    } else {
      if (mounted) {
        setState(() {
          // isInternetConnected = true;
        });
      }
      if (tempList.isEmpty || tempList.length < perPage) {
        if (mounted) {
          setState(() {
            shouldLoadMore = false;
          });
        }
      }

      if (page == 1) {
        crmMatchingAndInquiryList.clear();
      }
      if (tempList.isNotEmpty) {
        crmMatchingAndInquiryList.addAll(tempList);
      }
    }
    return crmMatchingAndInquiryList;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SmartRefresher(
        enablePullDown: false,
        enablePullUp: true,
        footer: CustomFooter(
          builder: (BuildContext context, LoadStatus? mode) {
            Widget body = Container();
            if (mode == LoadStatus.loading) {
              if (shouldLoadMore) {
                body = paginationLoadingWidget();
              } else {
                body = Container();
              }
            }
            return SizedBox(
              height: 0.0,
              child: Center(child: body),
            );
          },
        ),
        header: const MaterialClassicHeader(),
        controller: _refreshController,
        onRefresh: loadDataFromApi,
        onLoading: () => loadDataFromApi(forPullToRefresh: false),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: showInquiryMatchingList(context, _futureCRMMatchingAndInquiry),
        ),
      ),
    );
  }

  Widget showInquiryMatchingList(
      BuildContext context, Future<List<dynamic>>? futureInquiriesFromBoard) {
    return FutureBuilder<List<dynamic>>(
      future: futureInquiriesFromBoard,
      builder: (context, articleSnapshot) {
        isLoading = false;

        if (articleSnapshot.hasData) {
          if (articleSnapshot.data!.isEmpty) {
            return noResultFoundPage();
          }

          List<dynamic> list = articleSnapshot.data!;

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              if (list[index] is! Article) {
                return Container();
              }
              Article matchedItem = list[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                child: Card(
                  shape: AppThemePreferences.roundedCorners(
                      AppThemePreferences.globalRoundedCornersRadius),
                  elevation: AppThemePreferences.boardPagesElevation,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 7,
                          child: InkWell(
                            onTap: () {
                              if (matchedItem.id != null && matchedItem.id is int) {
                                UtilityMethods.navigateToPropertyDetailPage(
                                  context: context,
                                  propertyID: matchedItem.id,
                                  heroId: matchedItem.id.toString(),
                                );
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CRMTypeHeadingWidget("matching_listing", ""),
                                CRMHeadingWidget(matchedItem.title!),
                                _inquiryDetailWidget(matchedItem),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Checkbox(
                            activeColor: AppThemePreferences().appTheme.primaryColor,
                            value: matchListingEmailIds.contains(matchedItem.id.toString()), onChanged: (bool? value) {
                            _onSelected(value!, matchedItem.id.toString());
                          },),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        } else if (articleSnapshot.hasError) {
          return Container();
        }
        return loadingIndicatorWidget();
      },
    );
  }

  Widget _inquiryDetailWidget(Article object) {
    String? bed;
    String? bath;
    String? area;
    String? price;

    Article obj = object;
    String _propertyPrice = "";
    String _firstPrice = "";
    bed = obj.features?.bedrooms ?? "";
    bath = obj.features?.bathrooms ?? "";
    area = obj.features?.landArea ?? "";
    price = "";
    if (obj.propertyDetailsMap!.containsKey(PRICE)) {
      String? tempPrice = obj.propertyDetailsMap![PRICE];
      if (tempPrice != null && tempPrice.isNotEmpty) {
        _propertyPrice = tempPrice;
      }
    }
    if (obj.propertyDetailsMap!.containsKey(FIRST_PRICE)) {
      String? tempPrice = obj.propertyDetailsMap![FIRST_PRICE];
      if (tempPrice != null && tempPrice.isNotEmpty) {
        _firstPrice = tempPrice;
      }
    }

    if (_propertyPrice.isNotEmpty) {
      price = _propertyPrice;
    } else if (_firstPrice.isNotEmpty) {
      price = _firstPrice;
    }

    return CRMFeatures(bed, bath, area, price);
  }

  void _onSelected(bool selected, String dataId) {
    if (selected) {
      setState(() {
        matchListingEmailIds.add(dataId);
      });
    } else {
      setState(() {
        matchListingEmailIds.remove(dataId);
      });
    }
    widget.crmMatchingAndInquiryListingsListener(matchListingEmailIds);
  }

  Widget loadingIndicatorWidget() {
    return showIndicatorWidget == true
        ? Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                alignment: Alignment.topCenter,
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

  Widget paginationLoadingWidget() {
    return Container(
      color: Theme.of(context).colorScheme.background,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 100,
        height: 100,
        child: BallRotatingLoadingWidget(),
      ),
    );
  }

  Widget noResultFoundPage() {
    return NoResultErrorWidget(
      hideGoBackButton: true,
      headerErrorText: UtilityMethods.getLocalizedString("no_result_found"),
      bodyErrorText: UtilityMethods.getLocalizedString("oops_matching_not_exist"),
    );
  }
}
