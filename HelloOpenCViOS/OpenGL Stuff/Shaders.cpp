//
//  Shaders.cpp
//  HelloOpenCViOS
//
//  Created by David on 04/06/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#include "Shaders.h"
#include <iostream>     // std::cout
#include <fstream>      // std::ifstream

GLint uniforms[static_cast<int>(Uniforms::NUM_UNIFORMS)];

bool Shader::LoadShaders(std::string const &vertShaderPathname, std::string const &fragShaderPathname)
{
    // Create shader program.
    m_program = glCreateProgram();
    
    // Create and compile vertex shader.
//    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"YUVShader" ofType:@"vsh"];
    if (!CompileShader(m_vertShader, GL_VERTEX_SHADER, vertShaderPathname))
	{
		std::cerr << "Failed to compile vertex shader" << std::endl;
        return false;
    }
    
    // Create and compile fragment shader.
//    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"YUVShader" ofType:@"fsh"];
    if (!CompileShader(m_fragShader, GL_FRAGMENT_SHADER, fragShaderPathname))
	{
		std::cerr << "Failed to compile fragment shader" << std::endl;
        return false;
    }
    
    // Attach vertex shader to program.
    glAttachShader(m_program, m_vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(m_program, m_fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(m_program, static_cast<int>(Attributes::ATTRIB_VERTEX), "position");
    glBindAttribLocation(m_program, static_cast<int>(Attributes::ATTRIB_TEXCOORD), "texCoord");
    
    // Link program.
    if (!LinkProgram(m_program))
	{
		std::cerr << "Failed to link program: " << m_program << std::endl;
        
        if (m_vertShader) {
            glDeleteShader(m_vertShader);
            m_vertShader = 0;
        }
        if (m_fragShader) {
            glDeleteShader(m_fragShader);
            m_fragShader = 0;
        }
        if (m_program) {
            glDeleteProgram(m_program);
            m_program = 0;
        }
        
        return false;
    }
    
    // Get uniform locations.
    uniforms[static_cast<int>(Uniforms::UNIFORM_Y)]  = glGetUniformLocation(m_program, "SamplerY");
    uniforms[static_cast<int>(Uniforms::UNIFORM_UV)] = glGetUniformLocation(m_program, "SamplerUV");
    
    // Release vertex and fragment shaders.
    if (m_vertShader)
	{
        glDetachShader(m_program, m_vertShader);
        glDeleteShader(m_vertShader);
    }
    if (m_fragShader)
	{
        glDetachShader(m_program, m_fragShader);
        glDeleteShader(m_fragShader);
    }
    
    return true;
}

bool Shader::CompileShader(GLuint &shader, GLenum const &type, std::string const &file)
{
    GLint status;
	
	std::ifstream fileStream(file);
	
	if (fileStream)
	{
		std::istreambuf_iterator<char> begin(fileStream), end;
		const GLchar* source = std::string(begin, end).c_str();
		
		shader = glCreateShader(type);
		glShaderSource(shader, 1, &source, NULL);
		glCompileShader(shader);
		
#if defined(DEBUG)
		GLint logLength;
		glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
		if (logLength > 0)
		{
			GLchar *log = new GLchar[logLength];
			glGetShaderInfoLog(shader, logLength, &logLength, log);
			std::cerr << "Shader compile log:\n" << log << std::endl;
			delete [] log;
		}
#endif
		
		glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
		if (status == 0)
		{
			glDeleteShader(shader);
			return false;
		}
	}
	else
		return false;
    
    return true;
}

bool Shader::LinkProgram(GLuint const &prog)
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = new GLchar[logLength];
        glGetProgramInfoLog(prog, logLength, &logLength, log);
		std::cerr << "Program link log:\n" << log << std::endl;
        delete [] log;
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
        return false;
    
    return true;
}
