
unittest{
  auto a = KanityData(2.0);
  auto b = a.dup;
  a = 3.0;
  //a = "hoge"; //エラー
  //a = KanityData(true); //エラー
  a = KanityData(3.0); //OK
  assert(b.get!double == 2.0);
}
unittest{
  auto a = KanityData([1, 2, 3]);
  auto b = a.dup;

  assert(a[0].get!int == 1);
  a[2] = 22;

  assert(a.toString == "[1, 2, 22]");
  assert(b.toString == "[1, 2, 3]");

  auto k = KanityData(new KanityData[3]);
  //k.get!(KanityData[]).log;
  k[0] = KanityData(114514);
  k[1] = KanityData("hage");
  k[2] = KanityData(3.14);
}
unittest{
  auto a = KanityData(DataType.Object);
  a.add("hoge", 32);
  a.add("lupin", "1st");
  a.lock; //最適化してアクセスを高速化
  //a.add("yajuu", 114514); //エラー

  auto b = a.dup;
  a["lupin"] = "3rd";

  assert(a["hoge"].get!int == 32);
  assert(a["lupin"].get!string == "3rd");
  assert(b["lupin"].get!string == "1st");
}

import kanity.imports;
import std.meta, std.traits, std.range : ElementType;
import std.variant;
import std.conv : to;

public enum DataType{
  Uninitialized,
  Null,
  Integer,
  Floater,
  Boolean,
  String,
  Array,
  Object,
}

alias NullType = typeof(null);
alias IntegerType = long;
alias FloaterType = double;
alias BooleanType = bool;
alias StringType = string;

private alias Types = AliasSeq!(NullType, IntegerType, FloaterType, BooleanType, StringType);

struct KanityData{
  union{
    private Algebraic!Types data_;
    @property{
      public auto data()
      in{
        assert(type != DataType.Array && type != DataType.Object);
      }body{
        return data_;
      }
      private void data(T)(T v){data_ = v;}
    }

    private KanityData[] array_;
    @property{
      public auto array()
      in{
        assert(type == DataType.Array);
      }body{
        return array_;
      }
      private void array(KanityData[] v){array_ = v;}
    }

    private KanityData[string] object_;
    @property{
      public auto object()
      in{
        assert(type == DataType.Object);
      }body{
        return object_;
      }
      private void object(KanityData[string] v){object_ = v;}
    }
  }
  private DataType type_ = DataType.Uninitialized;
  @property{
    public auto type(){return type_;}
    private void type(DataType v){type_ = v;}
  }

  this(DataType t){
    type = t;
    switch(t){
      case DataType.Uninitialized:
        data = null;
        break;
      case DataType.Null:
        data = null;
        break;
      case DataType.Integer:
        data = IntegerType.init;
        break;
      case DataType.Floater:
        data = FloaterType.init;
        break;
      case DataType.Boolean:
        data = BooleanType.init;
        break;
      case DataType.String:
        data = StringType.init;
        break;
      case DataType.Array:
        array = cast(KanityData[])[];
        break;
      case DataType.Object:
        KanityData[string] a;
        object = a;
        break;
      default:
        assert(0);
    }
  }
  this(T)(T v) if(!is(T == DataType)){
    type = DataType.Uninitialized;
    this = v;
  }

  //値
  void opAssign(T)(T v) if(isValid!T)
  in{
    assert(type == toDataType!T || type == DataType.Uninitialized);
  }body{
    if(type == DataType.Uninitialized) type = toDataType!T;
    data = v.to!(ValidType!T);
  }

  T get(T)() if(isValid!T)
  in{
    assert(type == toDataType!T);
  }body{
    return data.get!(ValidType!T).to!T;
  }

  //KanityData;
  void opAssign(KanityData v)
  in{
    assert(type == v.type || type == DataType.Uninitialized);
  }body{
    if(type == DataType.Uninitialized) type = v.type;
    switch(v.type){
      default:
        this.data = v.data;
        break;
      case DataType.Array:
        this.array = v.array;
        break;
      case DataType.Object:
        this.object = v.object;
        break;
    }
  }

  T get(T : KanityData)(){
    return this;
  }

  //配列
  void opAssign(T)(T[] v) if((isValid!T || is(T == KanityData)) && !isSomeChar!T)
  in{
    assert(type == DataType.Array || type == DataType.Uninitialized);
  }body{
    if(type == DataType.Uninitialized) type = DataType.Array;

    static if(is(T == KanityData)){
      array = v;
    }else{
      import std.algorithm, std.array;
      array = v.map!(a => KanityData(a)).array;
    }
  }

  A get(A)()
  if((isArray!A && !isSomeString!A) &&
    (isValid!(ElementType!A) || is(ElementType!A == KanityData)))
  in{
    assert(type == DataType.Array);
  }body{
    alias T = ElementType!A;
    static if(is(T == KanityData)){
      return this.array;
    }else{
      import std.algorithm, std.array;
      return this.array.map!(a => a.get!T).array;
    }
  }

  KanityData opIndex(size_t index)
  in{
    assert(type == DataType.Array);
  }body{
    return this.array[index];
  }

  void opIndexAssign(T)(T value, size_t index) if(isValid!T || is(T == KanityData))
  in{
    assert(type == DataType.Array);
  }body{
    this.array[index] = value;
  }

  //連想配列
  debug{
    private bool isLocked_ = false;
    @property{
      public bool isLocked(){return isLocked_;}
      private void isLocked(bool a){isLocked_ = a;}
    }
  }

  void opAssign(T)(T[string] v) if(isValid!T || is(T == KanityData))
  in{
    assert(type == DataType.Object || type == DataType.Uninitialized);
    assert(!isLocked);
  }body{
    if(type == DataType.Uninitialized) type = DataType.Object;
    static if(is(T == KanityData)){
      this.object = v;
    }else{
      import std.algorithm, std.array, std.typecons;
      this.object = v.byPair.map!(a => tuple(a[0], KanityData(a[1]))).assocArray;
    }
  }

  A get(A)() if(isAssociativeArray!A && isValid!(ValueType!A) && is(KeyType!A == string))
  in{
    assert(type == DataType.Object);
  }body{
    alias T = ValueType!A;
    static if(is(T == KanityData)){
      return this.object;
    }else{
      import std.algorithm, std.array, std.typecons;
      return this.object.byPair.map!(a => tuple(a[0], a[1].get!T)).assocArray;
    }
  }

  KanityData opIndex(string key)
  in{
    assert(type == DataType.Object);
    assert(key in object);
  }body{
    return object[key];
  }

  void opIndexAssign(T)(T value, string key) if(isValid!T || is(T == KanityData))
  in{
    assert(type == DataType.Object);
    assert(key in object);
  }body{
    object_[key] = value;
  }

  void add(T)(string key, T value) if(isValid!T || is(T == KanityData))
  in{
    assert(type == DataType.Object);
    assert(key !in object);
  }body{
    object_[key] = value;
  }

  void lock()
  in{
    assert(type == DataType.Object);
    assert(!isLocked);
  }body{
    debug{
      isLocked = true;
    }
    object.rehash;
  }

  string toString(){
    import std.algorithm, std.string;
    switch(this.type){
      case DataType.Uninitialized:
        return "uninitialized";
      case DataType.Null:
        return "null";
      case DataType.Integer:
        return data.get!IntegerType.to!string;
      case DataType.Floater:
        return data.get!FloaterType.to!string;
      case DataType.Boolean:
        return data.get!BooleanType ? "true" : "false";
      case DataType.String:
        return `"`~data.get!StringType~`"`;
      case DataType.Array:
        return "["~array.map!"a.toString".join(", ")~"]";
      case DataType.Object:
        return "{"~object.byKeyValue.map!(a => a.key~":"~a.value.toString).join(", ")~"}";
      default:
        assert(0);
    }
  }

  KanityData dup(){
    import std.algorithm, std.array, std.typecons;
    switch(this.type){
      case DataType.Uninitialized:
        return KanityData(DataType.Uninitialized);
      case DataType.Null:
        return KanityData(null);
      case DataType.Integer:
        return KanityData(data.get!IntegerType);
      case DataType.Floater:
        return KanityData(data.get!FloaterType);
      case DataType.Boolean:
        return KanityData(data.get!BooleanType);
      case DataType.String:
        return KanityData(data.get!StringType);
      case DataType.Array:
        return KanityData(array.map!(a => a.dup).array);
      case DataType.Object:
        return KanityData(object.byPair.map!(a => tuple(a[0], a[1].dup)).assocArray);
      default:
        assert(0);
    }
  }
}

private enum bool isValid(T) = is(ValidType!T);

private template ValidType(T){
  static if(is(T : BooleanType)){
    alias ValidType = BooleanType;
  }else static if(is(T : IntegerType)){
    alias ValidType = IntegerType;
  }else static if(is(T : FloaterType)){
    alias ValidType = FloaterType;
  }else static if(is(T : StringType)){
    alias ValidType = StringType;
  }else static if(is(T : NullType)){
    alias ValidType = NullType;
  }else{
    static assert(0, "Invald Type "~T.stringof);
  }
}

private template toDataType(T){
  static if(is(T : BooleanType)){
    alias toDataType = DataType.Boolean;
  }else static if(is(T : IntegerType)){
    alias toDataType = DataType.Integer;
  }else static if(is(T : FloaterType)){
    alias toDataType = DataType.Floater;
  }else static if(is(T : StringType)){
    alias toDataType = DataType.String;
  }else static if(is(T : NullType)){
    alias toDataType = DataType.Null;
  }else{
    static assert(0, "Invald Type "~T.stringof);
  }
}
