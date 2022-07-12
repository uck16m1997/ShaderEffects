Shader "Volumetric/SphericalFog"
{
    Properties
    {
        _FogCenter("Fog Center/Radius",Vector) = (0,0,0,0.5)
        // _DebugParam("Debug Param",float) = 0.0
        _Radius("Radius",Range(0,10)) = 0.5
        _FogColor("Fog Color",Color) = (1,1,1,1)
        _InnerRatio("Inner Ratio",Range(0,1)) = 0.5
        _Density("Density",Range(0,1))=0.5

    }
    SubShader
    {
        Tags { "Queue"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        // Removes Ligthing and background buffer writing
        Cull Off Lighting Off ZWrite Off
        // Allow putting objects within the fog
        ZTest Always
        // LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float CalculateFogIntensity(float3 sphereCenter,float sphereRadius,float innerRatio,float density, float3 cameraPosition,float3 viewDirection,float maxDistance){
                // calculate ray-sphere intersection
                // Formula P^2 - R^2 = 0
                // P are points on Ray = camPos + viewDirection*t(scalar) that satisfy above
                // (camPos + viewDirection*t)^2 - R^2 = 0
                // camPos^2 + 2*viewDirection*t + viewDirection^2*t^2 - R^2

                // Vector from camera to center of the sphere L

                float3 localCam = cameraPosition - sphereCenter;
                // float3 localCam = cameraPosition;

                // View Direction squared = x^2
                float a = dot(viewDirection,viewDirection);
                // b = 2xy
                float b = 2*dot(viewDirection,localCam);
                // c = y^2
                float c = dot(localCam,localCam) - sphereRadius * sphereRadius;
                // Quadratic Equation discriminant
                float d = b*b - 4*a*c;

                // if not negative we have at least one root
                if(d <0){
                    return 0;
                }
                // sqrt of discriminant
                float DSqrt = sqrt(d);
                // for the negative scenario if result is negative taking 0
                float dist = max((-b-DSqrt)/2*a,0);
                // for the poisiive scenario if result is negative taking 0
                float dist2 = max((-b + DSqrt)/2*a,0);


                // start from the negative scenario capped or 0 if behind camera
                float cam_sample = dist;
                // stop at the maxDistance if positive scenario is bigger
                float backDepth = min(maxDistance,dist2);

                // even step count from the front of the sphere to the back of a sphere
                float step_distance =(backDepth-dist)/10;
                // how much should fog get denser with distance
                float step_contribution =density;

                // Fog Density at the center of the sphere
                float centerValue = 1/(1-innerRatio);
                // how clear at the start of the march
                float clarity = 1;

                //start marching we divided by 10 when calculating step_distance so we need 10 steps 
                for(int seg=0;seg<10;seg++){
                    //Our local start position will be localCam pushed on the viewDirection by the starting intersection distance
                    float3 position= localCam + viewDirection * cam_sample;

                    //Calculate Relative(1 is the max and 0 is None) Fog Density by how far we are in to the fog compared to center fog density
                    //Saturate restricts the value by clamping it between 0 and 1
                    float val = saturate(centerValue * (1-length(position)/sphereRadius));
                    // Use relative fog density (relative to the distance) to assess fog amount with the step contribution
                    float fog_amount = saturate(val * step_contribution);
                    // Reduce clarity by fog amount
                    clarity *= (1-fog_amount);
                    // push the cam by step
                    cam_sample +=step_distance;
                }
                // Returns how foggy it is 
                // 0 means clear above 0 means foggy 
                
                return 1-clarity;


            }

            struct v2f
            {
                float3 view : TEXCOORD0;
                float4 pos : SV_POSITION;
                // Projection of our position   
                float4 projPos : TEXCOORD1;
            };


            float4 _FogCenter;
            fixed4 _FogColor;
            float _InnerRatio;
            float _Density;
            float _Radius;
            sampler2D _CameraDepthTexture;

            v2f vert (appdata_base v)
            {
                v2f o;
                float4 wPos = mul(unity_ObjectToWorld,v.vertex);
                o.pos = UnityObjectToClipPos(v.vertex);
                // View dir from camera to object world position
                o.view = wPos.xyz - _WorldSpaceCameraPos;
                // Projection clip position to screen 
                o.projPos = ComputeScreenPos(o.pos);

                // If camera is inside the object then 
                // set the z position of those pixels to equal to the camera position
                // This part requires research for me
                float inFrontOf = (o.pos.z/o.pos.w)>0;
                o.pos.z *= inFrontOf;


                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                half4 col;
                // Linear Eye Depth creats a depth texture for us sample and get depth values for maximum depth value
                // depth will be used as a max distance in our fog intensity calculations
                
                float depth = LinearEyeDepth(UNITY_SAMPLE_DEPTH (tex2Dproj (_CameraDepthTexture,UNITY_PROJ_COORD (i.projPos))));
                // float depth = 1;
                // depth is the distance between camera and the object
                // depth *= length(i.view);


                float3 viewDir = normalize(i.view); // normalize the view direction vector
                // FogCenters w is the radius for our implementation
                float fog = CalculateFogIntensity(unity_ObjectToWorld._m03_m13_m23,_Radius,_InnerRatio,_Density,_WorldSpaceCameraPos,viewDir,depth);

                col.rgb = _FogColor.rgb;
                col.a = fog;
                return col;
            }
            ENDCG
        }
    }
}
