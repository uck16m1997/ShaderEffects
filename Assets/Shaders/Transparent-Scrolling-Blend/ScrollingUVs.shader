Shader "Custom/ScrollingUVs"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _NormalTex("Normals", 2D) = "white" {}
        _NormalMapIntensity("Normal intensity", Range(0,10)) = 1

        _ScrollXSpeed("X Scroll Speed",Range(0,10)) = 2
        _ScrollYSpeed("Y Scroll Speed",Range(0,10)) = 2

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

        sampler2D _MainTex;
        sampler2D _NormalTex;
        fixed _ScrollXSpeed;
        fixed _ScrollYSpeed;
        float _NormalMapIntensity;


        struct Input
        {
            float2 uv_MainTex;
        };


        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Store the UV before we pass them to the tex2D 
            fixed2 scrolledUV = IN.uv_MainTex;
            
            // Variables storing x and y components scaled by time
            fixed xScrollValue = _ScrollXSpeed * _Time;
            fixed yScrollValue = _ScrollYSpeed * _Time;

            scrolledUV += fixed2(xScrollValue,yScrollValue);


            // Albedo comes from a texture tinted by color
            half4 c =   tex2D(_MainTex, scrolledUV);

            float3 normalMap  = UnpackNormal(tex2D(_NormalTex, scrolledUV));

            o.Albedo = c.rgb * _Color;

            o.Alpha = c.a;

            normalMap.r = normalMap.r * _NormalMapIntensity;        
            normalMap.g = normalMap.g * _NormalMapIntensity;
            normalMap.g = normalMap.g * _NormalMapIntensity;

            o.Normal = normalize(normalMap.rgb);

        }
        ENDCG
    }
    FallBack "Diffuse"
}
