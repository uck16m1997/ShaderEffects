Shader "Unlit/VFDiffuseShadows"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {

        Pass
        {
            Tags {"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight //not include and ignore lightmap
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"


            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal: NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                // TRANSFER_SHADOW expects SV_POSITION as pos instead of default vertex
                float4 pos : SV_POSITION;
                fixed4 diff: COLOR0;
                // Function to calculate shadow coords weirdly doesn't need semi colons
                SHADOW_COORDS(1)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                half3 worldNormal = UnityObjectToWorldNormal(v.normal);
                half nl = max(0,dot(worldNormal,_WorldSpaceLightPos0.xyz));
                o.diff = nl * _LightColor0;
                TRANSFER_SHADOW(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed shadow = SHADOW_ATTENUATION(i);
                col.rgb *= i.diff * shadow + (shadow < 0.2 ? float3(1,0,0):0);;
                return col;
            }
            ENDCG
        }
        Pass{
            Tags {"LightMode"="ShadowCaster"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex: POSITION;
                float3 normal: NORMAL;
                float4 uv: TEXCOORD0; 
            };

            struct v2f {
                // Output will be a shadow
                V2F_SHADOW_CASTER;
            };

            v2f vert(appdata v){
                v2f o;
                // cast shadows from vertex (these things dont need to end with semi colon ?)
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                // cast shadow from fragment (these things dont need to end with semi colon ?)
                SHADOW_CASTER_FRAGMENT(i);
            }
            ENDCG
        }
   
    }
}
