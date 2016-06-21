import std.experimental.logger;

int num;

extern(C){
  void init(){
    "hoge".log;
    test();
  }
  int get(){
    return num;
  }
  void set(int a){
    num = a;
  }
  void test();
}
