Shader "Custom/NormalShader"
{
    Properties
    {
        _Color ("Color", Color) = (0,1,0,1)
        _NormalTex("Normal Map",2D) = "bump" {}
        _NormalMapIntensity("Normal intensity", Range(0,3)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _NormalTex; 
        float4 _Color;
        float _NormalMapIntensity;

        struct Input
        {
            float2 uv_NormalTex;
        };



        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c =  _Color;
            o.Albedo = c.rgb;
            o.Alpha = c.a;

            float3 normalMap = UnpackNormal(tex2D(_NormalTex, IN.uv_NormalTex));

            normalMap.r = normalMap.r * _NormalMapIntensity;        
            normalMap.g = normalMap.g * _NormalMapIntensity;
            normalMap.g = normalMap.g * _NormalMapIntensity;

            o.Normal = normalize(normalMap.rgb);

        }
        ENDCG
    }
    FallBack "Diffuse"
}
