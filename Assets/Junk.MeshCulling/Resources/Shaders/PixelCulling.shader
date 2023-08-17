﻿// This shader draws a texture on the mesh.
Shader "RiggedCulling/PixelCulling_V2"
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
                float3 normalOS : NORMAL;
                float3 color : COLOR;
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
                float3 vertexOS = IN.positionOS.xyz;
                float3 normalOS = IN.normalOS.xyz;
                // Pass vertex normal to fragment shader
                float3 normalWS = TransformObjectToWorld(IN.normalOS.xyz);

                float deformAmount = 0.0;
                if (IN.color.r <0.1)
                {
                    deformAmount = -0.025; // Adjust the deformation factor as needed
                }
                vertexOS += normalOS * deformAmount;
                
                varyings.positionCS = TransformObjectToHClip(vertexOS);
                // The TRANSFORM_TEX macro performs the tiling and offset
                // transformation.
                varyings.texcoord0.xy = TRANSFORM_TEX(IN.uv0, _BaseMap);
                varyings.texcoord3 = IN.uv3;//TRANSFORM_TEX(IN.uv3, _BaseMap);
                varyings.positionWS = TransformObjectToWorld(vertexOS);

                

                return varyings;
            }

            half4 frag(Varyings varyings) : SV_Target
            {
                half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, varyings.texcoord0.xy);
                
                half3 vPreSkinnedPosition = varyings.texcoord3.xyz;
                half3 vEllipsoidPosition = ellipsoidposition(_EllipsoidCenter, _EllipsoidSide, _EllipsoidUp, _EllipsoidForward, varyings.texcoord3);
                
                // We use the xy of the position in ellipsoid space as the texture uv
                // offset decal so it shows on the center of the model
                half2 texcoordOffset = float2(-1.25,0.5);
                half2 vTexcoord = vEllipsoidPosition.xy - texcoordOffset; 
                
                // Determine the falloff
                float vDistance = distance(vPreSkinnedPosition, _EllipsoidCenter);
                float falloff = vDistance - _Falloff;//remap(_Falloff, 0, 1, -0.5, 1);
                
                falloff = saturate(falloff);
                falloff = 1.0 - falloff;
                falloff = falloff - 0.1;
                // invert the falloff
                falloff = 1.0 - falloff;
                
                // fade out decal according to falloff
                half4 decalTex = SAMPLE_TEXTURE2D(_DecalMap, sampler_DecalMap_point_clamp,  TRANSFORM_TEX(vTexcoord, _DecalMap));
                //cullwhite(decalTex);
                half4 decal = decalTex;
                
                decal = lerp(decal, 0, falloff);
                //decal = smoothstep(0,1,decal);
                decal *= 3.5;
                
                if (decal.a > 0.2)
                    clip(-1);
                
                if(decal.r > 0.1)
                {
                    // darken it only because our test texture is too light
                    decalTex *= 0.4;
                    // lerp to the original texture
                    baseColor = lerp(baseColor, decalTex, 1);
                }
                
                return baseColor;
            }
            ENDHLSL
        }
    }
}