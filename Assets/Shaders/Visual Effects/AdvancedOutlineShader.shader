Shader "Custom/AdvamcedOutlineShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _OutlineColor ("Outline Color", Color) =  (0,0,0,1)
        _Outline ("Outline Width", Range(0.002,0.4)) = 0.005
    }
    SubShader
    {        
        
        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Lambert
        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };


        fixed4 _Color;

        void surf (Input IN, inout SurfaceOutput o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = _Color.rgb;

        }
        ENDCG

        Pass{
            Cull Front
            CGPROGRAM
            // Physically based Standard lighting model, and enable shadows on all light types
            #pragma vertex vert
            #pragma fragment frag 
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex: POSITION;
                float3 normal: NORMAL;
            };

            struct v2f {
                float4 pos: SV_POSITION;
                float4 color: COLOR;
            };

            sampler2D _MainTex;

            struct Input
            {
                float2 uv_MainTex;
            };

            fixed4 _OutlineColor;
            float _Outline;

            v2f vert (appdata v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                // This returns the normal in worldspace instead of local space apparently
                float3 norm = normalize(mul((float3x3)UNITY_MATRIX_IT_MV,v.normal));
                // float3 norm = v.normal;

                // Take the normals from the world and project it in to the viewspace
                float2 offset = TransformViewToProjection(norm.xy);
                
                // Add outline to offset by multiplication will increase all x,y,z values of offset
                // o.pos.xy += offset * o.pos.z * _Outline;
                o.pos.xy += offset  *  o.pos.z *  _Outline;


                o.color = _OutlineColor;
                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                return i.color;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
