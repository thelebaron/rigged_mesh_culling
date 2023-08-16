using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class EllipsoidShaderController : MonoBehaviour
{
    public Vector3 ellipsoidPosition = Vector3.zero;
    public Vector3 ellipsoidSide     = Vector3.one;
    public Vector3 ellipsoidUp       = Vector3.up;
    public Vector3 ellipsoidForward  = Vector3.forward;
    public float   ellipsoidScale    = 0.01f;
    // range
    [Range(0.0f, 1.0f)]
    public float   falloff = 0.01f;

    public Material material;

    private void Start()
    {
        // Make sure the material has the correct shader
        if (material.shader.name != "RiggedCulling/PixelCulling_V2")
        {
            Debug.LogError("This script requires the 'RiggedCulling/PixelCulling' shader.");
            enabled = false;
            return;
        }
    }

    private void Update()
    {
        if (material)
        {
            material.SetVector("_EllipsoidCenter", ellipsoidPosition);
            material.SetVector("_EllipsoidSide", ellipsoidSide); // * ellipsoidScale);
            material.SetVector("_EllipsoidUp", ellipsoidUp); // * ellipsoidScale); //
            material.SetVector("_EllipsoidForward", ellipsoidForward); // * ellipsoidScale);
            material.SetFloat("_Falloff", falloff);
        }
    }
    
    public void AdjustSize(float newSize) {
        ellipsoidScale   =  newSize;
        ellipsoidSide    *= newSize;
        ellipsoidUp      *= newSize;
        ellipsoidForward *= newSize;
    }
    
    // Gizmos for the editor
    private void OnDrawGizmosSelected()
    {
        var mesh = new Mesh();
        EllipsoidMesh.GenerateMesh(mesh, ellipsoidPosition, ellipsoidSide, ellipsoidUp, ellipsoidForward);
        Gizmos.color = Color.red;
        Gizmos.DrawWireMesh(mesh, ellipsoidPosition, Quaternion.identity, Vector3.one);
    }
}