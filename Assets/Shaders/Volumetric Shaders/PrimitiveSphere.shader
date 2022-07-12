Shader "Volumetric/PrimitiveSphere"
{
    Properties
    {
        Rad ("Radius", Range(0,2)) = 0.5

    }
    SubShader
    {
        Tags { "Queue"="Transparent" }
        // Blending This Item * SrcAlpha + Background*OneMinusSrcAlpha
        Blend SrcAlpha OneMinusSrcAlpha
        // LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // contains world camera pos
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            float Rad;
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                // float3 normal:NORMAL;
            };

            struct v2f
            {
                // wPos
                float3 wPos : TEXCOORD0;
                // Relative Position
                float4 pos : SV_POSITION;
                // fixed4 diff:COLOR0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                // convert the local position of the vertex to world pos by unity_ObjectToWorld
                o.wPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                // 
                // half3 worldNormal = UnityObjectToWorldNormal(v.normal);
                // half nl = max(0,dot(worldNormal,_WorldSpaceLightPos0.xyz));
                // o.diff = nl * _LightColor0;
                //
                return o;
            }

            // How many steps we take along the ray before giving up looking for a hit value
            #define STEPS 128
            // Size of the steps
            #define STEP_SIZE 0.01

            bool SphereHit(float3 pos,float3 center,float radius){
                // If distance of position less than radius then it is inside the sphere
                return distance(pos,center) <radius;
            }

            // Position is where we start direction will be ray dir
            float3 RaymarchHit(float3 position,float3 direction){
                // Shift the position on the direction with magnitude of step size
                for(int i=0;i<STEPS;i++){
                    // If hit the Sphere when at position  
                    // for sphere at 0,0,0 which is relative center of the material
                    // with radius 0.5
                    if (SphereHit(position,unity_ObjectToWorld._m03_m13_m23,Rad)){
                        return position;
                    }
                    position += direction * STEP_SIZE;
                }
                // We have gotten to the end of the for loop without hitting anythig
                return float3(0,0,0);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 viewDirection = normalize(i.wPos - _WorldSpaceCameraPos);
                float3 worldPosition = i.wPos;
                float3 depth = RaymarchHit(worldPosition,viewDirection);

                // depth is pixels location
                // depth - center of sphere will be the normal of that pixel
                half3 worldNormal = depth - unity_ObjectToWorld._m03_m13_m23;
                half nl = max(0,dot(worldNormal,_WorldSpaceLightPos0.xyz));
                
            

                if (length(depth) !=0){
                    depth *=  nl * _LightColor0;
                    return fixed4(depth,1);
                }
                else{
                    return fixed4(1,1,1,0);
                }
            }
            ENDCG
        }
    }
}
