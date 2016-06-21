module kanity.drawing.renderer.opengl.texture;

import kanity.imports;
import kanity.drawing.imports;
import kanity.drawing.renderer;

class GLTexture : Texture{
  private{
    GLuint texture_;
  }
  @property{
    public GLuint texture(){return texture_;}
    private void texture(GLuint t){texture_ = t;}
  }
  this(uint w, uint h, Format f){
    super(w, h, f);
    GLuint id;
    glCreateTextures(GL_TEXTURE_2D, 1, &id);
    texture = id;
    texture.glTextureStorage2D(1, (a){
      switch(a){
        case Format.RGB8:
          return GL_RGB8;
        case Format.RGBA8:
          return GL_RGBA8;
        default:
          enforce(0, "Unknown format.");
          return 0;
      }
    }(format), w, h);
  }
  ~this(){
    glDeleteTextures(1, &texture_);
  }

  override void loadImage(ubyte[] image){
    texture.glTextureSubImage2D(0, 0, 0, width, height, (a){
      switch(a){
        case Format.RGB8:
          return GL_RGB;
        case Format.RGBA8:
          return GL_RGBA;
        default:
          assert(0);
      }
    }(format), GL_UNSIGNED_BYTE, cast(void*)(image.ptr));
  }
}
