// This shader draws a texture on the mesh.
Shader "RiggedCulling/PixelCulling"
{
    // The _BaseMap variable is visible in the Material's Inspector, as a field
    // called Base Map.
    Properties
    {
        _MyArr ("Tex", 2DArray) = "" {}
        _BaseMap("Base Map", 2D) = "white"
        
        _EllipsoidCenter("EllipsoidPosition", Vector) = (1,1,1,0)
        _EllipsoidSide("EllipsoidSide", Vector) = (1,0,0,0)
        _EllipsoidUp("EllipsoidUp", Vector) = (0,1,0,0)
        _EllipsoidForward("EllipsoidForward", Vector) = (0,0,1,0)
        _Falloff("Falloff", Float) = 1.0
        _Scale("Scale", Float) = 1.0
        
        _DecalMap("Decal Map", 2D) = "red"
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5
            
            #pragma vertex vert
            #pragma fragment frag
            

            SamplerState sampler_DecalMap_point_clamp;
            

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "RetroFunctions.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                // The uv variable contains the UV coordinate on the texture for the
                // given vertex.
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

            CBUFFER_START(UnityPerMaterial)
                // The following line declares the _BaseMap_ST variable, so that you
                // can use the _BaseMap variable in the fragment shader. The _ST
                // suffix is necessary for the tiling and offset function to work.
                float4 _BaseMap_ST;
                float4 _DecalMap_ST;
                float4 _BaseColor;
            
                float3 _EllipsoidCenter;
                float3 _EllipsoidSide;
                float3 _EllipsoidUp;
                float3 _EllipsoidForward;
                float _Falloff;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings varyings;
                varyings.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                // The TRANSFORM_TEX macro performs the tiling and offset
                // transformation.
                varyings.texcoord0.xy = TRANSFORM_TEX(IN.uv0, _BaseMap);
                varyings.texcoord3 = IN.uv3;//TRANSFORM_TEX(IN.uv3, _BaseMap);
                varyings.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                return varyings;
            }

            half4 frag(Varyings varyings) : SV_Target
            {
                half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, varyings.texcoord0.xy);

                // Calculate ellipsoid position
                float3 vLocalPosition = varyings.texcoord3.xyz - _EllipsoidCenter;
                float3 vEllipsoidPosition;
                vEllipsoidPosition.x = dot(_EllipsoidSide.xyz, vLocalPosition.xyz);
                vEllipsoidPosition.y = dot(_EllipsoidUp.xyz, vLocalPosition.xyz);
                vEllipsoidPosition.z = dot(_EllipsoidForward.xyz, vLocalPosition.xyz);

                // Calculate falloff and adjust decal
                float vDistance = length(vLocalPosition);
                float falloff = vDistance - _Falloff;
                falloff = saturate(falloff);
                falloff = 1.0 - falloff;

                // Sample decal texture
                float2 vTexcoord = vEllipsoidPosition.xy;
                half4 decal = SAMPLE_TEXTURE2D(_DecalMap, sampler_DecalMap_point_clamp, TRANSFORM_TEX(vTexcoord, _DecalMap));

                // Apply falloff to decal
                decal *= falloff;
                decal = smoothstep(0, 1, decal);
                decal *= 3.5;
                if (decal.a > 0.2)
                {
                    clip(-1);
                }
                // Apply decal to base color
                baseColor = lerp(baseColor, decal, 0.75);

                return baseColor;
            }
            ENDHLSL
        }
    }
}