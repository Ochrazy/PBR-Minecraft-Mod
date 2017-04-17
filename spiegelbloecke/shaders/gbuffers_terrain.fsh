#version 120

uniform sampler2D texture;
uniform sampler2D lightmap;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec3 normal;

varying float entity;

void main() 
{
	gl_FragData[0] = texture2D(texture, texcoord.st) * texture2D(lightmap, lmcoord.st) * color; // color
	gl_FragData[1] = vec4(vec3(gl_FragCoord.z), 1.0); // depth
	gl_FragData[2] = vec4(normal * 0.5 + 0.5, 1.0); // normal in range of 0..1
	gl_FragData[4] = vec4(entity/450.0, 0.0, 0.0, 1.0); // gaux1
	gl_FragData[5] = vec4(texcoord.x, texcoord.y, 0.0, 1.0); // gaux2
}