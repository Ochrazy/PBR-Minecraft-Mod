#version 120

uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D depthtex0;
uniform sampler2D gnormal;
uniform sampler2D composite;
uniform sampler2D gaux1;
uniform sampler2D gaux2;

varying vec4 texcoord;

uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
float pw = 1.0/ viewWidth;  // pixel width
float ph = 1.0/ viewHeight; // pixel height

bool isEntityQuartz(float e)
{
	return (e > 154.5/450.0 && e < 155.5/450.0);
}

bool isEntityEmeraldBlock(float e)
{
	return (e > 132.5/450.0 && e < 133.5/450.0);
}

bool isEntityCoalBlock(float e)
{
	return (e > 172.5/450.0 && e < 173.5/450.0);
}

// Celshading
float edepth(vec2 coord) 
{
	return texture2D(depthtex0,coord).z;
}

const float BORDER = 3.0;

vec3 celshade(vec3 color, vec2 mirrorTexcoord)
{
	//edge detect
	float d = edepth(mirrorTexcoord.xy);
	float dtresh = 1/(far-near)/5000.0;	
	vec4 dc = vec4(d,d,d,d);
	vec4 sa;
	vec4 sb;
	
	sa.x = edepth(mirrorTexcoord.xy + vec2(-pw,-ph)*BORDER);
	sa.y = edepth(mirrorTexcoord.xy + vec2(pw,-ph)*BORDER);
	sa.z = edepth(mirrorTexcoord.xy + vec2(-pw,0.0)*BORDER);
	sa.w = edepth(mirrorTexcoord.xy + vec2(0.0,ph)*BORDER);
	
	//opposite side samples
	sb.x = edepth(mirrorTexcoord.xy + vec2(pw,ph)*BORDER);
	sb.y = edepth(mirrorTexcoord.xy + vec2(-pw,ph)*BORDER);
	sb.z = edepth(mirrorTexcoord.xy + vec2(pw,0.0)*BORDER);
	sb.w = edepth(mirrorTexcoord.xy + vec2(0.0,-ph)*BORDER);
	
	vec4 dd = abs(2.0* dc - sa - sb) - dtresh;
	dd = vec4(step(dd.x,0.0),step(dd.y,0.0),step(dd.z,0.0),step(dd.w,0.0));
	
	float e = clamp(dot(dd,vec4(0.25f,0.25f,0.25f,0.25f)),0.0,1.0);
	return color * e;
}

vec3 color2Gray(vec3 color) 
{
	float gray = (color.r + color.g + color.b)/3.0;
	return vec3(gray);
}

vec3 color2Sepia(vec3 color) 
{
	vec3 sepia = vec3(0.0);
	sepia.r = (color.r * .393) + (color.g * .769) + (color.b * .189);
	sepia.g = (color.r * .349) + (color.g * .686) + (color.b * .168);
	sepia.b = (color.r * .272) + (color.g * .534) + (color.b * .131);
	return sepia / 2.0;
}

void main()
{
	vec4 reflectionColor = texture2D(composite, texcoord.st);
	vec4 reflectionTexcoords = texture2D(gaux2, texcoord.st);
	vec4 reflectionTexcoordsFromEndpoint = texture2D(gaux2, reflectionTexcoords.st);
	vec4 color = texture2D(gcolor, texcoord.st);
	
	// DoubleReflections
	if((reflectionTexcoords.a < 0.1) && (reflectionTexcoordsFromEndpoint.a < 0.1))
	{ 
		color.rgb = texture2D(gcolor, reflectionTexcoords.st).rgb;

		// Calculate final color again (double Reflections ) 
		vec4 colorNoReflections = texture2D(gdepth, texcoord.st);

		color.rgb = colorNoReflections.rgb * (1-colorNoReflections.a) + color.rgb * colorNoReflections.a;
	}
	
	// Apply Effects only to the Reflections
	if(reflectionTexcoords.a < 0.1)
	{
		float entityID = texture2D(gaux1, texcoord.st).r;

		if(isEntityEmeraldBlock(entityID))
			color.rgb = celshade(color.rgb, reflectionTexcoords.st);
		else if(isEntityQuartz(entityID)) 
			color.rgb = color2Sepia(color.rgb);
		else if(isEntityCoalBlock(entityID)) 
			color.rgb = color2Gray(color.rgb);
	}

	gl_FragColor = color;
}
