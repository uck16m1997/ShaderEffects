Shader "Volumetric/CloudShader"
{
    Properties
    {
        _Scale ("Scale",Range(0.1,10.0))=2.0
        _ViewScale ("View Scale",Range(0.1,20.0))=10.0

        _StepScale ("Step Scale",Range(0.1,100.0))=1.0
        _Steps("Number of Steps",Range(1,200))=60
        _MinHeight("Min Height",Range(0,5))=0
        _MaxHeight("Max Height",Range(6,10))=10
        _FadeDist("Fade Distance",Range(0,10))=0.5
        _SunDir("Sun Direction",Vector) = (1,0,0,0)


    }
    SubShader
    {
        Tags { "Queue"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off Lighting Off ZWrite Off
        Ztest Always 
        // LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 view : TEXCOORD0;
                float4 projPos : TEXCOORD1;
                float3 wpos: TEXCOORD2; 
            };

            float _MinHeight;
            float _MaxHeight;
            float _FadeDist;
            float _Scale;
            float _StepScale;
            float _Steps;
            float _ViewScale;
            float4 _SunDir;
            float4 _RandomSeed;
            sampler2D _CameraDepthTexture;


            //  generates single random variable from 3d vectors
            float random(float3 value,float3 dotDir){
                // sin on vectors reduces the value by applying sin on each axis
                float3 smallV = sin(value);
                // Use random clipped(-1,1) variables 
                float random = dot(smallV,dotDir);
                random = frac(sin(random)*123574.43212);
                return random;      
            }

            float3 random3d(float3 value){
                return float3(random(value,float3(1,2,3)),
                              random(value,float3(2,3,1)),
                              random(value,float3(3,1,2)));
            }

            float noise3d(float3 value){
                value *=_Scale;
                value.x += _Time.x*5;
                float3 interp = frac(value);
                interp = smoothstep(0.0,1.0,interp);

                float3 ZValues[2];
                for (int z=0;z<=1;z++){

                    float3 YValues[2];
                    for (int y=0;y<=1;y++){

                        float3 XValues[2];
                        for (int x=0;x<=1;x++){
                            float3 cell =floor(value)+float3(x,y,z);
                            XValues[x] = random3d(cell);
                        }
                        YValues[y] = lerp(XValues[0],XValues[1],interp.x);
                    }
                    ZValues[z] = lerp(YValues[0],YValues[1],interp.y);
                }
                float noise = -1.0 + 2.0* lerp(ZValues[0],ZValues[1],interp.z);
                return noise;
            }

            fixed4 integrate(fixed4 sum,float diffuse,float density,fixed4 bgcol,float t){
                fixed3 lighting = fixed3(0.65,0.68,0.7)*1.3+0.5*fixed3(0.7,0.5,0.3)*diffuse;
                fixed3 colrgb = lerp(fixed3(1.0,0.95,0.8),fixed3(0.65,0.65,0.65),density);
                fixed4 col = fixed4(colrgb.r,colrgb.g,colrgb.b,density);
                col.rgb *=lighting;
                // colors will give bigger blend when t is smaller third component will be closer to 1
                // background will giver bigger blend when t is larger will be less than 1
                col.rgb = lerp(col.rgb,bgcol,1.0-exp(-0.003*t*t));
                col.a *= 0.5;
                col.rgb *= col.a;
                return sum+col*(1 - sum.a);
            }

            // define functions don't need type for parameters ?
            // makes it simple to pass functions
            // if t > depth you gone beyond what your camera is seeing break
            // pos is camera position + t*Viewdirection t are steps
            // if y is less than min or more than max or alpha of sum tell us this is opaque then no need to continue taking steps 
            // because either cant see behind or not interested in calculating for those heights
            // t is updated at every step
            // we will get our density from noiseMap and if density is not insignificant (above 0.01) 
            // calculate  diffuse between current density and density nudged at the light source/sun direction
            // integrate will take the sum(initial color) and new diffuse to update sum and update t at end of the step
            #define MARCH(steps,noiseMap,cameraPos,viewDir,bgcol,sum,depth,t){\
                for (int i=0;i<steps+1;i++){\
                    if(t>depth){break;}\
                    float3 pos = cameraPos +t*viewDir;\
                    if (pos.y< _MinHeight || pos.y> (unity_ObjectToWorld._m13 +_MaxHeight) || sum.a>0.99){\
                        t+=max(0.1,0.02*t);\
                        continue;\
                    }\
                    \
                    float density = noiseMap(pos);\
                    if (density >0.01){\
                        float diffuse = clamp((density - noiseMap(pos +0.3 * _SunDir))/0.6,0.0,1.0);\
                        sum = integrate(sum,diffuse,density,bgcol,t);\
                    }\
                    t += max(0.1,0.02*t);\
                }\
            }\

            //  integrate(sum,diffuse,density,bgcol,t);\
            // makes sure that range of values in the clouds will have enough transparent and opaque mixture
            // does this by clouds that are close to the maxheight are somewhat faded out
            #define NOISEPROC(N,P) 1.75 * N * saturate((unity_ObjectToWorld._m13 +_MaxHeight-P.y)/_FadeDist)
            
            // #define NOISEPROCBOT(N,P) 0.75 * N * saturate((unity_ObjectToWorld._m13 -P.y))


            // Noise map function
            float map1(float3 q){
                // our point starts at given q

                float3 p = q;
                // int denom = 100;
                // q.x = denom;
                // q.z = denom;

                // f (frequency) is accumulation of noise
                float f;
                f = 0.5*noise3d(q);
                q=q*2;
                f += 0.25*noise3d(q);
                q=q*4;
                f += 0.15*noise3d(q);
                return NOISEPROC(f,p);

            }

            fixed4 raymarch(float3 cameraPos,float3 viewDir,fixed4 bgcol,float depth){

                fixed4 col = fixed4(0,0,0,0);
                // ct will track the number of steps we have taken by accumulating
                float ct = 0;
                // map will perform the noise calculations for us
                MARCH(_Steps,map1,cameraPos,viewDir,bgcol,col,depth,ct);
                MARCH(_Steps,map1,cameraPos,viewDir,bgcol,col,depth*2,ct);
                // MARCH(_Steps,map1,cameraPos,viewDir,bgcol,col,depth*4,ct);   
                MARCH(_Steps,map1,cameraPos,viewDir,bgcol,col,depth*8,ct);
                // MARCH(_Steps,map1,cameraPos,viewDir,bgcol,col,depth*16,ct);

                // clamp will clamp all values of the vector between the given two value 
                return clamp(col,0.0,1.0);
                

            }


            v2f vert (appdata v)
            {
                v2f o;
                o.wpos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.pos= UnityObjectToClipPos(v.vertex);
                o.view =  o.wpos- _WorldSpaceCameraPos;
                o.projPos = ComputeScreenPos(o.pos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float depth = 1;
                // depth is the distance between camera and the object
                depth *= length(i.view);
                fixed4 col = fixed4(1,1,1,0);
                fixed4 clouds = raymarch( float3(i.view.x/_ViewScale,1,i.view.z/_ViewScale),normalize(i.view)*_StepScale,col,depth);
                // fixed4 clouds = raymarch( float3(_WorldSpaceCameraPos.x,1,_WorldSpaceCameraPos.z),normalize(i.view)*_StepScale,col,depth);

                float3 mixedCol = col * (1.0-clouds.a)+ clouds.rgb;
                return fixed4(mixedCol.r,mixedCol.g,mixedCol.b,clouds.a);
            }
            ENDCG
        }
    }
}
