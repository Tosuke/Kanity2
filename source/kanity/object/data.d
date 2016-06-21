module kanity.object.data;

import kanity.imports;


enum DataType{
  None,
  Integer,
  Floater,
  Boolian,
  String,
  Array,
  Object
}
alias IntegerType = int;
alias FloaterType = double;
alias BoolianType = bool;
alias StringType = string;
alias ArrayType = KanityData[];
alias ObjectType = KanityObject;

struct KanityData{
  private immutable DataType type_;
  @property{
    public auto type(){
      return type_;
    }
  }
  private union{
    IntegerType integer_;
    FloaterType floater_;
    BoolianType boolian_;
    StringType str_;
    ArrayType array_;
    ObjectType object_;
  }
  public @property{
    auto integer(){
      typeAssert(DataType.Integer);
      return integer_;
    }
    auto integer(IntegerType n){
      typeAssert(DataType.Integer);
      integer_ = n;
    }
    auto floater(){
      typeAssert(DataType.Floater);
      return floater_;
    }
    auto floater(FloaterType n){
      typeAssert(DataType.Floater);
      floater_ = n;
    }
    auto boolian(){
      typeAssert(DataType.Boolian);
      return boolian_;
    }
    auto boolian(BoolianType b){
      typeAssert(DataType.Boolian);
      boolian_ = b;
    }
    auto str(){
      typeAssert(DataType.String);
      return str_;
    }
    auto str(StringType s){
      typeAssert(DataType.String);
      str_ = s;
    }
    auto array(){
      typeAssert(DataType.Array);
      return array_;
    }
    auto array(ArrayType d){
      typeAssert(DataType.Array);
      array_ = d;
    }
    auto object(){
      typeAssert(DataType.Object);
      return object_;
    }
    auto object(ObjectType o){
      typeAssert(DataType.Object);
      object_ = o;
    }
  }
  private void typeAssert(){
    assert(0, "Invalid type");
  }
  private void typeAssert(DataType t){
    if(t != type) typeAssert();
  }

  this(DataType t){
    type_ = t;
  }
  this(T)(T data){
    static if(is(T == BoolianType)){
      this(DataType.Boolian);
      boolian = data;
    }else static if(is(T : IntegerType)){
      this(DataType.Integer);
      integer = data.to!IntegerType;
    }else static if(is(T : FloaterType)){
      this(DataType.Floater);
      floater = data.to!FloaterType;
    }else static if(is(T : StringType)){
      this(DataType.String);
      str = data.to!StringType;
    }else static if(is(T == ArrayType)){
      this(DataType.Array);
      array = data;
    }else static if(is(T == ObjectType)){
      this(DataType.Object);
      object = data;
    }else{
      typeAssert();
    }
  }

  public T get(T)(){
    static if(is(T == BoolianType)){
      return boolian;
    }else static if(__traits(isScalar, T)){
      return (type == DataType.Integer ? integer : floater).to!T;
    }else static if(is(T : StringType)){
      return str.to!T;
    }else static if(is(T == ArrayType)){
      return array;
    }else static if(is(T == ObjectType)){
      return object;
    }else{
      typeAssert();
    }
  }
  public T opCast(T)(){
    return this.get!T;
  }
  public void opAssign(T)(T data){
    static if(is(T == BoolianType)){
      boolian = data;
    }else static if(is(T : IntegerType)){
      integer = data.to!IntegerType;
    }else static if(is(T : FloaterType)){
      floater = data.to!FloaterType;
    }else static if(is(T : StringType)){
      str = data.to!StringType;
    }else static if(is(T == ArrayType)){
      array = data;
    }else static if(is(T == ObjectType)){
      object = data;
    }else{
      typeAssert();
    }
  }
  public T opBinary(string op, T)(T rhs){
    static if(is(T == BoolianType)){
      auto data = boolian;
    }else static if(__traits(isScalar, T)){
      real data = type == DataType.Integer ? integer.to!real : floater.to!real;
    }else static if(is(T : StringType)){
      auto data = str;
    }else static if(is(T == ArrayType)){
      auto data = array;
    }else static if(is(T == ObjectType)){
      auto data = object;
    }else{
      auto data = null;
      typeAssert();
    }
    static if(__traits(compiles, mixin("data"~op~"rhs"))){
      return (mixin("data"~op~"rhs")).to!T;
    }else{
      typeAssert;
      return T.init;
    }
  }
}
unittest{
  assert(KanityData(DataType.None).type == DataType.None);
  assert(KanityData(100).get!int == 100);
  assert(KanityData(114514).get!real == 114514.0);
  assert(KanityData(3.14).get!double == 3.14);
  assert(!cast(bool)KanityData(true) == false);
  assert(KanityData("hoge").get!string == "hoge");
  auto alice = KanityData("b");
  auto bob = alice;
  alice = "a";
  assert(bob.get!string == "b");
}
class KanityObject{
  
}
