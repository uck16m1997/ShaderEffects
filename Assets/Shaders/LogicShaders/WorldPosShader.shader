Shader "Custom/WorldPosShader"
{
    Properties
    {
        _Color ("Rim Color", Color) = (0,0.5,0.5,0.0)
        _RimPower ("Rim Power", Range(0.5,8.0)) = 3.0

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Lambert

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0



        struct Input
        {
            float3 worldPos;
            float3 viewDir;
        };


        fixed4 _Color;
        float _RimPower;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutput o)
        {
            // Albedo comes from a texture tinted by color
            half rim = 1 - saturate(dot(normalize(IN.viewDir),o.Normal));
            // o.Emission = _Color.rgb * pow(rim,_RimPower);
            float fraction = frac(IN.worldPos.y*10 *0.5) ;
            _RimPower = fraction;
            o.Emission = (fraction > 0.4 ? _Color : float3(0.3,0,0.3)) * rim ;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
