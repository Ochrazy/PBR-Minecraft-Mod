#version 120

varying vec4 color;
varying vec3 normal;
varying vec4 texcoord;
varying vec4 lmcoord;

attribute vec4 mc_Entity;
varying float entity;

void main() 
{
	texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;		
	lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;

	gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;

	color = gl_Color;

	normal = normalize(gl_NormalMatrix * gl_Normal);

	entity = mc_Entity.x;
}