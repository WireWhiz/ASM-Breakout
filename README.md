"Simple" program I made to teach myself x86 assembly language. Try to understand it at your own risk. I might make a walk through of it on my website at some pont, or add a paddle so you can actually play the game, but at the momen I'm too lazy.

It works by first creating a window with GLFW in the c++ main file, then it calls an ASM function that does everything else by writing to a byte array for colors. That array is passed to a drawing function in the c++ file to be displayed using OpenGL.

I'd love to see some cool forks of this where the base cpp file is used to make different asm based games

At the moment I've only tested it on linux, but with the addition of some lib files it should work on windows as well. You will need nasm for building the ASM files.

TODOS: <br>
Make a controllable paddle <br>
Windows support <br>
Swap chain, as it seems that the bottleneck at the moment is drawing to the image. (You can see the remnants of an attempt of one)