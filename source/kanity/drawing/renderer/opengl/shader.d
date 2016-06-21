module kanity.drawing.renderer.opengl.shader;

import kanity.imports;
import kanity.drawing.imports;
import kanity.drawing.renderer;

class GLShaderProgram : ShaderProgram{
  private GLuint program_;
  @property{
    public GLuint program(){return program_;}
    private void program(GLuint i){program_ = i;}
  }
  this(){
    program = glCreateProgram();
  }
  ~this(){
    glDeleteProgram(program);
  }
  override void link(){
    enforce(vertexShader !is null && fragmentShader !is null);

    auto v = cast(GLShader)vertexShader;
    program.glAttachShader(v.shader);
    auto f = cast(GLShader)fragmentShader;
    program.glAttachShader(f.shader);

    program.glLinkProgram();

    GLint result;
    program.glGetProgramiv(GL_LINK_STATUS, &result);
    if(!result){
      GLint logLength;
      program.glGetProgramiv(GL_INFO_LOG_LENGTH, &logLength);
      logLength = logLength == 0 ? 1 : logLength;
      auto logMessage = new char[logLength];
      program.glGetProgramInfoLog(logLength, null, logMessage.ptr);
      error(logMessage.to!string);
    }

    super.link();
  }
}
class GLShader : Shader{
  private GLuint shader_;
  @property{
    public GLuint shader(){return shader_;}
    private void shader(GLuint s){shader_ = s;}
  }
  this(Type t){
    super(t);
    shader = glCreateShader((a){
      switch(a){
        case Type.VertexShader:
          return GL_VERTEX_SHADER;
        case Type.FragmentShader:
          return GL_FRAGMENT_SHADER;
        default:
          assert(0);
      }
    }(type));
  }
  ~this(){
    glDeleteShader(shader);
  }
  override void loadGLSL(string source){
    const char* str = source.toStringz;
    shader.glShaderSource(1, &str, null);
    shader.glCompileShader();

    GLint result;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &result);
    if(!result){
      GLint logLength;
      glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
      logLength = logLength == 0 ? 1 : logLength;
      auto logMessage = new char[logLength];
      glGetShaderInfoLog(shader, logLength, null, logMessage.ptr);
      error(logMessage.to!string);
    }
  }
  override void loadSPIRV(ubyte[] data){
    enforce(0, "Sorry this version of OpenGL is not supported for SPIRV.");
  }
}
