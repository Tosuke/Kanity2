module kanity.drawing.renderer.opengl.renderer;

import kanity.imports;
import kanity.drawing.imports;
import kanity.drawing.renderer;
import kanity.drawing.renderer.opengl;

class GLRenderer : Renderer{
  override{
    Texture createTexture(uint w, uint h, Texture.Format f){
      return new GLTexture(w, h, f);
    }
    Shader createShader(Shader.Type t){
      return new GLShader(t);
    }
    ShaderProgram createShaderProgram(){
      return new GLShaderProgram();
    }
    DrawableObject2D createDrawableObject2D(){
      return new GLDrawableObject2D(this);
    }
  }

  override void preDraw(){
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  }
}
