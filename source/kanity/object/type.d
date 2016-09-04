module kanity.object.type;

import kanity.imports;
import kanity.object.data;

import std.traits;

//KanityDataType
/*
静的型付け言語からの利用などのために、KanityDataの型を規定して制限する(スキーマとして使う？)
'=='により(完全な)一致、'in'により包含関係を表す(a in b = a ⊆ b)
Example:
  data in schema : バリデーション
*/
/*
//KanityDataType
unittest{
  auto data = KanityData(10).type;
          //= KanityDataType(DataType.Integer);

  auto schema1 = KanityDataType(DataType.Integer);
  assert(data == schema1);
  assert(data in schema1);

  auto schema2 = KanityDataType(DataType.Numeric);
  assert(data != schema2);
  assert(data in schema2);

  auto schema3 = KanityDataType(DataType.String);
  assert(data != schema3);
  assert(data !in schema3);
}
//KanityArrayType
unittest{
  auto data = KanityData([KanityData(10), KanityData(3.14)]).type;
          //= KanityDataType([DataType.Integer, DataType.Floater]);

  auto schema1 = KanityDataType([DataType.Integer, DataType.Floater]);
  assert(data == schema1);
  assert(data in schema1);

  auto schema2 = KanityDataType(KanityArrayType(DataType.Numeric));
  assert(data != schema2);
  assert(data in schema2);

  auto schema3 = KanityDataType([DataType.Integer]);
  assert(data != schema3);
  assert(data in schema3);

  auto schema4 = KanityDataType([DataType.String, DataType.Floater, DataType.Boolean]);
  assert(data != schema4);
  assert(data !in schema4);
}
//KanityObjectType
unittest{
  auto data = KanityData(["Name":KanityData("AZ"), "Age":KanityData(100)]).type;
          //= KanityDataType(["Name":DataType.String, "Age":DataType.Integer]);

  auto schema1 = KanityDataType(["Name":DataType.String, "Age":DataType.Integer]);
  assert(data == schema1);
  assert(data in schema1);

  auto schema2 = KanityDataType(["Name":DataType.String]);
  assert(data != schema2);
  assert(data in schema2);

  auto schema3 = KanityDataType(["Age":DataType.Integer, "IsHage":DataType.Boolean]);
  assert(data != schema3);
  assert(data !in schema3);

  auto schema4 = KanityDataType(["Age":DataType.Floater]);
  assert(data != schema4);
  assert(data !in schema4);
}

enum DataType{
  //実際の値
  Null,
  Integer,
  Floater,
  Boolean,
  String,
  Array,
  Object,
  Function,
  Component,
  //属性の値(比較演算の時のみ有効)
  Any,      //(全て)
  Numeric,  //(Integer, Floater)
  Scalar    //(Integer, Floater, Boolean)
}

struct KanityDataType{
  //"=="
  bool opEquals(KanityDataType t){
    return  this == t.type &&
            (this.type == DataType.Array  ? this == t.arrayType   : true) &&
            (this.type == DataType.Object ? this == t.objectType  : true);
  }
  //"in"
  bool opBinary(string op)(KanityDataType t){
    static if(op == "in"){
      // this ⊆ t?
      return  this in t.type &&
              (this.type == DataType.Array  ? this in t.arrayType   : true) &&
              (this.type == DataType.Object ? this in t.objectType  : true);
    }else{
      assert(0, "Operator "~op~" not implemented");
    }
  }

  public DataType type = DataType.Null;

  this(DataType t){
    opAssign(t);
  }

  void opAssign(DataType t){
    type = t;
  }
  //'=='
  bool opEquals(DataType t){
    return this.type == t;
  }
  //'in'
  bool opBinary(string op)(DataType t){
    static if(op == "in"){
      //this ⊆ t?
      switch(t){
        default:
          return this.type == t;

        case DataType.Any:
          return true;

        case DataType.Numeric:
          return  type == DataType.Integer ||
                  type == DataType.Floater;

        case DataType.Scalar:
          return  type == DataType.Integer ||
                  type == DataType.Floater ||
                  type == DataType.Boolean;
      }
    }else{
      assert(0, "Operator "~op~" not implemented");
    }
  }

  //[]のとき無効
  public KanityArrayType arrayType;

  this(KanityArrayType t){
    this.type = DataType.Array;
    opAssign(t);
  }

  this(T)(T[] t){
    this.type = DataType.Array;
    arrayType = KanityArrayType(t);
  }
  void opAssign(T)(T t) if(is(T == KanityArrayType) || isArray!T)
    in{
      assert(type == DataType.Array);
    }
    body{
      arrayType = t;
    }

  //'=='
  bool opEquals(KanityArrayType t)
    in{
      assert(type == DataType.Array);
    }
    body{
      if(arrayType.isNull) return true;

      return this.arrayType == t;
    }
  //'in'
  bool opBinary(string op)(KanityArrayType t)
    in{
      assert(type == DataType.Array);
    }
    body{
      static if(op == "in"){
        //this ⊆ t?
        if(arrayType.isNull) return true;

        return this.arrayType in t;
      }else{
        assert(0, "Operator "~op~" not implemented");
      }
    }
  //実際にはKanityDataType[string]
  //length == 0のとき無効
  public KanityObjectType objectType;

  this(T)(T t) if(is(T == KanityObjectType) || is(T == DataType[string])){
    type = DataType.Object;
    opAssign(t);
  }

  void opAssign(KanityObjectType t)
    in{
      assert(type == DataType.Object);
    }
    body{
      objectType = t;
    }
  void opAssign(DataType[string] t)
    in{
      assert(type == DataType.Object);
    }
    body{
      import std.algorithm, std.range, std.array;
      opAssign(
         zip(t.byKey, t.byValue.map!(a => KanityDataType(a))).assocArray
      );
    }

  //"=="
  bool opEquals(KanityObjectType t)
    in{
      assert(type == DataType.Object);
    }
    body{
      if(objectType.length == 0) return true;

      import std.algorithm, std.range;
      return  objectType.length == t.length &&
               zip(objectType.byKeyValue, t.byKeyValue)
              .all!(a => a[0].key == a[1].key && a[0].value == a[1].value);
    }

  //"in"
  bool opBinary(string op)(KanityObjectType t)
    in{
      assert(type == DataType.Object);
    }
    body{
      static if(op == "in"){
        //this ⊆ t?
        if(objectType.length == 0) return true;

        import std.algorithm, std.range;
        return t.byKey()
                .all!(a => a in objectType && objectType[a] in t[a]);
      }else{
        assert(0, "Operator "~op~" not implemented");
      }
    }
}
public struct KanityArrayType{
  private KanityDataType* item_;
  @property{
    public KanityDataType item(){return *item_;}
    private void item(KanityDataType a){opAssign(a);}
  }
  private KanityDataType[] items_;
  @property{
    public KanityDataType[] items(){return items_;}
    private void items(KanityDataType[] a){opAssign(a);}
  }
  alias items this;

  private bool useItems_ = true;
  @property{
    public bool useItems(){return useItems_;}
    private void useItems(bool a){useItems_ = a;}
  }

  bool isNull(){
    return useItems ? items.length == 0 : item_ == null;
  }

  this(T)(T t) if(is(T == KanityDataType) || is(T == DataType)){
    opAssign(t);
  }

  this(T)(T[] t) if(is(T == KanityDataType) || is(T == DataType)){
    opAssign(t);
  }

  void opAssign(KanityDataType t){
    import core.stdc.string;
    item_ = new KanityDataType();
    memcpy(item_, &t, typeof(t).sizeof);
    useItems = false;
  }
  void opAssign(DataType t){
    opAssign(KanityDataType(t));
  }

  void opAssign(KanityDataType[] t){
    items_ = t;
    useItems = true;
  }
  void opAssign(DataType[] t){
    import std.algorithm, std.array;
    opAssign(t.map!(a => KanityDataType(a)).array);
  }


  //"=="
  bool opEquals(KanityArrayType t){
    import std.algorithm, std.range;
    if(this.useItems){
      if(t.useItems){
        return this.items == t.items;
      }else{
        return zip(this.items, t.item.repeat(this.items.length))
              .all!(a => a[0] == a[1]);
      }
    }else{
      if(t.useItems){
        return zip(this.item.repeat(t.items.length), t.items)
              .all!(a => a[0] == a[1]);
      }else{
        return this.item == t.item;
      }
    }
  }
  //"in"
  bool opBinary(string op)(KanityArrayType t){
    static if(op == "in"){
      //this ⊆ t?
      import std.algorithm, std.range;
      if(this.useItems){
        if(t.useItems){
          return this.items.length >= t.items.length &&
                 zip(this.items.take(t.items.length), t.items)
                .all!(a => a[0] in a[1]);
        }else{
          //TODO:なぜallで動かないのか
          return zip(this.items, t.item.repeat(this.items.length))
                .map!(a => a[0] in a[1]).reduce!((a, b) => a && b);
        }
      }else{
        if(t.useItems){
          return zip(this.item.repeat(t.items.length), t.items)
                .map!(a => a[0] in a[1]).reduce!((a, b) => a && b);
        }else{
          return this.item in t.item;
        }
      }
    }else{
      assert("Operator "~op~" not implemented");
    }
  }
}
public alias KanityObjectType = KanityDataType[string];
*/
