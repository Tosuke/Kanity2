module kanity.drawing.renderer.object;

import kanity.imports;
import kanity.drawing.imports;
import kanity.drawing.renderer;
import std.algorithm, std.range, std.array;

interface IDrawable{
  void draw(bool);
  void draw();
}
abstract class DrawableObject2D : IDrawable{
  private{
    bool updated_ = false;
    mat4 modelMatrix_;
    Renderer renderer;
    ShaderProgram shaderProgram_;

    uint vertexAttributeLayout_;
    uint texCoordAttributeLayout_;

    uint mvpMatrixLayout_;

    uint vertexNum_;
    uint indicesNum_;
    bool useIndexBuffer_ = false;
  }

  AssociateArray!(int, Texture) texture;

  this(Renderer r){
    renderer = r;
    shaderProgram_ = r.shaderProgram;
    texture = AssociateArray!(int, Texture)(&update);
    modelMatrix = mat4.identity;
  }
  this(){
    texture = AssociateArray!(int, Texture)(&update);
  }

  void draw(){
    draw(updated_);
    updated_ = false;
  }

  //trueの時のみ描画
  abstract void draw(bool);

  @property{
  public:
    uint vertexAttributeLayout(){return vertexAttributeLayout_;}
    void vertexAttributeLayout(uint i){vertexAttributeLayout_ = i;};
    vec2[] vertex(){
      return getAttributeVec!2(vertexAttributeLayout);
    }
    void vertex(vec2[] data){
      setAttributeVec(vertexAttributeLayout, data);
      vertexNum_ = vertex.length.to!uint;
    }
    uint texCoordAttributeLayout(){return texCoordAttributeLayout_;}
    void texCoordAttributeLayout(uint i){texCoordAttributeLayout_ = i;}
    vec2[] texCoord(){
      return getAttributeVec!2(texCoordAttributeLayout);
    }
    void texCoord(vec2[] data){
      setAttributeVec(texCoordAttributeLayout, data);
    }

    uint[] indices(){
      return getIndices();
    }
    void indices(uint[] d){
      setIndices(d);
    }

    mat4 modelMatrix(){return modelMatrix_;}
    void modelMatrix(mat4 m){
      modelMatrix_ = m;
      mvpMatrix = perspectiveMatrix * modelMatrix_;
      update();
    }
    ShaderProgram shaderProgram(){
      return shaderProgram_ !is null ? shaderProgram_ : null;
    }
    void shaderProgram(ShaderProgram s){
      shaderProgram_ = s;
      update();
    }

    uint mvpMatrixLayout(){return mvpMatrixLayout_;}
    void mvpMatrixLayout(uint i){mvpMatrixLayout_ = i;}
    protected mat4 mvpMatrix(){
      return getUniformMatrix(mvpMatrixLayout);
    }
    protected void mvpMatrix(mat4 m){
      setUniformMatrix(mvpMatrixLayout, m);
    }
  protected:
    mat4 perspectiveMatrix(){
      return renderer.perspectiveMatrix;
    }
    bool useIndexBuffer(){
      return useIndexBuffer_;
    }
    uint vertexNum(){
      return vertexNum_;
    }
    uint indicesNum(){
      return indicesNum_;
    }
  }

  Vector!(float, d)[] getAttributeVec(int d)(int index){
    return getAttribute(index).chunks(d).map!(a => Vector!(float, d)(a[])).array;
  }
  void setAttributeVec(V)(int index, V[] data) if(!is(V.type : float)){
    auto d = V.dimension;
    //TODO:std.experimental.allocator
    auto buf = new float[data.length * d];
    foreach(int i, a; data[]){
      auto j = i * d;
      buf[j..j + d] = a.vector[];
    }
    setAttribute(index, buf, d);
    update();
  }

  private{
    float[][int] attribute;
  }
  protected float[] getAttribute(int index){
    return attribute.get(index, []);
  }
  abstract void setAttribute(int index, float[] data, lazy uint dim = 0){
    attribute[index] = data;
    update();
  }

  protected{
    mat4[int] uniformMat4;
  }
  mat4 getUniformMatrix(int index){
    return uniformMat4[index];
  }
  void setUniformMatrix(int index, mat4 matrix){
    uniformMat4[index] = matrix;
    update();
  }

  private{
    uint[] indices_;
  }
  uint[] getIndices(){
    return indices_;
  }
  abstract void setIndices(uint[] data){
    useIndexBuffer_ = true;
    indicesNum_ = data.length.to!uint;
    update();
  }


  protected void update(){
    updated_ = true;
  }
}

private struct AssociateArray(TKey, TValue){
  private TValue[TKey] data;
  private void delegate() update;

  this(void delegate() func){
    update = func;
  }

  TValue opIndex(TKey key){
    return data[key];
  }

  void opIndexAssign(TValue v, TKey key){
    data[key] = v;
    update();
  }

  auto byKeyValue(){
    return data.byKeyValue;
  }
}
