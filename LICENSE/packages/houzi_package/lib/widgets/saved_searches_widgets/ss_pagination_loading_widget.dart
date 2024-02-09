import 'package:flutter/material.dart';
import 'package:houzi_package/widgets/data_loading_widget.dart';

class SavedSearchPaginationLoadingWidget extends StatelessWidget {
  const SavedSearchPaginationLoadingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).backgroundColor,
      alignment: Alignment.center,
      child: Column(
        children: [
          SizedBox(
            width: 60,
            height: 50,
            child: BallRotatingLoadingWidget(),
          ),
        ],
      ),
    );
  }
}