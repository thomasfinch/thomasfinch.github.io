---
layout: post
title:  "iOS Jailbreak Tweak Development Tips"
date:   2015-05-21 12:42:37
categories: development iOS jailbreak
---

During the time I've spent developing jailbreak tweaks for iOS, I've come across plenty of small tips and tricks to make my workflow better and make development easier in general. This post is a collection of those, so other developers can benefit as well. Most are probably familiar to experienced developers, but there are new developers learning every day :) .

## General Resources
* [iPhoneDevWiki](http://iphonedevwiki.net/) - A great place for information about tweak development. Lots of technical information and guides for things like setting up a basic development environment.
* [TheiPhoneWiki](https://www.theiphonewiki.com/wiki/Main_Page) - More in-depth, technical information than the iPhoneDevWiki, mostly related to the process of jailbreaking.
* [/r/Jailbreak](http://www.reddit.com/r/jailbreak) - The main jailbreak subreddit, probably the best place for general jailbreak news.
* [/r/JailbreakDevelopers](http://www.reddit.com/r/jailbreakdevelopers) - Subreddit for jailbreak tweak developers, a good place to find help for problems you encounter during development.
* [SharedInstance](http://sharedinstance.net) - Developer-oriented jailbreak blog

## Workflow

* [Sublime-Logos](https://github.com/Cykey/Sublime-Logos) - Syntax highlighting for Logos keywords in Sublime Text
* [SSH over USB](http://iphonedevwiki.net/index.php/SSH_Over_USB) - Allows SSH'ing into a device connected through USB rather than through WiFi. This speeds up the process of deploying a new build to a device and makes development smoother in general. THEOS\_DEVICE\_IP must be set to localhost and THEOS\_DEVICE\_PORT must be set to the tunnel port (2222 by default). I have these set in my .bash\_profile rather than project makefiles since they're the same for every project.


## Theos

These variables can be entered in a project's makefile.

* __PACKAGE\_VERSION__ - Makes a tweak's package version number _not_ show the build number at the end. For example, without this flag present your package version might show up as "1.4-1" in Cydia, for version 1.4 build 1. With `PACKAGE_VERSION = 1.4` in your makefile it would instead show up as "1.4". Make sure PACKAGE\_VERSION and the version number in your control file always match.
* __GO\_EASY\_ON\_ME__ - Setting this flag to 1 will disable Theos treating warnings as errors. This is helpful for quick experimental tweaks or for the beginning of development, but is not recommended for finished tweaks (fix the warnings!).
* __THEOS\_BUILD\_DIR__ - Setting this flag to a folder name will put all of the tweak's intermediate build files and finished deb files in a single folder, instead of all in the main folder of your project.
* __ARC__ - If you would like to use ARC in a twaek rather than manual reference counting, you can set `ADDITIONAL_OBJCFLAGS = -fobjc-arc` in your makefile. This may or may not be a good idea, [iPhoneDevWiki has more information about it here](http://iphonedevwiki.net/index.php/Using_ARC_in_tweaks).

## Tools
* [class-dump/class-dump-z](http://stevenygard.com/projects/class-dump/) - Class-dump and class-dump-z are tools that can create pseudo-header files from Objective-C class information in compiled binaries. It's a great starting tool for reverse engineering an app to hook it, and quite often is the only tool needed. Class-dump generated headers for SpringBoard and all of the iOS public and private frameworks can easily be found online.
* [DumpDecrypted](https://github.com/stefanesser/dumpdecrypted) - All App Store apps are encrypted by default, which means they have to be decrypted for reverse engineering or class-dumping. DumpDecrypted is a quick and easy tool to decrypt encrypted iOS apps.
* [Deviceconsole](https://github.com/rpetrich/deviceconsole) - Lets you view the system log of an iOS device connected through USB on your computer. Useful for seeing what's happening on a device. Plus how can you print debug without seeing your print statements???
* [iOS Simulator](http://sharedinstance.net/2013/10/running-tweaks-in-simulator/) - You can in fact run jailbreak tweaks in the iOS simulator. It takes a bit of work and probably isn't worth your time if you have a jailbroken device available, but if you don't then it could be very useful. I used it to mess around with tweaking iOS 7 before a public jailbreak was released.
