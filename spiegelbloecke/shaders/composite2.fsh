#version 120

uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D gnormal;
uniform sampler2D composite;
uniform sampler2D gaux1;
uniform sampler2D gaux2;

uniform mat4 gbufferProjectionInverse;

varying vec4 texcoord;

const int gaussRadius = 11;

// sigma = 5
const float gaussFilter[gaussRadius] = float[gaussRadius](0.066414, 0.079465, 0.091364, 0.100939, 0.107159, 0.109317, 0.107159, 0.100939, 0.091364, 0.079465, 0.066414);

uniform float viewHeight;
float pixelSize = 1.0/viewHeight;
float blurStrength = 3.0;

vec3 convertScreenSpaceToWorldSpace(vec2 coord)
{
    vec4 fragposition = gbufferProjectionInverse * vec4(vec3(coord, texture2D(gdepth, coord).x) * 2.0 - 1.0, 1.0);
    fragposition /= fragposition.w;
    return fragposition.xyz;
}

vec3 GetNormal(vec2 coord) 
{
	vec3 normal = vec3(0.0f);
		 normal = texture2D(gnormal, coord.st).rgb;
	normal = normal * 2.0f - 1.0f;

	normal = normalize(normal);

	return normal;
}

void main()
{
	vec4 reflectionColor = texture2D(composite, texcoord.st);

	// Blur the color
	vec4 reflectionTexcoords = texture2D(gaux2, texcoord.st);
	blurStrength = blurStrength * reflectionTexcoords.z;
	
	// Reflection-Pixels have an alpha of zero
    if((reflectionTexcoords.a < 0.1) && (blurStrength > 0.1)) 
	{
		// For the vertical pass: just blur the reflection on the mirror,
		// since we can't actually access all the colors on the edges -> need a fix!
		vec2 deltaTexcoords = texcoord.st - float(int(gaussRadius/2)) * vec2(0.0, 1.0) * pixelSize * blurStrength;
		vec3 blurredColor = vec3(0.0);
		for (int i = 0; i < gaussRadius; i++) 
		{ 
			blurredColor.rgb += gaussFilter[i] * texture2D(composite, deltaTexcoords.st).rgb;
			deltaTexcoords.st += vec2(0.0, 1.0) * pixelSize * blurStrength;
		}
		reflectionColor.rgb = blurredColor;
	}
	
	// Calculate final color 
    float reflectivity = reflectionColor.a;
	vec4 color = texture2D(gcolor, texcoord.st);	

	// Calculate Fresnel
	vec3 cameraSpacePosition = convertScreenSpaceToWorldSpace(texcoord.st);
	vec3 cameraSpaceNormal = GetNormal(texcoord.st);	
	float fresnelPower = 5.0 * texture2D(gaux1, texcoord.st).y;
	// NdotL will be in range of -1..0
	float fresnel = 0.25 + (1-0.25) * pow(clamp(1.0f + dot(normalize(cameraSpacePosition.xyz), cameraSpaceNormal), 0.0f, 1.0f), fresnelPower);

	// Add the Fresnel
	reflectivity *= fresnel;

	// This is actually the physically correct way of adding Fresnel. 
	// But we don't want even more Reflections (that are probably wrong anyway) ;)
	//reflectivity = mix(reflectivity, 1.0, fresnel); 

	// Calculate final color
	color.rgb = color.rgb * (1-reflectivity) + reflectionColor.rgb * reflectivity;

	//gl_FragData[0] = vec4(fresnel, fresnel, fresnel, 1.0);
	//gl_FragData[0] = vec4(reflectivity, reflectivity, reflectivity, 1.0);
	gl_FragData[0] = color;
	gl_FragData[1] = vec4(texture2D(gcolor, texcoord.st).rgb, reflectivity);
	gl_FragData[2] = texture2D(gnormal, texcoord.st);
	gl_FragData[3] = reflectionColor; // Reflection color
	gl_FragData[4] = texture2D(gaux1, texcoord.st); // entity
	gl_FragData[5] = texture2D(gaux2, texcoord.st); // reflectionTexcoords
}
