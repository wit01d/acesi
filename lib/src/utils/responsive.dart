import 'dart:math' as math;

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

@immutable
class Breakpoint {
  const Breakpoint({required this.start, required this.end, this.name, this.data});
  final double start;
  final double end;
  final String? name;
  final dynamic data;
  Breakpoint copyWith({
    double? start,
    double? end,
    String? name,
    dynamic data,
  }) =>
      Breakpoint(
        start: start ?? this.start,
        end: end ?? this.end,
        name: name ?? this.name,
        data: data ?? this.data,
      );
  @override
  String toString() => 'Breakpoint(start: $start, end: $end, name: $name)';
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Breakpoint &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          name == other.name;
  @override
  int get hashCode => start.hashCode * end.hashCode * name.hashCode;
}

class ResponsiveBreakpoints extends StatefulWidget {
  const ResponsiveBreakpoints({
    required this.child,
    required this.breakpoints,
    super.key,
    this.breakpointsLandscape,
    this.landscapePlatforms,
    this.useShortestSide = false,
    this.debugLog = false,
  });
  final Widget child;
  final List<Breakpoint> breakpoints;
  final List<Breakpoint>? breakpointsLandscape;
  final List<ResponsiveTargetPlatform>? landscapePlatforms;
  final bool useShortestSide;
  final bool debugLog;
  @override
  ResponsiveBreakpointsState createState() => ResponsiveBreakpointsState();
  static Widget builder({
    required Widget child,
    required List<Breakpoint> breakpoints,
    List<Breakpoint>? breakpointsLandscape,
    List<ResponsiveTargetPlatform>? landscapePlatforms,
    bool useShortestSide = false,
    bool debugLog = false,
  }) =>
      ResponsiveBreakpoints(
        breakpoints: breakpoints,
        breakpointsLandscape: breakpointsLandscape,
        landscapePlatforms: landscapePlatforms,
        useShortestSide: useShortestSide,
        debugLog: debugLog,
        child: child,
      );
  static ResponsiveBreakpointsData of(BuildContext context) {
    final InheritedResponsiveBreakpoints? data =
        context.dependOnInheritedWidgetOfExactType<InheritedResponsiveBreakpoints>();
    if (data != null) return data.data;
    throw FlutterError.fromParts(
      <DiagnosticsNode>[
        ErrorSummary('ResponsiveBreakpoints.of() called with a context that does not contain ResponsiveBreakpoints.'),
        ErrorDescription('No Responsive ancestor could be found starting from the context that was passed '
            'to ResponsiveBreakpoints.of(). Place a ResponsiveBreakpoints at the root of the app '
            'or supply a ResponsiveBreakpoints.builder.'),
        context.describeElement('The context used was')
      ],
    );
  }
}

class ResponsiveBreakpointsState extends State<ResponsiveBreakpoints> with WidgetsBindingObserver {
  double windowWidth = 0;
  double getWindowWidth() => MediaQuery.of(context).size.width;
  double windowHeight = 0;
  double getWindowHeight() => MediaQuery.of(context).size.height;
  Breakpoint breakpoint = const Breakpoint(start: 0, end: 0);
  List<Breakpoint> breakpoints = [];
  double screenWidth = 0;
  double getScreenWidth() {
    final double widthCalc = useShortestSide ? (windowWidth < windowHeight ? windowWidth : windowHeight) : windowWidth;
    return widthCalc;
  }

  double screenHeight = 0;
  double getScreenHeight() {
    final double heightCalc =
        useShortestSide ? (windowWidth < windowHeight ? windowHeight : windowWidth) : windowHeight;
    return heightCalc;
  }

  Orientation get orientation => (windowWidth > windowHeight) ? Orientation.landscape : Orientation.portrait;
  static const List<ResponsiveTargetPlatform> _landscapePlatforms = [
    ResponsiveTargetPlatform.iOS,
    ResponsiveTargetPlatform.android,
    ResponsiveTargetPlatform.fuchsia,
  ];
  ResponsiveTargetPlatform? platform;
  void setPlatform() {
    platform = kIsWeb ? ResponsiveTargetPlatform.web : Theme.of(context).platform.responsiveTargetPlatform;
  }

  bool get isLandscapePlatform => (widget.landscapePlatforms ?? _landscapePlatforms).contains(platform);
  bool get isLandscape => orientation == Orientation.landscape && isLandscapePlatform;
  bool get useShortestSide => widget.useShortestSide;
  void setDimensions() {
    windowWidth = getWindowWidth();
    windowHeight = getWindowHeight();
    screenWidth = getScreenWidth();
    screenHeight = getScreenHeight();
    breakpoint =
        breakpoints.firstWhereOrNull((element) => screenWidth >= element.start && screenWidth <= element.end) ??
            const Breakpoint(start: 0, end: 0);
  }

  List<Breakpoint> getActiveBreakpoints() {
    if (isLandscape) {
      return widget.breakpointsLandscape ?? widget.breakpoints;
    }
    return widget.breakpoints;
  }

  void setBreakpoints() {
    if ((windowWidth != getWindowWidth()) || (windowHeight != getWindowHeight()) || (windowWidth == 0)) {
      windowWidth = getWindowWidth();
      windowHeight = getWindowHeight();
      breakpoints
        ..clear()
        ..addAll(getActiveBreakpoints())
        ..sort(ResponsiveUtils.breakpointComparator);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.debugLog) {
      if (widget.breakpointsLandscape != null) {
        debugPrint('**PORTRAIT**');
      }
      ResponsiveUtils.debugLogBreakpoints(widget.breakpoints);
      if (widget.breakpointsLandscape != null) {
        debugPrint('**LANDSCAPE**');
        ResponsiveUtils.debugLogBreakpoints(widget.breakpointsLandscape);
      }
    }
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setBreakpoints();
      setDimensions();
      setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setBreakpoints();
        setDimensions();
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(ResponsiveBreakpoints oldWidget) {
    super.didUpdateWidget(oldWidget);
    setBreakpoints();
    setDimensions();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    setPlatform();
    return InheritedResponsiveBreakpoints(
      data: ResponsiveBreakpointsData.fromWidgetState(this),
      child: widget.child,
    );
  }
}

const String mobile = 'MOBILE';
const String tablet = 'TABLET';
const String phone = 'PHONE';
const String desktop = 'DESKTOP';

@immutable
class ResponsiveBreakpointsData {
  const ResponsiveBreakpointsData({
    this.screenWidth = 0,
    this.screenHeight = 0,
    this.breakpoint = const Breakpoint(start: 0, end: 0),
    this.breakpoints = const [],
    this.isMobile = false,
    this.isPhone = false,
    this.isTablet = false,
    this.isDesktop = false,
    this.orientation = Orientation.portrait,
  });
  final double screenWidth;
  final double screenHeight;
  final Breakpoint breakpoint;
  final List<Breakpoint> breakpoints;
  final bool isMobile;
  final bool isPhone;
  final bool isTablet;
  final bool isDesktop;
  final Orientation orientation;
  static ResponsiveBreakpointsData fromWidgetState(ResponsiveBreakpointsState state) => ResponsiveBreakpointsData(
        screenWidth: state.screenWidth,
        screenHeight: state.screenHeight,
        breakpoint: state.breakpoint,
        breakpoints: state.breakpoints,
        isMobile: state.breakpoint.name == mobile,
        isPhone: state.breakpoint.name == phone,
        isTablet: state.breakpoint.name == tablet,
        isDesktop: state.breakpoint.name == desktop,
        orientation: state.orientation,
      );
  @override
  String toString() =>
      'ResponsiveBreakpoints(breakpoint: $breakpoint, breakpoints: ${breakpoints.asMap()}, isMobile: $isMobile, isPhone: $isPhone, isTablet: $isTablet, isDesktop: $isDesktop)';
  bool equals(String name) => breakpoint.name == name;
  bool largerThan(String name) =>
      screenWidth > (breakpoints.firstWhereOrNull((element) => element.name == name)?.end ?? double.infinity);
  bool largerOrEqualTo(String name) =>
      screenWidth >= (breakpoints.firstWhereOrNull((element) => element.name == name)?.start ?? double.infinity);
  bool smallerThan(String name) =>
      screenWidth < (breakpoints.firstWhereOrNull((element) => element.name == name)?.start ?? 0);
  bool smallerOrEqualTo(String name) =>
      screenWidth <= (breakpoints.firstWhereOrNull((element) => element.name == name)?.end ?? 0);
  bool between(String name, String name1) =>
      screenWidth >= (breakpoints.firstWhereOrNull((element) => element.name == name)?.start ?? 0) &&
      screenWidth <= (breakpoints.firstWhereOrNull((element) => element.name == name1)?.end ?? 0);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResponsiveBreakpointsData &&
          runtimeType == other.runtimeType &&
          screenWidth == other.screenWidth &&
          screenHeight == other.screenHeight &&
          breakpoint == other.breakpoint;
  @override
  int get hashCode => screenWidth.hashCode * screenHeight.hashCode * breakpoint.hashCode;
}

@immutable
class InheritedResponsiveBreakpoints extends InheritedWidget {
  const InheritedResponsiveBreakpoints({required this.data, required super.child, super.key});
  final ResponsiveBreakpointsData data;
  @override
  bool updateShouldNotify(InheritedResponsiveBreakpoints oldWidget) => data != oldWidget.data;
}

class ResponsiveGridView extends StatelessWidget {
  const ResponsiveGridView({
    required this.gridDelegate,
    super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.alignment = Alignment.centerLeft,
    this.children = const <Widget>[],
    this.maxRowCount,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.cacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
  })  : itemBuilder = null,
        itemCount = children?.length,
        assert(children != null);
  const ResponsiveGridView.builder({
    required this.gridDelegate,
    required this.itemBuilder,
    super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.alignment = Alignment.centerLeft,
    this.itemCount,
    this.maxRowCount,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.cacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
  }) : children = null;
  final Axis scrollDirection;
  final bool reverse;
  final ScrollController? controller;
  final bool? primary;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;
  final ResponsiveGridDelegate gridDelegate;
  final IndexedWidgetBuilder? itemBuilder;
  final List<Widget>? children;
  final int? itemCount;
  final int? maxRowCount;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final double? cacheExtent;
  final int? semanticChildCount;
  final DragStartBehavior dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final Clip clipBehavior;
  final String? restorationId;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final EdgeInsets paddingHolder = padding as EdgeInsets? ?? EdgeInsets.zero;
        int crossAxisCount;
        int? maxItemCount;
        EdgeInsetsGeometry alignmentPadding;
        double crossAxisWidth;
        final double crossAxisExtent = constraints.maxWidth - paddingHolder.horizontal;
        assert(crossAxisExtent > 0, '$paddingHolder exceeds layout width (${constraints.maxWidth})');
        if (gridDelegate.crossAxisExtent != null) {
          crossAxisCount = (crossAxisExtent / (gridDelegate.crossAxisExtent! + gridDelegate.crossAxisSpacing)).floor();
          crossAxisWidth = crossAxisCount * (gridDelegate.crossAxisExtent! + gridDelegate.crossAxisSpacing) +
              paddingHolder.horizontal;
        } else if (gridDelegate.maxCrossAxisExtent != null) {
          crossAxisCount =
              (crossAxisExtent / (gridDelegate.maxCrossAxisExtent! + gridDelegate.crossAxisSpacing)).ceil();
          final double usableCrossAxisExtent = crossAxisExtent - gridDelegate.crossAxisSpacing * (crossAxisCount - 1);
          final double childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;
          crossAxisWidth =
              crossAxisCount * (childCrossAxisExtent + gridDelegate.crossAxisSpacing) + paddingHolder.horizontal;
        } else {
          crossAxisCount =
              (crossAxisExtent / (gridDelegate.minCrossAxisExtent! + gridDelegate.crossAxisSpacing)).floor();
          final double usableCrossAxisExtent = crossAxisExtent - gridDelegate.crossAxisSpacing * (crossAxisCount - 1);
          final double childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;
          crossAxisWidth =
              crossAxisCount * (childCrossAxisExtent + gridDelegate.crossAxisSpacing) + paddingHolder.horizontal;
        }
        if (alignment == Alignment.centerLeft || alignment == Alignment.topLeft || alignment == Alignment.bottomLeft) {
          alignmentPadding = EdgeInsets.zero;
        } else if (alignment == Alignment.center ||
            alignment == Alignment.topCenter ||
            alignment == Alignment.bottomCenter) {
          final double paddingCalc = constraints.maxWidth - crossAxisWidth;
          if (paddingCalc <= 0) {
            alignmentPadding = EdgeInsets.zero;
          } else if (paddingCalc > gridDelegate.crossAxisSpacing) {
            alignmentPadding = EdgeInsets.only(
                left: ((constraints.maxWidth - crossAxisWidth - gridDelegate.crossAxisSpacing) / 2) +
                    gridDelegate.crossAxisSpacing);
          } else {
            alignmentPadding = EdgeInsets.only(left: paddingCalc);
          }
        } else {
          alignmentPadding = EdgeInsets.only(left: constraints.maxWidth - crossAxisWidth);
        }
        if (maxRowCount != null) {
          maxItemCount = maxRowCount! * crossAxisCount;
        }
        SliverChildDelegate childrenDelegate;
        if (itemBuilder != null) {
          childrenDelegate = SliverChildBuilderDelegate(
            itemBuilder!,
            childCount: maxItemCount ?? itemCount,
            addAutomaticKeepAlives: addAutomaticKeepAlives,
            addRepaintBoundaries: addRepaintBoundaries,
            addSemanticIndexes: addSemanticIndexes,
          );
        } else {
          childrenDelegate = SliverChildListDelegate(
            children!,
            addAutomaticKeepAlives: addAutomaticKeepAlives,
            addRepaintBoundaries: addRepaintBoundaries,
            addSemanticIndexes: addSemanticIndexes,
          );
        }
        return Container(
          padding: alignmentPadding,
          child: _ResponsiveGridViewLayout(
            scrollDirection: scrollDirection,
            reverse: reverse,
            controller: controller,
            primary: primary,
            physics: physics,
            shrinkWrap: shrinkWrap,
            padding: padding,
            gridDelegate: gridDelegate,
            childrenDelegate: childrenDelegate,
            itemCount: itemCount,
            cacheExtent: cacheExtent,
            semanticChildCount: semanticChildCount,
            dragStartBehavior: dragStartBehavior,
            keyboardDismissBehavior: keyboardDismissBehavior,
            clipBehavior: clipBehavior,
            restorationId: restorationId,
          ),
        );
      });
}

class _ResponsiveGridViewLayout extends BoxScrollView {
  const _ResponsiveGridViewLayout({
    required this.gridDelegate,
    required this.childrenDelegate,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    this.itemCount,
    super.cacheExtent,
    int? semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
  }) : super(
          semanticChildCount: semanticChildCount ?? itemCount,
        );
  final ResponsiveGridDelegate gridDelegate;
  final SliverChildDelegate childrenDelegate;
  final int? itemCount;
  @override
  Widget buildChildLayout(BuildContext context) => SliverGrid(
        delegate: childrenDelegate,
        gridDelegate: gridDelegate,
      );
}

class ResponsiveGridDelegate extends SliverGridDelegate {
  const ResponsiveGridDelegate({
    this.crossAxisExtent,
    this.maxCrossAxisExtent,
    this.minCrossAxisExtent,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.childAspectRatio = 1,
  })  : assert(
            (crossAxisExtent != null && crossAxisExtent >= 0) ||
                (maxCrossAxisExtent != null && maxCrossAxisExtent >= 0) ||
                (minCrossAxisExtent != null && minCrossAxisExtent >= 0),
            'Must provide a valid cross axis extent.'),
        assert(mainAxisSpacing >= 0),
        assert(crossAxisSpacing >= 0),
        assert(childAspectRatio > 0);
  final double? crossAxisExtent;
  final double? maxCrossAxisExtent;
  final double? minCrossAxisExtent;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  bool _debugAssertIsValid(double crossAxisExtent) {
    assert(crossAxisExtent > 0.0);
    assert(mainAxisSpacing >= 0.0);
    assert(crossAxisSpacing >= 0.0);
    assert(childAspectRatio > 0.0);
    return true;
  }

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    assert(_debugAssertIsValid(constraints.crossAxisExtent));
    int crossAxisCount;
    double mainAxisStride;
    double crossAxisStride;
    double childMainAxisExtent;
    double? childCrossAxisExtent;
    if (crossAxisExtent != null) {
      crossAxisCount = (constraints.crossAxisExtent / (crossAxisExtent! + crossAxisSpacing)).floor();
      childCrossAxisExtent = crossAxisExtent;
      childMainAxisExtent = childCrossAxisExtent! / childAspectRatio;
      mainAxisStride = childMainAxisExtent + mainAxisSpacing;
      crossAxisStride = childCrossAxisExtent + crossAxisSpacing;
    } else if (maxCrossAxisExtent != null) {
      crossAxisCount = (constraints.crossAxisExtent / (maxCrossAxisExtent! + crossAxisSpacing)).ceil();
      final double usableCrossAxisExtent = constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1);
      childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;
      childMainAxisExtent = childCrossAxisExtent / childAspectRatio;
      mainAxisStride = childMainAxisExtent + mainAxisSpacing;
      crossAxisStride = childCrossAxisExtent + crossAxisSpacing;
    } else {
      crossAxisCount = (constraints.crossAxisExtent / (minCrossAxisExtent! + crossAxisSpacing)).floor();
      final double usableCrossAxisExtent = constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1);
      childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;
      childMainAxisExtent = childCrossAxisExtent / childAspectRatio;
      mainAxisStride = childMainAxisExtent + mainAxisSpacing;
      crossAxisStride = childCrossAxisExtent + crossAxisSpacing;
    }
    return SliverGridRegularTileLayout(
      crossAxisCount: crossAxisCount,
      mainAxisStride: mainAxisStride,
      crossAxisStride: crossAxisStride,
      childMainAxisExtent: childMainAxisExtent,
      childCrossAxisExtent: childCrossAxisExtent,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(ResponsiveGridDelegate oldDelegate) =>
      oldDelegate.crossAxisExtent != crossAxisExtent ||
      oldDelegate.maxCrossAxisExtent != maxCrossAxisExtent ||
      oldDelegate.minCrossAxisExtent != minCrossAxisExtent ||
      oldDelegate.mainAxisSpacing != mainAxisSpacing ||
      oldDelegate.crossAxisSpacing != crossAxisSpacing ||
      oldDelegate.childAspectRatio != childAspectRatio;
}

class MaxWidthBox extends StatelessWidget {
  const MaxWidthBox(
      {required this.maxWidth,
      required this.child,
      super.key,
      this.alignment = Alignment.topCenter,
      this.padding,
      this.backgroundColor});
  final double? maxWidth;
  final Widget child;
  final AlignmentGeometry alignment;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQuery = MediaQuery.of(context);
    if (maxWidth != null) {
      if (mediaQuery.size.width > maxWidth!) {
        mediaQuery = mediaQuery.copyWith(
            size: Size(maxWidth! - (padding?.horizontal ?? 0), mediaQuery.size.height - (padding?.vertical ?? 0)));
      }
    }
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: Container(
          color: backgroundColor,
          padding: padding,
          child: MediaQuery(
            data: mediaQuery,
            child: child,
          ),
        ),
      ),
    );
  }
}

enum ResponsiveRowColumnType {
  row,
  column,
}

class ResponsiveRowColumn extends StatelessWidget {
  const ResponsiveRowColumn(
      {required this.layout,
      super.key,
      this.children = const [],
      this.rowMainAxisAlignment = MainAxisAlignment.start,
      this.rowMainAxisSize = MainAxisSize.max,
      this.rowCrossAxisAlignment = CrossAxisAlignment.center,
      this.rowTextDirection,
      this.rowVerticalDirection = VerticalDirection.down,
      this.rowTextBaseline,
      this.columnMainAxisAlignment = MainAxisAlignment.start,
      this.columnMainAxisSize = MainAxisSize.max,
      this.columnCrossAxisAlignment = CrossAxisAlignment.center,
      this.columnTextDirection,
      this.columnVerticalDirection = VerticalDirection.down,
      this.columnTextBaseline,
      this.rowSpacing,
      this.columnSpacing,
      this.rowPadding = EdgeInsets.zero,
      this.columnPadding = EdgeInsets.zero});
  final List<ResponsiveRowColumnItem> children;
  final ResponsiveRowColumnType layout;
  final MainAxisAlignment rowMainAxisAlignment;
  final MainAxisSize rowMainAxisSize;
  final CrossAxisAlignment rowCrossAxisAlignment;
  final TextDirection? rowTextDirection;
  final VerticalDirection rowVerticalDirection;
  final TextBaseline? rowTextBaseline;
  final MainAxisAlignment columnMainAxisAlignment;
  final MainAxisSize columnMainAxisSize;
  final CrossAxisAlignment columnCrossAxisAlignment;
  final TextDirection? columnTextDirection;
  final VerticalDirection columnVerticalDirection;
  final TextBaseline? columnTextBaseline;
  final double? rowSpacing;
  final double? columnSpacing;
  final EdgeInsets rowPadding;
  final EdgeInsets columnPadding;
  bool get isRow => layout == ResponsiveRowColumnType.row;
  bool get isColumn => layout == ResponsiveRowColumnType.column;
  @override
  Widget build(BuildContext context) {
    if (layout == ResponsiveRowColumnType.row) {
      return Padding(
        padding: rowPadding,
        child: Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: rowMainAxisAlignment,
          mainAxisSize: rowMainAxisSize,
          crossAxisAlignment: rowCrossAxisAlignment,
          textDirection: rowTextDirection,
          verticalDirection: rowVerticalDirection,
          textBaseline: rowTextBaseline,
          children: [
            ...buildChildren(children, true, rowSpacing),
          ],
        ),
      );
    }
    return Padding(
      padding: columnPadding,
      child: Flex(
        direction: Axis.vertical,
        mainAxisAlignment: columnMainAxisAlignment,
        mainAxisSize: columnMainAxisSize,
        crossAxisAlignment: columnCrossAxisAlignment,
        textDirection: columnTextDirection,
        verticalDirection: columnVerticalDirection,
        textBaseline: columnTextBaseline,
        children: [
          ...buildChildren(children, false, columnSpacing),
        ],
      ),
    );
  }

  List<Widget> buildChildren(List<ResponsiveRowColumnItem> children, bool rowColumn, double? spacing) {
    final List<ResponsiveRowColumnItem> childrenHolder = [...children]..sort((a, b) {
        if (rowColumn) {
          return a.rowOrder.compareTo(b.rowOrder);
        } else {
          return a.columnOrder.compareTo(b.columnOrder);
        }
      });
    final List<Widget> widgetList = [];
    for (int i = 0; i < childrenHolder.length; i++) {
      widgetList.add(childrenHolder[i].copyWith(rowColumn: rowColumn));
      if (spacing != null && i != childrenHolder.length - 1) {
        widgetList
            .add(Padding(padding: rowColumn ? EdgeInsets.only(right: spacing) : EdgeInsets.only(bottom: spacing)));
      }
    }
    return widgetList;
  }
}

class ResponsiveRowColumnItem extends StatelessWidget {
  const ResponsiveRowColumnItem(
      {required this.child,
      super.key,
      this.rowOrder = 1073741823,
      this.columnOrder = 1073741823,
      this.rowColumn = true,
      this.rowFlex,
      this.columnFlex,
      this.rowFit,
      this.columnFit});
  final Widget child;
  final int rowOrder;
  final int columnOrder;
  final bool rowColumn;
  final int? rowFlex;
  final int? columnFlex;
  final FlexFit? rowFit;
  final FlexFit? columnFit;
  @override
  Widget build(BuildContext context) {
    if (rowColumn && (rowFlex != null || rowFit != null)) {
      return Flexible(flex: rowFlex ?? 1, fit: rowFit ?? FlexFit.loose, child: child);
    } else if (!rowColumn && (columnFlex != null || columnFit != null)) {
      return Flexible(flex: columnFlex ?? 1, fit: columnFit ?? FlexFit.loose, child: child);
    }
    return child;
  }

  ResponsiveRowColumnItem copyWith({
    int? rowOrder,
    int? columnOrder,
    bool? rowColumn,
    int? rowFlex,
    int? columnFlex,
    FlexFit? rowFlexFit,
    FlexFit? columnFlexFit,
    Widget? child,
  }) =>
      ResponsiveRowColumnItem(
        rowOrder: rowOrder ?? this.rowOrder,
        columnOrder: columnOrder ?? this.columnOrder,
        rowColumn: rowColumn ?? this.rowColumn,
        rowFlex: rowFlex ?? this.rowFlex,
        columnFlex: columnFlex ?? this.columnFlex,
        rowFit: rowFlexFit ?? rowFit,
        columnFit: columnFlexFit ?? columnFit,
        child: child ?? this.child,
      );
}

class ResponsiveScaledBox extends StatelessWidget {
  const ResponsiveScaledBox(
      {required this.width, required this.child, super.key, this.autoCalculateMediaQueryData = true});
  final double? width;
  final Widget child;
  final bool autoCalculateMediaQueryData;
  @override
  Widget build(BuildContext context) {
    if (width != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final MediaQueryData mediaQueryData = MediaQuery.of(context);
          final double aspectRatio = constraints.maxWidth / constraints.maxHeight;
          final double scaledWidth = width!;
          final double scaledHeight = width! / aspectRatio;
          final bool overrideMediaQueryData =
              autoCalculateMediaQueryData && (mediaQueryData.size == Size(constraints.maxWidth, constraints.maxHeight));
          final EdgeInsets scaledViewInsets = getScaledViewInsets(
              mediaQueryData: mediaQueryData,
              screenSize: mediaQueryData.size,
              scaledSize: Size(scaledWidth, scaledHeight));
          final EdgeInsets scaledViewPadding = getScaledViewPadding(
              mediaQueryData: mediaQueryData,
              screenSize: mediaQueryData.size,
              scaledSize: Size(scaledWidth, scaledHeight));
          final EdgeInsets scaledPadding = getScaledPadding(padding: scaledViewPadding, insets: scaledViewInsets);
          final Widget childHolder = FittedBox(
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            child: Container(
              width: width,
              height: scaledHeight,
              alignment: Alignment.center,
              child: child,
            ),
          );
          if (overrideMediaQueryData) {
            return MediaQuery(
              data: mediaQueryData.copyWith(
                  size: Size(scaledWidth, scaledHeight),
                  viewInsets: scaledViewInsets,
                  viewPadding: scaledViewPadding,
                  padding: scaledPadding),
              child: childHolder,
            );
          }
          return childHolder;
        },
      );
    }
    return child;
  }

  EdgeInsets getScaledViewInsets(
      {required MediaQueryData mediaQueryData, required Size screenSize, required Size scaledSize}) {
    final double leftInsetFactor = mediaQueryData.viewInsets.left / screenSize.width;
    final double topInsetFactor = mediaQueryData.viewInsets.top / screenSize.height;
    final double rightInsetFactor = mediaQueryData.viewInsets.right / screenSize.width;
    final double bottomInsetFactor = mediaQueryData.viewInsets.bottom / screenSize.height;
    final double scaledLeftInset = leftInsetFactor * scaledSize.width;
    final double scaledTopInset = topInsetFactor * scaledSize.height;
    final double scaledRightInset = rightInsetFactor * scaledSize.width;
    final double scaledBottomInset = bottomInsetFactor * scaledSize.height;
    return EdgeInsets.fromLTRB(scaledLeftInset, scaledTopInset, scaledRightInset, scaledBottomInset);
  }

  EdgeInsets getScaledViewPadding(
      {required MediaQueryData mediaQueryData, required Size screenSize, required Size scaledSize}) {
    double scaledLeftPadding;
    double scaledTopPadding;
    double scaledRightPadding;
    double scaledBottomPadding;
    final double leftPaddingFactor = mediaQueryData.viewPadding.left / screenSize.width;
    final double topPaddingFactor = mediaQueryData.viewPadding.top / screenSize.height;
    final double rightPaddingFactor = mediaQueryData.viewPadding.right / screenSize.width;
    final double bottomPaddingFactor = mediaQueryData.viewPadding.bottom / screenSize.height;
    scaledLeftPadding = leftPaddingFactor * scaledSize.width;
    scaledTopPadding = topPaddingFactor * scaledSize.height;
    scaledRightPadding = rightPaddingFactor * scaledSize.width;
    scaledBottomPadding = bottomPaddingFactor * scaledSize.height;
    return EdgeInsets.fromLTRB(scaledLeftPadding, scaledTopPadding, scaledRightPadding, scaledBottomPadding);
  }

  EdgeInsets getScaledPadding({required EdgeInsets padding, required EdgeInsets insets}) {
    double scaledLeftPadding;
    double scaledTopPadding;
    double scaledRightPadding;
    double scaledBottomPadding;
    scaledLeftPadding = math.max(0, padding.left - insets.left);
    scaledTopPadding = math.max(0, padding.top - insets.top);
    scaledRightPadding = math.max(0, padding.right - insets.right);
    scaledBottomPadding = math.max(0, padding.bottom - insets.bottom);
    return EdgeInsets.fromLTRB(scaledLeftPadding, scaledTopPadding, scaledRightPadding, scaledBottomPadding);
  }
}

class BouncingScrollBehavior extends ScrollBehavior {
  const BouncingScrollBehavior();
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) => child;
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const BouncingScrollPhysics();
}

class BouncingScrollWrapper extends StatelessWidget {
  const BouncingScrollWrapper({required this.child, super.key, this.dragWithMouse = false});
  final Widget child;
  final bool dragWithMouse;
  static Widget builder(BuildContext context, Widget child, {bool dragWithMouse = false}) =>
      BouncingScrollWrapper(dragWithMouse: dragWithMouse, child: child);
  @override
  Widget build(BuildContext context) => ScrollConfiguration(
        behavior: dragWithMouse
            ? const BouncingScrollBehavior()
                .copyWith(dragDevices: {...const BouncingScrollBehavior().dragDevices, PointerDeviceKind.mouse})
            : const BouncingScrollBehavior(),
        child: child,
      );
}

class ClampingScrollBehavior extends ScrollBehavior {
  const ClampingScrollBehavior();
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const ClampingScrollPhysics();
}

class ClampingScrollWrapper extends StatelessWidget {
  const ClampingScrollWrapper({required this.child, super.key, this.dragWithMouse = false});
  final Widget child;
  final bool dragWithMouse;
  static Widget builder(BuildContext context, Widget child, {bool dragWithMouse = false}) =>
      ClampingScrollWrapper(dragWithMouse: dragWithMouse, child: child);
  @override
  Widget build(BuildContext context) => ScrollConfiguration(
        behavior: dragWithMouse
            ? const ClampingScrollBehavior()
                .copyWith(dragDevices: {...const ClampingScrollBehavior().dragDevices, PointerDeviceKind.mouse})
            : const ClampingScrollBehavior(),
        child: child,
      );
}

class NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => child;
}

class NoScrollbarWrapper extends StatelessWidget {
  const NoScrollbarWrapper({required this.child, super.key});
  final Widget child;
  static Widget builder(BuildContext context, Widget child) => NoScrollbarWrapper(child: child);
  @override
  Widget build(BuildContext context) => ScrollConfiguration(
        behavior: NoScrollbarBehavior(),
        child: child,
      );
}

class ResponsiveUtils {
  static int breakpointComparator(Breakpoint a, Breakpoint b) => a.start.compareTo(b.start);
  static String debugLogBreakpoints(List<Breakpoint>? breakpoints) {
    if (breakpoints == null || breakpoints.isEmpty) return '| Empty |';
    final List<Breakpoint> breakpointsHolder = List.from(breakpoints)..sort(breakpointComparator);
    final stringBuffer = StringBuffer()..write('| ');
    for (int i = 0; i < breakpointsHolder.length; i++) {
      final Breakpoint breakpoint = breakpointsHolder[i];
      stringBuffer
        ..write(breakpoint.start)
        ..write(' ----- ');
      final List<dynamic> attributes = [];
      final String? name = breakpoint.name;
      if (name != null) attributes.add(name);
      if (attributes.isNotEmpty) {
        stringBuffer
          ..write('(')
          ..write(attributes.join(','))
          ..write(')')
          ..write(' ----- ');
      }
      stringBuffer.write(breakpoint.end == double.infinity ? '∞' : breakpoint.end);
      if (i != breakpoints.length - 1) {
        stringBuffer.write(' ----- ');
      }
    }
    stringBuffer.write(' |');
    debugPrint(stringBuffer.toString());
    return stringBuffer.toString();
  }
}

enum ResponsiveTargetPlatform {
  android,
  fuchsia,
  iOS,
  linux,
  macOS,
  windows,
  web,
}

extension TargetPlatformExtension on TargetPlatform {
  ResponsiveTargetPlatform get responsiveTargetPlatform {
    switch (this) {
      case TargetPlatform.android:
        return ResponsiveTargetPlatform.android;
      case TargetPlatform.fuchsia:
        return ResponsiveTargetPlatform.fuchsia;
      case TargetPlatform.iOS:
        return ResponsiveTargetPlatform.iOS;
      case TargetPlatform.linux:
        return ResponsiveTargetPlatform.linux;
      case TargetPlatform.macOS:
        return ResponsiveTargetPlatform.macOS;
      case TargetPlatform.windows:
        return ResponsiveTargetPlatform.windows;
    }
  }
}

class ResponsiveValue<T> {
  ResponsiveValue(this.context, {required this.conditionalValues, this.defaultValue}) {
    if (conditionalValues.firstWhereOrNull((element) => element.name != null) != null) {
      try {
        ResponsiveBreakpoints.of(context);
      } catch (e) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('A conditional value was caught referencing a nonexistent breakpoint.'),
          ErrorDescription('ResponsiveValue requires a parent ResponsiveBreakpoint '
              'to reference breakpoints. Add a ResponsiveBreakpoint or remove breakpoint references.')
        ]);
      }
    }
    final List<Condition<T>> conditions = [...conditionalValues];
    value = (getValue(context, conditions) ?? defaultValue) as T;
  }
  late T value;
  final T? defaultValue;
  final List<Condition<T>> conditionalValues;
  final BuildContext context;
  T? getValue(BuildContext context, List<Condition<T>> conditions) {
    final Condition<T>? activeCondition = getActiveCondition(context, conditions);
    if (activeCondition == null) return null;
    if (ResponsiveBreakpoints.of(context).orientation == Orientation.landscape &&
        activeCondition.landscapeValue != null) {
      return activeCondition.landscapeValue;
    }
    return activeCondition.value;
  }

  Condition<T>? getActiveCondition(BuildContext context, List<Condition<T>> conditions) {
    final ResponsiveBreakpointsData responsiveBreakpointsData = ResponsiveBreakpoints.of(context);
    final double screenWidth = responsiveBreakpointsData.screenWidth;
    for (final Condition<T> condition in conditions.reversed) {
      if (condition.condition == Conditional.equals && condition.name == responsiveBreakpointsData.breakpoint.name) {
        return condition;
      }
      if (condition.condition == Conditional.between &&
          screenWidth >= condition.breakpointStart! &&
          screenWidth <= condition.breakpointEnd!) {
        return condition;
      }
      if (condition.condition == Conditional.smallerThan) {
        if (condition.name != null && responsiveBreakpointsData.smallerThan(condition.name!)) {
          return condition;
        }
        if (condition.breakpointStart != null && screenWidth < condition.breakpointStart!) {
          return condition;
        }
        continue;
      }
      if (condition.condition == Conditional.largerThan) {
        if (condition.name != null && responsiveBreakpointsData.largerThan(condition.name!)) {
          return condition;
        }
        if (condition.breakpointStart != null && screenWidth > condition.breakpointStart!) {
          return condition;
        }
        continue;
      }
    }
    return null;
  }
}

enum Conditional {
  largerThan,
  equals,
  smallerThan,
  between,
}

class Condition<T> {
  Condition._(
      {required this.value, this.breakpointStart, this.breakpointEnd, this.name, this.condition, T? landscapeValue})
      : landscapeValue = landscapeValue ?? value,
        assert(breakpointStart != null || name != null),
        assert(condition != Conditional.equals || name != null);
  const Condition.equals({required this.name, this.value, T? landscapeValue})
      : landscapeValue = landscapeValue ?? value,
        breakpointStart = null,
        breakpointEnd = null,
        condition = Conditional.equals;
  const Condition.largerThan({int? breakpoint, this.name, this.value, T? landscapeValue})
      : landscapeValue = landscapeValue ?? value,
        breakpointStart = breakpoint,
        breakpointEnd = breakpoint,
        condition = Conditional.largerThan;
  const Condition.smallerThan({int? breakpoint, this.name, this.value, T? landscapeValue})
      : landscapeValue = landscapeValue ?? value,
        breakpointStart = breakpoint,
        breakpointEnd = breakpoint,
        condition = Conditional.smallerThan;
  const Condition.between({required int? start, required int? end, this.value, T? landscapeValue})
      : landscapeValue = landscapeValue ?? value,
        breakpointStart = start,
        breakpointEnd = end,
        name = null,
        condition = Conditional.between;
  final int? breakpointStart;
  final int? breakpointEnd;
  final String? name;
  final Conditional? condition;
  final T? value;
  final T? landscapeValue;
  Condition<T> copyWith({
    int? breakpointStart,
    int? breakpointEnd,
    String? name,
    Conditional? condition,
    T? value,
    T? landscapeValue,
  }) =>
      Condition<T>._(
        breakpointStart: breakpointStart ?? this.breakpointStart,
        breakpointEnd: breakpointEnd ?? this.breakpointEnd,
        name: name ?? this.name,
        condition: condition ?? this.condition,
        value: value ?? this.value,
        landscapeValue: landscapeValue ?? this.landscapeValue,
      );
  @override
  String toString() =>
      'Condition(breakpointStart: $breakpointStart, breakpointEnd: $breakpointEnd, name: $name, condition: $condition, value: $value, landscapeValue: $landscapeValue)';
  int sort(Condition<T> a, Condition<T> b) {
    if (a.breakpointStart == b.breakpointStart) return 0;
    return (a.breakpointStart! < b.breakpointStart!) ? -1 : 1;
  }
}

class ResponsiveVisibility extends StatelessWidget {
  const ResponsiveVisibility({
    required this.child,
    super.key,
    this.visible = true,
    this.visibleConditions = const [],
    this.hiddenConditions = const [],
    this.replacement = const SizedBox.shrink(),
    this.maintainState = false,
    this.maintainAnimation = false,
    this.maintainSize = false,
    this.maintainSemantics = false,
    this.maintainInteractivity = false,
  });
  final Widget child;
  final bool visible;
  final List<Condition<bool>> visibleConditions;
  final List<Condition<bool>> hiddenConditions;
  final Widget replacement;
  final bool maintainState;
  final bool maintainAnimation;
  final bool maintainSize;
  final bool maintainSemantics;
  final bool maintainInteractivity;
  @override
  Widget build(BuildContext context) {
    final List<Condition<bool>> conditions = [];
    bool visibleValue = visible;
    conditions
      ..addAll(visibleConditions.map((e) => e.copyWith(value: true)))
      ..addAll(hiddenConditions.map((e) => e.copyWith(value: false)));
    visibleValue = ResponsiveValue<bool>(context, defaultValue: visibleValue, conditionalValues: conditions).value;
    return Visibility(
      replacement: replacement,
      visible: visibleValue,
      maintainState: maintainState,
      maintainAnimation: maintainAnimation,
      maintainSize: maintainSize,
      maintainSemantics: maintainSemantics,
      maintainInteractivity: maintainInteractivity,
      child: child,
    );
  }
}

class ResponsiveConstraints extends StatelessWidget {
  const ResponsiveConstraints(
      {required this.child, super.key, this.constraint, this.conditionalConstraints = const []});
  final Widget child;
  final BoxConstraints? constraint;
  final List<Condition<BoxConstraints?>> conditionalConstraints;
  @override
  Widget build(BuildContext context) {
    BoxConstraints? constraintValue = constraint;
    constraintValue = ResponsiveValue<BoxConstraints?>(context,
            defaultValue: constraintValue, conditionalValues: conditionalConstraints)
        .value;
    return Container(
      constraints: constraintValue,
      child: child,
    );
  }
}

class Spacing {
  static const double fontSize = 16;
  static const baseRadius1 = 40.0;
  static const baseRadius2 = 40.0 / 2;
  static const double _baseUnit = 4;
  static double get xs => _calculateModularScale(0);
  static double get sm => _calculateModularScale(1);
  static double get md => _calculateModularScale(2);
  static double get lg => _calculateModularScale(3);
  static double get xl => _calculateModularScale(4);
  static double get xxl => _calculateModularScale(5);
  static double scale(double units) => _baseUnit * units;
  static EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) => EdgeInsets.symmetric(
        horizontal: horizontal * _baseUnit,
        vertical: vertical * _baseUnit,
      );
  static EdgeInsets all(double units) => EdgeInsets.all(scale(units));
  static EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) =>
      EdgeInsets.only(
        left: scale(left),
        top: scale(top),
        right: scale(right),
        bottom: scale(bottom),
      );
  static const double _baseFontSize = 16;
  static const double _ratio = 1.25;
  static double get displayLarge => _baseFontSize * math.pow(_ratio, 5);
  static double get displayMedium => _baseFontSize * math.pow(_ratio, 4);
  static double get displaySmall => _baseFontSize * math.pow(_ratio, 3);
  static double get headlineLarge => _baseFontSize * math.pow(_ratio, 2);
  static double get headlineMedium => _baseFontSize * _ratio;
  static double get headlineSmall => _baseFontSize;
  static double get bodyLarge => _baseFontSize;
  static double get bodyMedium => _baseFontSize / _ratio;
  static double get bodySmall => _baseFontSize / math.pow(_ratio, 2);
  static double get verticalRhythm => _baseFontSize * 1.5;
  static double get spacingUnit => _baseFontSize / 4;
  static EdgeInsets fontBasedPadding(double units) => EdgeInsets.all(spacingUnit * units);
  static EdgeInsets fontBasedVertical(double units) => EdgeInsets.symmetric(vertical: spacingUnit * units);
  static EdgeInsets fontBasedHorizontal(double units) => EdgeInsets.symmetric(horizontal: spacingUnit * units);
  static const double _goldenRatio = 1.618;
  static const double _perfectFourth = 1.333;
  static double _calculateModularScale(int step) => _baseUnit * math.pow(_goldenRatio, step);
  static double get verticalUnit => _calculateModularScale(1);
  static double verticalSpace(int units) => verticalUnit * units;
  static double get horizontalUnit => _calculateModularScale(1);
  static double horizontalSpace(int units) => horizontalUnit * units;
  static double get componentSpacing => _calculateModularScale(2);
  static double get sectionSpacing => _calculateModularScale(3);
  static EdgeInsets get listItemSpacing => symmetric(vertical: 2);
  static EdgeInsets get cardPadding => all(4);
  static EdgeInsets get contentPadding => symmetric(horizontal: 4, vertical: 3);
  static EdgeInsets responsiveSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return symmetric(horizontal: 2, vertical: 1.5);
    } else if (width < 1200) {
      return symmetric(horizontal: 4, vertical: 2);
    }
    return symmetric(horizontal: 6, vertical: 3);
  }

  static EdgeInsets get primarySpacing => all(4);
  static EdgeInsets get secondarySpacing => all(3);
  static EdgeInsets get tertiarySpacing => all(2);
  static EdgeInsets stackSpacing({required int level}) {
    final base = _baseUnit * level;
    return EdgeInsets.only(
      left: base,
      right: base,
      top: base * _goldenRatio,
      bottom: base * _goldenRatio,
    );
  }

  static EdgeInsets rhythmicSpacing({
    required int horizontal,
    required int vertical,
    double? ratio,
  }) {
    final r = ratio ?? _perfectFourth;
    return EdgeInsets.symmetric(
      horizontal: horizontalSpace(horizontal),
      vertical: verticalSpace(vertical) * r,
    );
  }
}

class ResponsiveSpacing {
  const ResponsiveSpacing(this.scaleFactor);
  factory ResponsiveSpacing.fromContext(BuildContext context, {double baseSize = 600.0}) {
    final screenSize = MediaQuery.of(context).size;
    final scaleFactor = math.min(screenSize.width, screenSize.height) / baseSize;
    return ResponsiveSpacing(scaleFactor);
  }
  final double scaleFactor;
  double scale(double units) => Spacing.scale(units) * scaleFactor;
  EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) => EdgeInsets.symmetric(
        horizontal: scale(horizontal),
        vertical: scale(vertical),
      );
  EdgeInsets all(double units) => EdgeInsets.all(scale(units));
  EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) =>
      EdgeInsets.only(
        left: scale(left),
        top: scale(top),
        right: scale(right),
        bottom: scale(bottom),
      );
  EdgeInsets rhythmicSpacing({
    required int horizontal,
    required int vertical,
    double? ratio,
  }) =>
      EdgeInsets.symmetric(
        horizontal: scale(Spacing.horizontalSpace(horizontal)),
        vertical: scale(Spacing.verticalSpace(vertical) * (ratio ?? Spacing._perfectFourth)),
      );
  EdgeInsets stackSpacing({required int level}) {
    final base = scale(Spacing._baseUnit * level);
    return EdgeInsets.only(
      left: base,
      right: base,
      top: base * Spacing._goldenRatio,
      bottom: base * Spacing._goldenRatio,
    );
  }
}
