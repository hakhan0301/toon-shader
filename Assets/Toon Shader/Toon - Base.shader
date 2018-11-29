Shader "Custom/Toon - Base"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color("Color", Color) = (1,1,1,1)

		_ToonLUT("Toon LUT", 2D) = "white" {}
			
	}
	SubShader
	{

		Pass
		{
			Name "BASE_LIGHTING"
			Tags
			{
				"RenderType" = "Opaque"
				"LightMode" = "ForwardBase"
			}
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			#pragma multi_compile_fwdbase
			#include "AutoLight.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD1;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				LIGHTING_COORDS(1, 2)
			};

			sampler2D _MainTex;
			sampler2D _ToonLUT;
			fixed4 _Color;

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				TRANSFER_VERTEX_TO_FRAGMENT(o);

				o.normal = UnityObjectToWorldNormal(v.normal);

				o.uv = v.uv;
				return o;
			}

			fixed4 softLight(fixed4 a, fixed4 b)
			{
				return (1 - 2 * b) * a * a + 2 * b * a;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float attenuation = LIGHT_ATTENUATION(i);

				fixed ndotl = dot(i.normal, _WorldSpaceLightPos0.xyz) * attenuation;
				fixed4 shadow = tex2D(_ToonLUT, ndotl);
				fixed4 col = tex2D(_MainTex, i.uv) * _Color;
				
				fixed4 baseLighting = softLight(col, shadow);

				return baseLighting;
			}
			ENDCG
		}

		Pass
		{
			Name "ADD_LIGHTING"

			Tags
			{
				"RenderType" = "Opaque"
				"LightMode" = "ForwardAdd"
			}

			Blend One One
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			#include "Lighting.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 posWorld : TEXCOORD0;
				float3 normal : NORMAL;
			};

			sampler2D _MainTex;
			sampler2D _ToonLUT;

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.normal = UnityObjectToWorldNormal(v.normal);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float3 vert2Light = _WorldSpaceLightPos0.xyz - i.posWorld.xyz;
				fixed attenuation = lerp(1, 1 / length(vert2Light), _WorldSpaceLightPos0.w);
				vert2Light = normalize(vert2Light);
				fixed3 lightDir = lerp(_WorldSpaceLightPos0.xyz, vert2Light, _WorldSpaceLightPos0.w);

				attenuation = pow(attenuation, 1);
				fixed ndotl = dot(i.normal, lightDir) * attenuation;

				fixed4 lightColor = tex2D(_ToonLUT, ndotl) * _LightColor0;
				return lightColor * .34;
			}

			ENDCG
		}
			 
		Pass
		{
			Tags
			{
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			#include "UnityCG.cginc"

			struct v2f {
				V2F_SHADOW_CASTER;
			};


			v2f vert(appdata_base v)
			{
				v2f o;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}

	Fallback "Unlit"
}
