---
title: 计算textview文本行数
date: 2019-02-20
categories: Android UI
author: Ye YongTao
tags:
    - TexView
cover_picture: /images/dog.jpeg
---

![](/images/dog.jpeg)

通过 **ViewTreeObserver** 来计算 **TextView** 当前内容所占的行数。


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


