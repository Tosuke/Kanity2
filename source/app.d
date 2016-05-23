import derelict.glfw3.glfw3;
import derelict.opengl3.gl;
import derelict.opengl3.gl3;
import std.exception : enforce;
import std.conv : to;
import std.experimental.logger;

void main(){
	import kanity.utils.soloader;
	auto handle = SharedObject.load("./libtest.so");
	auto init = SharedObject.loadFunc!(void function())(handle, "init");
	init();

	DerelictGLFW3.load();
	DerelictGL.load();
	DerelictGL3.load();

	enforce(glfwInit(), "Failed to init GLFW3.");
	scope(exit) glfwTerminate();

	glfwWindowHint(GLFW_RESIZABLE, 0);
	auto window = glfwCreateWindow(640, 480, "Hello, GLFW3!!", null, null);
	enforce(window, "Failed to create window.");

	window.glfwMakeContextCurrent();

	glClearColor(255, 255, 255, 255);

	while(!window.glfwWindowShouldClose()){
		glClear(GL_COLOR_BUFFER_BIT);

		window.glfwSwapBuffers();

		glfwPollEvents();
	}
}
extern(C){
	void test(){
			"hage".log;
	}
}
