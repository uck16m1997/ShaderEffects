Shader "Unlit/BasicVF"
{
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 color : COLOR;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex; // In the fragment shader (function frag)
            float4 _MainTex_ST; // In the vertex shader (function below(vert))

            v2f vert (appdata v)
            {
                // In vertex space
                v2f o; 
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.color.r = (v.vertex.x+5)/10;
                o.color.b = (v.vertex.z+5)/10;
                return o; // v2f o gets returned and passed to frag function as parameter i 
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // In screen space 1920x1080 etc
                // sample the texture
                fixed4 col = i.color;
                // col.r = (v.vertex.x+5)/10;
                // col.b = (v.vertex.z+5)/10;
                return col;
            }
            ENDCG
        }
    }
}
