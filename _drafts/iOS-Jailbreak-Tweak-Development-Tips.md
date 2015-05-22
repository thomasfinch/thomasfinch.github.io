---
layout: post
title:  "iOS Jailbreak Tweak Development Tips"
date:   2015-05-22 12:00:00
categories: blog
---

During the time I've spent developing jailbreak tweaks for iOS, I've come across plenty of small things to make my workflow better and make development easier in general. This post is a collection of those, so other developers can benefit as well. Most are probably familiar to experienced developers, but there are new developers learning every day :) .

## General Resources
* [iPhoneDevWiki](http://iphonedevwiki.net/) - A great place for information about tweak development. Lots of technical information and guides for things like setting up a basic development environment.
* [TheiPhoneWiki](https://www.theiphonewiki.com/wiki/Main_Page) - More in-depth, technical information than the iPhoneDevWiki, mostly related to the process of jailbreaking.
* [/r/Jailbreak](http://www.reddit.com/r/jailbreak) - The main jailbreak subreddit, probably the best place for general jailbreak news.
* [/r/JailbreakDevelopers](http://www.reddit.com/r/jailbreakdevelopers) - Subreddit for jailbreak tweak developers, a good place to find help for problems you encounter during development.
* [SharedInstance](http://sharedinstance.net) - Developer-oriented jailbreak blog
* `irc.saurik.com` - Saurik's IRC server, lots of developers hang around here and are available to help with problems or questions you may have.

## Workflow

* [Sublime-Logos](https://github.com/Cykey/Sublime-Logos) - Syntax highlighting for Logos keywords in Sublime Text, by default in files with `.x` or `.xm` extensions.
* [SSH over USB](http://iphonedevwiki.net/index.php/SSH_Over_USB) - Allows SSH'ing into a device connected through USB rather than through WiFi. This speeds up the process of deploying a new build to a device and makes development smoother in general. THEOS\_DEVICE\_IP must be set to localhost and THEOS\_DEVICE\_PORT must be set to the tunnel port (2222 by default). I have these set in my .bash\_profile rather than project makefiles since they're the same for every project.
* `ssh-copy-id` - This one seems obvious to me now, but wasn't at all when I started developing. Copying the public SSH key from your computer to your phone allows you to log in through SSH without entering your password every time. This is convenient when using SSH normally, but it's a lifesaver when building and running tweaks on your device. Entering your password every single time you build and run gets really, really annoying. More information and instructions can be found [here](http://www.thegeekstuff.com/2008/11/3-steps-to-perform-ssh-login-without-password-using-ssh-keygen-ssh-copy-id/).


## Theos

These variables can be entered in a project's makefile.

* __PACKAGE\_VERSION__ - Makes a tweak's package version _not_ show the build number at the end. For example, without this flag present your package version might show up as "1.4-1" in Cydia, for version 1.4 build 1. With `PACKAGE_VERSION = 1.4` in your makefile it would instead show up as "1.4". Make sure PACKAGE\_VERSION and the version number in your control file always match.
* __GO\_EASY\_ON\_ME__ - Setting this flag to 1 will disable Theos treating warnings as errors. This is helpful for quick experimental tweaks or for the beginning of development, but is not recommended for finished tweaks (fix the warnings!).
* __THEOS\_BUILD\_DIR__ - Setting this flag to a folder name will put all of the tweak's intermediate build files and finished deb files in a single folder, instead of all in the main folder of your project.
* __Automatic Reference Counting (ARC)__ - If you would like to use ARC in a tweak rather than manual reference counting, you can set `ADDITIONAL_OBJCFLAGS = -fobjc-arc` in your makefile. This may or may not be a good idea, [iPhoneDevWiki has more information about it here](http://iphonedevwiki.net/index.php/Using_ARC_in_tweaks).

## Tools
* [class-dump/class-dump-z](http://stevenygard.com/projects/class-dump/) - Class-dump and class-dump-z are tools that can create pseudo-header files from Objective-C class information in compiled binaries. It's a great starting tool for reverse engineering an app to hook it, and quite often is the only tool needed. Class-dump generated headers for SpringBoard and all of the iOS public and private frameworks can easily be found online.
* [DumpDecrypted](https://github.com/stefanesser/dumpdecrypted) - All App Store apps are encrypted, which means they have to be decrypted for reverse engineering or class-dumping. DumpDecrypted is a quick and easy tool to decrypt encrypted iOS apps.
* [Deviceconsole](https://github.com/rpetrich/deviceconsole) - Lets you view the system log of an iOS device connected through USB on your computer. Useful for seeing what's happening on a device, including NSLog statements from your tweak.
* [Cycript](http://www.cycript.org/) - Cycript allows you to interact with running Objective-C programs using a simple Javascript syntax. It's super useful for exploring an app that you want to create a tweak for, because you can traverse the view hierarchy and test method calls right in the app itself.
* [Hopper Disassembler](http://hopperapp.com/) - Hopper is invaluable for reverse engineering. If you ever wonder specifically what happens within a SpringBoard method and can't guess from just the name, Hopper can help you find out. Although there are other disassemblers (like [IDA](https://www.hex-rays.com/products/ida/)) available, I think Hopper is the best looking and easiest to use (and most affordable). Aside from reverse engineering, I've found Hopper useful when getting unsymbolicated crash logs from users since they only list the offset in a tweak's binary that the crash happened at.
* __GDB/LLDB__ - I haven't used a debugger for fixing bugs in my tweaks before, but I find them useful for doing research into how different methods work within apps. The version of GDB hosted by Saurik doesn't work for me, although I was able to find an older version online that does. I would recommend setting up LLDB for remote debugging by following [iPhoneDevWiki's instructions](http://iphonedevwiki.net/index.php/Debugserver).
* [iOS Simulator](http://sharedinstance.net/2013/10/running-tweaks-in-simulator/) - You can in fact run jailbreak tweaks in the iOS simulator. It takes a bit of work and probably isn't worth your time if you have a jailbroken device available, but if you don't then it could be very useful. I used it to mess around with tweaking iOS 7 before a public jailbreak was released.

## Other Tips
* If you want to force another tweak to load before yours, you can use `dlopen` to force its dylib to be loaded first. For example, I use the line `dlopen("/Library/MobileSubstrate/DynamicLibraries/SubtleLock.dylib", RTLD_NOW);` in Priority Hub's constructor to force SubtleLock to be loaded first, so that Priority Hub can 
* Look at code for open source projects! There are tons of open source tweaks that can be found through Google or on [iPhoneDevWiki's list of open source projects](http://iphonedevwiki.net/index.php/Open_Source_Projects). If you're stuck on a problem, maybe someone has solved it before.
* Ask for help! There are plenty of good places to ask for help from other developers, like [/r/JailbreakDevelopers](http://www.reddit.com/r/jailbreakdevelopers) or Saurik's IRC server or even by contacting other developers directly through Twitter or email. Even if you don't need help, you can learn a lot from hanging around and reading.
