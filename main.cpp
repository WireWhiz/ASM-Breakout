#include <iostream>
#include <cstdint>
#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <chrono>
#include <stdlib.h>

extern "C" uint16_t WIDTH;
extern "C" uint16_t HEIGHT;
uint8_t* framebuffer= nullptr;

const char* vertexCode =  "#version 330 core\n"
                          "layout (location = 0) in vec3 aPos;\n"
                          "layout (location = 1) in vec2 aTexCoord;\n"
                          "\n"
                          "out vec2 TexCoord;\n"
                          "\n"
                          "void main()\n"
                          "{\n"
                          "    gl_Position = vec4(aPos, 1.0);\n"
                          "    TexCoord = aTexCoord;"
                          "}";

const char* fragmentCode = "#version 330 core\n"
                           "out vec4 FragColor;\n"
                           "  \n"
                           "in vec2 TexCoord;\n"
                           "\n"
                           "uniform sampler2D frame;\n"
                           "\n"
                           "void main()\n"
                           "{\n"
                           "    FragColor = texture(frame, TexCoord);\n"
                           "}";

float quadVertices[] = {
         // positions         // texture coords
         1.0f,  1.0f, 0.0f,   1.0f, 1.0f,   // top right
         1.0f, -1.0f, 0.0f,   1.0f, 0.0f,   // bottom right
        -1.0f, -1.0f, 0.0f,   0.0f, 0.0f,   // bottom left
        -1.0f, -1.0f, 0.0f,   0.0f, 0.0f,   // bottom left
        -1.0f,  1.0f, 0.0f,   0.0f, 1.0f,   // top left
         1.0f,  1.0f, 0.0f,   1.0f, 1.0f,   // top right
};
unsigned int vertexBuffer;

GLFWwindow* window;


std::chrono::high_resolution_clock::time_point lastFrame;
double deltaTime = 0;
extern "C" void run(unsigned char* vertexBuffer);

unsigned int currentFrame = 0;
constexpr int numFrames = 1;

unsigned int shaderPrograms[numFrames];
unsigned int framebuffers[numFrames];

extern "C" bool draw()
{
    if(glfwWindowShouldClose(window))
        return false;
    auto thisFrame = std::chrono::high_resolution_clock::now();
    //update(framebuffer, (double)std::chrono::duration_cast<std::chrono::milliseconds>(lastFrame - thisFrame).count() / 1000);
    lastFrame = thisFrame;


    GLint width = WIDTH;
    GLint height = HEIGHT;
    glUseProgram(shaderPrograms[currentFrame]);
    glBindTexture(GL_TEXTURE_2D, framebuffers[currentFrame]);
    //glTexSubImage2D(GL_TEXTURE_2D, 0, writeBounds[0], writeBounds[1], writeBounds[2], writeBounds[3], GL_RGB, GL_UNSIGNED_BYTE, framebuffer);
    glUniform1i(glGetUniformLocation(shaderPrograms[currentFrame], "frame"), currentFrame);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, framebuffer);

    currentFrame++;
    currentFrame %= numFrames;


    glDrawArrays(GL_TRIANGLES, 0, 6);
    glfwSwapBuffers(window);

    glfwPollEvents();
    return true;
}

void init()
{
    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_ANY_PROFILE);
    glfwSwapInterval(-1);
    window = glfwCreateWindow(WIDTH, HEIGHT, "ASM Breakout", nullptr, nullptr);
    if (window == NULL)
    {
        std::cout << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
    }
    glfwMakeContextCurrent(window);

    glewInit();

    glViewport(0, 0, WIDTH, HEIGHT);


    glGenVertexArrays(1, &vertexBuffer);


    glBindVertexArray(vertexBuffer);


    //Create vertex buffer
    glGenBuffers(1, &vertexBuffer);



    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);


    glBufferData(GL_ARRAY_BUFFER, sizeof(quadVertices), quadVertices, GL_STATIC_DRAW);


    // position attribute
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(0));

    glEnableVertexAttribArray(0);
    // texture attribute
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void *) (3 * sizeof(float)));
    glEnableVertexAttribArray(1);






    //Create shader to display texture
    unsigned int vertex, fragment;
    int success;
    char infoLog[512];
    vertex = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertex, 1, &vertexCode, NULL);
    glCompileShader(vertex);
    glGetShaderiv(vertex, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(vertex, 512, NULL, infoLog);
        std::cout << "ERROR::SHADER::VERTEX::COMPILATION_FAILED\n" << infoLog << std::endl;
    };


    fragment = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragment, 1, &fragmentCode, NULL);
    glCompileShader(fragment);
    glGetShaderiv(fragment, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(fragment, 512, NULL, infoLog);
        std::cout << "ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n" << infoLog << std::endl;
    };


    // shader Program
    for (int i = 0; i < numFrames; ++i) {
        shaderPrograms[i] = glCreateProgram();
        glAttachShader(shaderPrograms[i], vertex);
        glAttachShader(shaderPrograms[i], fragment);
        glLinkProgram(shaderPrograms[i]);

        // print linking errors if any
        glGetProgramiv(shaderPrograms[i], GL_LINK_STATUS, &success);
        if (!success) {
            glGetProgramInfoLog(shaderPrograms[i], 512, NULL, infoLog);
            std::cout << "ERROR::SHADER::PROGRAM::LINKING_FAILED\n" << infoLog << std::endl;
        }
    }










    // delete the shaders as they're linked into our program now and no longer necessary
    glDeleteShader(vertex);
    glDeleteShader(fragment);






    // Create image for our asm code to write too
    framebuffer = new uint8_t[WIDTH * HEIGHT * 4];

    for (int i = 0; i < WIDTH * HEIGHT * 3; ++i) {
        framebuffer[i] = 0;
    }

    glGenTextures(numFrames, framebuffers);
    //glGenFramebuffers(numFrames, renderbuffers);
    for (int i = 0; i < numFrames; ++i) {
        glActiveTexture(GL_TEXTURE0 + i); // activate the texture unit first before binding texture
        glBindTexture(GL_TEXTURE_2D, framebuffers[i]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, WIDTH, HEIGHT, 0, GL_RGBA, GL_UNSIGNED_BYTE, framebuffer);
    }


}

void cleanup()
{
    glDeleteTextures(numFrames, framebuffers);
    glDeleteProgram(shaderPrograms[0]);
    glfwTerminate();
}

void test(){
    draw();
}

int main()
{
    init();
    test();
    run(framebuffer);
    cleanup();
    return 0;
}