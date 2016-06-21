module kanity.drawing.window;

import kanity.imports;
import kanity.drawing.imports;
import kanity.drawing.renderer;
import kanity.drawing.renderer.opengl;

class Window{
  private{
    GLFWwindow* window;
    Renderer renderer;
  }
  this(){
    int result;
    //GLFWの初期化
    glfwSetErrorCallback(&error_callback);
    result = glfwInit();
    fatal(!result, "Failed to init 'GLFW3'.");
    //FreeImageの初期化
    FreeImage_Initialise();
  }
  ~this(){
    FreeImage_DeInitialise();
  }

  void init(){
    glfwWindowHint(GLFW_RESIZABLE, GL_FALSE);
    glfwWindowHint(GLFW_SAMPLES, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 5);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

  	window = glfwCreateWindow(640, 480, "Hello, GLFW3!!", null, null);
  	enforce(window, "Failed to create window.");

  	window.glfwMakeContextCurrent();
    DerelictGL3.reload;

    window.glfwGetFramebufferSize(&width, &height);

    glDebugMessageCallback(&glErrorCallback, cast(const(void)*)null);
    glDebugMessageControl(GL_DONT_CARE, GL_DONT_CARE, GL_DONT_CARE, 0, null, GL_TRUE);
    glViewport(0, 0, 640, 480);
    glClearColor(0.0f, 0.0f, 0.3f, 1.0f);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glEnable(GL_BLEND);

    renderer = new GLRenderer();

    auto shader = renderer.createShaderProgram();
    auto vs = renderer.createShader(Shader.Type.VertexShader);
    vs.layout.vertexPosition = 0;
    vs.layout.vertexTexCoord = 1;
    vs.layout.vertexColor = 2;
    vs.layout.MVPmatrix = 0;
    auto fs = renderer.createShader(Shader.Type.FragmentShader);
    fs.layout.textureSampler = 2;

    import std.file;
    vs.loadGLSL("./minimal.vert".readText);
    fs.loadGLSL("./minimal.frag".readText);
    shader.vertexShader = vs;
    shader.fragmentShader = fs;
    shader.link;

    renderer.perspectiveMatrix = orthographicMatrix(0, 640, 480, 0, -1, 1);

    auto image = FreeImage_Load(FIF_PNG, "SPTest.png", PNG_DEFAULT);
    enforce(image);
    image.FreeImage_FlipHorizontal();
    image.FreeImage_FlipVertical();

    import std.math, std.range, std.algorithm;
    width = FreeImage_GetWidth(image);
    height = FreeImage_GetHeight(image);

    auto data = new ubyte[width * height * 4];
    auto bits = cast(ubyte*)FreeImage_GetBits(image);
    auto pitch = FreeImage_GetPitch(image);
    for(int y = 0; y < height; y++){
      for(int x = 0; x < width; x++){
        auto i = (x + y * width) * 4;
        auto j = (x * 4 + y * pitch);
        data[i + 0] = bits[j + FI_RGBA_RED];
        data[i + 1] = bits[j + FI_RGBA_GREEN];
        data[i + 2] = bits[j + FI_RGBA_BLUE];
        data[i + 3] = bits[j + FI_RGBA_ALPHA];
      }
    }
    pixels = data;

    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    /*texture.glTextureParameteri(GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    texture.glTextureParameteri(GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    texture.glTextureParameteri(GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    texture.glTextureParameteri(GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);*/
    auto texture = renderer.createTexture(width, height, Texture.Format.RGBA8);
    texture.loadImage(pixels);

    auto object = renderer.createDrawableObject2D();
    object.shaderProgram = shader;
    object.vertexAttributeLayout = shader.layout.vertexPosition;
    object.texCoordAttributeLayout = shader.layout.vertexTexCoord;
    object.mvpMatrixLayout = shader.layout.MVPmatrix;
    mat4 model = mat4.identity.rotatez(3.1415926535).scale(0.5, 0.5, 1.0).translate(320, 240, 0.0);
    object.modelMatrix = model;

    object.vertex = [
      vec2(0, 0),
      vec2(320, 0),
      vec2(0, 240),
      vec2(320, 240)
    ];
    object.texCoord = [
      vec2(0.0, 0.0),
      vec2(1.0, 0.0),
      vec2(0.0, 1.0),
      vec2(1.0, 1.0)
    ];
    object.indices = [
      0, 2, 3,
      0, 3, 1
    ];

    object.texture[shader.layout.textureSampler] = texture;

    renderer.add(object);

  }
  uint textureId;
  ubyte[] pixels;
  int width;
  int height;

  void draw(){
    renderer.draw(true);

    window.glfwSwapBuffers();
    glfwPollEvents();
  }

  @property int windowWidth(){return 640;}

  @property bool isRunning(){
    return !window.glfwWindowShouldClose();
  }
}

extern(C) void error_callback(int error, const(char)* description) nothrow{
  try{
    errorf("%s, %d", description.to!string, error);
  }catch{

  }
}

extern(C) void glErrorCallback(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const(GLchar)* message, void* userParam) nothrow{
  try{
    error(message.to!string);
  }catch{}
}
