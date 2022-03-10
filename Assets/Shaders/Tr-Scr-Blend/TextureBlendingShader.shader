Shader "Custom/TextureBlendingShader"
{
    Properties
    {
        _Color ("Diffuse Tint", Color) = (1,1,1,1)

        // Terrain Colors
        _TerrainA ( "Terrain Color A",Color) = (1,1,1,1)
        _TerrainB ( "Terrain Color B",Color) = (1,1,1,1)

        // Channel Textures

        _RTexture("Red Channel Texture",2D) = ""{}
        _GTexture("Green Channel Texture",2D) = ""{}
        _BTexture("Blue Channel Texture",2D) = ""{}
        _ATexture("Alpha Channel Texture",2D) = ""{}
        _BlendTex("Blend Texture",2D) = ""{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Lambert

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.5


        struct Input
        {
            float2 uv_RTexture;
            float2 uv_GTexture;
            float2 uv_BTexture;
            float2 uv_ATexture;
            float2 uv_BlendTex;
        };

        fixed4 _Color;
        float4 _TerrainA;
        float4 _TerrainB;

        sampler2D _RTexture;
        sampler2D _GTexture;
        sampler2D _BTexture;
        sampler2D _ATexture;
        sampler2D _BlendTex;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutput o)
        {
            // Get the pixel data from the blend texture
            // we need a float 4 here because the texture will return R,B,G and A
            float4 blendData = tex2D(_BlendTex,IN.uv_BlendTex);
            
            // Get the data from the textures we want to blend 
            float4 rTexData = tex2D(_RTexture, IN.uv_RTexture);
            float4 gTexData = tex2D(_GTexture, IN.uv_GTexture);
            float4 bTexData = tex2D(_BTexture, IN.uv_BTexture);
            float4 aTexData = tex2D(_ATexture, IN.uv_ATexture);
            
            // Now we need to construct a new RGBA value and add all the different blended texture back together
            float4 finalColor;
            finalColor = lerp(rTexData,gTexData,blendData.g);
            finalColor = lerp(finalColor,bTexData,blendData.b);
            finalColor = lerp(finalColor,aTexData,blendData.a);
            finalColor.a = 1.0;

            // Add on our terrain tinting colors 
            float4 terrainLayers = lerp(_TerrainA,_TerrainB,blendData.r);
            finalColor *= terrainLayers;
            finalColor = saturate(finalColor);

            // Albedo comes from a texture tinted by color
            o.Albedo = finalColor.rgb * _Color.rgb;
            // Metallic and smoothness come from slider variables

            o.Alpha = finalColor.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}

    