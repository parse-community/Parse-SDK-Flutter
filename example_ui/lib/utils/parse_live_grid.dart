import 'package:flutter/material.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

import 'parse_live_list.dart';

class ParseLiveGridWidget<T extends ParseObject> extends StatefulWidget {
  const ParseLiveGridWidget({
    Key? key,
    required this.query,
    this.gridLoadingElement,
    this.queryEmptyElement,
    this.duration = const Duration(milliseconds: 300),
    this.scrollPhysics,
    this.scrollController,
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.primary,
    this.reverse = false,
    this.childBuilder,
    this.shrinkWrap = false,
    this.removedItemBuilder,
    this.listenOnAllSubItems,
    this.listeningIncludes,
    this.lazyLoading = true,
    this.preloadedColumns,
    this.animationController,
    this.crossAxisCount = 3,
    this.crossAxisSpacing = 5.0,
    this.mainAxisSpacing = 5.0,
    this.childAspectRatio = 0.80,
  }) : super(key: key);

  final QueryBuilder<T> query;
  final Widget? gridLoadingElement;
  final Widget? queryEmptyElement;
  final Duration duration;
  final ScrollPhysics? scrollPhysics;
  final ScrollController? scrollController;

  final Axis scrollDirection;
  final EdgeInsetsGeometry? padding;
  final bool? primary;
  final bool reverse;
  final bool shrinkWrap;

  final ChildBuilder<T>? childBuilder;
  final ChildBuilder<T>? removedItemBuilder;

  final bool? listenOnAllSubItems;
  final List<String>? listeningIncludes;

  final bool lazyLoading;
  final List<String>? preloadedColumns;

  final AnimationController? animationController;

  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;

  @override
  _ParseLiveGridWidgetState<T> createState() => _ParseLiveGridWidgetState<T>();

  static Widget defaultChildBuilder<T extends ParseObject>(
      BuildContext context, ParseLiveListElementSnapshot<T> snapshot) {
    Widget child;
    if (snapshot.failed) {
      child = const Text('something went wrong!');
    } else if (snapshot.hasData) {
      child = ListTile(
        title: Text(
          snapshot.loadedData!.get<String>(keyVarObjectId)!,
        ),
      );
    } else {
      child = const ListTile(
        leading: CircularProgressIndicator(),
      );
    }
    return child;
  }
}

class _ParseLiveGridWidgetState<T extends ParseObject>
    extends State<ParseLiveGridWidget<T>> {
  ParseLiveList<T>? _liveGrid;
  bool noData = true;

  @override
  void initState() {
    ParseLiveList.create(
      widget.query,
      listenOnAllSubItems: widget.listenOnAllSubItems,
      listeningIncludes: widget.listeningIncludes,
      lazyLoading: widget.lazyLoading,
      preloadedColumns: widget.preloadedColumns,
    ).then((ParseLiveList<T> value) {
      if (value.size > 0) {
        setState(() {
          noData = false;
        });
      } else {
        setState(() {
          noData = true;
        });
      }
      setState(() {
        _liveGrid = value;
        _liveGrid!.stream.listen((ParseLiveListEvent<ParseObject> event) {
          if (mounted) {
            setState(() {});
          }
        });
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_liveGrid == null) {
      return widget.gridLoadingElement ?? Container();
    }
    if (noData) {
      return widget.queryEmptyElement ?? Container();
    }
    return buildAnimatedGrid(_liveGrid!);
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Widget buildAnimatedGrid(ParseLiveList<T> liveGrid) {
    Animation<double> boxAnimation;
    boxAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: widget.animationController!,
        curve: const Interval(
          0,
          0.5,
          curve: Curves.decelerate,
        ),
      ),
    );
    return GridView.builder(
        itemCount: liveGrid.size,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            crossAxisSpacing: widget.crossAxisSpacing,
            mainAxisSpacing: widget.mainAxisSpacing,
            childAspectRatio: widget.childAspectRatio),
        itemBuilder: (
          BuildContext context,
          int index,
        ) {
          return ParseLiveListElementWidget<T>(
            key: ValueKey<String>(liveGrid.getIdentifier(index)),
            stream: () => liveGrid.getAt(index),
            loadedData: () => liveGrid.getLoadedAt(index)!,
            preLoadedData: () => liveGrid.getPreLoadedAt(index)!,
            sizeFactor: boxAnimation,
            duration: widget.duration,
            childBuilder:
                widget.childBuilder ?? ParseLiveGridWidget.defaultChildBuilder,
          );
        });
  }

  @override
  void dispose() {
    _liveGrid?.dispose();
    _liveGrid = null;
    super.dispose();
  }
}
