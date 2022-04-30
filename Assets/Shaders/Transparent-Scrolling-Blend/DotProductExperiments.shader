Shader "Custom/DotProductExperiments"
{
    Properties
    {
        _RimColor ("Rim Color",Color) = (0.0,0.5,0.0)
        _RimPower ("Rim Power",Range(0.5,8.0)) = 3.0
    }
    SubShader
    {
        Tags { "Queue"="Transparent" }
        // LOD 200

        Pass {
            ZWrite On
            ColorMask 0
        }


        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Lambert alpha:fade
        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        // sampler2D _MainTex;

        struct Input
        {
            float3 viewDir;
        };

        float4 _RimColor;
        float _RimPower;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutput o)
        {
            half rim = 1.0 - saturate(dot(normalize(IN.viewDir),o.Normal));
            o.Emission = _RimColor.rgb * pow(rim,_RimPower) *10;
            o.Alpha = pow(rim,_RimPower);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
