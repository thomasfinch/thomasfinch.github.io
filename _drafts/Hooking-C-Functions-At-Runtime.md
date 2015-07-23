---
layout: post
title:  "Hooking C Functions at Runtime"
date:   2015-07-23 12:00:00
categories: blog
---

This is a quick writeup on something I experimented with recently, runtime hooking of C functions. The basic idea is to hook specific functions within a program (that is, replace the original function implementation with your own arbitrary implementation) without modifying the original program. Runtime function hooking isn't uncommon, it's used for iOS jailbreak tweaks (powered by [Cydia Substrate](http://www.cydiasubstrate.com/) or [Substitute](https://github.com/comex/substitute)) as well as the [Xposed framework](http://repo.xposed.info/module/de.robv.android.xposed.installer) on Android.