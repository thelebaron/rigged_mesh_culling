// note not dots compatible yet

Shader "Tests/DecalProjectionTest"
{
    Properties
    {
        _BaseMap("Base Map", 2D) = "white"
        _DecalMap("Decal Map", 2D) = "red"
        _DecalProjectionDirection ("Decal Projection Direction", Vector) = (0, 0, 1, 0)
        _DecalScale ("Decal Scale", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5
            
            #pragma vertex vert
            #pragma fragment frag
            
            SamplerState sampler_DecalMap_point_clamp;

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float4 uv0          : TEXCOORD0;
                float4 uv3          : TEXCOORD3;
            };

            struct Varyings
            {
                float4 positionCS  : SV_POSITION;
                // The uv variable contains the UV coordinate on the texture for the
                // given vertex.
                float4 texcoord0    : TEXCOORD0;
                float3 positionWS   : TEXCOORD2;    // xyz: positionWS
                float4 texcoord3    : TEXCOORD3;
            };
            
            // This macro declares _BaseMap as a Texture2D object.
            TEXTURE2D(_BaseMap);
            TEXTURE2D(_DecalMap);
            // This macro declares the sampler for the _BaseMap texture.
            SAMPLER(sampler_BaseMap);
            SAMPLER(sampler_DecalMap);
            float4 _DecalProjectionDirection;
            float _DecalScale;

            CBUFFER_START(UnityPerMaterial)
                // The following line declares the _BaseMap_ST variable, so that you
                // can use the _BaseMap variable in the fragment shader. The _ST
                // suffix is necessary for the tiling and offset function to work.
                float4 _BaseMap_ST;
                float4 _DecalMap_ST;
                float4 _BaseColor;
                float _Falloff;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings varyings;
                varyings.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                varyings.texcoord0.xy = TRANSFORM_TEX(IN.uv0, _BaseMap);
                varyings.texcoord3 = IN.uv3;//TRANSFORM_TEX(IN.uv3, _BaseMap);
                varyings.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                return varyings;
            }


            half4 frag(Varyings varyings) : SV_Target
            {
                half4 baseColor = 0.0;
                half4 decalColor = 0.0;
                half2 uv = varyings.texcoord0.xy;
                
                baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, varyings.texcoord0.xy);
                
                // Calculate the world-space projection direction
                float3 worldDirection = normalize(mul(unity_ObjectToWorld, _DecalProjectionDirection).xyz);

                //
                float scale = 1;
                
                // Project the UV coordinate using the world-space direction
                float2 projectedUV = uv + (worldDirection.xy * _DecalScale)* (worldDirection.z + 1) * 0.5;
                
                // Sample both textures and blend them
                decalColor = SAMPLE_TEXTURE2D(_DecalMap, sampler_DecalMap, projectedUV);
                
                if (decalColor.a > 0.2)
                    clip(-1);
                
                return baseColor * (1 - decalColor.a) + decalColor;
            }
            ENDHLSL
        }
    }
}
