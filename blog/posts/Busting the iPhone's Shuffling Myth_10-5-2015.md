# Busting the iPhone's Shuffling Myth

Last week I happened across [an interesting Reddit post](http://www.reddit.com/r/explainlikeimfive/comments/34hnnj/eli5_despite_having_150_songs_on_a_playlist/). In it, the poster asks why the same songs seem to keep coming up when shuffling a music library on iTunes.
The top comment claims that iTunes/iPods don't shuffle songs completely randomly, but instead weight the shuffling to favor songs that are played more often so users enjoy the shuffled mix of songs more.

Clearly many users feel that this is true (or at least that shuffling is somehow not random) - Google turns up plenty of blog posts and forum questions about why iTunes or other Apple products don't shuffle randomly since they play the same songs often.
In fact, it's such a common complaint that Apple addressed it in 2005 with an iTunes feature called "smart shuffle" which would let users choose just how random shuffle actually was with a slider that could space songs from the same album or artist further apart. ([Source](http://www.mcelhearn.com/itunes-features-that-have-been-retired/))

<div style="text-align:center"><img src ="images/SmartShuffle.jpg" /><br /><em>The iTunes 5 Smart Shuffle feature (<a href="http://archive.oreilly.com/users/files/64559/SmartShuffle.jpg">Source</a>)</em></div>

Although the smart shuffle feature is now gone (it was removed with the release of iTunes 8 in 2008), the myth that iTunes/iPods/iPhones' shuffling isn't completely random still persists.
I thought initially that the whole idea of non-random shuffling was ridiculous since we humans see patterns in all sorts of things, whether the patterns exist intentionally or not.
However, given the long list of users convinced that shuffling wasn't random and the fact that Apple had experimented with non-random shuffling at least once in the past, I felt that the question was worthy of more investigation.


### Diggig Deeper
Since the Reddit commenter specifically mentioned iPods as having a weighted shuffle algorithm, I tested the myth with their slightly more modern equivalent, the iPhone. Though I could have shuffled a list of songs repeatedly and recorded their order each time, the much more conclusive (and fun) way to figure out if the iPhone's music app weights shuffling is to reverse engineer it.

Here's a list of tools I used:

* A jailbroken iPhone (in my case, a 5s on iOS 8.1.2)
* [LLDB](http://lldb.llvm.org) - For debugging the music app on-device
* [Class-Dump-Z](https://code.google.com/p/networkpx/wiki/class_dump_z) - Extracts class and method information for Objective-C
* [JTool](http://www.newosxbook.com/index.php?page=downloads) - Used to extract frameworks from the iOS DYLD cache (though it does much more than just that)
* [Hopper Disassembler](http://www.hopperapp.com) - For analyzing the music app and framework binaries

One of the best tools to start out with when reverse engineering Objective-C is ```class-dump-z``` (or its predecessor, ```class-dump```). ```Class-dump-z``` is able to create pseudo-header files for each class in a binary file based on the class and method information within the file. Thankfully the naming conventions/traditions of Objective-C tend to lead to verbose method names, meaning that it's usually easy to guess what a given method does.

To run ```class-dump-z``` on the music app binary, I first copied it from my phone (located at ```/Applications/Music.app/Music```) to my computer. Thankfully, the app was not encrypted like App Store apps are. If it was, it could have been decrypted using Stefan Esser's handy [dumpdecrypted](https://github.com/stefanesser/dumpdecrypted) tool.