module kanity.drawing.renderer.opengl.object;

import kanity.imports;
import kanity.drawing.imports;
import kanity.drawing.renderer;
import kanity.drawing.renderer.opengl;

import std.range;
import std.algorithm;

class GLDrawableObject2D : DrawableObject2D{
  private{
    GLuint vao;
    GLuint[uint] vbos;
    GLuint indexBuffer = -1;

    vec2[] vertex_;
    bool useVertex = false;

  }

  this(){
    super();
    glCreateVertexArrays(1, &vao);
  }
  this(Renderer r){
    super(r);

    glCreateVertexArrays(1, &vao);
  }
  ~this(){
    vbos.byValue.each!((a){
      glDeleteBuffers(1, &a);
    });
    glDeleteVertexArrays(1, &vao);
  }

  override void draw(bool flag){
    if(!flag) return;

    auto s = cast(GLShaderProgram)(shaderProgram);
    glUseProgram(s.program);

    foreach(a; uniformMat4.byKeyValue){
      glUniformMatrix4fv(a.key, 1, GL_TRUE, a.value.value_ptr);
    }
    foreach(a; texture.byKeyValue.enumerate){
      glActiveTexture(GL_TEXTURE0 + a.index.to!uint);
      glUniform1i(a.value.key, a.index.to!int); //Set textureModule to texture sampler
      auto t = cast(GLTexture)(a.value.value);
      glBindTexture(GL_TEXTURE_2D, t.texture);
    }

    glBindVertexArray(vao);
    if(useIndexBuffer){
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
      glDrawElements(GL_TRIANGLES, this.indicesNum, GL_UNSIGNED_INT, cast(void*)0);
    }else{
      glDrawArrays(GL_TRIANGLES, 0, this.vertexNum);
    }
  }

  override void setAttribute(int index, float[] data, lazy uint dim = 0){
    super.setAttribute(index, data);

    if(index !in vbos){
      uint buf;
      glCreateBuffers(1, &buf);
      vbos[index] = buf;

      vao.glEnableVertexArrayAttrib(index);
      vao.glVertexArrayAttribFormat(index, dim, GL_FLOAT, GL_FALSE, 0);
      vao.glVertexArrayAttribBinding(index, index);
      vao.glVertexArrayVertexBuffer(index, vbos[index], 0, GLfloat.sizeof.to!int * dim);
    }
    vbos[index].glNamedBufferData(data.sizeof * data.length, data.ptr, GL_STATIC_DRAW);
  }

  override void setIndices(uint[] data){
    super.setIndices(data);

    if(indexBuffer == -1){
      glCreateBuffers(1, &indexBuffer);
    }
    indexBuffer.glNamedBufferData(data.sizeof * data.length, data.ptr, GL_STATIC_DRAW);
  }
}
