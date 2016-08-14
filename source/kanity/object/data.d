module kanity.object.data;

import kanity.imports;
import kanity.object.type;
import kanity.object.object;
import kanity.component.component;

//KanityData
/*
Kanity内のオブジェクトのデータの最小単位
JSON相当のデータを格納する
代入した時点で型が決定し、
(デバッグモード時に)暗黙変換不可能な型で取得しようとしたり代入したりしようとするとエラー
*/

//KanityData
unittest{
  auto a = KanityData(2.0);
  auto b = a.dup;
  a = 3;
  //a = "hoge"; //エラー
  //a = KanityData(true); //エラー
  a = KanityData(3.0); //OK
  assert(b == 2.0);
}

//KanityDataArray
unittest{
  auto a = KanityData([1, 2, 3]);
  auto b = a.dup;

  assert((a.get!KanityDataArray)[0] == 1);
  assert(a[1] == 2); //糖衣構文的な
  a[2] = 22;

  assert(a.toString == "[1, 2, 22]");
  assert(b.toString == "[1, 2, 3]");

  auto k = KanityDataArray(3);
  k[0] = KanityData(114514);
  k[1] = KanityData("hage");
  k[2] = KanityData(3.14);
  auto c = KanityData(k);
}

//KanityDataObject
unittest{
  KanityDataObject p;
  p.add("hoge", 32);
  p.add("lupin", "1st");
  p.lock; //最適化してアクセスを高速化
  //p.add("yajuu", 114514); //エラー

  auto a = KanityData(p);
  auto b = a.dup;
  a.get!KanityDataObject["lupin"] = "3rd";

  assert(a.get!KanityDataObject["hoge"] == 32);
  assert(a["hoge"] == 32);
  assert(a.toString == "[lupin:3rd, hoge:32]");
  assert(b["lupin"] == "1st");

  auto object = KanityDataObject(p);
  object.add("lupin", 1);
  assert(object["lupin"] == 1);
  assert(object["hoge"] == 32);
}

//KanityFunction
unittest{
  auto f = KanityFunction((int a, int b) => a + b);
  assert(f(KanityData(2), KanityData(3)) == 5);
  assert(f(4, 5) == 9);
  assert(f(KanityData(8), 9) == 17);
  auto a = KanityData(f);
  assert(a(5, 6) == 11);

  auto g = KanityData(() => "hoge");
  assert(g() == "hoge");

}

alias IntegerType = long;
alias FloaterType = double;
alias BooleanType = bool;
alias StringType = string;
alias ComponentType = KanityComponent;

private alias DataContainer = KanityDataContainer!(IntegerType, FloaterType, BooleanType, StringType);
public alias KanityData = DataContainer.KanityData_t;
public alias KanityDataArray = DataContainer.KanityDataArray_t;
public alias KanityDataObject = DataContainer.KanityDataObject_t;
public alias KanityFunction = DataContainer.KanityFunction_t;

private template KanityDataContainer(Types...){
  alias ArrayType = KanityDataArray_t;
  alias ObjectType = KanityDataObject_t;
  alias FunctionType = KanityFunction_t;
  //自分のコンテナ型を含む
  import std.meta, std.traits;
  alias TList = AliasSeq!(Types, ArrayType, ObjectType, FunctionType);

  struct KanityData_t{
    import std.variant;
    //Releaseビルドの時はstd.variant.Variantの薄いラッパ
    //Debugビルドの時のみ型検査を行う(暗黙変換可能な型を受けとる)

    import std.algorithm, std.range;
    private Variant data;
    alias data this;

    private KanityDataType type_;
    @property{
      public KanityDataType type(){
        return type_;
      }
      private void type(T)(T t) if(is(typeof(type_ = t))){
        type_ = t;
      }
    }
    private TypeInfo typeInfo;

    this(T)(T d)
    if((!isArray!T || isSomeString!T) && !isSomeFunction!T && !isAssociativeArray!T)
      in{
        typeAssert(isValid!T);
      }
      body{
        initialize(d);
      }
    this(T)(){
      initialize!void();
    }

    private void initialize(T)() if(isValid!T){
      type = toDataType!T;
      debug{
        typeInfo = typeid(ValidType!T);
      }
    }
    private void initialize(T)(T d) if(isValid!T){
      initialize!T();
      data = d;
    }

    //代入時型検査
    void opAssign(T)(T d) if(!is(T == KanityData_t))
      in{
        typeAssert(isAssignable!T);
      }
      body{
        data = d;
      }
    void opAssign(KanityData_t d)
      in{
        typeAssert(d.type in this.type || this.type == DataType.Null);
      }
      body{
        static import core.stdc.string;
        core.stdc.string.memcpy(&this, &d, KanityData_t.sizeof);//ビットコピーする以外の手段がほしい
      }

    //コピー処理
    KanityData_t dup(){
      switch(type.type){
        default:
          return this;

        case DataType.Array:
          return KanityData_t(data.get!ArrayType.dup);
        case DataType.Object:
          return KanityData_t(data.get!ObjectType.dup);
      }
    }
    string toString(){
      return data.toString;
    }

    T get(T)(){
      return data.get!T;
    }

    //糖衣構文を実現するための関数たち
    //Array
    this(T)(T[] d) if(!isSomeString!(T[]))
      in{
        typeAssert(isValid!T || is(T == KanityData_t));
      }
      body{
        initialize(KanityDataArray_t(d));
        type = data.get!KanityDataArray_t().type;
      }
    KanityData_t opIndex(T)(T index) if(isIntegral!T)
      in{
        typeAssert(type == DataType.Array);
      }
      body{
        return data.get!ArrayType[index];
      }
    void opIndexAssign(T, S)(T value, S index) if(isIntegral!S)
      in{
        typeAssert(type == DataType.Array);
      }
      body{
        data.get!ArrayType[index] = value;
      }

    //Object
    this(T)(T[string] d)
      in{
        typeAssert(isValid!T || is(T == KanityData_t));
      }
      body{
        initialize(KanityDataObject_t(d));
        type = data.get!KanityDataObject_t().type;
      }
    KanityData_t opIndex(T)(T index) if(isSomeString!T)
      in{
        typeAssert(type == DataType.Object);
      }
      body{
        return data.get!ObjectType[index.to!string];
      }
    void opIndexAssign(T, S)(T value, S index) if(isSomeString!S)
      in{
        typeAssert(type == DataType.Objct);
      }
      body{
        data.get!ObjectType[index.to!string] = value;
      }

    //Function
    this(T)(T f) if(isSomeFunction!T){
      initialize(KanityFunction_t(f));
    }
    KanityData_t opCall()
      in{
        typeAssert(type == DataType.Function);
      }
      body{
        return data.get!FunctionType()();
      }
    KanityData_t opCall(Args...)(Args args)
      in{
        typeAssert(type == DataType.Function);
      }
      body{
        return data.get!FunctionType()(args);
      }


    debug{
      bool isAssignable(T)(){
        foreach(A; ValidTypes!T){
          if(typeInfo == typeid(A)){
            return true;
          }
        }
        return false;
      }
    }
  }
  struct KanityDataArray_t{
    //うまく型を受けとれないようなのでつくった
    private KanityData_t[] data;
    alias data this;

    this(size_t length){
      data = new KanityData_t[](length);
      foreach(ref a; data){
        a = KanityData_t();
      }
    }

    this(T)(T[] d){
      initialize(d);
    }

    private void initialize(T)(T[] d) if(!is(T : KanityData_t)){
      import std.algorithm, std.array;
      //d.map!((T a) => KanityData_t(a)).array; って書きたいのに動いてくれない
      auto k = new KanityData_t[](d.length);
      size_t index = 0;
      foreach(a; d){
        k[index++] = KanityData_t(a);
      }
      initialize(k);
    }
    private void initialize(KanityData_t[] d){
      data = d;
    }

    KanityDataArray_t dup(){
      import std.algorithm, std.array, std.range;
      //return KanityDataArray_t(data.map!((KanityData_t a) => a.dup).array);って書きたいけど…
      KanityDataArray_t k = KanityDataArray_t(data.dup);
      foreach(size_t index, KanityData_t _; k){
        k[index] = k[index].dup;
      }
      return k;
    }

    @property KanityArrayType type(){
      import std.algorithm, std.array;
      return KanityArrayType(data.map!"a.type".array);
    }

    immutable opSlice(){
      return cast(immutable(KanityData_t[]))data;
    }

    auto toString(){
      import std.algorithm, std.string;
      return "["~(data.map!(a => a.toString).join(", "))~"]";
    }
  }

  struct KanityDataObject_t{
    //変数名を固定することでO(1)でのアクセスを可能にするハッシュ
    private KanityData_t[string] data;
    alias data this;

    private KanityDataObject_t* prototype = null;

    private bool isLocked_ = false;
    @property{
      public bool isLocked(){
        return isLocked_;
      }
      private void isLocked(bool b){
        isLocked_ = b;
      }
    }

    this(KanityDataObject_t p){
      static import core.stdc.string;
      prototype = new KanityDataObject_t();
      auto temp = p.dup;
      core.stdc.string.memcpy(prototype, &temp, typeof(temp).sizeof);
    }
    this(T)(T[string] d){
      initialize(d);
    }
    private void initialize(T)(T[string] d) if(!is(T : KanityData_t)){
      import std.algorithm, std.range, std.array;
      initialize(
        zip(d.byKey, d.byValue.map!(a => KanityData_t(a))).assocArray
      );
    }

    private void initialize(KanityData_t[string] d){
      data = d;
    }

    void add(T)(string name, T d)
      in{
        assert(!isLocked);
      }
      body{
        data[name] = d;
      }

    void lock(){
      isLocked = true;
      data.rehash;
    }

    KanityData_t opIndex(string name)
      in{
        assert(name in this);//リリース時にも例外を投げるようにすべき？
      }
      body{
        if(prototype == null){
          return data[name];
        }else{
          return data.get(name, prototype.opIndex(name));
        }
      }
    void opIndexAssign(T)(T value, string name)
      in{
        assert(name in this);//同上
      }
      body{
        if(name in data){
          data[name] = value;
        }else{
          prototype.opIndexAssign(value, name);
        }
      }

    KanityDataObject_t dup(){
      KanityDataObject_t k = KanityDataObject_t(this.data.dup);
      foreach(immutable string key; k[].byKey){
        k[key] = k[key].dup;
      }
      return k;
    }

    @property KanityObjectType type(){
      import std.algorithm, std.range, std.array;
      return zip(data.byKey, data.byValue.map!"a.type").assocArray;
    }

    inout opSlice(){
      return cast(immutable(KanityData_t[string]))data;
    }

    bool opBinaryRight(string op)(string key){
      static if(op == "in"){
        return  key in data ||
                (prototype != null ? prototype.opBinaryRight!"in"(key) : false);
      }else{
        static assert(0, "Operator "~op~" not implemented");
      }
    }

    string toString(){
      import std.algorithm, std.string;
      return "["~(data.byKeyValue.map!(a => a.key~":"~a.value.toString).join(", "))~"]";
    }
  }

  struct KanityFunction_t{
    alias Func = KanityData_t delegate(KanityData_t[]);
    private Func func;
    private KanityDataType returnType_;
    private KanityDataType[] parameterTypeList_;
    @property{
      public KanityDataType returnType(){
        return returnType_;
      }
      public KanityDataType[] parameterTypeList(){
        return parameterTypeList_;
      }
      private void returnType(KanityDataType k){
        returnType_ = k;
      }
      private void parameterTypeList(KanityDataType[] k){
        parameterTypeList_ = k;
      }
    }

    this(T)(T f) if(isSomeFunction!T){
      returnType = KanityDataType(toDataType!(ReturnType!T));
      alias P = Parameters!T;

      static if(P.length == 0){
        parameterTypeList = [];
        func = (KanityData_t[] p) => KanityData_t(f());
      }else{
        parameterTypeList = new KanityDataType[P.length];
        size_t index = 0;
        foreach(S; P){
          parameterTypeList_[index++] = KanityDataType(toDataType!S);
        }

        KanityData_t tmp(KanityData_t[] p){
          return KanityData_t(mixin(callFunction!P()));
        }
        func = &tmp;
      }
    }

    KanityData_t opCall()
     in{
       typeAssert(parameterTypeList == []);
     }
     body{
       return func([]);
     }

    KanityData_t opCall(Args...)(Args args) if(allSatisfy!(isValid, Args)){
      KanityData_t[Args.length] list;
      size_t index = 0;
      foreach(a; args){
        static if(is(typeof(a) == KanityData_t)){
          list[index++] = a;
        }else{
          list[index++] = KanityData_t(a);
        }
      }
      debug{
        import std.range, std.algorithm, std.array;
        //型が正しいかどうか検証する
        assert(
           zip(list[].map!(a => a.type), parameterTypeList)
          .map!(a => a[0] in a[1]).reduce!((a, b) => a && b)
        );
      }
      return func(list[]);
    }

  }
  static string callFunction(U...)(){
    import std.string : join;
    string[U.length] a;
    size_t index = 0;
    foreach(T; U){
      a[index] = "p["~index.to!string~"].get!"~T.stringof;
      index++;
    }
    return "f("~a[].join(",")~")";
  }


  private DataType toDataType(T)(){
    import std.traits;
    static if(is(T == void)){
      return DataType.Null;
    }else static if(isIntegral!T){
      return DataType.Integer;
    }else static if(isFloatingPoint!T){
      return DataType.Floater;
    }else static if(isBoolean!T){
      return DataType.Boolean;
    }else static if(isSomeString!T){
      return DataType.String;
    }else static if(is(T : ArrayType)){
      return DataType.Array;
    }else static if(is(T : ObjectType)){
      return DataType.Object;
    }else static if(is(T : FunctionType)){
      return DataType.Function;
    }else{
      static assert(0);
    }
  }
  //自分の型リストの中から与えられた型に最も近い型を返す
  //TODO:余りに雑なので修正する(型の順番に関係なく最適な型を選択できるようにする)
  import std.meta, std.traits;
  template ValidType(T){
    alias X = ValidTypes!T;
    static if(X.length >= 1){
      alias ValidType = X[0];
    }else{
      static assert(0);
    }
  }
  template ValidTypes(T){
    alias K = T;
    enum bool Checker(S) = is(K : S);
    alias X = Filter!(Checker, TList);
    alias ValidTypes = X;
  }
  enum bool isValid(T) = ValidTypes!T.length >= 1 || is(T : KanityData_t) || is(T : void);

  private void typeAssert(bool f = false){
    assert(f, "Invalid Type");
  }
}
