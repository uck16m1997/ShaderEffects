Shader "Custom/CellShade"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white"
        _CellShade ("CellShadeLevel",float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Toon

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        fixed _CellShade;

        struct Input
        {
            float2 uv_MainTex;
        };



        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutput o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            o.Albedo = c.rgb;

        }

        half4 LightingToon(SurfaceOutput s, half3 lightDir, half atten){
            //First calculate the dot product of the light direction and the surface's normal

            half NdotL = max(0,dot(s.Normal,lightDir));
            
            half cel = floor(NdotL * _CellShade)/(_CellShade -0.5);
            // Set what color should be returned
            half4 color;

            color.rgb = s.Albedo * _LightColor0.rgb * (cel*atten);
            color.a = s.Alpha;

            // return the calculated color
            return color;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
