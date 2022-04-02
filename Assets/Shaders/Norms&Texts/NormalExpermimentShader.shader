Shader "Custom/NormalExpermimentShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _myX ("Nx", Range(-2, 2)) = 1
        _myY ("Ny", Range(-2, 2)) = 1
        _myZ ("Nz", Range(-2, 2)) = 1
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

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };


        fixed4 _Color;
        half _myX;
        half _myY;
        half _myZ;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutput o)
        {
            // Albedo comes from a texture tinted by color

            // Metallic and smoothness come from slider variables
            o.Normal = normalize(float3(_myX, _myY, _myZ));
            fixed4 c = _Color;
            o.Albedo =   c;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
