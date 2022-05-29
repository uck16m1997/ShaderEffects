Shader "Holistic/Waves" {
    Properties {
      _MainTex("Diffuse", 2D) = "white" {}
      _Tint("Colour Tint", Color) = (1,1,1,1)
      _Freq("Frequency", Range(0,5)) = 3
      _Speed("Speed",Range(0,100)) = 10
      _Amp("Amplitude",Range(0,1)) = 0.5
		  _FoamTex ("Foam", 2D) = "white" {}
      _ScrollXSpeed("X Scroll Speed",Range(0,10)) = 2
      _ScrollYSpeed("Y Scroll Speed",Range(0,10)) = 2
    }
    SubShader {
      CGPROGRAM
      #pragma surface surf Lambert vertex:vert // Lambert surface shader + vertex shader
      
      struct Input {
          float2 uv_MainTex;
          float3 vertColor;
      };
      
      float4 _Tint;
      float _Freq;
      float _Speed;
      float _Amp;
      fixed _ScrollXSpeed;
      fixed _ScrollYSpeed;

      struct appdata {
          float4 vertex: POSITION;
          float3 normal: NORMAL;
          float4 texcoord: TEXCOORD0;
          float4 texcoord1: TEXCOORD1;
          float4 texcoord2: TEXCOORD2;
      };
      
      void vert (inout appdata v, out Input o) {
          UNITY_INITIALIZE_OUTPUT(Input,o);
          float t = _Time * _Speed; // Time is used to change height (_Time variable given by unity increases with real time) 
          float waveHeight = sin(t + v.vertex.x * _Freq) * _Amp + // Height is  Sinus function of (time + vertex position x scaled by the frequency of waves ) scaled by the amplitude
                        sin(t*2 + v.vertex.x * _Freq*2) * _Amp +
                        cos(t*2 + v.vertex.z * _Freq*2) * _Amp ; ; // Two sin waves creates variaing waves
          v.vertex.y = v.vertex.y + waveHeight; // y value will be increased with height ( It doesn't affect the mesh physically)
          v.normal = normalize(float3(v.normal.x + waveHeight, v.normal.y, v.normal.z)); // Need to update the normals for the new vertex positions
          o.vertColor = waveHeight + 1; // Vertex color based on the waveHeight for that vertex 

      }

      sampler2D _MainTex;
      sampler2D _FoamTex;

      void surf (Input IN, inout SurfaceOutput o) {

          // Variables storing x and y components scaled by time


          fixed _ScrollX = _Time * _ScrollXSpeed;
          fixed _ScrollY = _Time * _ScrollYSpeed;

          float3 water = (tex2D (_MainTex, IN.uv_MainTex + float2(_ScrollX, _ScrollY))).rgb;
          // float3 foam = (tex2D (_FoamTex, IN.uv_MainTex + float2(_ScrollX/2.0, _ScrollY/2.0))).rgb;
          o.Albedo = ((water + _Tint)/2.0)*IN.vertColor.rgb;

          // float4 c = tex2D(_MainTex, IN.uv_MainTex); // Get the main color from texture
          // o.Albedo = c * IN.vertColor.rgb; // Real albedo is mixture of texture and vertex color
      }
      ENDCG

    } 
    Fallback "Diffuse"
  }