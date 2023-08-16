// This shader draws a texture on the mesh.
Shader "RiggedCulling/PixelCulling"
{
    // The _BaseMap variable is visible in the Material's Inspector, as a field
    // called Base Map.
    Properties
    {
        _MyArr ("Tex", 2DArray) = "" {}
        _BaseMap("Base Map", 2D) = "white"
        _EllipsoidScale("Scale", Float) = 0.01
        
        _EllipsoidPosition("EllipsoidPosition", Vector) = (0,0,0,0)
        _EllipsoidSide("EllipsoidSide", Vector) = (0,0,0,0)
        _EllipsoidUp("EllipsoidUp", Vector) = (0,0,0,0)
        _EllipsoidForward("EllipsoidForward", Vector) = (0,0,0,0)
        
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
            
                float3 _EllipsoidPosition;
                float3 _EllipsoidSide;
                float3 _EllipsoidUp;
                float3 _EllipsoidForward;
                float _EllipsoidScale;
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
                half4 baseColor = 0.0;
                baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, varyings.texcoord0.xy);
                // set basecolor to red
                //baseColor.r = 1.0;
                
                float3 vPreSkinnedPosition = varyings.texcoord3.xyz;
                float3 vEllipsoidCenter = _EllipsoidPosition;
                float3 vEllipsoidSide = _EllipsoidSide;
                float3 vEllipsoidUp = _EllipsoidUp;
                float3 vEllipsoidForward = _EllipsoidForward;

                // Determine the falloff
                float vDistance = distance(vPreSkinnedPosition, vEllipsoidCenter);

                // note large scale makes everything brighter - need to correlate scale to the actual decal scaling/tile size
                float vScale = remap(_EllipsoidScale, 0, 1, -0.5, 1);

                
                float falloff = vDistance - vScale;
                falloff = saturate(falloff);
                falloff = 1.0 - falloff;
                //falloff = pow(falloff, 2);
                falloff = falloff - 0.1;
                // invert the falloff
                falloff = 1.0 - falloff;
                //baseColor = falloff;
                
                // Subtract off ellipsoid center
                float3 vLocalPosition = ( vPreSkinnedPosition.xyz - vEllipsoidCenter.xyz );
                float3 vEllipsoidPosition;
                
                // Apply rotation and ellipsoid scale. Ellipsoid basis is the orthonormal basis
                // of the ellipsoid divided by the per-axis ellipsoid size.
                vEllipsoidPosition.x = dot( vEllipsoidSide.xyz, vLocalPosition.xyz );
                vEllipsoidPosition.y = dot( vEllipsoidUp.xyz, vLocalPosition.xyz );
                vEllipsoidPosition.z = dot( vEllipsoidForward.xyz, vLocalPosition.xyz );
                
                // Use the length of the position in ellipsoid space as input to texkill/clip
                float fTexkillInput = length( vEllipsoidPosition ); 
                clip( fTexkillInput );
                // We use the xy of the position in ellipsoid space as the texture uv
                float2 vTexcoord = vEllipsoidPosition.xy - float2(1.25,-0.75); // offset as model sits outside of 0-1 range
                // also note model is posed with arms at 45 degrees to the ground, so at the arms the effect is wonky
                
                

                half4 decal = SAMPLE_TEXTURE2D(_DecalMap, sampler_DecalMap_point_clamp,  TRANSFORM_TEX(vTexcoord, _DecalMap));
               
                
                float dist = length(vEllipsoidCenter.xyz - varyings.texcoord3);
                dist -= _EllipsoidScale;
                
                //spherical clipping
                // old worldspace: float dist = length(_Scale.xyz * varyings.positionWS.xyz - _Position.xyz);
                //if (dist < _EllipsoidScale)
                   //clip(-1);

                //float len = length(vEllipsoidCenter.xyz - varyings.positionCS.xyz);
                //if (distB * 1 < _EllipsoidScale)

                
                
                float3 position = varyings.positionWS.xyz;//glModelViewMatrix * gl_Vertex;
                float d = distance(position, vEllipsoidCenter.xyz + position);//distance(positionWS, worldSpaceCameraPos);

                //decal += d;

                //inverseFalloff = smoothstep(0,3,inverseFalloff);
                // fade out decal according to falloff

                
                decal = lerp(decal, half4(0,0,0,0), falloff);
                decal = smoothstep(0,1,decal);
                decal *= 3.5;
                if (decal.a > 0.2)
                {
                    clip(-1);
                }
                
                if(falloff>0.0)
                {
                    //decal += baseColor;
                }
                else
                {
                    //decal = 0.0;
                }

                if(decal.r > 0.1)
                {
                    baseColor = lerp(baseColor, decal, 0.75);
                    //baseColor += decal;
                }
                
                if (decal.a > 0.2)
                {
                    //clip(-1);
                    baseColor = float4(1,0,1,1);
                }
                
                return baseColor;
            }
            ENDHLSL
        }
    }
}