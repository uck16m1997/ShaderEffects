Shader "Volumetric/CloudsCamera"
{
    Properties
    {
        _MainTex("",2D) = "white"{}
    }
    SubShader
    {
        Cull Off ZWrite Off
        Ztest Always 

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"


            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv: TEXCOORD0;
                float3 view : TEXCOORD1;

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
            sampler2D _MainTex;
            float _MainTex_TexelSize;
            sampler2D _ValueNoise;
            float4x4 _FrustumCornersWS;
            float4 _CameraPosWS;
            float4x4 _CameraInvViewMatrix;
            float3 plasma;


            fixed4 integrate(fixed4 sum,float diffuse,float density,fixed4 bgcol,float t){
                fixed3 lighting = fixed3(0.65,0.68,0.7)*1.3+0.5*fixed3(0.7,0.5,0.3)*diffuse;
                fixed3 colrgb = lerp(fixed3(1.0,0.95,0.8),fixed3(0.65,0.65,0.65),density);
                fixed4 col = fixed4(colrgb.r,colrgb.g,colrgb.b,density);
                col.rgb *=lighting;
                // colors will give bigger blend when t is smaller third component will be closer to 1
                // background will giver bigger blend when t is larger will be less than 1
                col.rgb = lerp(col.rgb,bgcol,1.0-exp(-0.003*t*t));
                col.rgb = lerp(col.rgb,plasma,exp(-0.003*t*t));

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
            


            float noiseFromImage(float3 x){
                x *= _Scale;
                float3 p = floor(x);
                float3 f = frac(x);
                f = smoothstep(0,1,f);

                // pluck a noise out of the image
                float2 uv = (p.xy +float2(37.0,-17.0)*p.z)+f.xy;
                float2 rg = tex2Dlod(_ValueNoise,float4(uv/256,0,0)).rg;
                return -1.0+2.0*lerp(rg.g,rg.r,f.z);
            }

            fixed3 CalculatePlasma(float2 pos,float _Speed,float _Scale1,float _Scale2,float _Scale3, float _Scale4){
                fixed3 col = fixed3(1,1,1);
                const float PI= 3.1415925;
                float t = _Time.x * _Speed;

                float xpos = pos.x*0.001;
                float ypos = pos.y*0.001;
                // color will be applied by the sinus value of that world position
                float c = sin(xpos * _Scale1 +t); //x pos

                c+= sin(ypos* _Scale2 +t);
                c+= sin((xpos*sin(t/2.0) + ypos *sin(t/3.0)) * _Scale3 + t);

                float c1 = pow(xpos + 0.5 * sin(t/5),2);
                float c2 = pow(ypos + 0.5 * sin(t/3),2);
                c+= sin(sqrt(_Scale4 * (c1 + c2)+1+t));
                // // Metallic and smoothness come from slider variables
                col.r = sin(c/4.0*PI);
                col.g = sin(c/4.0*PI + 2*PI/4);
                col.b = sin(c/4.0*PI + 4*PI/4);

                return col;

            }

            // Noise map function
            float map1(float3 q){
                // our point starts at given q

                float3 p = q;
                // int denom = 100;
                // q.x = denom;
                // q.z = denom;

                // f (frequency) is accumulation of noise
                float f;
                f = 0.5*noiseFromImage(q);
                q=q*2;
                f += 0.25*noiseFromImage(q);
                q=q*4;
                f += 0.15*noiseFromImage(q);
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


            v2f vert (appdata_img v)
            {
                v2f o;
                // use the index to grab hold of the indices in the frustum matrix
                half index = v.vertex.z;
                // Moving pixel just behind the camera
                v.vertex.z=0.1;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord.xy;

                // Check if the UV is upside down or not
                // if upside dwon flip its y 
                #if UNITY_UV_START_AT_TOP
                    if(_MainTexSize.y <0){
                        o.uv.y = 1- o.uv.y;
                    }
                #endif

                // change the view direction in to the space of the camera itself
                o.view = _FrustumCornersWS[(int)index];
                o.view /= abs(o.view.z);
                o.view = mul(_CameraInvViewMatrix,o.view);


                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Start the march from Camera Pos world space
                float3 start = _CameraPosWS;
                // uv values
                float2 uv = i.uv;
                // test if the uv values are upside down

                // Check if the UV is upside down or not
                // if upside dwon flip its y 
                #if UNITY_UV_START_AT_TOP
                    if(_MainTexSize.y <0){
                        uv.y = 1- uv.y;
                    }
                #endif

                float depth = LinearEyeDepth(tex2D(_CameraDepthTexture,uv).r);
                // makes no sense normalized length is 1 ?
                depth*= length(normalize(i.view));
                // Color is setted from the main texture we assigned
                fixed4 col = tex2D(_MainTex,i.uv);
                plasma = CalculatePlasma(i.pos,20,2,2,2,2);
                // sum is ray march on top of previous color
                fixed4 sum = raymarch(start,normalize(i.view),col,depth);
                // If alpha 0 (see through) then color will pass
                // If alpha 1(opaque) then just ray march clouds will pass
                return fixed4(col* (1-sum.a)+sum.rgb,1.0);

            }
            ENDCG
        }
    }
}
