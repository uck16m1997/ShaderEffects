Shader "Custom/BlingPhongShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _SpecColor ("Specular Colour", Color) = (1,1,1,1)
        _Spec ("Specular", Range(0,1)) = 0.5
        _Gloss ("Gloss", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        // #pragma surface surf BlinnPhong // you can use this for the same affect ? it is provided by unity

        #pragma surface surf BasicBlinn

        half4 LightingBasicBlinn(SurfaceOutput s, half3 lightDir,half3 viewDir,half atten){
            half3 h = normalize(lightDir + viewDir); // halfway between light and view directions

            half diff = max(0,dot (s.Normal,h));

            float nh = max(0,dot(s.Normal,lightDir));
            float spec = pow(nh,48.0);

            half4 c;
            c.rgb = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * spec )* atten * _SinTime;
            c.a = s.Alpha;
            return c;

        }
        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0


        struct Input
        {
            float2 uv_MainTex;
        };

        half _Spec;
        fixed _Gloss;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutput o)
        {
            // Albedo comes from a texture tinted by color
            o.Albedo = _Color.rgb;
            // Metallic and smoothness come from slider variables
            o.Gloss = _Gloss;
            o.Specular = _Spec;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
