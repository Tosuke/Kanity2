module kanity.engine;

import kanity.imports;
import kanity.drawing.window;

import std.concurrency;

shared Window window_;
@property{
  Window window(){
    return cast(Window)window_;
  }
  void window(Window r){
    window_ = cast(shared Window)r;
  }
}

class Engine{
  private{
    MultiLogger logger;
  }
  this(){
    initLogger;
    initLib;
  }
  void start(){
    spawn(&renderContext, thisTid);
    auto wasInitSuccess = receiveOnly!(bool);
    assert(wasInitSuccess);
    "hoge".log;
  }
private:
  void initLogger(){
    import kanity.utils.logger;

    logger = new MultiLogger();
    sharedLog = logger;
    debug{
      import std.stdio;
      logger.insertLogger("debug", new KaniLogger(stderr));
    }
  }
  void initLib(){
    import derelict.opengl3.gl3;
    import derelict.glfw3.glfw3;
    import derelict.freeimage.freeimage;

    import std.algorithm;
    import std.typecons;

    [
      tuple("GLFW3", &DerelictGLFW3.load),
      tuple("OpenGL3", &DerelictGL3.load),
      tuple("FreeImage", &DerelictFI.load)
    ].each!((a){
      try{
        a[1]();
      }catch{
        fatalf("Failed to load '%s'.", a[0]);
      }
    });
  }
}
extern(C){
	void test(){
			"hage".info;
	}
}
void renderContext(Tid ownerTid){
  synchronized{
    window = new Window();
    window.init;
  }

  send(ownerTid, true);

  bool isRunning = true;
  while(isRunning){
    synchronized{
      window.draw;
      isRunning = window.isRunning;
    }
  }
}
