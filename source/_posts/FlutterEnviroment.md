---
title: 在Android Studio中搭建Flutter开发环境（MAC OS）
date: 2019-02-22
categories: Flutter
author: Ye YongTao
tags:
    - Flutter
cover_picture: /images/posts/flutter_env/cover.png
---

![](/images/posts/flutter_env/flutter.png)

&emsp;&emsp;[Flutter](https://flutter.io) 是由谷歌在去年推出的一款跨平台开发框架，可以快速的在 Android、IOS 以及 Fuchsia 上构建高质量的原生用户界面，本篇文章记录了如何在 Android Studio 搭建 Flutter 的开发环境，因为我的电脑是 MAC OS，所以只记录了在 MAC OS 中的配置流程。
## 一、下载 Flutter SDK
&emsp;&emsp;Flutter SDK 的官方下载地址为：https://flutter.io/docs/development/tools/sdk/archive?tab=macos#macos ，网页里面列举了很多版本的 SDK，我自己是下载的最新的稳定版本。

![](/images/posts/flutter_env/001.jpg)

&emsp;&emsp;下载完 SDK 后，将压缩包解压到你指定的目录下，并记住该目录，后面会用到。
## 二、更新环境变量
&emsp;&emsp;解压完 Flutter SDK 后，需要将其添加到电脑的环境变量中，具体操作如下：
### 2.1 编辑 .bash_profile
1）打开你的终端或者 iTerm2，然后输入 

```bash
$ vim $HOME/.bash_profile
```
此时会弹出如下页面：

![](/images/posts/flutter_env/002.jpg)

点击键盘上的 “E” 键进入到具体的配置文件中；

2）进入到配置文件后，还不能进行编辑，将输入法切换成英文模式，然后点击键盘上的 “A” 键，此时可以进入编辑模式，输入如下指令：

```bash
export PUB_HOSTED_URL = https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL = https://storage.flutter-io.cn 
export PATH = PATH_TO_FLUTTER_GIT_DIRECTORY/flutter/bin:$PATH
```
<font color=red>注意：PATH_TO_FLUTTER_GIT_DIRECTORY 则是你解压的 Flutter SDK 所在的路径</font>

&emsp;&emsp;输入完成后，点击键盘上的 “ESC” 键，退出编辑模式，输入法保持英文模式，此时输入 “:”，再输入 “wq” 即可保存退出。

3）若要验证 Flutter 环境是否配置成功，可以输入如下命令验证：

```bash
$ echo $PATH
```

## 三、安装 Flutter 插件
&emsp;&emsp;Flutter 的环境配置好以后，就可以进入到 Android Studio 中进行 Flutter 的相关配置了，Flutter 官方文档上要求 Android Studio 的版本应该在 3.0 或以上，所以版本较低的同学需要先升级下 Android Studio。
&emsp;&emsp;Android Studio 版本符合条件后，点击插件首选项 **(Preferences -> Plugins -> Browse Repositories)**，然后在输入框中输入 “Flutter”，在搜索结果列表中选择 “**Flutter**”，并点击右侧的 “**Install**” 按钮，待安装完成再重启 Android Studio 即可生效。

![](/images/posts/flutter_env/003.jpg)

&emsp;&emsp;此时点击 **（File -> New）** 即可看到可以新建 Flutter 工程了，然后就可以开启你的 Flutter 之旅啦！！！

![](/images/posts/flutter_env/004.jpg)

&emsp;&emsp;由于自己也是第一次接触 Flutter，具体怎么开发 Flutter 还不熟悉，可以参考官网的文档，跟着 demo 练练手，附上官网教程：https://flutterchina.club/get-started/test-drive/ 。照着敲完一遍 demo 的最大感受就是，Flutter 的热重载是真的舒服，比 RN 的各种配置各种卡顿，方便流畅很多，但是整个 UI 的布局摒弃了 xml，与 RN 那种 css 也不一样，采用 widget 的形式来构建整个 UI，这又是一个全新的概念，初次接触还不是太习惯，所以还需要慢慢的去琢磨去学习。



