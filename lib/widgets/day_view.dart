import 'package:flutter/material.dart';

class DayView extends StatefulWidget {
  const DayView({super.key});

  @override
  State<DayView> createState() => _DayViewState();
}

class _DayViewState extends State<DayView> {
  late PageController _pageController;
  static const initialPage = 7000;
  int _activePage = initialPage;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _activePage
    );
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  void _handlePageChanged(int newActivePage) {}

  LayoutBuilder _dayBuilder(int page) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
            child: Stack(
              children: [],
            )
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _handlePageChanged,
      itemBuilder: (context, page) => _dayBuilder(page),
    );
  }
}