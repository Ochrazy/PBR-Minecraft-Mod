#version 120

// Set some Variables for the Shader Mod
const int 		R8 						= 0;
const int 		RG8 					= 0;
const int 		RGB8 					= 0;
const int 		RGB16 					= 0;
const int 		RGBA8 					= 0;
const int 		RGBA16 					= 1;
const int 		gcolorFormat 			= RGBA16;
const int 		gdepthFormat 			= RGBA16;
const int 		gnormalFormat 			= RGBA16;
const int 		compositeFormat 		= RGBA16;
const int 		gaux1Format 		    = RGBA16;
const int 		gaux2Format 		    = RGBA16;
//

uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D gdepthtex;
uniform sampler2D gnormal;
uniform sampler2D composite;
uniform sampler2D gaux1;
uniform sampler2D gaux2;

// Reflection-Pixels have an alpha of zero
vec4 reflectionTexcoords = vec4(0, 0, 0, 1); // xy = coords; z = blurStrength; a = is it a Reflection?

varying vec4 texcoord;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform float frameTimeCounter;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
float pw = 1.0/ viewWidth;  // pixel width
float ph = 1.0/ viewHeight; // pixel height

// Use this to get the blockID/entity
float getEntityID()
{
	vec4 entity = texture2D(gaux1, texcoord.st);

	// Sky/Entity etc. write their color to gaux1 -> so overwrite it here again!
	if(entity.a > 0.999 && entity.b < 0.001) 
	{
		return entity.r;
	}
	else return 0.0; 
}

// Helper functions
bool isEntityStone(float e)
{
    return (e > 0.5/450.0 && e < 1.5/450.0);
}

bool isEntityCobblestone(float e)
{
    return (e > 3.5/450.0 && e < 4.5/450.0);
}

bool isEntityGravel(float e)
{
    return (e > 12.5/450.0 && e < 13.5/450.0);
}

bool isEntityGoldOre(float e)
{
    return (e > 13.5/450.0 && e < 14.5/450.0);
}

bool isEntityIronOre(float e)
{
    return (e > 14.5/450.0 && e < 15.5/450.0);
}

bool isEntityCoalOre(float e)
{
    return (e > 15.5/450.0 && e < 16.5/450.0);
}

bool isEntityOakWoodPlank(float e)
{
    return (e > 4.5/450.0 && e < 5.5/450.0);
}

bool isEntityGold(float e)
{
	return (e > 40.5/450.0 && e < 41.5/450.0);
}

bool isEntityIron(float e)
{
	return (e > 41.5/450.0 && e < 42.5/450.0);
}

bool isEntityDiamond(float e)
{
	return (e > 56.5/450.0 && e < 57.5/450.0);
}

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

bool isEntityMirror(float entity)
{           // Blurry
	return (isEntityStone(entity) ||
            isEntityCobblestone(entity) ||
            isEntityGravel(entity) ||
			// Reflectivity
            isEntityGoldOre(entity) ||
            isEntityIronOre(entity) ||
            isEntityCoalOre(entity) ||
			// Bend Mirror
            isEntityDiamond(entity) ||
			// "Realistic" Materials
            isEntityOakWoodPlank(entity) ||
            isEntityGold(entity) ||
            isEntityIron(entity) ||
			// Effects (CelShading/Sepia)
            isEntityQuartz(entity) ||
			isEntityEmeraldBlock(entity) ||
			isEntityCoalBlock(entity));
}

// Gets the local Texture Coordinates (range 0..1)
vec2 getLocalTextureCoordinates01(vec2 screenSpaceTextureCoordinates, float entity)
{
	// This function works only for a few types correctly!
	vec4 localTexcoords = texture2D(gaux2, texcoord.st);
	if(localTexcoords.a > 0.999 && localTexcoords.b < 0.001) 
	{
		if(isEntityIron(entity))
			return ((texture2D(gaux2, screenSpaceTextureCoordinates.st) - vec4(0.1568, 0.3764,0,0)) * vec4(63.0, 33.0, 1, 1)).st;
		else if(isEntityDiamond(entity))
			return ((texture2D(gaux2, screenSpaceTextureCoordinates.st) - vec4(0.12549, 0.12549,0,0)) * vec4(63.0, 33.0, 1, 1)).st;
	}
	else return vec2(0.0); 
}

vec3 convertScreenSpaceToWorldSpace(vec2 coord)
{
    vec4 fragposition = gbufferProjectionInverse * vec4(vec3(coord, texture2D(gdepthtex, coord).x) * 2.0 - 1.0, 1.0);
    fragposition /= fragposition.w;
    return fragposition.xyz;
}

vec3 convertCameraSpaceToScreenSpace(vec3 cameraSpace) 
{
    vec4 clipSpace = gbufferProjection * vec4(cameraSpace, 1.0);
    vec3 NDCSpace = clipSpace.xyz / clipSpace.w;
    vec3 screenSpace = 0.5 * NDCSpace + 0.5;
		 screenSpace.z = 0.1f;
    return screenSpace;
}

vec3 GetNormal(in vec2 coord) 
{
	vec3 normal = vec3(0.0f);
		 normal = texture2D(gnormal, coord.st).rgb;
	normal = normal * 2.0f - 1.0f;

	normal = normalize(normal);

	return normal;
}

// Raytracer 
vec4 ComputeRaytraceReflection(vec2 screenSpacePosition2D, vec3 cameraSpaceNormal) 
{
    float initialStepAmount = 1.0 - clamp(0.1f / 100.0, 0.0, 0.99);
	
	// 
    vec3 cameraSpacePosition = convertScreenSpaceToWorldSpace(screenSpacePosition2D);	
		 
    vec3 cameraSpaceViewDir = normalize(cameraSpacePosition);
    vec3 cameraSpaceVector = initialStepAmount * normalize(reflect(cameraSpaceViewDir,cameraSpaceNormal));
	vec3 oldPosition = cameraSpacePosition;

	// Normal Offset
    vec3 cameraSpaceVectorPosition = oldPosition + cameraSpaceVector + normalize(cameraSpaceNormal) * 0.5;
    vec3 currentPosition = convertCameraSpaceToScreenSpace(cameraSpaceVectorPosition);
	vec4 raytracedColor = vec4(0.0);
    const int maxRefinements = 3;
	int numRefinements = 0;
    int count = 0;
	vec2 finalSamplePos = texcoord.st;

	int numSteps = 0;

    for (int i = 0; i < 40; i++)
    {
        if(currentPosition.x < 0 || currentPosition.x > 1 ||
           currentPosition.y < 0 || currentPosition.y > 1 ||
           currentPosition.z < 0 || currentPosition.z > 1 ||
           -cameraSpaceVectorPosition.z < 0.0f)
        { 
		   break; 
		}

        vec2 samplePos = currentPosition.xy;
        float sampleDepth = convertScreenSpaceToWorldSpace(samplePos).z;

        float currentDepth = cameraSpaceVectorPosition.z;
        float diff = sampleDepth - currentDepth;
        float error = length(cameraSpaceVector / pow(2.0f, numRefinements));

        //If a collision was detected, refine raymarch
        if(diff >= 0 && diff <= error * 2.00f && numRefinements <= maxRefinements) 
        {
        	//Step back
        	cameraSpaceVectorPosition -= cameraSpaceVector / pow(2.0f, numRefinements);
        	++numRefinements;
		//If refinements run out
		} 
		else if (diff >= 0 && diff <= error * 4.0f && numRefinements > maxRefinements)
		{
			finalSamplePos = samplePos;
			reflectionTexcoords.st = finalSamplePos.st;	
			reflectionTexcoords.a = 0.0;
			break;
		}		
		
        cameraSpaceVectorPosition += cameraSpaceVector / pow(2.0f, numRefinements);

        if (numSteps > 1)
			cameraSpaceVector *= 1.375f;	//Each step gets bigger

		currentPosition = convertCameraSpaceToScreenSpace(cameraSpaceVectorPosition);
        count++;
        numSteps++;
    }
	
	raytracedColor.rgb = texture2D(gcolor, finalSamplePos).rgb;

	// smooth border (round edges)
	raytracedColor.a = clamp(1 - pow(distance(vec2(0.5), finalSamplePos)*1.6, 10.0), 0.0, 1.0);

    return raytracedColor;
}

void main() 
{
	// Get BlockID
	float entityID = getEntityID();

	// Get local Texcoords
	vec2 localTexcoords = getLocalTextureCoordinates01(texcoord.st, entityID);

	vec4 color = vec4(texture2D(gcolor, texcoord.st).rgb, 1.0);
	vec4 reflectionColor = vec4(texture2D(gcolor, texcoord.st).rgb, 1.0); // alpha = Reflectivity

	// For better readability
	float reflectivity = 1.0;
	float blurStrength = 0.0; 
	float fresnelPower = 0.0; // no Fresnel

	// Raytrace Reflections
	if(isEntityMirror(entityID)) 
	{
		// Get current normal
		vec3 cameraSpaceNormal = GetNormal(texcoord.st);	

		if(isEntityIron(entityID)) 
		{
			blurStrength = 0.5; 
            reflectivity = 0.5;
			fresnelPower = 0.5;
		}
		
		if(isEntityGold(entityID))
		 {
			blurStrength = 0.0; // do not blur gold-reflections
            reflectivity = 0.8;
			fresnelPower = 0.2;
		}

		if(isEntityOakWoodPlank(entityID)) 
		{
			blurStrength = 1.0; 
            reflectivity = 0.8;
			fresnelPower = 1.0;
		}
		
		if(isEntityDiamond(entityID)) {
			// Bend Mirror (very easy and naiive Implementation, but enough for nice Screenshots ;)
			//cameraSpaceNormal = normalize(cameraSpaceNormal + (vec3(0.0, 0.35, 0.0) * (localTexcoords.sts * 2.0 - 1.0)));
			cameraSpaceNormal = normalize(cameraSpaceNormal - (vec3(0.0, 0.45, 0.0) * (localTexcoords.sts * 2.0 - 1.0)));
			blurStrength = 0.0; // do not blur diamond-reflections
			reflectivity = 1.0;
		}
        else if(isEntityGoldOre(entityID))
            reflectivity = 0.8;
        else if(isEntityIronOre(entityID))
            reflectivity = 0.4;
        else if(isEntityCoalOre(entityID))
            reflectivity = 0.25;
        else if(isEntityStone(entityID))
        {
            reflectivity = 1.0;
            blurStrength = 0.0;
			fresnelPower = 0.0;
        }
        else if(isEntityCobblestone(entityID))
        {
            reflectivity = 1.0;
            blurStrength = 0.5;
        }
        else if(isEntityGravel(entityID))
        {
            reflectivity = 1.0;
            blurStrength = 1.0;
        }
		else if(isEntityEmeraldBlock(entityID))
		{
			blurStrength = 0.0; 
            reflectivity = 1.0;
			fresnelPower = 0.0;
		}
		else if(isEntityQuartz(entityID)) 
		{
			blurStrength = 0.0; 
            reflectivity = 1.0;
			fresnelPower = 0.0;
		}
		else if(isEntityCoalBlock(entityID)) 
		{
			blurStrength = 0.0; 
            reflectivity = 1.0;
			fresnelPower = 0.0;
		}
		
		// Calculate the Reflection
		vec4 raytracedColor = ComputeRaytraceReflection(texcoord.st, cameraSpaceNormal);

		reflectionTexcoords.z = blurStrength; 
        reflectionColor.a = reflectivity;

		reflectionColor.rgb = raytracedColor.rgb;
		reflectionColor.a *= raytracedColor.a;
	} 

	// fix for hand-Reflection Interaction
	vec4 depthHand = texture2D(gdepth, texcoord.st);
	if(depthHand.a > 0.09 && depthHand.a < 0.11)
	{					
			reflectionTexcoords = vec4(0.0, 0.0, 0.0, 1.0);
			color.rgb = texture2D(gcolor, texcoord.st).rgb;
			reflectionColor.rgb = texture2D(gcolor, texcoord.st).rgb;
	}	

	//gl_FragData[0] = vec4(localTexcoords.st, 0.0, 1.0); // output local texture coordinates color
	gl_FragData[0] = color; // local texture coordinates color
	gl_FragData[1] = texture2D(gdepth, texcoord.st);
	gl_FragData[2] = texture2D(gnormal, texcoord.st);
	gl_FragData[3] = reflectionColor; // Reflection color
	gl_FragData[4] = vec4(entityID, fresnelPower, 0.0, 1.0); // entity
	gl_FragData[5] = reflectionTexcoords; // reflectionTexcoords (gaux2)
}

