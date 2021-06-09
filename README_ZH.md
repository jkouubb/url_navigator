Language: [English](README.md) | [中文简体](README_ZH.md)

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
  /// Declare a top folder for your page tree. Root of the tree must be [FolderTreeNode]
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
  FolderTreeNode folderTreeNode = FolderTreeNode(name: 'show_list');

  PageTreeNode listPageNode = ListPageNode();
  listPageNode.addChild(ListDetailPageNode());

  folderTreeNode.addChild(listPageNode);

  PageTree listTree = PageTree('inner', folderTreeNode);

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

   /* Each [UrlDelegate] is a [UrlListener], they observe [UrlManager], once there is a List<PageTreeNode> change from [UrlManager], they accept the new one and update themselves */
   UrlManager.addListener(delegate);

    /* RootUrlDelegate is a [UrlStackManagerObserver], it observes the url stack. Once stack updates, it updates its currentConfiguration and notify the Root Router */
    UrlStackManager.addObserver(delegate);
    super.initState();
  }

  @override
  void dispose() {

    /* Don't forget remove Delegate when the Navigator is being disposed */
    UrlManager.removeListener(delegate);
    UrlStackManager.removeObserver(delegate);

    /* When delegate is being disposed, you need to reset the cursor of the tree this delegate observes */
    PageTreeManager.instance.updateCurrentNode(delegate.treeName, null);
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

### 绝对路径跳转
绝对路径跳转很简单, 只需要输入全路径即可, 比如下面的例子：

```dart

UrlDelegate.of(context).pushReplace('app/main/enter_setting');

```

多级路由跳转：
下面的情景是从根路由页面app/main/enter_setting页面跳转到根路由页面app/main/list, app/main/list页面包含字路由list_page/list_detail_page。请确保所有的页面路径都对应[PageTreeNode]

```dart

UrlDelegate.of(context).push('app/main/list/show_list/list_page/list_detail_page', parameters: {'name': 'jack'});

```

### 相对路径跳转
相对路径跳转目前只支持单级路由跳转。比如app/setting/seting_page跳转到app/setting/setting_page/edit_setting_page可以写为:

```dart

UrlDelegate.of(context).push('page:./edit_setting_page'); // 'page' is the name of the tree which you want to user relative path

```

再次强调, 多级相对路径比如./a_page/./b_page是不支持的(一般来说也不会有这种场景)

