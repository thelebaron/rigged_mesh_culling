


float contains(float3 testPoint, float3 AABBCenter, float3 AABBExtents)
{
    if (testPoint.x < AABBCenter.x - AABBExtents.x)
        return 0;
    if (testPoint.x > AABBCenter.x + AABBExtents.x)
        return 0;

    if (testPoint.y < AABBCenter.y - AABBExtents.y)
        return 0;
    if (testPoint.y > AABBCenter.y + AABBExtents.y)
        return 0;

    if (testPoint.z < AABBCenter.z - AABBExtents.z)
        return 0;
    if (testPoint.z > AABBCenter.z + AABBExtents.z)
        return 0;

    return 1;
}

// inverts a(clamped) 0 or 1 value, with the opposite of 1 or 0.
// for use with global 0/1 values
inline float invertglobalfloat(float value){
    if(value == 0)
        return 1;
    
    return 0;
    
}

inline float inverselerp(float from, float to, float value){
  return value - from;
}


inline float remap(float x, float in_min, float in_max,
                   float out_min, float out_max)
{
    float t = (x - in_min) / (in_max - in_min);
    return lerp(out_min, out_max, t);
}

half3 quadraticlerp(half3 start, half3 end, float value)
{
    return start * (1 - value * value) + end * (value * value); // Quadratic interpolation
}

// ellipsoid for preskinned bindpose position on a mesh
// see L4D gdc presentations for more info
half3 ellipsoidposition(half3 center, half3 side, half3 up, half3 forward, half4 bindposition)
{
    half3 vPreSkinnedPosition = bindposition.xyz;                  // 1 instruction 
    
    // Subtract off ellipsoid center
    half3 vLocalPosition = vPreSkinnedPosition - center;           // 3 instructions (one per component)
    half3 vEllipsoidPosition = 0;                                  // 1 instruction
    
    // Apply rotation and ellipsoid scale. Ellipsoid basis is the orthonormal basis
    // of the ellipsoid divided by the per-axis ellipsoid size.
    vEllipsoidPosition.x = dot( side.xyz, vLocalPosition.xyz );    // 4 instructions
    vEllipsoidPosition.y = dot( up.xyz, vLocalPosition.xyz );      // 4 instructions
    vEllipsoidPosition.z = dot( forward.xyz, vLocalPosition.xyz ); // 4 instructions
    
    // Use the length of the position in ellipsoid space as input to texkill/clip
    //float texkillInput = length( vEllipsoidPosition.xyz );         // Approx 8-9 instructions (3 multiplies, 2 adds, square root operation)
    //clip( texkillInput );                                          // 1 instruction
    
    return vEllipsoidPosition;
}

half4 cullwhite(float4 color)
{
    //float brightness = dot(color.rgb, half3(0.299, 0.587, 0.114)); // Standard formula for calculating brightness of a color
    //if (brightness > 0.99) // this will clip pure white and very close to white pixels
        //{
        //clip(-1);
        //}

    // Define a threshold to consider a pixel as "pure white"
    half threshold = 0.5;
                
    // If the color is close to pure white, discard the fragment
    if (color.a > threshold)
        clip(-1);
    return color;
}

inline float remap_clamp(float x, float in_min, float in_max,
                         float out_min, float out_max)
{
    float t = (x - in_min) / (in_max - in_min);
    t = clamp(t, 0, 1);
    return lerp(out_min, out_max, t);
}

inline float easeInQuart(float t) 
{
    float clamped = clamp(t,0,1);
    return pow(clamped, 4);
}

inline float inverseEaseInQuart(float x)
{
    return pow(clamp(x,0,1), 0.25);
}


// vertex function for emulating polygon wobble from lack of precision
float4 vertexjitter(float4 positionOS, float x, float y)
{
    //Vertex snapping // complains about wanting matrixmvp > UnityObjectToClipPos
    float4 snapToPixel = mul(UNITY_MATRIX_MVP, positionOS); //TransformWorldToHClip(input.positionOS.xyz); // <-- doesnt work with skinnedmeshrenderer - this line causes a warning but is still usable
    float4 vertex = snapToPixel;
    vertex.xyz = snapToPixel.xyz / snapToPixel.w;
    vertex.x = floor(x * vertex.x) / x;
    vertex.y = floor(y * vertex.y) / y;
    vertex.xyz *= snapToPixel.w;
    //vertex = mul(unity_WorldToObject, vertex);
    float4 positionCS = vertex;
    //#endif
    return positionCS;
}


// vertex function for changing the fov of the vertex shader
inline float3 fps_projection(float fov, float4 positionOS)
{
    float3 position =  positionOS.xyz;
    position = TransformWorldToView(TransformObjectToWorld(positionOS.xyz));

    fov = 65.0;

    
    fov = remap(fov, 1, 180, 180, 1);
    //inline float remap(float x, float in_min, float in_max, float out_min, float out_max)
    fov = fov / 180.0f;
    fov = fov * 0.5f;
    fov = fov * 3.14159265358979323846f;
    fov = tan(fov);
    
    fov = fov * UNITY_MATRIX_P[1].y;
    fov = fov * -1.0;
    fov = 1/fov;
    float reciprocal = 1/fov;//rcp(fov);

    float x = reciprocal * position.x;
    float y = reciprocal * position.y;
    float z = position.z;
    float3 combined = float3(x, y, z);
    
    position = TransformWorldToObject(mul(UNITY_MATRIX_I_V, float4(combined, 1) ).xyz);
    
    return position;
}


float4 effect(float enable, float4 col)
{
    float4 colr = col;

    
    return colr;
}

// Light falloff for doom like effect
float4 diminishedlighting(float4 color, float3 worldSpaceCameraPos, float4x4 unity_CameraToWorld, float3 positionWS, float4 positionCS,  half3 viewDirTS)
{
    float3 camforward = mul((float3x3)unity_CameraToWorld, float3(0,0,1));
    float directionFromCamera = normalize(worldSpaceCameraPos - positionWS);
    float dotProductCameraFwd = dot(camforward, viewDirTS);
    
    // Diminished lighting   
    //https://stackoverflow.com/questions/16131963/depth-as-distance-to-camera-plane-in-glsl
    float3 cs_position = positionCS.xyz;//glModelViewMatrix * gl_Vertex;
    float distToCamera = -cs_position.z;
    //float3 gl_Position = UNITY_MATRIX_MVP * cs_position;
        
    // Old distance to object 
    float dist = distance(positionWS, worldSpaceCameraPos);
    dist = positionCS.w; // apparently this works, I guess its the clip space distance to camera??
    //dist = viewDirTS.z; // closer but not using direction
        
    //DISABLED
    //if(dotProductCameraFwd > 0 )//&& _GlobalDisableDimLighting == 0)
    //{
        //DISABLED
        half3 dimcol = lerp(color.rgb * 0.5, 0, 0.4);// _Diminished );
        // Debug with green: dimcol = float3(0,1,0);
        // equiv c# - math.remap(40, 55, 1, 0, dist);
        // clamp/saturate the value as going above 1 made things black
        float d = saturate(remap(dist, 7, 25, 0, 1));
        // lerp between values based on distance
        half3 l = lerp(color.rgb, dimcol, d);
        color.rgb = l;
    //}

    return color;
}
float camdistance(float4 color, float3 worldSpaceCameraPos, float4x4 unity_CameraToWorld, float3 positionWS, float4 positionCS,  half3 viewDirTS)
{
    float3 camforward = mul((float3x3)unity_CameraToWorld, float3(0,0,1));
    float directionFromCamera = normalize(worldSpaceCameraPos - positionWS);
    float dotProductCameraFwd = dot(camforward, viewDirTS);
    
    // Diminished lighting   
    //https://stackoverflow.com/questions/16131963/depth-as-distance-to-camera-plane-in-glsl
    float3 cs_position = positionCS.xyz;//glModelViewMatrix * gl_Vertex;
    float distToCamera = -cs_position.z;
    //float3 gl_Position = UNITY_MATRIX_MVP * cs_position;
        
    // Old distance to object 
    float dist = distance(positionWS, worldSpaceCameraPos);
    dist = positionCS.w; // apparently this works, I guess its the clip space distance to camera??
    //dist = viewDirTS.z; // closer but not using direction
        
    //DISABLED
    //if(dotProductCameraFwd > 0 )//&& _GlobalDisableDimLighting == 0)
    //{
    //DISABLED
    half3 dimcol = lerp(color.rgb * 0.5, 0, 0.4);// _Diminished );
    // Debug with green: dimcol = float3(0,1,0);
    // equiv c# - math.remap(40, 55, 1, 0, dist);
    // clamp/saturate the value as going above 1 made things black
    float d = saturate(remap(dist, 7, 25, 0, 1));
    // lerp between values based on distance
    half3 l = lerp(color.rgb, dimcol, d);
    color.rgb = l;
    //}

    return distToCamera;
}


float doomLight(float zdepth, float brightness) 
{

    float depth = zdepth * _ZBufferParams.z;
    // #if defined(UNITY_REVERSED_Z)
    //     depth = 1.0 - depth;
    // #endif
    depth *= 1.6;
    depth -= .1125;
    float li = (brightness * 2.0) - (224.0 / 256.0);
    // li = saturate(li);
    float maxlight = (brightness * 2.0) - (40.0 / 256.0);
    maxlight = saturate(maxlight);
    float dscale = depth * 0.4 * (1.0 - unity_OrthoParams.w);
    return saturate(li + dscale) + 0.01;
}