import std.experimental.logger;



extern(C){
  void init(){
    "hoge".log;
    test();
  }
  void test();
}
