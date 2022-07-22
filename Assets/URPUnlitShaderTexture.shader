// This shader draws a texture on the mesh.
Shader "Example/URPUnlitShaderTexture"
{
    // The _BaseMap variable is visible in the Material's Inspector, as a field
    // called Base Map.
    Properties
    {
        _BaseMap("Base Map", 2D) = "white"
        _Position("Position", Vector) = (0,0,0,0)
        _Scale("Scale", Vector) = (1,1,1,0)
        _Radius("Radius", Float) = 0.01
        
        
        _DecalMap("Decal Map", 2D) = "red"
        //_Color("Color", Color) = (1,1,1,1)
        //_CutawayColor("Cutaway Color", Color) = (1,1,1,1)
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
                
            float4 _BaseColor;
            float4 _CutawayColor;
            float4 _Position;
            float4 _Scale;
            float _Radius;

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                // The uv variable contains the UV coordinate on the texture for the
                // given vertex.
                float2 uv0          : TEXCOORD0;
                float4 uv1          : TEXCOORD1;
                float4 uv2          : TEXCOORD2;
                float4 uv3          : TEXCOORD3;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                // The uv variable contains the UV coordinate on the texture for the
                // given vertex.
                float2 uv           : TEXCOORD0;
                float3 positionWS   : TEXCOORD2;    // xyz: positionWS
                float4 texCoord3 :  TEXCOORD3;
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
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings varyings;
                varyings.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                // The TRANSFORM_TEX macro performs the tiling and offset
                // transformation.
                varyings.uv = TRANSFORM_TEX(IN.uv3, _BaseMap);
                varyings.texCoord3 = IN.uv3;//TRANSFORM_TEX(IN.uv3, _BaseMap);
                varyings.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                return varyings;
            }

            half4 frag(Varyings varyings) : SV_Target
            {
                // The SAMPLE_TEXTURE2D marco samples the texture with the given
                // sampler.
                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, varyings.uv);

                float3 decalUV = float3(0,1,1);
                half4 decal = SAMPLE_TEXTURE2D(_DecalMap, sampler_DecalMap, varyings.uv);
                float4 x = SAMPLE_TEXTURE2D(_DecalMap, sampler_DecalMap, decalUV.zy);
                float4 y = SAMPLE_TEXTURE2D(_DecalMap, sampler_DecalMap, decalUV.xz);
                float4 z = SAMPLE_TEXTURE2D(_DecalMap, sampler_DecalMap, decalUV.xy);
                float4 output = x * 1 + y * 1 + z * 1;

                color += output;
                
                float dist = length(_Position.xyz - varyings.texCoord3);
                dist -= _Radius;
                
                //spherical clipping
                // old worldspace: float dist = length(_Scale.xyz * varyings.positionWS.xyz - _Position.xyz);
                if (dist < _Radius)
                   clip(-1);
                
                return color;
            }
            ENDHLSL
        }
    }
}