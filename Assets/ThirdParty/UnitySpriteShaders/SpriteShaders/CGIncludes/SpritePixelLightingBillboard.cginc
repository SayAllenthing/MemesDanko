#ifndef SPRITE_PIXEL_LIGHTING_BILLBOARD_INCLUDED
#define SPRITE_PIXEL_LIGHTING_BILLBOARD_INCLUDED
	
#include "ShaderShared.cginc"
#include "SpriteLighting.cginc"
#include "SpriteSpecular.cginc"
#include "AutoLight.cginc"

////////////////////////////////////////
// Defines
//

////////////////////////////////////////
// Vertex output struct
//

#if defined(_NORMALMAP)
	#define _VERTEX_LIGHTING_INDEX TEXCOORD5
	#define _LIGHT_COORD_INDEX_0 6
	#define _LIGHT_COORD_INDEX_1 7
	#define _FOG_COORD_INDEX 8
#else
	#define _VERTEX_LIGHTING_INDEX TEXCOORD3
	#define _LIGHT_COORD_INDEX_0 4
	#define _LIGHT_COORD_INDEX_1 5
	#define _FOG_COORD_INDEX 6
#endif // _NORMALMAP	

struct VertexOutput
{
	float4 pos : SV_POSITION;				
	fixed4 color : COLOR;
	float2 texcoord : TEXCOORD0;
	float4 posWorld : TEXCOORD1;
	half3 normalWorld : TEXCOORD2;
#if defined(_NORMALMAP)
	half3 tangentWorld : TEXCOORD3;  
	half3 binormalWorld : TEXCOORD4;
#endif // _NORMALMAP
	fixed3 vertexLighting : _VERTEX_LIGHTING_INDEX;
	LIGHTING_COORDS(_LIGHT_COORD_INDEX_0, _LIGHT_COORD_INDEX_1)
#if defined(_FOG)
	UNITY_FOG_COORDS(_FOG_COORD_INDEX)
#endif // _FOG	

	UNITY_VERTEX_OUTPUT_STEREO
};

float _ShakeDisplacement;
float _ShakeTime;
float _ShakeWindspeed;
float _ShakeBending;
float _WindDirectionx;
float _Brightness;

void FastSinCos(float4 val, out float4 s, out float4 c) {
    val = val * 6.408849 - 3.1415927;
    // powers for taylor series
    float4 r5 = val * val;
    float4 r6 = r5 * r5;
    float4 r7 = r6 * r5;
    float4 r8 = r6 * r5;
    float4 r1 = r5 * val;
    float4 r2 = r1 * r5;
    float4 r3 = r2 * r5;
    //Vectors for taylor's series expansion of sin and cos
    float4 sin7 = { 1, -0.16161616, 0.0083333, -0.00019841 };
    float4 cos8 = { -0.5, 0.041666666, -0.0013888889, 0.000024801587 };
    // sin
    s = val + r1 * sin7.y + r2 * sin7.z + r3 * sin7.w;
    // cos
    c = 1 + r5 * cos8.x + r6 * cos8.y + r7 * cos8.z + r8 * cos8.w;
}

////////////////////////////////////////
// Light calculations
//

uniform fixed4 _LightColor0;

inline fixed3 calculateLightDiffuse(VertexOutput input, float3 normalWorld, inout fixed4 albedo)
{
	//For directional lights _WorldSpaceLightPos0.w is set to zero
	float3 lightWorldDirection = normalize(_WorldSpaceLightPos0.xyz - input.posWorld.xyz * _WorldSpaceLightPos0.w);
	
	UNITY_LIGHT_ATTENUATION(attenuation, input, input.posWorld.xyz);
	
	float angleDot = max(0, dot(normalWorld, lightWorldDirection));
	
#if defined(_DIFFUSE_RAMP)
	fixed3 lightDiffuse = calculateRampedDiffuse(_LightColor0.rgb, attenuation, angleDot);
#else
	fixed3 lightDiffuse = _LightColor0.rgb * (attenuation * angleDot);
#endif // _DIFFUSE_RAMP
	
	return lightDiffuse;
}

inline float3 calculateNormalWorld(VertexOutput input)
{
#if defined(_NORMALMAP)
	return calculateNormalFromBumpMap(input.texcoord, input.tangentWorld, input.binormalWorld, input.normalWorld);
#else
	return input.normalWorld;
#endif
}

fixed3 calculateVertexLighting(float3 posWorld, float3 normalWorld)
{
	fixed3 vertexLighting = fixed3(0,0,0);

#ifdef VERTEXLIGHT_ON
	//Get approximated illumination from non-important point lights
	vertexLighting = Shade4PointLights (	unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
											unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
											unity_4LightAtten0, posWorld, normalWorld) * 0.5;
#endif

	return vertexLighting;
}

fixed3 calculateAmbientLight(half3 normalWorld)
{
#if defined(_SPHERICAL_HARMONICS)
	fixed3 ambient = ShadeSH9(half4(normalWorld, 1.0));
#else 
	fixed3 ambient = unity_AmbientSky.rgb;
#endif
	return ambient;
}

#if defined(SPECULAR)

fixed4 calculateSpecularLight(SpecularCommonData s, float3 viewDir, float3 normal, float3 lightDir, float3 lightColor, half3 ambient)
{
	SpecularLightData data = calculatePhysicsBasedSpecularLight (s.specColor, s.oneMinusReflectivity, s.smoothness, normal, viewDir, lightDir, lightColor, ambient, unity_IndirectSpecColor.rgb);
	fixed4 pixel = calculateLitPixel(fixed4(s.diffColor, s.alpha), data.lighting);
	pixel.rgb += data.specular * s.alpha;
	return pixel;
}

fixed4 calculateSpecularLightAdditive(SpecularCommonData s, float3 viewDir, float3 normal, float3 lightDir, float3 lightColor)
{
	SpecularLightData data = calculatePhysicsBasedSpecularLight (s.specColor, s.oneMinusReflectivity, s.smoothness, normal, viewDir, lightDir, lightColor, half3(0,0,0), half3(0,0,0));
	fixed4 pixel = calculateAdditiveLitPixel(fixed4(s.diffColor, s.alpha), data.lighting);
	pixel.rgb += data.specular * s.alpha;
	return pixel;
}

#endif //SPECULAR

////////////////////////////////////////
// Vertex program
//

VertexOutput vert(VertexInput v)
{
	VertexOutput output;
	
	UNITY_SETUP_INSTANCE_ID(input);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    float factor = (1 - _ShakeDisplacement - v.color.r) * 0.5;

    const float _WindSpeed = (_ShakeWindspeed + v.color.g);
    const float _WaveScale = _ShakeDisplacement;

    const float4 _waveXSize = float4 (0.048, 0.06, 0.24, 0.096);
    const float4 waveSpeed = float4(1.2, 2, 1.6, 4.8);

    float4 _waveXmove = float4 (0.024, 0.04, -0.12, 0.096);

    float4 waves;
    waves = v.vertex.x *_waveXSize;

    waves += _Time.x *(1 - _ShakeTime * 2) *waveSpeed * _WindSpeed;

    float4 s, c;
    waves = frac(waves);
    FastSinCos(waves, s, c);
    float waveAmount = v.texcoord.y *(v.color.a + _ShakeBending);

    s *= waveAmount;

    s *= normalize(waveSpeed);

    s = s * s;
    float fade = dot(s, 1.3);
    s = s * s;
    float3 waveMove = float3 (0, 0, 0);
    waveMove.x = dot(s, _waveXmove*2);
    v.vertex.x -= mul((float3x3) unity_WorldToObject, waveMove).x;
	
	output.pos = calculateLocalPos(v.vertex);
	output.color = calculateVertexColor(v.color);
	output.texcoord = calculateTextureCoord(v.texcoord);
	output.posWorld = calculateWorldPos(v.vertex);
	
	float backFaceSign = 1;
#if defined(FIXED_NORMALS_BACKFACE_RENDERING)	
	backFaceSign = calculateBackfacingSign(output.posWorld.xyz);
#endif	

	output.normalWorld = calculateSpriteWorldNormal(v, backFaceSign);
	output.vertexLighting = calculateVertexLighting(output.posWorld, output.normalWorld);
	
#if defined(_NORMALMAP)
	output.tangentWorld = calculateWorldTangent(v.tangent);
	output.binormalWorld = calculateSpriteWorldBinormal(v, output.normalWorld, output.tangentWorld, backFaceSign);
#endif

	TRANSFER_VERTEX_TO_FRAGMENT(output)
	
#if defined(_FOG)
	UNITY_TRANSFER_FOG(output,output.pos);
#endif // _FOG	
	
	return output;
}

////////////////////////////////////////
// Fragment programs
//

fixed4 fragBase(VertexOutput input) : SV_Target
{
	fixed4 texureColor = calculateTexturePixel(input.texcoord);
	ALPHA_CLIP_COLOR(texureColor, input.color)
	
	//Get normal direction
	fixed3 normalWorld = calculateNormalWorld(input);

	//Get Ambient diffuse
	fixed3 ambient = calculateAmbientLight(normalWorld);

	
#if defined(SPECULAR)
	
	UNITY_LIGHT_ATTENUATION(attenuation, input, input.posWorld.xyz);
	
	//For directional lights _WorldSpaceLightPos0.w is set to zero
	float3 lightWorldDirection = normalize(_WorldSpaceLightPos0.xyz - input.posWorld.xyz * _WorldSpaceLightPos0.w);
	
	//Returns pixel lit by light, texture color should inlcluded alpha
	half3 viewDir = normalize(_WorldSpaceCameraPos - input.posWorld.xyz);
	fixed4 pixel = calculateSpecularLight(getSpecularData(input.texcoord.xy, texureColor, input.color), viewDir, normalWorld, lightWorldDirection, _LightColor0.rgb * attenuation, ambient + input.vertexLighting);
	
	APPLY_EMISSION_SPECULAR(pixel, input.texcoord)
	
#else

	//Get primary pixel light diffuse
	fixed3 diffuse = calculateLightDiffuse(input, normalWorld, texureColor);
	
	//Combine along with vertex lighting for the base lighting pass
	fixed3 lighting = ambient + diffuse + input.vertexLighting;
	
	APPLY_EMISSION(lighting, input.texcoord)
	
	fixed4 pixel = calculateLitPixel(texureColor, input.color, lighting);
	
#endif
	
#if defined(_RIM_LIGHTING)
	pixel.rgb = applyRimLighting(input.posWorld, normalWorld, pixel);
#endif
	
	COLORISE(pixel)
	APPLY_FOG(pixel, input)
	
	return pixel;
}

fixed4 fragAdd(VertexOutput input) : SV_Target
{
	fixed4 texureColor = calculateTexturePixel(input.texcoord);
	
#if defined(_COLOR_ADJUST)
	texureColor = adjustColor(texureColor);
#endif // _COLOR_ADJUST	

	ALPHA_CLIP_COLOR(texureColor, input.color)
	
	//Get normal direction
	fixed3 normalWorld = calculateNormalWorld(input);
		
#if defined(SPECULAR)
	
	UNITY_LIGHT_ATTENUATION(attenuation, input, input.posWorld.xyz);
	
	//For directional lights _WorldSpaceLightPos0.w is set to zero
	float3 lightWorldDirection = normalize(_WorldSpaceLightPos0.xyz - input.posWorld.xyz * _WorldSpaceLightPos0.w);
	
	half3 viewDir = normalize(_WorldSpaceCameraPos - input.posWorld.xyz);
	fixed4 pixel = calculateSpecularLightAdditive(getSpecularData(input.texcoord.xy, texureColor, input.color), viewDir, normalWorld, lightWorldDirection, _LightColor0.rgb * attenuation);
	
#else
	
	//Get light diffuse
	fixed3 lighting = calculateLightDiffuse(input, normalWorld, texureColor);
	fixed4 pixel = calculateAdditiveLitPixel(texureColor, input.color, lighting);
	
#endif
	
	COLORISE_ADDITIVE(pixel)
	APPLY_FOG_ADDITIVE(pixel, input)
	
	return pixel;
}


#endif // SPRITE_PIXEL_LIGHTING_INCLUDED