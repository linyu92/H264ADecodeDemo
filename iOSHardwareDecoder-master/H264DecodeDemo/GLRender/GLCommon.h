//
//  GLCommon.h
//  practicework
//
//  Created by bleach on 16/5/25.
//  Copyright © 2016年 duowan. All rights reserved.
//

#ifndef GLCommon_h
#define GLCommon_h

#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

#pragma mark - GL
#define STRINGIZE(x) #x
#define SHADER_STRING(text) @ STRINGIZE(text)

typedef struct GLTextureOptions {
    GLenum minFilter;
    GLenum magFilter;
    GLenum wrapS;
    GLenum wrapT;
    GLenum internalFormat;
    GLenum format;
    GLenum type;
    GLboolean mimap;
} GLTextureOptions;

typedef struct GLColor {
    GLfloat red;
    GLfloat green;
    GLfloat blue;
    GLfloat alpha;
} GLColor;

typedef struct GLVertex4 {
    GLfloat vx;
    GLfloat vy;
    GLfloat vz;
    GLfloat vw;
} GLVertex4;

typedef struct GLTexcoord2 {
    GLfloat tx;
    GLfloat ty;
} GLTexcoord2;

typedef struct GLPackData {
    GLVertex4 vertex;
    GLTexcoord2 texcoord;
    GLfloat alpha;
} GLPackData;

typedef struct GLQuad {
    GLPackData data[4];
} GLQuad;


static GLfloat GLSquareData[] = {
    -1.0f, 1.0f, 0.0f, 1.0f,    0.0f, 1.0f,     1.0f,
    -1.0f, -1.0f, 0.0f, 1.0f,   0.0f, 0.0f,     1.0f,
    1.0f, -1.0f, 0.0f, 1.0f,    1.0f, 0.0f,     1.0f,
    1.0f, 1.0f, 0.0f, 1.0f,     1.0f, 1.0f,     1.0f,
};

static inline const char * GetGLErrorString(GLenum error) {
    const char *str;
    switch(error) {
        case GL_NO_ERROR:
            str = "GL_NO_ERROR";
            break;
        case GL_INVALID_ENUM:
            str = "GL_INVALID_ENUM";
            break;
        case GL_INVALID_VALUE:
            str = "GL_INVALID_VALUE";
            break;
        case GL_INVALID_OPERATION:
            str = "GL_INVALID_OPERATION";
            break;
        default:
            str = "(ERROR: Unknown Error Enum)";
            break;
    }
    return str;
}

#define GetGLError()									\
{														\
GLenum err = glGetError();							\
while (err != GL_NO_ERROR) {						\
NSLog(@"GLError %s set in File:%s Line:%d\n",   \
GetGLErrorString(err), __FILE__, __LINE__);	    \
err = glGetError();								\
}													\
}
#endif /* GLCommon_h */
