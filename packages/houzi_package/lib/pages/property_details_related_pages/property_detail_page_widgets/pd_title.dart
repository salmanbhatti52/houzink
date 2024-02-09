import 'package:flutter/material.dart';
import 'package:houzi_package/files/app_preferences/app_preferences.dart';
import 'package:houzi_package/files/generic_methods/utility_methods.dart';
import 'package:houzi_package/models/article.dart';
import 'package:houzi_package/widgets/generic_text_widget.dart';

import '../../../widgets/article_box_widgets/tags_widgets/featured_tag_widget.dart';
import '../../../widgets/article_box_widgets/tags_widgets/tag_widget.dart';

class PropertyDetailPageTitle extends StatefulWidget {
  final Article article;
  const PropertyDetailPageTitle({required this.article, Key? key}) : super(key: key);

  @override
  State<PropertyDetailPageTitle> createState() => _PropertyDetailPageTitleState();
}

class _PropertyDetailPageTitleState extends State<PropertyDetailPageTitle> {
  String title = "";

  Article? _article;
  String _propertyStatus = "";
  List propertyTagsList = [];

  @override
  void initState() {
    super.initState();
    _article = widget.article;
    loadData();
  }

  loadData() {
    List _propertyStatusList = widget.article.features!.propertyStatusList ?? [];
    List _propertyLabelList = widget.article.features!.propertyLabelList ?? [];
    propertyTagsList = [..._propertyStatusList, ..._propertyLabelList];
    bool _isFeatured = widget.article.propertyInfo!.isFeatured ?? false;
    if (_isFeatured) {
      propertyTagsList.insert(0, _isFeatured);
    }
    _propertyStatus = widget.article.propertyInfo!.propertyStatus ?? "";
  }

  @override
  Widget build(BuildContext context) {
    if (_article != widget.article) {
      _article = widget.article;
      loadData();
    }
    title = widget.article.title ?? "";
    if(title.isNotEmpty){
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (propertyTagsList.isNotEmpty)
              Wrap(
                children: propertyTagsList.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 5, top: 5),
                    child: item is bool ? FeaturedTagWidget() : TagWidget(label: item),
                  );
                }).toList(),
              )
            else if(_propertyStatus.isNotEmpty) TagWidget(label: _propertyStatus),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: GenericTextWidget(
                UtilityMethods.stripHtmlIfNeeded(title),
                strutStyle: StrutStyle(height: AppThemePreferences.genericTextHeight),
                style: AppThemePreferences().appTheme.propertyDetailsPagePropertyTitleTextStyle,
              ),
            ),
          ],
        ),
      );
    }else{
      return Container();
    }
  }
}
