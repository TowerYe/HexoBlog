---
title: Java 和 Kotlin 中的单例模式
date: 2019-04-25
categories: 设计模式
author: Ye YongTao
tags:
    - Singleton
    - kotlin
cover_picture: /images/posts/singleton/cover.png
---

![](/images/posts/singleton/singleton.png)

&emsp;&emsp;**单例模式（Singleton Pattern）**是 Java 中最简单的设计模式之一，属于创建型模式。这种模式涉及到一个单一的类，该类负责创建自己的对象，同时确保只有单个对象被创建。这个类提供了一种访问其唯一的对象的方式，可以直接访问，不需要实例化该类的对象。
注意：

* 单例类只能有一个实例。
* 单例类必须自己创建自己的唯一实例。
* 单例类必须给所有其他对象提供这一实例。

##一、Java实现单例模式

###1.1 懒汉式（线程不安全）

| 是否懒加载 | 是否线程安全 | 描述  |
| --- | --- | --- |
|  是  | 否 | 这种方式是最基本的实现方式，这种实现最大的问题就是不支持多线程。因为没有加锁 synchronized，所以严格意义上它并不算单例模式。这种方式 lazy loading 很明显，不要求线程安全，在多线程不能正常工作。 |

**实现方式：**

```java
public class Singleton {
    private static Singleton instance;
    
    private Singleton() {
    }
    
    public static Singleton getInstance() {
        if (instance == null) {
            instance = new Singleton();
        }
        return instance;
    }
}
```

###1.2 懒汉式（线程安全）

| 是否懒加载 | 是否线程安全 | 描述  |
| --- | --- | --- |
|  是  | 是 | 这种方式具备很好的 lazy loading，能够在多线程中很好的工作，但是，效率很低，99% 情况下不需要同步。优点：第一次调用才初始化，避免内存浪费。缺点：必须加锁 synchronized 才能保证单例，但加锁会影响效率。 |

**实现方式**

```java
public class Singleton {
    private static Singleton instance;

    private Singleton() {
    }

    public static synchronized Singleton getInstance() {
        if (instance == null) {
            instance = new Singleton();
        }
        return instance;
    }
}
```

###1.3 饿汉式（线程安全）

| 是否懒加载 | 是否线程安全 | 描述  |
| --- | --- | --- |
|  否  | 是 | 这种方式比较常用，但容易产生垃圾对象。优点：没有加锁，执行效率会提高。缺点：类加载时就初始化，浪费内存。|

&emsp;&emsp;它基于 classloader 机制避免了多线程的同步问题，不过，instance 在类装载时就实例化，虽然导致类装载的原因有很多种，在单例模式中大多数都是调用 getInstance 方法， 但是也不能确定有其他的方式（或者其他的静态方法）导致类装载，这时候初始化 instance 显然没有达到 lazy loading 的效果。 

**实现方式**

```java
public class Singleton {
    private static Singleton instance = new Singleton();

    private Singleton() {
    }

    public static Singleton getInstance() {
        return instance;
    }
}
```

###1.4 双检锁/双重校验锁（DCL，即 double-checked locking）（线程安全）

| 是否懒加载 | 是否线程安全 | 描述  |
| --- | --- | --- |
|  是  | 是 | 这种方式采用双锁机制，安全且在多线程情况下能保持高性能。但是 JDK 版本需要在 1.5 及其以上 |

**实现方式**

```java
public class Singleton {
    private volatile static Singleton singleton;

    private Singleton() {
    }

    public static Singleton getSingleton() {
        if (singleton == null) {
            synchronized (Singleton.class) {
                if (singleton == null) {
                    singleton = new Singleton();
                }
            }
        }
        return singleton;
    }
}
```

###1.5 登记式/静态内部类（线程安全）

| 是否懒加载 | 是否线程安全 | 描述  |
| --- | --- | --- |
|  是  | 是 | 由于静态内部类SingletonHolder只有在getInstance()方法第一次被调用时，才会被加载，而且构造函数为private，因此该种方式实现了懒汉式的单例模式。不仅如此，根据JVM本身机制，静态内部类的加载已经实现了线程安全。所以给大家推荐这种写法。|

&emsp;&emsp;这种方式同样利用了 classloader 机制来保证初始化 instance 时只有一个线程，它跟第 3 种方式不同的是：第 3 种方式只要 Singleton 类被装载了，那么 instance 就会被实例化（没有达到 lazy loading 效果），而这种方式是 Singleton 类被装载了，instance 不一定被初始化。因为 SingletonHolder 类没有被主动使用，只有通过显式调用 getInstance 方法时，才会显式装载 SingletonHolder 类，从而实例化 instance。想象一下，如果实例化 instance 很消耗资源，所以想让它延迟加载，另外一方面，又不希望在 Singleton 类加载时就实例化，因为不能确保 Singleton 类还可能在其他的地方被主动使用从而被加载，那么这个时候实例化 instance 显然是不合适的。这个时候，这种方式相比第 3 种方式就显得很合理。

**实现方式**

```java
public class Singleton {
    private static class SingletonHolder {
        private static final Singleton INSTANCE = new Singleton();
    }

    private Singleton() {
    }

    public static final Singleton getInstance() {
        return SingletonHolder.INSTANCE;
    }
}
```

###1.6 枚举（线程安全）

| 是否懒加载 | 是否线程安全 | 描述  |
| --- | --- | --- |
|  否  | 是 | 这种实现方式还没有被广泛采用，但这是实现单例模式的最佳方法。它更简洁，自动支持序列化机制，绝对防止多次实例化。但是 JDK 版本需要在 1.5 及其以上 |

&emsp;&emsp;这种方式是 Effective Java 作者 Josh Bloch 提倡的方式，它不仅能避免多线程同步问题，而且还自动支持序列化机制，防止反序列化重新创建新的对象，绝对防止多次实例化。不过，由于 JDK1.5 之后才加入 enum 特性，用这种方式写不免让人感觉生疏，在实际工作中，也很少用。并且不能通过 reflection attack 来调用私有构造方法。

**实现方式**

```java
public enum Singleton {
    INSTANCE;
}
```

* 枚举类实现其实省略了private类型的构造函数。
*  枚举类的域(field)其实是相应的enum类型的一个实例对象

&emsp;&emsp;对于第一点实际上enum内部是如下代码:

```java
public enum Singleton {
    INSTANCE;
    // 这里隐藏了一个空的私有构造方法
    private Singleton () {}
}
```

&emsp;&emsp;对于一个标准的enum单例模式，最优秀的写法还是实现接口的形式:


```java
// 定义单例模式中需要完成的代码逻辑
public interface ISingleton {
    void doSomething();
}

public enum Singleton implements ISingleton {
    INSTANCE {
        @Override
        public void doSomething() {
            System.out.println("complete singleton");
        }
    };

    public static ISingleton getInstance() {
        return Singleton.INSTANCE;
    }
}
```

|  实现方式  | 是否懒加载 | 是否线程安全 |
| --- | --- | --- |
|懒汉式（线程不安全）|  是  | 否 |
|懒汉式（线程安全）|  是  | 是 |
|饿汉式|  否  | 是 |
|双检锁/双重校验锁（DCL，即 double-checked locking）|  是  | 是 |
|登记式/静态内部类|  是  | 是 |
|枚举|  否  | 是 |

&emsp;&emsp;一般情况下，不建议使用第 1 种和第 2 种懒汉方式，建议使用第 3 种饿汉方式。只有在要明确实现 lazy loading 效果时，才会使用第 5 种方式。如果涉及到反序列化创建对象时，可以尝试使用第 6 种枚举方式。如果有其他特殊的需求，可以考虑使用第 4 种双检锁方式。

##二、Kotlin实现单例模式

&emsp;&emsp;在前面提到的 Java 中实现单例模式的方式，将其翻译成 Kotlin 就是 Kotlin 的单例实现了，但是这样用 Java 的方法去显得有些多余和不舒服，因为，Kotlin 中有现成的单例可以用 —— **Object**。

###2.1 饿汉式

**实现方式**

```java
object Singleton {
}
```

&emsp;&emsp;Kotlin 中 **Object** 关键字就是一个饿汉式的单例模式，比起 Java 的一堆代码，可以说是实现起来方便了很多，在  Android Studio 中查看对应的 Kotlin Bytecode，可以看到如下代码：

```java
public final class Singleton {
   public static final Singleton INSTANCE;

   private Singleton() {
      INSTANCE = (SingletonKt)this;
   }

   static {
      new SingletonKt();
   }
}
```

&emsp;&emsp;这就意味着 Kotlin 通过 `Object` 关键字，帮我们实现了饿汉式单例的相关逻辑。

###2.2 双检锁/双重校验锁（DCL，即 double-checked locking）

**实现方式**

```java
class Singleton private constructor() {
    companion object {
        val instance: Singleton by lazy(mode = LazyThreadSafetyMode.SYNCHRONIZED) {
            Singleton()
        }
    }
}
```

&emsp;&emsp;其中 `mode = LazyThreadSafetyMode.SYNCHRONIZED` 是可以直接省略掉的，因为 lazy 默认的模式就是 `LazyThreadSafetyMode.SYNCHRONIZED`

```java
class Singleton private constructor() {
    companion object {
        val instance: Singleton by lazy() {
            Singleton()
        }
    }
}
```

&emsp;&emsp;和 Java 的代码相比也是简洁了很多，这里主要是利用了 Kotlin 中的延迟属性 —— **[Lazy](https://www.kotlincn.net/docs/reference/delegated-properties.html)**，它的参数是一个 **[lambda](https://www.kotlincn.net/docs/reference/lambdas.html)**，可以调用它来初始化这个值，然后会返回一个 Lazy 实例的函数，返回的实例可以作为实现延迟属性的委托。第一次调用会执行已传递给 lazy( ) 的 lambda 表达式并记录结果， 后续调用只是返回记录的结果。Lazy 具体的内部实现代码如下：


```java
private class SynchronizedLazyImpl<out T>(initializer: () -> T, lock: Any? = null) : Lazy<T>, Serializable {
    private var initializer: (() -> T)? = initializer
    @Volatile private var _value: Any? = UNINITIALIZED_VALUE
    // final field is required to enable safe publication of constructed instance
    private val lock = lock ?: this

    override val value: T
        get() {
            val _v1 = _value
            if (_v1 !== UNINITIALIZED_VALUE) {
                @Suppress("UNCHECKED_CAST")
                return _v1 as T
            }

            return synchronized(lock) {
                val _v2 = _value
                if (_v2 !== UNINITIALIZED_VALUE) {
                    @Suppress("UNCHECKED_CAST") (_v2 as T)
                }
                else {
                    val typedValue = initializer!!()
                    _value = typedValue
                    initializer = null
                    typedValue
                }
            }
        }

    override fun isInitialized(): Boolean = _value !== UNINITIALIZED_VALUE

    override fun toString(): String = if (isInitialized()) value.toString() else "Lazy value not initialized yet."

    private fun writeReplace(): Any = InitializedLazyImpl(value)
}
```
&emsp;&emsp;通过 `value` 的 `get()` 的方法可以很清楚的看到，通过 `UNINITIALIZED_VALUE` 的值来进行不同的操作，值为 true 表示已经延迟实例化过了，false 表示没有被实例化。一旦`UNINITIALIZED_VALUE` 的值变为 true，则会一直保持为 true，所以类不会再继续实例化。这与 Java 的双重校验锁模式的逻辑是一样的。

##三、带参数的单例模式

&emsp;&emsp;最近在把以前的 Java 代码转换成 Kotlin 时，遇到了类似如下带参的单例模式：

```java
private static volatile Singleton instance;
    
    private Singleton(Context context){
        this.context = context
    }
    
    public static Singleton getInstance(Context context) {
        if (null == instance) {
            synchronized (Singleton) {
                if (null == instance) {
                    instance = new Singleton(context);
                }
            }
        }
        return instance;
    }
```

&emsp;&emsp;最开始想的是直接 Object 改写这个类，省去双重校验锁的那堆代码，然后发现有参数，但是刚好 Object 修饰的类构造方法是私有的，这下就GG了。然后又将其转换成 **2.2 节** 中的 Kotlin 实现双重校验锁的方式，也是不能传参数，所以就没有然后了。 最后没想到其他方法，就只好强行将这段 Java 代码翻译成 Kotlin，得到如下代码：

```java
class Singleton private constructor(context: Context) {

    companion object {
        @Volatile
        private var instance: Singleton? = null

        fun getInstance(context: Context): Singleton {
            if (instance == null) {
                synchronized(Singleton::class) {
                    if (instance == null) {
                        instance = Singleton(context)
                    }
                }
            }
            return instance!!
        }
    }
}
```

&emsp;&emsp;这就是根据 Java 代码的方式翻译成了 Kotlin，虽然实现了对应的功能，但是并没有体现出 Kotlin 的思想，于是就又在网上一顿乱搜，终于找到了用 Kotlin 的思想来实现这个问题 （[Kotlin singletons with argument](https://medium.com/@BladeCoder/kotlin-singletons-with-argument-194ef06edd9e)，需翻墙），具体如下：

```java
// T -> 具体的单例类，A -> 参数类型
open class SingletonHolder<out T, in A>(private val creator: A.() -> T) {

    private var instance: T? = null

    fun getInstance(arg: A): T =
            instance ?: synchronized(this) {
                instance ?: creator(arg).apply { instance = this }
            }
}

class Singleton private constructor(context: Context) {

    companion object : SingletonHolder<Singleton, Context>(::Singleton) {
    }
}
```

&emsp;&emsp;构建一个 `SingletonHolder` 类作为单例类伴随对象的基类，以便在单例类上重用并自动公开其 `getInstance()` 函数。`SingletonHolder` 类构造方法中的 `creator` 参数，它是一个函数类型，作为一个函数引用的依赖交给构造器。比如：上面列子的 `creator` 就是 `Singleton` 类的构造函数，也就是伴随对象中的 `::Singleton`。
&emsp;&emsp;`SingletonHolder` 入参均是 **[泛型](https://www.kotlincn.net/docs/reference/generics.html)** ，并不限制传入的单例类和参数类型，所以该类是通用的，凡是需要传递参数的单例模式，只需将单例类的伴随对象继承于 `SingletonHolder`，然后传入当前的单例类和参数类型即可，避免了直接翻译成 Kotlin 代码那种方式还需要在每个单例类中写重复的代码。目前 `SingletonHolder` 只支持一个参数，如果是有多个参数，可以采用 `Pair<>` 或者 `Triple<>` 来实现。



