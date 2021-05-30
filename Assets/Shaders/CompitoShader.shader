Shader "Custom/CompitoShader" {

	Properties {
		_Tint("Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Splat Map & Albedo", 2D) = "white" {}
		_DetailTex("Detail Texture", 2D) = "gray" {}

		[Gamma] _Metallic("Metallic", Range(0, 1)) = 0

		[NoScaleOffset] _NormalMap("Normals", 2D) = "bump" {}

		[NoScaleOffset] _Texture1 ("Texture 1", 2D) = "white" {}
		[NoScaleOffset] _Texture2 ("Texture 2", 2D) = "white" {}
		[NoScaleOffset] _Texture3 ("Texture 3", 2D) = "white" {}
		[NoScaleOffset] _Texture4 ("Texture 4", 2D) = "white" {}
		[NoScaleOffset] _Texture5 ("Texture 5", 2D) = "white" {}
		[NoScaleOffset] _Texture6 ("Texture 6", 2D) = "white" {}
		[NoScaleOffset] _Texture7 ("Texture 7", 2D) = "white" {}
		[NoScaleOffset] _Texture8 ("Texture 8", 2D) = "white" {}

		_Bumpness("Bump Multiplier", float) = 1.0
		_Smoothness("Smoothness", Range(0, 1)) = 0.1
	}

	SubShader {

		Pass {
			Tags {
				"LightMode" = "ForwardBase"
			}
			CGPROGRAM

			#pragma target 3.0

			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			#include "UnityPBSLighting.cginc"

			#include "UnityCG.cginc"

			float4 _Tint;
			sampler2D _MainTex, _DetailTex;

			sampler2D _NormalMap;

			float4 _MainTex_ST, _DetailTex_ST;

			sampler2D _Texture1, _Texture2, _Texture3, _Texture4, _Texture5, _Texture6, _Texture7, _Texture8;

			float _Bumpness, _Smoothness, _Metallic;

			struct VertexData {
				float4 position : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct Interpolators {
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
				float2 uvSplat : TEXCOORD1;
				float3 normal : TEXCOORD3;
				float2 uvDetail : TEXCOORD2;
				float3 worldPos : TEXCOORD4;
			};

			Interpolators MyVertexProgram (VertexData v) {
				Interpolators i;
				i.position = UnityObjectToClipPos(v.position);
				i.worldPos = mul(unity_ObjectToWorld, v.position);
				i.uv = TRANSFORM_TEX(v.uv, _MainTex);
				i.uvSplat = v.uv;
				i.normal = UnityObjectToWorldNormal(v.normal);
				i.normal = normalize(v.normal);
				i.uvDetail = TRANSFORM_TEX(v.uv, _DetailTex);
				return i;
			}

			void InitializeFragmentNormal(inout Interpolators i) {
				i.normal.xy = tex2D(_NormalMap, i.uv).wy * 2 - 1;
				i.normal.xy *= _Bumpness;
				i.normal.z = sqrt(1 - saturate(dot(i.normal.xy, i.normal.xy)));
				i.normal = i.normal.xzy;
				i.normal = normalize(i.normal);
			}

			float4 MyFragmentProgram (Interpolators i) : SV_TARGET {
				InitializeFragmentNormal(i);
				float4 splat = tex2D(_MainTex, i.uvSplat);
					tex2D(_Texture1, i.uv) * splat.r +
					tex2D(_Texture2, i.uv) * splat.g +
					tex2D(_Texture3, i.uv) * splat.b +
					tex2D(_Texture4, i.uv) * (1 - splat.r - splat.g - splat.b);
				
				float4 color = tex2D(_MainTex, i.uv) * _Tint;
				color *= tex2D(_DetailTex, i.uvDetail) * unity_ColorSpaceDouble;

				i.normal = tex2D(_Texture5, i.uv) * splat.r +
					tex2D(_Texture6, i.uv) * splat.g * _Bumpness +
					tex2D(_Texture7, i.uv) * splat.b * _Bumpness +
					tex2D(_Texture8, i.uv) + (1 - splat.r - splat.g - splat.b) * _Bumpness;

				i.normal = normalize(i.normal);
				float3 lightDir = _WorldSpaceLightPos0.xyz;
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

				float3 lightColor = _LightColor0.rgb;
				float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;

				float3 specularTint;
				float oneMinusReflectivity;
				albedo = DiffuseAndSpecularFromMetallic(
					albedo, _Metallic, specularTint, oneMinusReflectivity
				);
				

				UnityLight light;
				light.color = lightColor;
				light.dir = lightDir;
				light.ndotl = DotClamped(i.normal, lightDir);

				UnityIndirect indirectLight;
				indirectLight.diffuse = 0;
				indirectLight.specular = 0;

				return UNITY_BRDF_PBS(
					albedo, specularTint,
					oneMinusReflectivity, _Smoothness,
					i.normal, viewDir,
					light, indirectLight
				) + color + splat;
			}

			ENDCG
		}
	}
}