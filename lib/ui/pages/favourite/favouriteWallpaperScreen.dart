import 'dart:io';
import 'package:Prism/data/favourites/provider/favouriteProvider.dart';
import 'package:Prism/routes/router.dart';
import 'package:Prism/theme/jam_icons_icons.dart';
import 'package:Prism/ui/widgets/home/wallpapers/clockOverlay.dart';
import 'package:Prism/ui/widgets/home/core/colorBar.dart';
import 'package:Prism/ui/widgets/menuButton/downloadButton.dart';
import 'package:Prism/ui/widgets/menuButton/favWallpaperButton.dart';
import 'package:Prism/ui/widgets/menuButton/setWallpaperButton.dart';
import 'package:Prism/ui/widgets/menuButton/shareButton.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:Prism/main.dart' as main;
import 'package:Prism/theme/config.dart' as config;

class FavWallpaperViewScreen extends StatefulWidget {
  final List arguments;
  const FavWallpaperViewScreen({this.arguments});

  @override
  _FavWallpaperViewScreenState createState() => _FavWallpaperViewScreenState();
}

class _FavWallpaperViewScreenState extends State<FavWallpaperViewScreen>
    with SingleTickerProviderStateMixin {
  Future<bool> onWillPop() async {
    if (navStack.length > 1) navStack.removeLast();
    debugPrint(navStack.toString());
    return true;
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int index;
  String thumb;
  bool isLoading = true;
  PaletteGenerator paletteGenerator;
  List<Color> colors;
  Color accent;
  bool colorChanged = false;
  String downloadLinkBackwards;
  File _imageFile;
  bool screenshotTaken = false;
  ScreenshotController screenshotController = ScreenshotController();
  PanelController panelController = PanelController();
  AnimationController shakeController;
  bool panelClosed = true;

  Future<void> _updatePaletteGenerator() async {
    setState(() {
      isLoading = true;
    });
    paletteGenerator = await PaletteGenerator.fromImageProvider(
      CachedNetworkImageProvider(thumb),
      maximumColorCount: 20,
    );
    setState(() {
      isLoading = false;
    });
    colors = paletteGenerator.colors.toList();
    if (paletteGenerator.colors.length > 5) {
      colors = colors.sublist(0, 5);
    }
    setState(() {
      accent = colors[0];
    });
  }

  void updateAccent() {
    if (colors.contains(accent)) {
      final index = colors.indexOf(accent);
      setState(() {
        accent = colors[(index + 1) % 5];
      });
      setState(() {
        colorChanged = true;
      });
    }
  }

  @override
  void initState() {
    shakeController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    index = widget.arguments[0] as int;
    thumb = widget.arguments[1] as String;
    isLoading = true;
    _updatePaletteGenerator();
    super.initState();
    SystemChrome.setEnabledSystemUIOverlays([]);
  }

  @override
  void dispose() {
    shakeController.dispose();
    super.dispose();
    SystemChrome.setEnabledSystemUIOverlays(
        [SystemUiOverlay.top, SystemUiOverlay.bottom]);
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> offsetAnimation = Tween(begin: 0.0, end: 48.0)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(shakeController)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              shakeController.reverse();
            }
          });
    return WillPopScope(
      onWillPop: onWillPop,
      child: Provider.of<FavouriteProvider>(context, listen: false).liked[index]
                      ["provider"] ==
                  "WallHaven" ||
              Provider.of<FavouriteProvider>(context, listen: false)
                      .liked[index]["provider"] ==
                  "Pexels" ||
              Provider.of<FavouriteProvider>(context, listen: false)
                      .liked[index]["provider"] ==
                  "Prism"
          ? Scaffold(
              resizeToAvoidBottomPadding: false,
              key: _scaffoldKey,
              backgroundColor:
                  isLoading ? Theme.of(context).primaryColor : accent,
              body: SlidingUpPanel(
                onPanelOpened: () {
                  if (panelClosed) {
                    debugPrint('Screenshot Starting');
                    if (colorChanged) {
                      screenshotController
                          .capture(
                        pixelRatio: 3,
                        delay: const Duration(milliseconds: 10),
                      )
                          .then((File image) async {
                        setState(() {
                          _imageFile = image;
                          screenshotTaken = true;
                          panelClosed = false;
                        });
                        debugPrint('Screenshot Taken');
                      }).catchError((onError) {
                        debugPrint(onError.toString());
                      });
                    } else {
                      (main.prefs.get('optimisedWallpapers') ?? true) == true
                          ? screenshotController
                              .capture(
                              pixelRatio: 3,
                              delay: const Duration(milliseconds: 10),
                            )
                              .then((File image) async {
                              setState(() {
                                _imageFile = image;
                                screenshotTaken = true;
                                panelClosed = false;
                              });
                              debugPrint('Screenshot Taken');
                            }).catchError((onError) {
                              debugPrint(onError.toString());
                            })
                          : debugPrint("Wallpaper Optimisation is disabled!");
                    }
                  }
                },
                onPanelClosed: () {
                  setState(() {
                    panelClosed = true;
                  });
                },
                backdropEnabled: true,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: const [],
                collapsed: Container(
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      color: config.Colors().secondDarkColor(1)),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height / 20,
                    child: const Center(
                        child: Icon(
                      JamIcons.chevron_up,
                      color: Colors.white,
                    )),
                  ),
                ),
                minHeight: MediaQuery.of(context).size.height / 20,
                parallaxEnabled: true,
                parallaxOffset: 0.54,
                color: config.Colors().secondDarkColor(1),
                maxHeight: MediaQuery.of(context).size.height * .46,
                controller: panelController,
                panel: Container(
                  height: MediaQuery.of(context).size.height * .42,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    color: config.Colors().secondDarkColor(1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Center(
                          child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Icon(
                          JamIcons.chevron_down,
                          color: Colors.white,
                        ),
                      )),
                      ColorBar(colors: colors),
                      Provider.of<FavouriteProvider>(context, listen: false)
                                  .liked[index]["provider"] ==
                              "WallHaven"
                          ? Expanded(
                              flex: 4,
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(35, 0, 35, 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              0, 5, 0, 10),
                                          child: Text(
                                            Provider.of<FavouriteProvider>(
                                                    context,
                                                    listen: false)
                                                .liked[index]["id"]
                                                .toString()
                                                .toUpperCase(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText1,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              JamIcons.eye,
                                              size: 20,
                                              color: Colors.white70,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              "${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["views"]}",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyText2,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            const Icon(
                                              JamIcons.heart_f,
                                              size: 20,
                                              color: Colors.white70,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              "${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["fav"]}",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyText2,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            const Icon(
                                              JamIcons.save,
                                              size: 20,
                                              color: Colors.white70,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              "${double.parse((double.parse(Provider.of<FavouriteProvider>(context, listen: false).liked[index]["size"].toString()) / 1000000).toString()).toStringAsFixed(2)} MB",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyText2,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              0, 0, 0, 0),
                                          child: Row(
                                            children: [
                                              Text(
                                                Provider.of<FavouriteProvider>(
                                                            context,
                                                            listen: false)
                                                        .liked[index]
                                                            ["category"]
                                                        .toString()[0]
                                                        .toUpperCase() +
                                                    Provider.of<FavouriteProvider>(
                                                            context,
                                                            listen: false)
                                                        .liked[index]
                                                            ["category"]
                                                        .toString()
                                                        .substring(1),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyText2,
                                              ),
                                              const SizedBox(width: 10),
                                              const Icon(
                                                JamIcons.unordered_list,
                                                size: 20,
                                                color: Colors.white70,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Text(
                                              "${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["resolution"]}",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyText2,
                                            ),
                                            const SizedBox(width: 10),
                                            const Icon(
                                              JamIcons.set_square,
                                              size: 20,
                                              color: Colors.white70,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Text(
                                              Provider.of<FavouriteProvider>(
                                                      context,
                                                      listen: false)
                                                  .liked[index]["provider"]
                                                  .toString(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyText2,
                                            ),
                                            const SizedBox(width: 10),
                                            const Icon(
                                              JamIcons.database,
                                              size: 20,
                                              color: Colors.white70,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Provider.of<FavouriteProvider>(context,
                                          listen: false)
                                      .liked[index]["provider"] ==
                                  "Prism"
                              ? Expanded(
                                  flex: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        35, 0, 35, 10),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: <Widget>[
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      0, 5, 0, 10),
                                              child: Text(
                                                Provider.of<FavouriteProvider>(
                                                        context,
                                                        listen: false)
                                                    .liked[index]["id"]
                                                    .toString()
                                                    .toUpperCase(),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyText1,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                const Icon(
                                                  JamIcons.camera,
                                                  size: 20,
                                                  color: Colors.white70,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  "${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["photographer"]}",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyText2,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                            Row(
                                              children: [
                                                const Icon(
                                                  JamIcons.arrow_circle_right,
                                                  size: 20,
                                                  color: Colors.white70,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  "${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["category"]}",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyText2,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                            Row(
                                              children: [
                                                const Icon(
                                                  JamIcons.save,
                                                  size: 20,
                                                  color: Colors.white70,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  "${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["size"]}",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyText2,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: <Widget>[
                                            Row(
                                              children: [
                                                Text(
                                                  "${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["resolution"]}",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyText2,
                                                ),
                                                const SizedBox(width: 10),
                                                const Icon(
                                                  JamIcons.set_square,
                                                  size: 20,
                                                  color: Colors.white70,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                            Row(
                                              children: [
                                                Text(
                                                  Provider.of<FavouriteProvider>(
                                                          context,
                                                          listen: false)
                                                      .liked[index]["provider"]
                                                      .toString(),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyText2,
                                                ),
                                                const SizedBox(width: 10),
                                                const Icon(
                                                  JamIcons.database,
                                                  size: 20,
                                                  color: Colors.white70,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Provider.of<FavouriteProvider>(context,
                                              listen: false)
                                          .liked[index]["provider"] ==
                                      "Pexels"
                                  ? Expanded(
                                      flex: 4,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            35, 0, 35, 15),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: <Widget>[
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          JamIcons.camera,
                                                          size: 20,
                                                          color: Colors.white70,
                                                        ),
                                                        const SizedBox(
                                                            width: 10),
                                                        Container(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              .4,
                                                          child: Text(
                                                            Provider.of<FavouriteProvider>(
                                                                    context,
                                                                    listen:
                                                                        false)
                                                                .liked[index][
                                                                    "photographer"]
                                                                .toString(),
                                                            textAlign:
                                                                TextAlign.left,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyText2,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          JamIcons.set_square,
                                                          size: 20,
                                                          color: Colors.white70,
                                                        ),
                                                        const SizedBox(
                                                            width: 10),
                                                        Text(
                                                          Provider.of<FavouriteProvider>(
                                                                  context,
                                                                  listen: false)
                                                              .liked[index]
                                                                  ["resolution"]
                                                              .toString(),
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyText2,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: <Widget>[
                                                    Row(
                                                      children: [
                                                        Text(
                                                          Provider.of<FavouriteProvider>(
                                                                  context,
                                                                  listen: false)
                                                              .liked[index]
                                                                  ["id"]
                                                              .toString(),
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyText2,
                                                        ),
                                                        const SizedBox(
                                                            width: 10),
                                                        const Icon(
                                                          JamIcons.info,
                                                          size: 20,
                                                          color: Colors.white70,
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          Provider.of<FavouriteProvider>(
                                                                  context,
                                                                  listen: false)
                                                              .liked[index]
                                                                  ["provider"]
                                                              .toString(),
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyText2,
                                                        ),
                                                        const SizedBox(
                                                            width: 10),
                                                        const Icon(
                                                          JamIcons.database,
                                                          size: 20,
                                                          color: Colors.white70,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Expanded(flex: 4, child: Container()),
                      Expanded(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            DownloadButton(
                              colorChanged: colorChanged,
                              link: screenshotTaken
                                  ? _imageFile.path
                                  : Provider.of<FavouriteProvider>(context,
                                          listen: false)
                                      .liked[index]["url"]
                                      .toString(),
                            ),
                            SetWallpaperButton(
                              colorChanged: colorChanged,
                              url: screenshotTaken
                                  ? _imageFile.path
                                  : Provider.of<FavouriteProvider>(context,
                                          listen: false)
                                      .liked[index]["url"]
                                      .toString(),
                            ),
                            FavouriteWallpaperButton(
                              id: Provider.of<FavouriteProvider>(context,
                                      listen: false)
                                  .liked[index]["id"]
                                  .toString(),
                              provider: Provider.of<FavouriteProvider>(context,
                                      listen: false)
                                  .liked[index]["provider"]
                                  .toString(),
                              trash: true,
                            ),
                            ShareButton(
                                id: Provider.of<FavouriteProvider>(context,
                                        listen: false)
                                    .liked[index]["id"]
                                    .toString(),
                                provider: Provider.of<FavouriteProvider>(
                                        context,
                                        listen: false)
                                    .liked[index]["provider"]
                                    .toString(),
                                url: Provider.of<FavouriteProvider>(context,
                                        listen: false)
                                    .liked[index]["url"]
                                    .toString(),
                                thumbUrl: Provider.of<FavouriteProvider>(
                                        context,
                                        listen: false)
                                    .liked[index]["thumb"]
                                    .toString())
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                body: Stack(
                  children: <Widget>[
                    AnimatedBuilder(
                        animation: offsetAnimation,
                        builder: (buildContext, child) {
                          if (offsetAnimation.value < 0.0) {
                            debugPrint('${offsetAnimation.value + 8.0}');
                          }
                          return GestureDetector(
                            onPanUpdate: (details) {
                              if (details.delta.dy < -10) {
                                panelController.open();
                                HapticFeedback.vibrate();
                              }
                            },
                            onLongPress: () {
                              setState(() {
                                colorChanged = false;
                              });
                              HapticFeedback.vibrate();
                              shakeController.forward(from: 0.0);
                            },
                            onTap: () {
                              HapticFeedback.vibrate();
                              !isLoading ? updateAccent() : debugPrint("");
                              shakeController.forward(from: 0.0);
                            },
                            child: CachedNetworkImage(
                              imageUrl: Provider.of<FavouriteProvider>(context,
                                      listen: false)
                                  .liked[index]["url"]
                                  .toString(),
                              imageBuilder: (context, imageProvider) =>
                                  Screenshot(
                                controller: screenshotController,
                                child: Container(
                                  margin: EdgeInsets.symmetric(
                                      vertical: offsetAnimation.value * 1.25,
                                      horizontal: offsetAnimation.value / 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        offsetAnimation.value),
                                    image: DecorationImage(
                                      colorFilter: colorChanged
                                          ? ColorFilter.mode(
                                              accent, BlendMode.hue)
                                          : null,
                                      image: imageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              progressIndicatorBuilder:
                                  (context, url, downloadProgress) => Stack(
                                children: <Widget>[
                                  const SizedBox.expand(child: Text("")),
                                  Center(
                                    child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation(
                                          config.Colors().mainAccentColor(1),
                                        ),
                                        value: downloadProgress.progress),
                                  ),
                                ],
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Icon(
                                  JamIcons.close_circle_f,
                                  color: isLoading
                                      ? Theme.of(context).accentColor
                                      : accent.computeLuminance() > 0.5
                                          ? Colors.black
                                          : Colors.white,
                                ),
                              ),
                            ),
                          );
                        }),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IconButton(
                          onPressed: () {
                            navStack.removeLast();
                            debugPrint(navStack.toString());
                            Navigator.pop(context);
                          },
                          color: isLoading
                              ? Theme.of(context).accentColor
                              : accent.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                          icon: const Icon(
                            JamIcons.chevron_left,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IconButton(
                          onPressed: () {
                            final link = Provider.of<FavouriteProvider>(context,
                                    listen: false)
                                .liked[index]["url"];
                            Navigator.push(
                                context,
                                PageRouteBuilder(
                                    transitionDuration:
                                        const Duration(milliseconds: 300),
                                    pageBuilder: (context, animation,
                                        secondaryAnimation) {
                                      animation = Tween(begin: 0.0, end: 1.0)
                                          .animate(animation);
                                      return FadeTransition(
                                          opacity: animation,
                                          child: ClockOverlay(
                                            colorChanged: colorChanged,
                                            accent: accent,
                                            link: link.toString(),
                                            file: false,
                                          ));
                                    },
                                    fullscreenDialog: true,
                                    opaque: false));
                          },
                          color: isLoading
                              ? Theme.of(context).accentColor
                              : accent.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                          icon: const Icon(
                            JamIcons.clock,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            )
          : Scaffold(
              key: _scaffoldKey,
              resizeToAvoidBottomPadding: false,
              backgroundColor:
                  isLoading ? Theme.of(context).primaryColor : accent,
              body: SlidingUpPanel(
                onPanelOpened: () {
                  if (panelClosed) {
                    debugPrint('Screenshot Starting');
                    if (colorChanged) {
                      screenshotController
                          .capture(
                        pixelRatio: 3,
                        delay: const Duration(milliseconds: 10),
                      )
                          .then((File image) async {
                        setState(() {
                          _imageFile = image;
                          screenshotTaken = true;
                          panelClosed = false;
                        });
                        debugPrint('Screenshot Taken');
                      }).catchError((onError) {
                        debugPrint(onError.toString());
                      });
                    } else {
                      (main.prefs.get('optimisedWallpapers') ?? true) == true
                          ? screenshotController
                              .capture(
                              pixelRatio: 3,
                              delay: const Duration(milliseconds: 10),
                            )
                              .then((File image) async {
                              setState(() {
                                _imageFile = image;
                                screenshotTaken = true;
                                panelClosed = false;
                              });
                              debugPrint('Screenshot Taken');
                            }).catchError((onError) {
                              debugPrint(onError.toString());
                            })
                          : debugPrint("Wallpaper Optimisation is disabled!");
                    }
                  }
                },
                onPanelClosed: () {
                  setState(() {
                    panelClosed = true;
                  });
                },
                backdropEnabled: true,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: const [],
                collapsed: Container(
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      color: config.Colors().secondDarkColor(1)),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height / 20,
                    child: const Center(
                        child: Icon(
                      JamIcons.chevron_up,
                      color: Colors.white,
                    )),
                  ),
                ),
                minHeight: MediaQuery.of(context).size.height / 20,
                parallaxEnabled: true,
                parallaxOffset: 0.54,
                color: config.Colors().secondDarkColor(1),
                maxHeight: MediaQuery.of(context).size.height * .46,
                controller: panelController,
                panel: Container(
                  height: MediaQuery.of(context).size.height * .42,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    color: config.Colors().secondDarkColor(1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Center(
                          child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Icon(
                          JamIcons.chevron_down,
                          color: Colors.white,
                        ),
                      )),
                      ColorBar(colors: colors),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(35, 0, 35, 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 5, 0, 10),
                                    child: Text(
                                      Provider.of<FavouriteProvider>(context,
                                              listen: false)
                                          .liked[index]["id"]
                                          .toString()
                                          .toUpperCase(),
                                      style:
                                          Theme.of(context).textTheme.bodyText1,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        JamIcons.eye,
                                        size: 20,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["views"]}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText2,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      const Icon(
                                        JamIcons.heart_f,
                                        size: 20,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["fav"]}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText2,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Text(
                                        "${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["resolution"]}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText2,
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(
                                        JamIcons.set_square,
                                        size: 20,
                                        color: Colors.white70,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Text(
                                        "${double.parse((double.parse(Provider.of<FavouriteProvider>(context, listen: false).liked[index]["size"].toString()) / 1000000).toString()).toStringAsFixed(2)} MB",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText2,
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(
                                        JamIcons.save,
                                        size: 20,
                                        color: Colors.white70,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: Provider.of<FavouriteProvider>(context,
                                          listen: false)
                                      .liked[index]["provider"] ==
                                  null
                              ? downloadLinkBackwards == null
                                  ? <Widget>[
                                      SetWallpaperButton(
                                        colorChanged: colorChanged,
                                        url: screenshotTaken
                                            ? _imageFile.path
                                            : Provider.of<FavouriteProvider>(
                                                                context,
                                                                listen: false)
                                                            .liked[index]
                                                        ["provider"] ==
                                                    null
                                                ? "https://w.wallhaven.cc/full/${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["id"].toString().substring(0, 2)}/wallhaven-${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["id"]}.png"
                                                : Provider.of<
                                                            FavouriteProvider>(
                                                        context,
                                                        listen: false)
                                                    .liked[index]["url"]
                                                    .toString(),
                                      ),
                                      FavouriteWallpaperButton(
                                        id: Provider.of<FavouriteProvider>(
                                                context,
                                                listen: false)
                                            .liked[index]["id"]
                                            .toString(),
                                        provider:
                                            Provider.of<FavouriteProvider>(
                                                    context,
                                                    listen: false)
                                                .liked[index]["provider"]
                                                .toString(),
                                        trash: true,
                                      ),
                                      ShareButton(
                                          id: Provider.of<FavouriteProvider>(
                                                  context,
                                                  listen: false)
                                              .liked[index]["id"]
                                              .toString(),
                                          provider:
                                              Provider.of<FavouriteProvider>(
                                                      context,
                                                      listen: false)
                                                  .liked[index]["provider"]
                                                  .toString(),
                                          url: Provider.of<FavouriteProvider>(
                                                  context,
                                                  listen: false)
                                              .liked[index]["url"]
                                              .toString(),
                                          thumbUrl:
                                              Provider.of<FavouriteProvider>(
                                                      context,
                                                      listen: false)
                                                  .liked[index]["thumb"]
                                                  .toString())
                                    ]
                                  : <Widget>[
                                      DownloadButton(
                                        colorChanged: colorChanged,
                                        link: screenshotTaken
                                            ? _imageFile.path
                                            : downloadLinkBackwards,
                                      ),
                                      SetWallpaperButton(
                                        colorChanged: colorChanged,
                                        url: screenshotTaken
                                            ? _imageFile.path
                                            : Provider.of<FavouriteProvider>(
                                                                context,
                                                                listen: false)
                                                            .liked[index]
                                                        ["provider"] ==
                                                    null
                                                ? "https://w.wallhaven.cc/full/${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["id"].toString().substring(0, 2)}/wallhaven-${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["id"]}.png"
                                                : Provider.of<
                                                            FavouriteProvider>(
                                                        context,
                                                        listen: false)
                                                    .liked[index]["url"]
                                                    .toString(),
                                      ),
                                      FavouriteWallpaperButton(
                                        id: Provider.of<FavouriteProvider>(
                                                context,
                                                listen: false)
                                            .liked[index]["id"]
                                            .toString(),
                                        provider:
                                            Provider.of<FavouriteProvider>(
                                                    context,
                                                    listen: false)
                                                .liked[index]["provider"]
                                                .toString(),
                                        trash: true,
                                      ),
                                      ShareButton(
                                          id: Provider.of<FavouriteProvider>(
                                                  context,
                                                  listen: false)
                                              .liked[index]["id"]
                                              .toString(),
                                          provider:
                                              Provider.of<FavouriteProvider>(
                                                      context,
                                                      listen: false)
                                                  .liked[index]["provider"]
                                                  .toString(),
                                          url: Provider.of<FavouriteProvider>(
                                                  context,
                                                  listen: false)
                                              .liked[index]["url"]
                                              .toString(),
                                          thumbUrl:
                                              Provider.of<FavouriteProvider>(
                                                      context,
                                                      listen: false)
                                                  .liked[index]["thumb"]
                                                  .toString())
                                    ]
                              : <Widget>[
                                  DownloadButton(
                                    colorChanged: colorChanged,
                                    link: screenshotTaken
                                        ? _imageFile.path
                                        : Provider.of<FavouriteProvider>(
                                                context,
                                                listen: false)
                                            .liked[index]["url"]
                                            .toString(),
                                  ),
                                  SetWallpaperButton(
                                    colorChanged: colorChanged,
                                    url: screenshotTaken
                                        ? _imageFile.path
                                        : Provider.of<FavouriteProvider>(
                                                        context,
                                                        listen: false)
                                                    .liked[index]["provider"] ==
                                                null
                                            ? "https://w.wallhaven.cc/full/${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["id"].toString().substring(0, 2)}/wallhaven-${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["id"]}.png"
                                            : Provider.of<FavouriteProvider>(
                                                    context,
                                                    listen: false)
                                                .liked[index]["url"]
                                                .toString(),
                                  ),
                                  FavouriteWallpaperButton(
                                    id: Provider.of<FavouriteProvider>(context,
                                            listen: false)
                                        .liked[index]["id"]
                                        .toString(),
                                    provider: Provider.of<FavouriteProvider>(
                                            context,
                                            listen: false)
                                        .liked[index]["provider"]
                                        .toString(),
                                    trash: true,
                                  ),
                                  ShareButton(
                                      id: Provider.of<FavouriteProvider>(
                                              context,
                                              listen: false)
                                          .liked[index]["id"]
                                          .toString(),
                                      provider: Provider.of<FavouriteProvider>(
                                              context,
                                              listen: false)
                                          .liked[index]["provider"]
                                          .toString(),
                                      url: Provider.of<FavouriteProvider>(
                                              context,
                                              listen: false)
                                          .liked[index]["url"]
                                          .toString(),
                                      thumbUrl: Provider.of<FavouriteProvider>(
                                              context,
                                              listen: false)
                                          .liked[index]["thumb"]
                                          .toString())
                                ],
                        ),
                      ),
                    ],
                  ),
                ),
                body: Stack(
                  children: <Widget>[
                    AnimatedBuilder(
                        animation: offsetAnimation,
                        builder: (buildContext, child) {
                          if (offsetAnimation.value < 0.0) {
                            debugPrint('${offsetAnimation.value + 8.0}');
                          }
                          return GestureDetector(
                            onPanUpdate: (details) {
                              if (details.delta.dy < -10) {
                                panelController.open();
                                HapticFeedback.vibrate();
                              }
                            },
                            onLongPress: () {
                              setState(() {
                                colorChanged = false;
                              });
                              HapticFeedback.vibrate();
                              shakeController.forward(from: 0.0);
                            },
                            onTap: () {
                              HapticFeedback.vibrate();
                              !isLoading ? updateAccent() : debugPrint("");
                              shakeController.forward(from: 0.0);
                            },
                            child: CachedNetworkImage(
                              imageUrl:
                                  "https://w.wallhaven.cc/full/${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["id"].toString().substring(0, 2)}/wallhaven-${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["id"]}.jpg",
                              imageBuilder: (context, imageProvider) {
                                downloadLinkBackwards =
                                    "https://w.wallhaven.cc/full/${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["id"].toString().substring(0, 2)}/wallhaven-${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["id"]}.jpg";
                                return Screenshot(
                                  controller: screenshotController,
                                  child: Container(
                                    margin: EdgeInsets.symmetric(
                                        vertical: offsetAnimation.value * 1.25,
                                        horizontal: offsetAnimation.value / 2),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                          offsetAnimation.value),
                                      image: DecorationImage(
                                        colorFilter: colorChanged
                                            ? ColorFilter.mode(
                                                accent, BlendMode.hue)
                                            : null,
                                        image: imageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              progressIndicatorBuilder:
                                  (context, url, downloadProgress) => Stack(
                                children: <Widget>[
                                  const SizedBox.expand(child: Text("")),
                                  Center(
                                    child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation(
                                          config.Colors().mainAccentColor(1),
                                        ),
                                        value: downloadProgress.progress),
                                  ),
                                ],
                              ),
                              errorWidget: (context, url, error) =>
                                  CachedNetworkImage(
                                imageUrl:
                                    "https://w.wallhaven.cc/full/${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["id"].toString().substring(0, 2)}/wallhaven-${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["id"]}.png",
                                imageBuilder: (context, imageProvider) {
                                  downloadLinkBackwards =
                                      "https://w.wallhaven.cc/full/${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["id"].toString().substring(0, 2)}/wallhaven-${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["id"]}.png";
                                  return Screenshot(
                                    controller: screenshotController,
                                    child: Container(
                                      margin: EdgeInsets.symmetric(
                                          vertical:
                                              offsetAnimation.value * 1.25,
                                          horizontal:
                                              offsetAnimation.value / 2),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            offsetAnimation.value),
                                        image: DecorationImage(
                                          colorFilter: colorChanged
                                              ? ColorFilter.mode(
                                                  accent, BlendMode.hue)
                                              : null,
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                progressIndicatorBuilder:
                                    (context, url, downloadProgress) => Center(
                                  child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation(
                                        config.Colors().mainAccentColor(1),
                                      ),
                                      value: downloadProgress.progress),
                                ),
                                errorWidget: (context, url, error) => Center(
                                  child: Icon(
                                    JamIcons.close_circle_f,
                                    color: isLoading
                                        ? Theme.of(context).accentColor
                                        : accent.computeLuminance() > 0.5
                                            ? Colors.black
                                            : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IconButton(
                          onPressed: () {
                            navStack.removeLast();
                            debugPrint(navStack.toString());
                            Navigator.pop(context);
                          },
                          color: isLoading
                              ? Theme.of(context).accentColor
                              : accent.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                          icon: const Icon(
                            JamIcons.chevron_left,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IconButton(
                          onPressed: () {
                            final link =
                                "https://w.wallhaven.cc/full/${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["id"].toString().substring(0, 2)}/wallhaven-${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["id"]}.${Provider.of<FavouriteProvider>(context, listen: false).liked[index]["thumb"].toString().substring(Provider.of<FavouriteProvider>(context, listen: false).liked[index]["thumb"].toString().length - 3, Provider.of<FavouriteProvider>(context, listen: false).liked[index]["thumb"].toString().length)}";
                            Navigator.push(
                                context,
                                PageRouteBuilder(
                                    transitionDuration:
                                        const Duration(milliseconds: 300),
                                    pageBuilder: (context, animation,
                                        secondaryAnimation) {
                                      animation = Tween(begin: 0.0, end: 1.0)
                                          .animate(animation);
                                      return FadeTransition(
                                          opacity: animation,
                                          child: ClockOverlay(
                                            colorChanged: colorChanged,
                                            accent: accent,
                                            link: link,
                                            file: false,
                                          ));
                                    },
                                    fullscreenDialog: true,
                                    opaque: false));
                          },
                          color: isLoading
                              ? Theme.of(context).accentColor
                              : accent.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                          icon: const Icon(
                            JamIcons.clock,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
