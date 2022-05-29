Shader "Custom/Plasma"
{
    Properties
    {
        _Tint("Color Tint",Color) = (1,1,1,1)
        _Speed ("Speed", Range(1,100)) = 10
        _Scale1 ("Scale 1", Range(0.1,10)) = 2
        _Scale2 ("Scale 2", Range(0.1,10)) = 2
        _Scale3 ("Scale 3", Range(0.1,10)) = 2
        _Scale4 ("Scale 4", Range(0.1,10)) = 2

    }
    SubShader
    {
        CGPROGRAM

        #pragma surface surf Lambert 


        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
        };

        float _Scale1;
        float _Scale2;
        float _Scale3;
        float _Scale4;
        float _Speed;
        float4 _Tint;

        void surf (Input IN, inout SurfaceOutput o)
        {

            const float PI= 3.1415925;
            float t = _Time.x * _Speed;

            // color will be applied by the sinus value of that world position
            float c = sin(IN.worldPos.x * _Scale1 +t); //x pos

            c+= sin(IN.worldPos.z * _Scale2 +t);
            c+= sin((IN.worldPos.x*sin(t/2.0) + IN.worldPos.z *sin(t/3.0)) * _Scale3 + t);

            float c1 = pow(IN.worldPos.x + 0.5 * sin(t/5),2);
            float c2 = pow(IN.worldPos.z + 0.5 * sin(t/3),2);
            c+= sin(sqrt(_Scale4 * (c1 + c2)+1+t));
            // Metallic and smoothness come from slider variables
            o.Albedo.r = sin(c/4.0*PI);
            o.Albedo.g = sin(c/4.0*PI + 2*PI/4);
            o.Albedo.b = sin(c/4.0*PI + 4*PI/4);

            o.Albedo *=_Tint;

        }
        ENDCG
    }
    FallBack "Diffuse"
}
