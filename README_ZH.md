Language: [English](README.md) | [中文简体](README-ZH.md)

# 什么是Url Navigator?
Url Navigator是一个基于Flutter Navigator2.0的路由框架，它的特色如下：

1. Url跳转: 在Url Navigator中, 所有的页面跳转都是基于Url的, 无论你身处哪个页面，无论你想跳到哪个页面(即使这个页面可能是一个子路由), 你只需要把正确的Url地址交给Url Navigator, 剩下的它帮你搞定

2. 更好的Web体验: 因为所有的页面跳转都是基于Url的, 使用Url Navigator的Flutter App在浏览器里可以有着更好的表现, 包括响应浏览器的前进、后退、刷新以及通过浏览器的Url栏直接输入Url进行跳转等

当然, 目前的Url Navigator还不是很完善。比如目前尚未完全支持相对路径跳转, 对浏览器搜索栏的支持还不够完善等, 我会在后面对它进行进一步的完善。

由于自己只是一个经验尚浅的在校学生(虽然快毕业了吧), 难免有一些实现的地方不够优雅或者存在隐患。如果大家有希望和我合作开发此package的想法, 欢迎通过QQ101425129或者邮箱jkouulong@qq.com和我联系。

下面是简单的使用Url Navigator的步骤, 更多细节请参考example工程.

# Url Navigator的使用

## 构造页面树节点

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

## 构造页面树

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

## 创建Router并监听节点缓存池

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

## 使用Url跳转页面
所有的UrlDelegate都可以处理任意级别的url跳转, 同时Url Navigator也支持在浏览器中直接输入url跳转, 跳转寻址方式有绝对绝对路径和相对路径两种方式。
目前, 使用Url Navigator进行url跳转需要遵循下面几条原则:

1. 同级别路由跳转使用绝对路径时只使用本级别下的绝对路径。如app/main/list/list_page跳转到app/main/list/list_page/list_detail_page, 其中app/main/list是根路由, list_page和list_page/list_detail_page是字路由全路径, 那么应该push 'list_page/list_detail_page'
2. 相对路径只用来在一层路由跳转, ./a_page/../b_page是不允许的

因为Url Navigator对多路由下对支持并不是很完美, 在后面完善后规则会逐渐放宽至没有

### 绝对路径跳转
绝对路径跳转很简单, 只需要输入全路径即可, 比如下面的例子：

```dart

UrlDelegate.of(context).pushReplace('app/main/enter_setting');

```

多级路由跳转：
下面的情景是从根路由页面app/main/enter_setting页面跳转到根路由页面app/main/list, app/main/list页面包含字路由list_page/list_detail_page。请确保所有的页面路径都对应[PageTreeNode]

```dart

UrlDelegate.of(context).push('app/main/list/list_page/list_detail_page', parameters: {'name': 'jack'});

```

### 相对路径跳转
相对路径跳转目前只支持单级路由跳转。比如app/setting/seting_page跳转到app/setting/setting_page/edit_setting_page可以写为:

```dart

UrlDelegate.of(context).push('page:./edit_setting_page'); // 'page' is the name of the tree which you want to user relative path

```

再次强调, 多级相对路径比如./a_page/./b_page是不支持的(一般来说也不会有这种场景)

