Shader "Custom/HoleMaker" {
    Properties{
            _Position("Position", Vector) = (0,0,0,0)
            _Scale("Scale", Vector) = (1,1,1,0)
            _Radius("Radius", Range(0,1)) = 0.01
            _Color("Color", Color) = (1,1,1,1)
            _CutawayColor("Cutaway Color", Color) = (1,1,1,1)
    }
            SubShader{
                    Tags { "RenderType" = "Opaque"}
                    LOD 200
                    Cull Front

                    CGPROGRAM
                    #pragma surface surf MonoColor fullforwardshadows vertex:vert

                    // Use shader model 3.0 target, to get nicer looking lighting
                    #pragma target 3.0

                    fixed4 _CutawayColor;

                    float4 _Position;
                    float4 _Scale;
                    float _Radius;

                    struct Input
                    {
                            float2 uv_MainTex;
                            float3 worldPos;
                    };

                    void vert(inout appdata_full v, out Input o)
                    {
                            UNITY_INITIALIZE_OUTPUT(Input, o);
                            v.normal *= -1;
                    }

                    half4 LightingMonoColor(SurfaceOutput s, half3 lightDir, half atten) {
                            return _CutawayColor;
                    }

                    void surf(Input IN, inout SurfaceOutput o)
                    {

                        //spherical clipping
                        float dist = length(_Scale.xyz * IN.worldPos.xyz - _Position.xyz);
                        if (dist < _Radius)
                            clip(-1);


                            o.Albedo = _CutawayColor.rgb;
                    }
                    ENDCG
            }
                    FallBack "Diffuse"
   }