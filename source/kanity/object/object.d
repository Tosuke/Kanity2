module kanity.object.object;

import kanity.imports;
import kanity.object.data;

struct KanityObject{
  /*private KanityData[string] data;

  this(KanityObject prototype){
    foreach(a; prototype[].byKeyValue){
      data[a.key] = a.value;
    }
  }

  void add(T)(string name, T data){
    static if(is(T == KanityData)){
      this.data[name] = data;
    }else{
      this.data[name] = KanityData(data);
    }
  }
  void rehash(){
    data.rehash;
  }

  auto opSlice(){
    return data.dup;
  }

  KanityData opIndex(string index)
    in{
      assert(index in data);
    }
    body{
      return data[index];
    }
  void opIndexAssign(T)(T d, string index)
    in{
      assert(index in data);
    }
    body{
      static if(is(T == KanityData)){
        data[index] = d;
      }else{
        data[index] = KanityData(d);
      }
    }

  KanityData opDispatch(string member)(){
    return opIndex(member);
  }
  void opDispatch(string member, T)(T d){
    opIndexAssign(d, member);
  }*/
}

unittest{
  /*
  KanityObject proto;
  auto obj = KanityObject(proto);
  obj.add("test", 1);
  assert(obj.test.get!int == 1);
  obj.test = 2;

  auto objObj = KanityObject(proto);
  objObj.add("hoge", obj);

  auto ext = KanityObject(objObj);
  ext.hoge.test = 3;

  assert(objObj.hoge.test.get!int == 2);
  */
}
