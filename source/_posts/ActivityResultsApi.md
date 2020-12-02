---
title: onActivityResult 退位让贤 Activity Results API
author: Ye YongTao
tags:
  - Activity
  - New Api
date: 2020-12-02
categories: Activity
cover_picture: /images/posts/activity_result_api/cover.png
---

![](/images/posts/activity_result_api/pic.png)

## 背景

在日常开发中，我们经常会遇到这么一个场景，从 A 页面跳转到 B 页面，在 B 页面一顿操作后，返回到 A 页面，并传回相应的数据。此时，我们毫不犹豫的就会想到 onActivityResult，姿势如下：

```kotlin
// A 跳转到 B
val intent = Intent(this, B:class.java)
startActivityForResult(intent, REQUEST_CODE)

// A 在 onActivityResult 回调中接收 B 返回的数据
override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    super.onActivityResult(requestCode, resultCode, data)
    when (requestCode) {
        REQUEST_CODE -> if (resultCode == Activity.RESULT_OK) 
        ...
    }
}
```

这种方式在安卓里面沿用了很久，除了用于页面跳转，还可以用以申请安卓系统权限，比如：

```kotlin
// 申请日历相关权限
requestPermissions(arrayOf(READ_CALENDAR, WRITE_CALENDAR), 123)

// 在 onRequestPermissionsResult 回调中处理权限
override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    if (requestCode == 123) {
        ...
    } else {
        ...
    }
}
```

这种方式虽然能够满足大家的需求，但是随着业务的增加，所有的逻辑都耦合在回调里了，与此同时，为了区分是哪个业务的返回结果，我们还得额外定义一堆的 REQUEST_CODE，这往往会造成一个问题，我在 A 页面开发的好好的，突然要跳转到 B 页面去获取相关数据，然后又要把数据传回到 A 页面，这个时候写着写着就会突然懵逼，A 页面定义的 REQUEST_CODE 是多少了？？？

>onActivityResult 这种方式存在的问题：
>
    1、回调中耦合严重，不易于后期维护；
    2、REQUEST_CODE 太多，容易搞混；

## RxActivityResult 和 RxPermissions

### RxActivityResult

[RxActivityResult](git@github.com:VictorAlbertos/RxActivityResult.git)  这个库顾名思义，就是用 Rx 事件流来代替 startActivityForResult 这一套流程，具体用法如下：

```java
RxActivityResult.on(this)
                .startIntent(new Intent(this, B.class))//请求result
                .map(result -> result.data())//对result的处理，转换为intent
                .subscribe(intent -> showResultIntentData(intent));//处理数据结果
```

通过链式的调用，就完成了从 A 页面跳转到 B 页面，并最终在 subscribe 中得到了 B 页面返回的 intent 数据，省去了烦人的 REQUEST_CODE 和 onActivityResult 回调。

查看其源码，之所以变方便了，是因为 RxActivityResult 这个库帮我们实现了 REQUEST_CODE 和 onActivityResult 的相关操作，所以我们无需在业务层像之前那样去写模板代码。在调用 startIntent 方法时，其内部会跳转到一个叫做 HolderActivity  的页面里，在这个 Activity 中还是通过传统的 startActivityForResult 和 onActivityResult 进行数据的传递，然后再把得到的数据通过 RX 流事件返回到了上层，其代码如下：

```java
// RxActivityResult 部分源码

public Observable<Result<T>> startIntent(final Intent intent) {
            return startIntent(intent, null);
}

public Observable<Result<T>> startIntent(final Intent intent, @Nullable OnPreResult onPreResult) {
            return startHolderActivity(new Request(intent), onPreResult);
}

private Observable<Result<T>> startHolderActivity(Request request, @Nullable OnPreResult onPreResult) {
       
       ...
       
       activitiesLifecycle.getOLiveActivity().subscribe(new Consumer<Activity>() {
           @Override
           public void accept(Activity activity) throws Exception {
                // 这里就是从当前页面跳转到 HolderActivity 页面中
                activity.startActivity(new Intent(activity, HolderActivity.class)
                       .addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION));
       }
   });

   return subject;
}

// HolderActivity 部分源码

@Override
protected void onCreate(Bundle savedInstanceState) {
   super.onCreate(savedInstanceState);
   
   ...

  try {
      // 跳转到 B 页面
      startActivityForResult(request.intent(), 0);
  } catch (ActivityNotFoundException e) {
      if (onResult != null) {
          onResult.error(e);
      }
  }

    ...

}

@Override
protected void onActivityResult(int requestCode, int resultCode, Intent data) {
   super.onActivityResult(requestCode, resultCode, data);
   this.resultCode = resultCode;
   this.requestCode = requestCode;
   this.data = data;

   if (this.onPreResult != null) {
       this.onPreResult.response(requestCode, resultCode, data)
               .doOnComplete(new Action() {
                   @Override
                   public void run() throws Exception {
                       finish();
                   }
               })
               .subscribe();
   } else {
       finish();
   }
}
```

### RxPermissions

[RxPermissions](git@github.com:tbruyelle/RxPermissions.git) 这个库则是用来获取安卓系统权限的，可以不用处理的权限请求的结果回调 onRequestPermissionsResult() 方法，其用法如下：

```kotlin
RxPermissions(this)
    .request(Manifest.permission.RECORD_AUDIO, Manifest.permission.WRITE_EXTERNAL_STORAGE)
    .subscribe({isGranted ->
            if (isGranted) {
                // 权限被授予
            } else {
                // 权限未被授予
            }) {
                // 异常
            }
}
```

使用方式也是很简单，和 RxActivityResult 一样，直接在 RX 流事件中得到了权限申请的结果，一步到位，没有多余的 REQUEST_CODE 和回调。之所以这么方便，也是得益于 RxPermissions 库在内部帮我们把 REQUEST_CODE 和 onRequestPermissionsResult 这一套逻辑实现了，其核心思想是，通过一个 Fragment 来进行相关权限的申请，再通过 RX 流事件将结果发送到上层，其代码如下：

```java
private RxPermissionsFragment getRxPermissionsFragment(@NonNull final FragmentManager fragmentManager) {
        // 查询fragment是否已经创建过
        RxPermissionsFragment rxPermissionsFragment = findRxPermissionsFragment(fragmentManager);
        boolean isNewInstance = rxPermissionsFragment == null;
        // 如果之前未创建fragment，new 一个新的 RxPermissionsFragment
        if (isNewInstance) {
            rxPermissionsFragment = new RxPermissionsFragment();
            fragmentManager
                    .beginTransaction()
                    .add(rxPermissionsFragment, TAG)
                    .commitNow();
        }
        return rxPermissionsFragment;
    }
```
当调用了 RxPermissions(this) 后，就会在当前页面添加一个 RxPermissionsFragment 实例。然后在调用 request 方法时，会通过 ensure 方法去检测待申请的权限：

```
public Observable<Boolean> request(final String... permissions) {
        return Observable.just(TRIGGER).compose(ensure(permissions));
}

/**
* Map emitted items from the source observable into {@code true} if permissions in parameters
* are granted, or {@code false} if not.
* <p>
* If one or several permissions have never been requested, invoke the related framework method
* to ask the user if he allows the permissions.
*/
@SuppressWarnings("WeakerAccess")
public <T> ObservableTransformer<T, Boolean> ensure(final String... permissions) {
   return new ObservableTransformer<T, Boolean>() {
       @Override
       public ObservableSource<Boolean> apply(Observable<T> o) {
           return request(o, permissions)
                   // Transform Observable<Permission> to Observable<Boolean>
                   .buffer(permissions.length)
                   .flatMap(new Function<List<Permission>, ObservableSource<Boolean>>() {
                       @Override
                       public ObservableSource<Boolean> apply(List<Permission> permissions) {
                            if (permissions.isEmpty()) {
                                    return Observable.empty();
                                }
                                // Return true if all permissions are granted.
                                for (Permission p : permissions) {
                                    if (!p.granted) {
                                        return Observable.just(false);
                                    }
                                }
                                return Observable.just(true);        
                       }
                   });
       }
   };
}
```

在 ensure 方法中会返回一个 ObservableTransformer 对象，在其 apply() 方法中，又调用了 request() 方法，然后使用buffer 操作符缓存所有的请求结果，并在 flatMap 操作符中将结果转换为 Boolean 类型，如果所有的权限都授权成功则返回 true，否则返回 false。而 request 方法最终会调用到 requestImplementation 方法中，具体代码如下：

```java
private Observable<Permission> requestImplementation(final String... permissions) {
   
   ...
   
   // 如果有未申请的权限，去 fragment 中申请
   if (!unrequestedPermissions.isEmpty()) {
       String[] unrequestedPermissionsArray = unrequestedPermissions.toArray(new String[unrequestedPermissions.size()]);
       requestPermissionsFromFragment(unrequestedPermissionsArray);
   }
   
   ...
   
}
```

requestPermissionsFromFragment 代码如下：

```java
void requestPermissionsFromFragment(String[] permissions) {
        mRxPermissionsFragment.get().log("requestPermissionsFromFragment " + TextUtils.join(", ", permissions));
        mRxPermissionsFragment.get().requestPermissions(permissions);
}
```

这里就会通过 mRxPermissionsFragment 来进行相关权限的申请，代码如下：

```java
// RxPermissionsFragment 部分源码

/**
 * 申请权限
 */
void requestPermissions(@NonNull String[] permissions) {
        requestPermissions(permissions, PERMISSIONS_REQUEST_CODE);
}

/**
 * onRequestPermissionsResult 回调获取权限授权结果
 */
public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults);

    if (requestCode != PERMISSIONS_REQUEST_CODE) return;

    boolean[] shouldShowRequestPermissionRationale = new boolean[permissions.length];

    for (int i = 0; i < permissions.length; i++) {
       shouldShowRequestPermissionRationale[i] = shouldShowRequestPermissionRationale(permissions[i]);
    }
    
    onRequestPermissionsResult(permissions, grantResults, shouldShowRequestPermissionRationale);
}
```

所以看到这里，熟悉的 REQUEST_CODE 和 onRequestPermissionsResult 回调又来了，所以不论是 RxActivityResult 还是 RxPermissions，在最后还是用的安卓原生那一套，只是这些库帮我们处理了对应的逻辑，直接将最终的结果抛回了上层，简化了我们的使用。

>通过一个无视图的 Fragment 来进行权限的申请和结果的处理，其实是很有想法和高效的，较之 Activity，
Fragment 是安卓更推荐使用的容器，它更轻量，也具有生命周期，也能直接申请权限和页面的跳转，所以才会被用到 RxActivityResult 和 RxPermissions 这两个库中来处理带结果的页面跳转和权限申请，除此之外，在 Glide 的生命周期管理中也有它的身影，ViewModel 中也能看见，足以见得 Fragment 的强大以及技术大牛们牛逼的思想，可以造出这么多厉害的轮子供大家使用。

## Activity Results API

在 androidx.activity:activity:1.2.0-alpha02 和 androidx.fragment:fragment:1.3.0-alpha02 中，已经废弃了 startActivityForResult、onActivityResult、requestPermissions 和 onRequestPermissionsResult 方法，想必是谷歌的工程师也觉得这一套太过繁琐，因此舍弃掉他们，推出了全新的 [Activity Results API](https://developer.android.com/training/basics/intents/result#kotlin) 来替代。

```java
/**
* {@inheritDoc}
*
* @deprecated use
* {@link #registerForActivityResult(ActivityResultContract, ActivityResultCallback)}
* passing in a {@link StartActivityForResult} object for the {@link ActivityResultContract}.
*/
@Override
@Deprecated
public void startActivityForResult(@SuppressLint("UnknownNullness") Intent intent,
       int requestCode) {
   super.startActivityForResult(intent, requestCode);
}

/**
* {@inheritDoc}
*
* @deprecated use
* {@link #registerForActivityResult(ActivityResultContract, ActivityResultCallback)}
* passing in a {@link StartActivityForResult} object for the {@link ActivityResultContract}.
*/
@Override
@Deprecated
public void startActivityForResult(@SuppressLint("UnknownNullness") Intent intent,
       int requestCode, @Nullable Bundle options) {
   super.startActivityForResult(intent, requestCode, options);
}
```

在安卓开发者平台上介绍到：

>位于 ComponentActivity 或 Fragment 中时，Activity Result API 会提供 prepareCall() API，用于注册结果回调。prepareCall() 接受 ActivityResultContract 和 ActivityResultCallback 作为参数，并返回 ActivityResultLauncher，供您用来启动另一个 Activity。

>ActivityResultContract 定义生成结果所需的输入类型以及结果的输出类型。这些 API 可为拍照和请求权限等基本 intent 操作提供默认协定。您还可以创建自己的自定义协定。

在最新版的

```gradle
implementation 'androidx.activity:activity-ktx:1.2.0-beta01'
implementation 'androidx.fragment:fragment-ktx:1.3.0-beta01'
``` 

prepareCall() 被命名为 registerForActivityResult()，但官网的中文文档还未更新，英文文档已更新。

先看下具体用法吧，代码如下：

```kotlin
private val myActivityLauncher =
    registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { activityResult ->
         // 接收 B 页面返回的数据
         if (activityResult.resultCode == Activity.RESULT_OK) {
            val result = activityResult.data?.getStringExtra("result")
        }
}

fun btnClick(view: View) {
    // 从 A 页面跳转到 B 页面
    val intent = Intent(this, B::class.java).apply {
            putExtra("data", "Activity Result Api Auto")
    }

    myActivityLauncher.launch(intent)
}

// B 页面返回
fun btnClick(view: View) {
   val intent = Intent().apply {
       putExtra("result", "B 页面 返回的结果")
   }
   setResult(Activity.RESULT_OK, intent)
   finish()
}
```

首先就是需要定义一个 ActivityResultLauncher 变量，然后通过 registerForActivityResult() 方法进行赋值，需注意的是该过程必须在当前页面的 START 之前，原因后面再说。

registerForActivityResult() 方法接受 2 个参数，

* 第一个参数就是我们定义的 Contract 协议， ActivityResultContract&lt;I, O>，I：输入类型，即：A 页面传入 B 页面的数据类型，O：输出类型，即：B 页面返回给 A 页面的数据类型；
* 第二个参数是一个回调 ActivityResultCallback<O>，其中 O 是 Contract 的输出类型，通过该回调就能得到页面返回的结果；

ActivityResultContracts.StartActivityForResult() 是谷歌为我们封装好的 Contract 协议，除此之外还有以下协议供开发者使用：

| 协议名称 | 协议内容 |
| --- | --- |
| StartActivityForResult | 通用的 Contract，不做任何转换，Intent 作为输入，ActivityResult 作为输出，这也是最常用的一个协定 |
| StartIntentSenderForResult | google支付 |
| RequestMultiplePermissions | 用于请求一组权限 |
| RequestPermission | 用于请求单个权限 |
| TakePicturePreview | 调用 MediaStore.ACTION_IMAGE_CAPTURE 拍照，返回值为 Bitmap 图片 |
| TakePicture | 调用 MediaStore.ACTION_IMAGE_CAPTURE 拍照，并将图片保存到给定的 Uri 地址，返回 true 表示保存成功 |
| TakeVideo | 调用 MediaStore.ACTION_VIDEO_CAPTURE 拍摄视频，保存到给定的 Uri 地址，返回一张缩略图 |
| PickContact | 从通讯录 APP 获取联系人 |
| GetContent | 提示用选择一条内容，返回一个通过 ContentResolver#openInputStream(Uri) 访问原生数据的 Uri 地址（content://形式）。默认情况下，它增加了 Intent#CATEGORY_OPENABLE, 返回可以表示流的内容 |
| CreateDocument | 提示用户选择一个文档，返回一个 (file:/http:/content:) 开头的 Uri |
| OpenMultipleDocuments | 提示用户选择文档（可以选择多个），分别返回它们的 Uri，以 List 的形式 |
| OpenDocumentTree | 提示用户选择一个目录，并返回用户选择的作为一个 Uri 返回，应用程序可以完全管理返回目录中的文档 |


registerForActivityResult() 是直接调用的 ComponentActivity 中的方法，代码如下：

```java
public final <I, O> ActivityResultLauncher<I> registerForActivityResult(
            @NonNull final ActivityResultContract<I, O> contract,
            @NonNull final ActivityResultRegistry registry,
            @NonNull final ActivityResultCallback<O> callback) {
        return registry.register(
                "activity_rq#" + mNextLocalRequestCode.getAndIncrement(), this, contract, callback);
}         
```

这里可以看到熟悉的 REQUEST_CODE 又来了，只不过不是我们自己定义的，由谷歌工程师帮我们定义了，“activity_rq#” 拼上一个自增长的 AtomicInteger，接下来看下 register 方法：

```java
public final <I, O> ActivityResultLauncher<I> register(
            @NonNull final String key,
            @NonNull final LifecycleOwner lifecycleOwner,
            @NonNull final ActivityResultContract<I, O> contract,
            @NonNull final ActivityResultCallback<O> callback) {
            
        // 得到了当前页面的生命周期
        Lifecycle lifecycle = lifecycleOwner.getLifecycle();
        
        // 这里就解释了前面提到的 ActivityResultLauncher 为什么必须要在页面 START 之前初始化
        if (lifecycle.getCurrentState().isAtLeast(Lifecycle.State.STARTED)) {
            throw new IllegalStateException("LifecycleOwner " + lifecycleOwner + " is "
                    + "attempting to register while current state is "
                    + lifecycle.getCurrentState() + ". LifecycleOwners must call register before "
                    + "they are STARTED.");
        }

        // 将传入的 key（activity_rq#0） 存入一个 HashMap 中，key 是随机数，value 是（activity_rq#0）
        final int requestCode = registerKey(key);
        mKeyToCallback.put(key, new CallbackAndContract<>(callback, contract));

        // 从缓存中获取是否已有此次启动的结果
        final ActivityResult pendingResult = mPendingResults.getParcelable(key);
        LifecycleContainer lifecycleContainer = mKeyToLifecycleContainers.get(key);
        if (lifecycleContainer == null) {
            lifecycleContainer = new LifecycleContainer(lifecycle);
        }
        // 如果有结果，且是 start 状态，则直接返回
        if (pendingResult != null) {
            mPendingResults.remove(key);
            LifecycleEventObserver observer = new LifecycleEventObserver() {
                @Override
                public void onStateChanged(
                        @NonNull LifecycleOwner lifecycleOwner,
                        @NonNull Lifecycle.Event event) {
                    // 在 START 的时候返回结果
                    if (Lifecycle.Event.ON_START.equals(event)) {
                        callback.onActivityResult(contract.parseResult(
                                pendingResult.getResultCode(),
                                pendingResult.getData()));
                    }
                }
            };
            lifecycleContainer.addObserver(observer);
            mKeyToLifecycleContainers.put(key, lifecycleContainer);
        }

        LifecycleEventObserver observer = new LifecycleEventObserver() {
            @Override
            public void onStateChanged(@NonNull LifecycleOwner lifecycleOwner,
                    @NonNull Lifecycle.Event event) {
                // DESTROY 时注销监听，避免内存泄漏
                if (Lifecycle.Event.ON_DESTROY.equals(event)) {
                    unregister(key);
                }
            }
        };
        lifecycleContainer.addObserver(observer);

        // 返回一个 ActivityResultLauncher
        return new ActivityResultLauncher<I>() {
            @Override
            public void launch(I input, @Nullable ActivityOptionsCompat options) {
                // 根据定义好的 contract 协议执行相应逻辑
                onLaunch(requestCode, contract, input, options);
            }

            @Override
            public void unregister() {
                ActivityResultRegistry.this.unregister(key);
            }

            @NonNull
            @Override
            public ActivityResultContract<I, ?> getContract() {
                return contract;
            }
        };
}
```

当 myActivityLauncher.launch(intent) 执行时，就会调用上面代码中的 onLaunch() 方法，该方法是 ActivityResultRegistry 抽象类中的一个抽象方法，具体的实现是在 ComponentActivity 类中，代码如下：

```java
private ActivityResultRegistry mActivityResultRegistry = new ActivityResultRegistry() {

   @Override
   public <I, O> void onLaunch(final int requestCode, @NonNull ActivityResultContract<I, O> contract, 
                            I input, @Nullable ActivityOptionsCompat options) {
                            
        ...
            
        if (ACTION_REQUEST_PERMISSIONS.equals(intent.getAction())) {
            // 申请权限相关逻辑
        } else if (ACTION_INTENT_SENDER_REQUEST.equals(intent.getAction())) {
           IntentSenderRequest request =
            // Google 支付  
           }
       } else {
           // startActivityForResult path
           ActivityCompat.startActivityForResult(activity, intent, requestCode, optionsBundle);
       }
   }
};
```

最后终于又看到了再熟悉不过的 ActivityCompat.startActivityForResult，那之后的结果获取不用想，肯定又会回到 onActivityResult 这个回调中了，代码如下：

```java
@Deprecated
protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        if (!mActivityResultRegistry.dispatchResult(requestCode, resultCode, data)) {
            super.onActivityResult(requestCode, resultCode, data);
        }
}
```

可以看到这个方法已经被谷歌舍弃了，但是不同于以往直接返回结果，这里的 onActivityResult 被 ActivityResultRegistry 给拦截了，看下 dispatchResult 的代码：

```java
@MainThread
public final boolean dispatchResult(int requestCode, int resultCode, @Nullable Intent data) {
   String key = mRcToKey.get(requestCode);
   if (key == null) {
       return false;
   }
   doDispatch(key, resultCode, data, mKeyToCallback.get(key));
   return true;
}
```

这里就可以看出，如果不是通过 launch 方法启动的，在 mRcToKey 的缓存中就找不到对应的 key，就会按照旧的逻辑，通过 onActivityResult 回调将结果返回，反之，则通过 doDispatch 方法返回。

```java
private <O> void doDispatch(String key, int resultCode, @Nullable Intent data,
       @Nullable CallbackAndContract<O> callbackAndContract) {
    // 这里的 callbackAndContract 即是在 registerForActivityResult 时传进来的那两个入参，如果不为空，则通过他们将结果直接返回
    if (callbackAndContract != null && callbackAndContract.mCallback != null) {
           ActivityResultCallback<O> callback = callbackAndContract.mCallback;
           ActivityResultContract<?, O> contract = callbackAndContract.mContract;
           callback.onActivityResult(contract.parseResult(resultCode, data));
    } else {
           // 为空则先将此次启动的结果缓存起来 
           mPendingResults.putParcelable(key, new ActivityResult(resultCode, data));
    }
}
```

这就是 Activity Results Api 的整个流程，不管是 RxActivityResult，还是 Activity Result Api，其最后都还是走到了传统的 startActivityForResult，然后再在 onActivityResult 中把结果拦截掉，以其他的形式回传给上层。

使用新的 Activity Result Api 获取权限，其方式也是跟页面带参跳转是一样的，这里就不再单独说明了，除了官方封装好的那些 Contrack 协议，我们也可以自定义，方式如下：

```kotlin
class MyActivityResultContract : ActivityResultContract<String, String>() {

    override fun createIntent(context: Context, input: String?): Intent {
        return Intent(context, SecondActivity::class.java).apply {
            putExtra("data", input)
        }
    }

    override fun parseResult(resultCode: Int, intent: Intent?): String? {
        val data = intent?.getStringExtra("result")
        return if (resultCode == Activity.RESULT_OK) data else "no data"
    }
}
```

方式很简单，就是继承 ActivityResultContract 类，传入 A -> B 的参数类型，以及 B -> A 的结果类型，并实现 createIntent 和 parseResult 两个方法即可，最后再在页面中传入自己定义的 ActivityResultContract 即可：

```kotlin
private val myActivityLauncher =
            registerForActivityResult(MyActivityResultContract()) { result ->
                // do something
            }

fun btnClick(view: View) {
    myActivityLauncher.launch("Activity Result Api")
}
```

## 总结

不管是 RX 的方式，还是 Activity Results Api 的方式，较之传统的 startActivityForResult 方式都简洁了不少，也减少了代码间的耦合，同时也不用再去定义一堆 REQUEST_CODE，所以还是挺好的，可以去尝试用起来。还有就是利用 Fragment 的相关特性去处理一些权限申请和生命周期管理也是一个很好的思路，可以以此进行拓展，进行更多的应用。

