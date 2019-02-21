---
title: 计算textview文本行数
date: 2019-02-20
categories: Android UI
author: Ye YongTao
tags:
    - TexView
cover_picture: /images/dog.jpeg
---

![](/images/cat.jpg)

&emsp;&emsp;通过 **ViewTreeObserver** 来计算 **TextView** 当前内容所占的行数，并替换指定行数的某几个字符为指定的字符。如：若当前 **TextView** 内容行数超过两行，先得到第一行文本最多能显示的字数，然后把第二行文本中的最后7个字符替换成指定的字符串，具体的代码如下：

```
ViewTreeObserver observer = observer = titleTxt.getViewTreeObserver();
observer.addOnGlobalLayoutListener(new ViewTreeObserver.OnGlobalLayoutListener() {
            @Override
            public void onGlobalLayout() {
                ViewTreeObserver obs = titleTxt.getViewTreeObserver();
                obs.removeGlobalOnLayoutListener(this);
                if (titleTxt.getLineCount() > 2) { //判断行数大于多少时改变
                    int lineEndIndex = titleTxt.getLayout().getLineEnd(1); //设置第二行打省略号
                    String text = titleTxt.getText().subSequence(0, lineEndIndex - 7) + "... \"，识别为";
                    titleTxt.setText(text);
                }
            }
        });

```


