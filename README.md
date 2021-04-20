# 什么是Url Navigator?
Url Navigator是一个基于Flutter Navigator2.0的路由框架，它的特色如下：

1. Url跳转: 在Url Navigator中, 所有的页面跳转都是基于Url的, 无论你身处哪个页面，无论你想跳到哪个页面(即使这个页面可能是一个子路由), 你只需要把正确的Url地址交给Url Navigator, 剩下的它帮你搞定

2. 更好的Web体验: 因为所有的页面跳转都是基于Url的, 使用Url Navigator的Flutter App在浏览器里可以有着更好的表现, 包括响应浏览器的前进、后退、刷新以及通过浏览器的Url栏直接输入Url进行跳转等

当然, 目前的Url Navigator还不是很完善。比如目前尚未完全支持相对路径跳转, 对浏览器搜索栏的支持还不够完善(现在虽然你可以输入一个包含子路由的Url并成功跳转到对应页面, 但是跳转成功后浏览器的搜索栏只会显示根路由的Url, 这意味着刷新页面时只会进入子路由的默认页面)等, 我会在后面对它进行进一步的完善。

由于自己只是一个经验尚浅的在校学生(虽然快毕业了吧), 难免有一些实现的地方不够优雅或者存在隐患。如果大家有希望和我合作开发此package的想法, 欢迎通过QQ101425129或者邮箱jkouulong@qq.com和我联系。

下面是简单的使用Url Navigator的步骤, 更多细节请参考example工程.

# Url Navigator的使用

## 构造页面树节点

```dart
class ListPageNode extends PageTreeNode {
  ListPageNode()
      : super(
          name: 'list_page',
          builder: (key, name, parameters) =>
              ListPage(key: key, name: name, parameters: parameters),
        );
}

class ListPage extends SimpleUrlPage {
  ListPage({Key key, String name, Map<String, String> parameters})
      : super(
          key: key,
          name: name,
          parameters: parameters,
          builder: (context) => ListPageWidget(),
        );
}

class ListPageWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(10),
      children: [
        ConstrainedBox(
          constraints: BoxConstraints.tight(Size(200, 40)),
          child: ElevatedButton(
            onPressed: () {
              UrlDelegate.of(context).push('list_page/list_detail_page',
                  parameters: {'name': 'alpha'});
            },
            child: Text('alpha'),
          ),
        ),
        SizedBox(
          height: 20,
        ),
        ConstrainedBox(
          constraints: BoxConstraints.tight(Size(200, 40)),
          child: ElevatedButton(
            onPressed: () {
              UrlDelegate.of(context).push('list_page/list_detail_page',
                  parameters: {'name': 'beta'});
            },
            child: Text('beta'),
          ),
        ),
        SizedBox(
          height: 20,
        ),
        ConstrainedBox(
          constraints: BoxConstraints.tight(Size(200, 40)),
          child: ElevatedButton(
            onPressed: () {
              UrlDelegate.of(context).push('app/setting_page');
            },
            child: Text('setting_page'),
          ),
        ),
      ],
    );
  }
}

```

## 构造页面树

```dart
void main() {
  FolderTreeNode appRoot = FolderTreeNode(name: 'app');
  appRoot.addChild(LoginPageNode());
  MainFolderNode mainFolderNode = MainFolderNode();
  mainFolderNode.addChild(MainSettingPageNode());
  mainFolderNode.addChild(MainListPageNode());
  appRoot.addChild(mainFolderNode);
  SettingPageNode settingPageNode = SettingPageNode();
  settingPageNode.addChild(EditSettingPageNode());
  appRoot.addChild(settingPageNode);
  PageTree rootTree = PageTree('app', appRoot);

  PageTreeNode listRoot = ListPageNode();
  listRoot.addChild(ListDetailPageNode());
  PageTree listTree = PageTree('list', listRoot);

  PageTreeInspector.instance.addTree(rootTree);
  PageTreeInspector.instance.addTree(listTree);

  runApp(MyApp());
}

```

## 创建Router并监听节点缓存池

```dart
class MyAppState extends State<MyApp> {
  RootUrlDelegate delegate;

  @override
  void initState() {
    delegate = RootUrlDelegate(treeName: 'app');
    delegate.addAnonymousPageBuilder({
      'toast': (parameters) => PopupBoxRoute(
              child: MainToastWidget(
            message: parameters['message'],
          )),
      'pop_up': (parameters) => PopupBoxRoute(child: MainPopUpWidget()),
    });

    TreeNodeCache.instance.addListener(delegate);
    super.initState();
  }

  @override
  void dispose() {
    TreeNodeCache.instance.removeListener(delegate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routeInformationParser: UrlParser('app/login_page'),
      routerDelegate: delegate,
    );
  }
}

```

## 使用Url跳转页面

```

UrlDelegate.of(context).push(
                          'app/main/list/list_page/list_detail_page',
                          parameters: {'name': 'jack'});

```
