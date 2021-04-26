Language: [English](README.md) | [中文简体](README_ZH.md)

# What is Url Navigator?
Url Navigator is a navigation framework based on Flutter Navigator2.0. Here are its features:

1. Url Navigation: In Url Navigator, navigation is based on Url. No matter which page you current are, no matter which page you want to go(even it can be a nest navigator), all you need is passing the correct url to Url Navigator.

2. Better Web experience: Since navigation is based on Url, Flutter App in Url Navigator may perform better(I hope) on browser, including forward、backward、refresh and jumping directly with url input

Yet, Url Navigator is not so perfect as I hope, I will continue to polish it.

Since I am only a colleage student with few experience(though I will graduate in 2 months), code may not such good, if you are optimistic about this package and want to participate, please contact me through qq:1014252129 or email:jkouulong@qq.com

Here are steps to use Url Navigator, for more detail, please check example project.

# How to use Url Navigator

## Build page node

```dart
class MainListPageNode extends PageTreeNode {
  MainListPageNode()
      : super(
          name: 'list',
          routeBuilder: (settings) => NoTransitionUrlPageRoute(
            settings: settings,
            content: MainListPageWidget(),
          ),
        );
}

```

## Build page tree

```dart
void main() {
  /// Declare a top folder for your page tree.
  ///
  /// It is not necessary, you can always use a [PageTreeNode] as the root of your page tree.
  /// FolderTreeNode does nothing but organize your app page tree so your url can be meaningful
  FolderTreeNode appRoot = FolderTreeNode(name: 'app');

  /* grow your tree */
  appRoot.addChild(LoginPageNode());

  FolderTreeNode mainFolderNode = FolderTreeNode(name: 'main');
  mainFolderNode.addChild(MainListPageNode());
  mainFolderNode.addChild(MainSettingPageNode());
  appRoot.addChild(mainFolderNode);

  SettingPageNode settingPageNode = SettingPageNode();
  settingPageNode.addChild(EditSettingPageNode());
  appRoot.addChild(settingPageNode);

  /* Declare a tree with a name and a root */
  PageTree rootTree = PageTree('page', appRoot);

  /* Another tree for nest navigator */
  PageTreeNode listRoot = ListPageNode();
  listRoot.addChild(ListDetailPageNode());
  PageTree listTree = PageTree('inner', listRoot);

  /* Register trees */
  PageTreeManager.instance.addTree(rootTree);
  PageTreeManager.instance.addTree(listTree);

  runApp(MyApp());
}

```

## create router and observe cache

```dart
class MyAppState extends State<MyApp> {
  RootUrlDelegate delegate;

  @override
  void initState() {
    /* In the Root of Your app, you need to use [RootUrlDelegate] to update url on browser */
    /* Each [UrlDelegate] needs to declare the name of the tree which it cares */
    delegate = RootUrlDelegate(treeName: 'page');

    /* AnonymousPages are Routes which are not linked with [UrlPage], their url won't show. Usually, they are used as alerts in a web page  */
    delegate.addAnonymousPageBuilder({
      'toast': (parameters) => UrlPopupRoute(
              content: MainToastWidget(
            message: parameters['message'],
          )),
      'pop_up': (parameters) => UrlPopupRoute(
            content: MainPopUpWidget(),
          ),
    });

    /* Each [UrlDelegate] is a [TreeNodeCacheObserver], they observe [TreeNodeCache], once there is a page from the tree they care in [TreeNodeCache], they pick it and update themselves */
    TreeNodeCache.addObserver(delegate);

    /* RootUrlDelegate is a [UrlStackManagerObserver], it observes the url stack. Once stack updates, it updates its currentConfiguration and notify the Root Router */
    UrlStackManager.addObserver(delegate);
    super.initState();
  }

  @override
  void dispose() {

    /* Don't forget remove Delegate when the Navigator is being disposed */
    TreeNodeCache.removeObserver(delegate);
    UrlStackManager.removeObserver(delegate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routeInformationParser: UrlParser(defaultPath: 'app/login_page'),
      routerDelegate: delegate,
    );
  }
}

```

## Navigator with Url
All UrlDelegate can handle url navigation on any level of navigator. What's more, Url Navigator also supports inputing url directly on browser. You can navigate both in full path and relative path.

Currently, using Url Navigator to navigate needs to obey rules below:

1. When you are navigating the same level page with full path, make sure url is the level you are navigating. For example, when navigating app/main/list/list_page/list_detail_page from app/main/list/list_page, url should be 'list_page/list_detail_page' instead of 'app/main/list/list_page/list_detail_page'
2. When you are navigating with relative path, make sure path only involves single layer of navigator. For example, tree1:../a_page/tree2:./b_page is invalid.

In the future, Url Navigator will be more powerful and rules will disappear.

### Navigate with full path

Navigate with full path is simple, all you need is just giving the path, for example:

```dart

UrlDelegate.of(context).pushReplace('app/main/enter_setting');

```

Navigation from root navigator to a page contains nested navigator is also simple.

For example, to navigate from app/main/enter_setting in root navigator to app/main/list in root navigator, which contains a nested navigator list_page/list_detail_page:

```dart

UrlDelegate.of(context).push('app/main/list/list_page/list_detail_page', parameters: {'name': 'jack'});

```

### Navigate with relative path
Relative path navigation only supports single level currently, for example, navigate from app/setting/seting_page to app/setting/setting_page/edit_setting_page:

```dart

UrlDelegate.of(context).push('page:./edit_setting_page'); // 'page' is the name of the tree which you want to user relative path

```

再次强调, 多级相对路径比如./a_page/./b_page是不支持的(一般来说也不会有这种场景)
Remember, navigate with relative path in multiple levels(like tree1:../a_page/tree2:./b_page) is not supported currently(this occasion is rarely)

