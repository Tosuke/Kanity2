module kanity.drawing.renderer.interfaces;

import kanity.imports;
import kanity.drawing.imports;
import kanity.drawing.renderer;

abstract class Renderer : IDrawable{
  import std.container, std.range;

  public ShaderProgram shaderProgram;
  public mat4 perspectiveMatrix;
  private SList!IDrawable list;

  this(){
    perspectiveMatrix = mat4.identity;
  }

  abstract{
    Texture createTexture(uint width, uint height, Texture.Format format);
    Shader createShader(Shader.Type type);
    ShaderProgram createShaderProgram();
    DrawableObject2D createDrawableObject2D();
  }
  @property{

  }
  final override void draw(){
    preDraw();
    foreach(obj; list[]){
      obj.draw();
    }
    postDraw();
  }
  final override void draw(bool f){
    preDraw();
    foreach(obj; list[]){
      obj.draw(f);
    }
    postDraw();
  }
  void preDraw(){}
  void postDraw(){}

  void add(IDrawable obj){
    list.insertFront(obj);
  }
}

abstract class Texture{
  enum Format{
    RGB8, RGBA8
  }
  private{
    uint width_, height_;
    Format format_;
  }
  @property{
    public:
      uint width(){return width_;}
      uint height(){return height_;}
      Format format(){return format_;}
    protected:
      void width(uint w){width_ = w;}
      void height(uint h){height_ = h;}
      void format(Format f){format_ = f;}
  }

  this(uint w, uint h, Format f){
    width = w; height = h; format = f;
  }

  //画像を読みこむ
  abstract void loadImage(ubyte[]);
}
