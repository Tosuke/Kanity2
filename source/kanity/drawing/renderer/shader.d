module kanity.drawing.renderer.shader;

import kanity.imports;
import kanity.drawing.imports;
import kanity.drawing.renderer;

abstract class ShaderProgram{
  private{
    Shader vertexShader_, fragmentShader_;
  }
  private bool isLinked = false;

  this(){
    //dummy
  }
  @property{
    public:
      Shader vertexShader(){return vertexShader_;}
      Shader fragmentShader(){return fragmentShader_;}
      void vertexShader(Shader s){
        if(!isLinked && s.type == Shader.Type.VertexShader){
          vertexShader_ = s;
        }else{
          enforce(0);
        }
      }
      void fragmentShader(Shader s){
        if(!isLinked && s.type == Shader.Type.FragmentShader){
          fragmentShader_ = s;
        }else{
          enforce(0);
        }
      }
  }

  abstract void link(){
    isLinked = true;
    import std.algorithm;
    [vertexShader, fragmentShader].each!((s){
      foreach(a; s.layout.layouts.byKeyValue){
        layout[a.key] = a.value;
      }
    });
    layout.rehash;
  }
  Layout layout;
}
abstract class Shader{
  enum Type{
    VertexShader,
    FragmentShader
  }
  private Type type_;
  @property{
    public Type type(){return type_;}
    protected void type(Type t){type_ = t;}
  }
  this(Type t){
    type = t;
  }

  abstract void loadGLSL(string);
  abstract void loadSPIRV(ubyte[]); //この形式でよいのかは不明(今のOpenGLでは利用不可、今後に期待)

  Layout layout;
}

private struct Layout{
  public GLuint[string] layouts;
  void opDispatch(string s)(GLuint i){
    layouts[s] = i;
  }
  GLuint opDispatch(string s)(){
    enforce(s in layouts, s ~ "is not found.");
    return layouts[s];
  }
  void opIndexAssign(GLuint a, string s){
    layouts[s] = a;
  }
  GLuint opIndex(string s){
    return layouts[s];
  }
  void rehash(){
    layouts.rehash;
  }
}
