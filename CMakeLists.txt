cmake_minimum_required(VERSION 3.20)
project(breakout C CXX ASM_NASM)


set(CMAKE_CXX_STANDARD 17)
SET(ASM_OPTIONS "-x assembler-with-cpp ")
SET(CMAKE_ASM_FLAGS "${CFLAGS} ${ASM_OPTIONS}" )

include_directories(include)

add_executable(breakout main.cpp breakout.asm main.h)

target_link_libraries(breakout -lXxf86vm -lX11 -lpthread -lglfw -lGLEW -lGL -lGLU -lpthread -lglut -lGLEW -lGL -lGLU )
