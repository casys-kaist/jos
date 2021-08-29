# Introduction

Welcome to KAIST's CS530 JOS project. You will implement a simple operating system named JOS developed by MIT which has been used in courses at several other schools.

JOS is simpler than Linux and Windows, but it includes most key operating systems abstractions, including a bootloader, memory protection, memory relocation, multiprogramming, a rudimentary file system, and a command shell.

JOS can be thought of as an [exokernel](https://pdos.csail.mit.edu/6.828/2008/readings/engler95exokernel.pdf), where the kernel implements a minimal set of core functionality that safely exports hardware resources to applications. These low-level kernel interfaces may be inconvenient for user processes to use directly, so user processes will make use of a "library operating system" (libos) to abstract these low-level exported resources into more convenient programming abstractions.

Each lab in the series enhances the functionality of your operating system. Each lab builds on the previous one, so it is important that you design, build, and test carefully at each step. Carelessness in early labs will be costly down the road. There are not a lot of lines of code to write on this project; take some time to understand each phase before moving to the next one.
