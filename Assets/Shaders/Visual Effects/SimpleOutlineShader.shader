Shader "Custom/SimpleOutlineShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _OutlineColor ("Outline Color", Color) =  (0,0,0,1)
        _Outline ("Outline Width", Range(0.002,0.1)) = 0.005
    }
    SubShader
    {        
        Zwrite Off
        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Lambert vertex:vert
        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };


        fixed4 _Color;
        fixed4 _OutlineColor;
        float _Outline;

        void vert (inout appdata_full v){
            v.vertex.xyz += v.normal * _Outline;
        }

        void surf (Input IN, inout SurfaceOutput o)
        {
            // Albedo comes from a texture tinted by color
            o.Emission = _OutlineColor.rgb;

        }
        ENDCG

        ZWrite On
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
    }
    FallBack "Diffuse"
}
