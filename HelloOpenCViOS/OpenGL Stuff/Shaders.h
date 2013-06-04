//
//  Shaders.h
//  HelloOpenCViOS
//
//  Created by David on 04/06/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#pragma once

#include <OpenGLES/ES2/gl.h>

// Uniform index.
enum class Uniforms
{
    UNIFORM_Y,
    UNIFORM_UV,
    NUM_UNIFORMS
};
extern GLint uniforms[static_cast<int>(Uniforms::NUM_UNIFORMS)];

// Attribute index.
enum class Attributes
{
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    NUM_ATTRIBUTES
};

class Shader
{
	GLuint m_vertShader = 0, m_fragShader = 0;
	GLuint m_program = 0;
	
public:
	inline ~Shader(void)
	{
		if (m_vertShader)
		{
            glDeleteShader(m_vertShader);
            m_vertShader = 0;
        }
        if (m_fragShader)
		{
            glDeleteShader(m_fragShader);
            m_fragShader = 0;
        }
		if (m_program)
		{
			glDeleteProgram(m_program);
			m_program = 0;
		}
	}
	
	bool LoadShaders(std::string const &vertShaderPathname, std::string const &fragShaderPathname);
	bool CompileShader(GLuint &shader, GLenum const &type, std::string const &file);
	bool LinkProgram(GLuint const &prog);
	
	inline GLuint GetProgram(void) { return m_program; }
};
