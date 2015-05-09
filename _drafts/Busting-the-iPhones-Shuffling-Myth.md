---
layout: post
title:  "Busting the iPhone's Shuffling Myth"
date:   2015-05-09 12:42:37
categories: jekyll update
---

Last week I happened across [an interesting Reddit post](http://www.reddit.com/r/explainlikeimfive/comments/34hnnj/eli5_despite_having_150_songs_on_a_playlist/). In it, the poster asks why the same songs seem to keep coming up when shuffling a music library on iTunes.
The top comment claims that iTunes/iPods don't shuffle songs completely randomly, but instead weight the shuffling to favor songs that are played more often so users enjoy the shuffled mix of songs more.

Clearly many users feel that this is true (or at least that shuffling is somehow not random) - Google turns up plenty of blog posts and forum questions about why iTunes or other Apple products don't shuffle randomly since they play the same songs often.
In fact, it's such a common complaint that Apple addressed it in 2005 with an iTunes feature called "smart shuffle" which would let users choose just how random shuffle actually was with a slider that could space songs from the same album or artist further apart. ([Source](http://www.mcelhearn.com/itunes-features-that-have-been-retired/))

<div style="text-align:center"><img src ="{{ site.url }}/resources/SmartShuffle.jpg" /><br /><em>The iTunes 5 Smart Shuffle feature (<a href="http://archive.oreilly.com/users/files/64559/SmartShuffle.jpg">Source</a>)</em><br /><br /></div>

Although the smart shuffle feature is now gone (it was removed with the release of iTunes 8 in 2008), the myth that iTunes/iPods/iPhones' shuffling isn't completely random still persists.
I thought initially that the whole idea of non-random shuffling was ridiculous since we tend to see patterns in all sorts of things, whether the patterns exist intentionally or not.
However, given the long list of users convinced that shuffling wasn't random and the fact that Apple had experimented with non-random shuffling at least once in the past, I felt that the question was worthy of more investigation.

### Digging Deeper
Since the Reddit commenter specifically mentioned iPods as having a weighted shuffle algorithm, I tested the myth with their slightly more modern equivalent, the iPhone. Though I could have shuffled a list of songs repeatedly and recorded their order each time, the much more conclusive (and fun) way to figure out if the iPhone's music app weights shuffling is to reverse engineer it.

Here's a list of tools I used:

* A jailbroken iPhone (in my case, a 5s on iOS 8.1.2)
* [LLDB](http://lldb.llvm.org) - For debugging the music app on-device
* [Class-Dump-Z](https://code.google.com/p/networkpx/wiki/class_dump_z) - Extracts class and method information for Objective-C
* [JTool](http://www.newosxbook.com/index.php?page=downloads) - Used to extract frameworks from the iOS DYLD cache (though it does much more than just that)
* [Hopper Disassembler](http://www.hopperapp.com) - For analyzing the music app and framework binaries

One of the best tools to start out with when reverse engineering Objective-C is ```class-dump-z``` (or its predecessor, ```class-dump```). ```Class-dump-z``` is able to create pseudo-header files for each class in a binary file based on the class and method information within the file. Thankfully the naming conventions/traditions of Objective-C tend to lead to verbose method names, meaning that it's usually easy to guess what a given method does.

To run ```class-dump-z``` on the music app binary, I first copied it from my phone (located at ```/Applications/Music.app/Music```) to my computer. Thankfully, the app was not encrypted like App Store apps are. If it was, it could have been decrypted using Stefan Esser's handy [dumpdecrypted](https://github.com/stefanesser/dumpdecrypted) tool. [Write out the process of running class-dump-z]

[Show how there are no methods or classes in the music binary related to shuffling -> shuffling must be done somewhere else (in a framework used by the music app)]

[The only logical framework for it to be in is the MediaPlayer framework -> show how to extract it with jtool -> class-dump it -> look for shuffling methods -> find the one shuffle method that looks promising]

[Let's figure out how this method works! -> open in Hopper -> Oh noes it's been stripped!!! can't look up methods by name!  wat now????]

### LLDB to the Rescue

[Only one thing to do: LLDB. Set up debugserver to connect to the Music app and connect to it from computer. Can now debug phone music app from mac. Set breakpoint on the shuffle method and tap the shuffle button at the top of the app -> breakpoint is hit! We now know that our method is somehow involved in the shuffle process.]

[Now debugging inside the method we're interested in. We know it has two arguments, let's look at them. (print $arg1 and $arg2 -> nsmutablearray of songSomething objects and unsigned integer initialIndex). Strong evidence that we're in the right place.]

[So what happens inside the function? disas! -> We have assembly! It's pretty simple to reverse engineer, but we also have pseudocode from the armv6 version using Hopper (assembly looks almost identical (other than armv6/arm64 differences) so pseudocode is pretty helpful).]

[We're almost done with LLDB, but not yet. We can see several calls to objc_msgSend but can't see exactly what they are. Can either set breakpoints on objc_msgSend (gross & tedious but it works) or can print the selecors at the given addresses]

### Analyzing the Shuffle Method

[We have assembly from LLDB for the arm64 version. Also have assembly + pseudocode for the armv6 version.]

[Assembly for armv6 & arm64 versions look almost identical other than obvious changes like register names etc. Most likely the original code is identical for both, meaning the armv6 pseudocode is useful.]

[Based on the armv6 pseudocode the function is pretty straightforward. The only problem is that we don't know what methods are called, we can only see that an objc_msgSend call was made.]
