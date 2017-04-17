#version 120

uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D gnormal;
uniform sampler2D composite;
uniform sampler2D gaux1;
uniform sampler2D gaux2;

varying vec4 texcoord;

const int gaussRadius = 11;

// sigma = 5
const float gaussFilter[gaussRadius] = float[gaussRadius](0.066414, 0.079465, 0.091364, 0.100939, 0.107159, 0.109317, 0.107159, 0.100939, 0.091364, 0.079465, 0.066414);

uniform float viewWidth;
float pixelSize = 1.0/viewWidth;
float blurStrength = 3.0;

void main() 
{
	vec4 reflectionColor = texture2D(composite, texcoord.st);

	// Blur the color
	vec4 reflectionTexcoords = texture2D(gaux2, texcoord.st);
	blurStrength = blurStrength * reflectionTexcoords.z;
	
	// Reflection-Pixels have an alpha of zero
    if((reflectionTexcoords.a < 0.1) && (blurStrength > 0.1)) 
	{
		// Use the texcoords on the actual mirror
		vec2 deltaTexcoords = texcoord.st - float(int(gaussRadius/2)) * vec2(1.0, 0.0) * pixelSize * blurStrength;
		vec3 blurredColor = vec3(0.0);
		for (int i = 0; i < gaussRadius; i++) 
		{ 
			// Get the Color from the Reflection Point!, so that we have all the color information 
			// (the blur would go off the edges of the mirror block)
			blurredColor.rgb += gaussFilter[i] * texture2D(composite, texture2D(gaux2, deltaTexcoords.st).st).rgb;

			// Do a Step of one pixel (* blurStrength) on the mirror
			deltaTexcoords.st += vec2(1.0, 0.0) * pixelSize * blurStrength;
		}
		reflectionColor.rgb = blurredColor;
	}

	gl_FragData[0] = texture2D(gcolor, texcoord.st);
	gl_FragData[1] = texture2D(gdepth, texcoord.st);
	gl_FragData[2] = texture2D(gnormal, texcoord.st);
	gl_FragData[3] = reflectionColor; // Reflection color
	gl_FragData[4] = texture2D(gaux1, texcoord.st); // entity
	gl_FragData[5] = texture2D(gaux2, texcoord.st); // reflectionTexcoords
}

