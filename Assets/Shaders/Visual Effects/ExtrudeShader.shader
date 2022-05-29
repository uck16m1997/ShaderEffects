Shader "Custom/ExtrudeShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Amount ("Extrude Scale", Range(-1,1))=0.01
    }
    SubShader
    {
 

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Lambert vertex:vert

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        struct appdata{
            float4 vertex: POSITION;
            float3 normal:NORMAL;
            float4 texcoord: TEXCOORD0;
        };

        fixed4 _Color;
        float _Amount;

        void vert (inout appdata v){
            v.vertex.xyz += v.normal *_Amount;
        }

 


        void surf (Input IN, inout SurfaceOutput o)
        {
            // Albedo comes from a texture tinted by color
            // fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = _Color.rgb;
          
        }
        ENDCG
    }
    FallBack "Diffuse"
}
