module kanity.utils.soloader;

import kanity.imports;
import std.string : toStringz;

alias SharedObjectHandle = void*;

struct SharedObject{
static:
  SharedObjectHandle load(string name){
    version(Posix){
      import core.sys.posix.dlfcn;
      auto handle = dlopen(name.toStringz, RTLD_NOW | RTLD_GLOBAL);
      dlerror().to!string.log;
      enforce(handle, dlerror().to!string);
      return handle;
    }
    version(Windows){
      auto handle = LoadLibraryA(name.toStringz);
      enforce(handle, "Failed to load library.");
      return handle;
    }
    assert(0, "Sorry, this environment is not supported.");
  }
  void unload(SharedObjectHandle handle){
    if(handle == null) return;

    version(Posix){
      import core.sys.posix.dlfcn;
      enforce(!dlclose(handle), dlerror().to!string);
      return;
    }
    version(Windows){
      FreeLibrary(handle);
      return;
    }
    assert(0, "Sorry, this environment is not supported.");
  }
  import std.traits;
  auto loadFunc(T)(SharedObjectHandle handle, string name) if(isSomeFunction!T){
    version(Posix){
      import core.sys.posix.dlfcn;
      auto func = dlsym(handle, name.toStringz);
      if(func == null) func = dlsym(handle, ("_" ~ name).toStringz);

      enforce(func, dlerror().to!string);
      return cast(T)func;
    }
    version(Windows){
      auto func = GetProcAddress(handle, name.toStringz);
      enforce(func, "Failed to load function.");
      return cast(T)func;
    }
    assert(0, "Sorry, this environment is not supported.");
  }
}
