---
layout: post
title:  "Hooking C Functions at Runtime"
date:   2015-07-24 12:00:00
categories: blog
---

This is a quick writeup on something I experimented with recently, runtime function hooking in C. The basic idea of hooking a function is to replace the function's code with your own code, so when the function is called your code is run instead. Hooking at runtime lets you change the way the program works when it's executed without having its code or actually modifying its file in any way. Runtime function hooking isn't uncommon, and is used for iOS jailbreak tweaks (powered by [Cydia Substrate](http://www.cydiasubstrate.com/) or [Substitute](https://github.com/comex/substitute)) as well as programs using the [Xposed framework](http://repo.xposed.info/module/de.robv.android.xposed.installer) on Android.

If you'd like to follow along with this post on your own computer, you'll need a Mac with Xcode and the Xcode command line tools installed. The code can be found [here on Github](https://github.com/thomasfinch/CRuntimeFunctionHooker).

## The Sample Program

The sample program we'll be hooking into is very basic:

```c
//testProgram.c
#include <stdio.h>

int hookTargetFunction() {
	printf("Calling original function!\n");
    return 5;
}

int main() {
	printf("The number is: %d\n", hookTargetFunction());
    return 0;
}
```

Compiling and running it gives the following output:

```
Calling original function!
The number is: 5
```

Our goal is to hook the function `hookTargetFunction` and change the number that's returned to something other than 5.

## Hooking the Target Function

The way we'll hook the target function is by creating a dynamic library and loading it when the program is run. The dynamic library's constructor will be run before the `main` of the target executable, so we'll be able to modify the target executable in memory before it runs. To make our replacement code run, we'll insert machine code for a jump instruction to our function at the beginning of the function we're hooking. In other words, when the computer tries to run the target function it will instead jump to where our replacement function is located and run our code instead.

The first step of the process is to create a dynamic library containing a constructor and a replacement function.

```c
//inject.c
#include <stdio.h>

int hookReplacementFunction() {
    printf("Calling replacement function!\n");
    return 3;
}

__attribute__((constructor))
static void ctor(void) {
    printf("Dylib constructor called!\n");
}
```

When it's compiled and loaded with the target program using the `DYLD_INSERT_LIBRARIES` environment variable, we can see that its constructor runs before the main program.

```console
$ ls
inject.c	testProgram	testProgram.c
$ clang -dynamiclib inject.c -o inject.dylib
$ DYLD_INSERT_LIBRARIES=inject.dylib ./testProgram
Dylib constructor called!
Calling original function!
The number is: 5
```

Now we can begin putting code in the constructor to hook the target function. Since x86 jump instructions use relative addressing, we can't just give the computer an address in memory to jump to. We'll first need to find the offset of the replacement function from the target function, which can be done by getting pointers to each function then subtracting one from the other.

```c
void *mainProgramHandle = dlopen(NULL, RTLD_NOW);
int64_t *origFunc = dlsym(mainProgramHandle , "hookTargetFunction");
int64_t *newFunc = (int64_t*)&hookReplacementFunction;
int32_t offset = (int64_t)newFunc - ((int64_t)origFunc + 5 * sizeof(char));
```

There are a few interesting things in this code sample. The first is using `dlopen` to get a pointer to our target executable. `dlopen` is normally used for loading shared libraries, but [according to its documentation](http://linux.die.net/man/3/dlopen) it can also be used to access the main executable if NULL is passed as the file name. The second thing to note is that jump offsets are actually taken from the address of the *next* instruction, which in this case is the address of the target function plus 5 bytes since the inserted jump instruction will be 5 bytes in size.

One minor step which I'm omitting from this writeup is making the memory of the target function writable, since it's only readable and executable by default for security reasons. Once that's complete, the final step is creating and inserting the jump instruction. The x86 opcode for an unconditional jump with an immediate offset is E9, so we'll put that as the first byte of the instruction followed by the offset.

```c
int64_t instruction = 0xE9 | offset << 8;
*origFunc = instruction;
```

Here is the finished `inject.c` file:

```c
#include <stdio.h>
#include <dlfcn.h>
#include <stdint.h>
#include <sys/mman.h>
#include <unistd.h>

int hookReplacementFunction() {
    printf("Calling replacement function!\n");
    return 3;
}

__attribute__((constructor))
static void ctor(void) {
	//Get pointers to the original and new functions and calculate the jump offset
    void *mainProgramHandle = dlopen(NULL, RTLD_NOW);
    int64_t *origFunc = dlsym(mainProgramHandle , "hookTargetFunction");
    int64_t *newFunc = (int64_t*)&hookReplacementFunction;
    int32_t offset = (int64_t)newFunc - ((int64_t)origFunc + 5 * sizeof(char));

    //Make the memory containing the original funcion writable
    //Code from http://stackoverflow.com/questions/20381812/mprotect-always-returns-invalid-arguments
    size_t pageSize = sysconf(_SC_PAGESIZE);
    uintptr_t start = (uintptr_t)origFunc;
    uintptr_t end = start + 1;
    uintptr_t pageStart = start & -pageSize;
    mprotect((void *)pageStart, end - pageStart, PROT_READ | PROT_WRITE | PROT_EXEC);

    //Insert the jump instruction at the beginning of the original function
    int64_t instruction = 0xe9 | offset << 8;
    *origFunc = instruction;
}
```

When it's compiled and run, it actually changes the output of the main program!

```console
$ ls
inject.c	testProgram	testProgram.c
$ ./testProgram 
Calling original function!
The number is: 5
$ clang -dynamiclib inject.c -o inject.dylib
$ DYLD_INSERT_LIBRARIES=inject.dylib ./testProgram
Calling replacement function!
The number is: 3
```

Here's another run with some debugging output, which shows the jump instruction inserted at the beginning of the target function:

```console
$ DYLD_INSERT_LIBRARIES=inject.dylib ./testProgram
Original function address: 0x1078abee0
Replacement function address: 0x1078b4c40
Offset: 0x8d5b
Before replacement: 
*(origFunc+0):	554889e5
*(origFunc+4):	488d3d73
*(origFunc+8):	00e84c00
*(origFunc+12):	00000089
After replacement: 
*(origFunc+0):	e95b8d00
*(origFunc+4):	488d3d73
*(origFunc+8):	00e84c00
*(origFunc+12):	00000089
Calling replacement function!
The number is: 3
```

## Limitations

One limitation of this method of hooking is that it requires the target function to be at least 5 bytes in size for a jump instruction to be inserted. That may seem like a silly restriction, but it's definitely possible to create functions that small (a single byte `ret` instruction, for example). I can't think of a way around this, after all it's hard to do much in a single byte. The most straightforward solution is just to not hook functions smaller than 5 bytes.

Another problem I ran into was getting this code to work on Linux. For some reason, Linux consistently loaded the dynamic library at a high address, so high that the offset overflowed the 32 bits available to it. I don't think this is fixable while still using a jump instruction, since the maximum size an offset can be is 32 bits. However, the function could be hooked using another method - for example pushing the address of the replacement function onto the stack, then jumping to it with a `ret` instruction. This would take more space than simply using a jump, but it's the only idea I have at the moment.


<br /><br />
I hope you enjoyed this writeup! Once again, feel free to download and test out the code on your own machine. It's much more fun when you try it yourself!
