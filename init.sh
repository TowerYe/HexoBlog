#!/bin/sh

npm install hexo --save

hexo clean && hexo g && hexo s
