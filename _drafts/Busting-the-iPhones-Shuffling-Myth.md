---
layout: post
title:  "Busting the iPhone's Shuffling Myth"
date:   2015-05-09 12:00:00
categories: blog
---

A while ago I happened across [an interesting Reddit post](http://www.reddit.com/r/explainlikeimfive/comments/34hnnj/eli5_despite_having_150_songs_on_a_playlist/). In it, the poster asks why the same songs seem to keep coming up when shuffling a music library on iTunes.
The top comment claims that iTunes/iPods don't shuffle songs completely randomly, but instead weight the shuffling to favor songs that are played more often so users enjoy the shuffled mix of songs more.

Clearly many users feel that this is true (or at least that shuffling is somehow not random) - Google turns up plenty of blog posts and forum questions about why iTunes or other Apple products don't shuffle randomly since they play the same songs often.
In fact, it's such a common complaint that Apple addressed it in 2005 with an iTunes feature called "smart shuffle" which would let users choose just how random shuffle actually was with a slider that could space songs from the same album or artist further apart. ([Source](http://www.mcelhearn.com/itunes-features-that-have-been-retired/))

<div style="text-align:center"><img src ="http://i.imgur.com/ii5aYEi.jpg" /><br /><em>The iTunes 5 Smart Shuffle feature (<a href="http://archive.oreilly.com/users/files/64559/SmartShuffle.jpg">Source</a>)</em><br /><br /></div>

Although the smart shuffle feature is now gone (it was removed with the release of iTunes 8 in 2008), the myth that iTunes/iPods/iPhones' shuffling isn't completely random still persists.
I thought initially that the whole idea of non-random shuffling was ridiculous since we tend to see patterns in all sorts of things, whether the patterns exist intentionally or not.
However, given the long list of users convinced that shuffling wasn't random and the fact that Apple had experimented with non-random shuffling at least once in the past, I felt that the question was worthy of more investigation.

### Diving In
Since the Reddit commenter specifically mentioned iPods as having a weighted shuffle algorithm, testing the myth with their slightly more modern equivalent, the iPhone, makes sense. Though shuffling a list of songs repeatedly and recording their order each time could work, the much more conclusive (and fun) way to figure out if the iPhone's music app weights shuffling is to reverse engineer it.

Here's a list of tools used:

* A jailbroken iPhone (in my case, a 5s on iOS 8.1.2)
* [Class-Dump](http://stevenygard.com/projects/class-dump/) - Extracts class and method information for Objective-C programs
* [Cycript](http://www.cycript.org) - Handy runtime analysis tool that allows interacting with running Objective-C using JavaScript syntax
* [OTool](http://www.manpagez.com/man/1/otool/) - Object file analysis tool
* [Hopper Disassembler](http://www.hopperapp.com) - Graphical disassembler
* [LLDB](http://lldb.llvm.org) - General purpose debugger

One of the best tools to start out with when reverse engineering Objective-C is class-dump. Class-dump is able to create pseudo-header files for each class in a binary file based on the runtime information within Mach-O files. Thankfully the naming conventions/traditions of Objective-C tend to lead to verbose method names, meaning that it's usually easy to guess what a given method does.

To run class-dump on the music app binary, I first copied it from my phone (located at /Applications/Music.app/Music) to my computer. Thankfully, the app is not encrypted like App Store apps are. If it was, it could have been decrypted using Stefan Esser's handy [dumpdecrypted](https://github.com/stefanesser/dumpdecrypted) tool.

Here's the process of running class-dump:

```bash
$ class-dump -H -o Headers Music 
$ ls Headers/
CDStructures.h
MAAppDelegate.h
MAApplication.h
MAPAAppDelegate.h
MAPHAppDelegate.h
MARadioRemoteControlContext.h
MARemoteController.h
MCDCarDisplayServiceProvider-Protocol.h
MusicTabBarControllerDelegate-Protocol.h
NSObject-Protocol.h
NSUserActivityDelegate-Protocol.h
RUCreateStationViewControllerDelegate-Protocol.h
RUMiniPlayerCoordinatorDelegate-Protocol.h
RUNowPlayingViewControllerDelegate-Protocol.h
RURadioViewControllerDelegate-Protocol.h
UIApplicationDelegate-Protocol.h
UIApplicationTestingDelegate-Protocol.h
UINavigationControllerDelegate-Protocol.h
UITabBarControllerDelegate-Protocol.h
```

Browsing through these generated headers gives us information about the classes in the music app, like each class's superclass, properties, and methods. However, none of the classes in the app seem to relate to shuffling. If this list seems incredibly short, well, it is. The music app is a full, functioning app! Where are all of the user interface classes? Searching the all the generated header files shows that none of them contain "shuffle". Where are the classes controlling stuff like shuffling? Fortunately the user interface classes are easy to track down, and give us a hint toward where to look for the shuffling code.

### Cycript

Cycript is a useful tool that lets us easily interact with running Objective-C code using JavaScript syntax. While the same information could be obtained using a debugger, Cycript is much easier and faster to use. It's invaluable for quickly prototyping jailbreak tweaks as well as exploring an app's view hierarchy, which we will do in the music app.

```bash
Thomass-Mac-Pro:~ thomasfinch$ ssh root@localhost -p 2222
Thomas-Finchs-iPhone:~ root# cycript -p "Music"
cy# UIApp
"<MAApplication: 0x14e61a360>"
cy# UIApp.keyWindow
"<UIWindow: 0x14e53c890; frame = (0 0; 320 568); gestureRecognizers = <NSArray: 0x174446480>; layer = <UIWindowLayer: 0x170422080>>"
```

After SSH-ing into my phone (in this case [through a USB connection](http://iphonedevwiki.net/index.php/SSH_Over_USB)) and connecting Cycript to the music app process, I can do practically anything within the app. With the above commands, we can see the shared UIApplication instance (MAApplication, also found in the class-dumped header files) as well as the key window. Omitting some subview exploration, we get the following:

```bash
cy# UIApp.keyWindow.subviews[0].subviews[0].subviews[0].subviews[0].subviews[0].subviews[0].subviews[0].subviews[0].subviews
@["<MPUVignetteBackgroundView: 0x1741de690; frame = (0 0; 320 568); clipsToBounds = YES; autoresize = W+H; layer = <CALayer: 0x17443c6c0>>",
"<MusicNowPlayingPlaybackControlsView: 0x14e73c3e0; frame = (0 0; 320 568); layer = <CALayer: 0x170839fe0>>",
"<MPUNowPlayingTitlesView: 0x14e73f730; frame = (0 418; 320 42.5); clipsToBounds = YES; userInteractionEnabled = NO; layer = <CALayer: 0x174824220>>",
"<MPUSlantedTextPlaceholderArtworkView: 0x14e75ca10; baseClass = UIImageView; frame = (0 64; 320 320); opaque = NO; autoresize = LM+RM+BM; gestureRecognizers = <NSArray: 0x170658090>; layer = <CALayer: 0x17063bfe0>>",
"<_UILayoutGuide: 0x1703a6820; frame = (0 0; 0 64); hidden = YES; layer = <CALayer: 0x170639e00>>"]
```

Now we're getting somewhere! Googling any of the first four view classes turns up results from GitHub repositories of class-dumped iOS frameworks. Specifically, they seem to belong to the private [MediaPlayerUI framework](https://github.com/MP0w/iOS-Headers/tree/master/iOS8.1/PrivateFrameworks/MediaPlayerUI). Browsing through the framework's headers shows that it's exclusively interface code (it *does* have UI in its name after all). However, since the music app uses an external framework for its user interface it's a good clue that looking for the shuffling code in an external framework is a reasonable idea.

We can list all shared libraries used in the music app using OTool:

```bash
$ otool -L Music 
Music:
	/System/Library/PrivateFrameworks/AirTraffic.framework/AirTraffic (compatibility version 1.0.0, current version 116.0.0)
	/usr/lib/libMobileGestalt.dylib (compatibility version 1.0.0, current version 1.0.0)
	/System/Library/PrivateFrameworks/MediaServices.framework/MediaServices (compatibility version 1.0.0, current version 1.0.0)
	/System/Library/PrivateFrameworks/StoreServices.framework/StoreServices (compatibility version 1.0.0, current version 1.0.0)
	/System/Library/PrivateFrameworks/RadioUI.framework/RadioUI (compatibility version 1.0.0, current version 1.0.0)
	/System/Library/PrivateFrameworks/Radio.framework/Radio (compatibility version 1.0.0, current version 1.0.0)
	/System/Library/Frameworks/MobileCoreServices.framework/MobileCoreServices (compatibility version 1.0.0, current version 66.0.0)
	/System/Library/Frameworks/AudioToolbox.framework/AudioToolbox (compatibility version 1.0.0, current version 492.0.0)
	/System/Library/PrivateFrameworks/MediaPlayerUI.framework/MediaPlayerUI (compatibility version 1.0.0, current version 1.0.0)
	/System/Library/PrivateFrameworks/Celestial.framework/Celestial (compatibility version 1.0.0, current version 1.0.0)
	/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote (compatibility version 1.0.0, current version 1.0.0)
	/System/Library/Frameworks/MediaPlayer.framework/MediaPlayer (compatibility version 1.0.0, current version 1.0.0)
	/System/Library/Frameworks/AVFoundation.framework/AVFoundation (compatibility version 1.0.0, current version 2.0.0)
	/System/Library/PrivateFrameworks/MusicUI.framework/MusicUI (compatibility version 1.0.0, current version 1.0.0)
	/System/Library/Frameworks/UIKit.framework/UIKit (compatibility version 1.0.0, current version 3318.16.14)
	/System/Library/Frameworks/Foundation.framework/Foundation (compatibility version 300.0.0, current version 1141.1.0)
	/usr/lib/libobjc.A.dylib (compatibility version 1.0.0, current version 228.0.0)
	/usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 1213.0.0)
	/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation (compatibility version 150.0.0, current version 1141.15.0)
```

As expected we see that the MediaPlayerUI framework is used, along with other common frameworks like Foundation and UIKit. Of the listed frameworks, the public [MediaPlayer framework](https://github.com/MP0w/iOS-Headers/tree/master/iOS8.1/Frameworks/MediaPlayer) seems promising - it's made for developers to control music playback, including playback from the built in music library (you can read Apple's official documentation of it [here](https://developer.apple.com/library/ios/documentation/MediaPlayer/Reference/MediaPlayer_Framework/index.html)). In addition the class-dumped headers for MediaPlayer have four classes with "shuffle" in their names, which is a big clue that the framework is related to shuffling in some capacity. From here we can start investigating methods that look promising, but I'll skip the trial and error and say that the one doing the shuffling is `MPMediaQueryShuffledItems - (void)shuffleItemsWithInitialIndex:(unsigned int)index`. Now we can start figuring out how it works.

### Hopper

In order to find out specifically how the shuffle method works we need to disassemble it. My first choice for disassembly is a graphical disassembler like Hopper Disassembler (or [IDA Pro](https://www.hex-rays.com/products/ida/)). To check out the shuffle method in Hopper, we first have to retrieve the binary for the MediaPlayer framework. A logical place to look on a jailbroken iOS device would be /System/Library/Frameworks/*.framework, but all of the framework folders are confusingly missing their main executables. As explained by [this iPhoneDevWiki article](http://iphonedevwiki.net/index.php/Dyld_shared_cache), all frameworks on iOS are combined in a big file called the DYLD shared cache to improve performance. After downloading the shared cache from a jailbroken phone (located at  /System/Library/Caches/com.apple.dyld/dyld\_shared\_cache_armX, where X = 64 in my case), we can open the cache file in Hopper Disassembler and select the MediaPlayer framework to start disassembly. Uh oh...

<div style="text-align:center"><img src ="http://i.imgur.com/yI6lTG2.png" /><br /><em>The stripped MediaPlayer framework binary in Hopper</em><br /><br /></div>

Upon opening the file we're met with an enormous list of methods simply named \<redacted>. Apple has stripped the binary, meaning they removed all of the method names and other useful symbols from the program's symbol table. This is bad news for us because we can't easily locate the shuffle method within the binary, searching for it turns up nothing. In other words, the code we're looking for is in there but we don't know where.

### LLDB to the Rescue

At this point, there's only one tool that makes sense: a debugger. There is a version of GDB available in Cydia, but it has never worked for me, so instead I'll use LLDB. 

[Only one thing to do: LLDB. Set up debugserver to connect to the Music app and connect to it from computer. Can now debug phone music app from mac. Set breakpoint on the shuffle method and tap the shuffle button at the top of the app -> breakpoint is hit! We now know that our method is somehow involved in the shuffle process.]

[Now debugging inside the method we're interested in. We know it has two arguments, let's look at them. (print $arg1 and $arg2 -> nsmutablearray of songSomething objects and unsigned integer initialIndex). Strong evidence that we're in the right place.]

[So what happens inside the function? disas! -> We have assembly! It's pretty simple to reverse engineer, but we also have pseudocode from the armv6 version using Hopper (assembly looks almost identical (other than armv6/arm64 differences) so pseudocode is pretty helpful).]

[We're almost done with LLDB, but not yet. We can see several calls to objc_msgSend but can't see exactly what they are. Can either set breakpoints on objc_msgSend (gross & tedious but it works) or can print the selecors at the given addresses]

### Analyzing the Shuffle Method

[We have assembly from LLDB for the arm64 version. Also have assembly + pseudocode for the armv6 version.]

[Assembly for armv6 & arm64 versions look almost identical other than obvious changes like register names etc. Most likely the original code is identical for both, meaning the armv6 pseudocode is useful.]

[Based on the armv6 pseudocode the function is pretty straightforward. The only problem is that we don't know what methods are called, we can only see that an objc_msgSend call was made.]
