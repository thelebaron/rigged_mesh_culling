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

    public Material material;

    private void Start()
    {
        // Make sure the material has the correct shader
        if (material.shader.name != "RiggedCulling/PixelCulling")
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
            material.SetVector("_EllipsoidPosition", ellipsoidPosition);
            material.SetVector("_EllipsoidSide", ellipsoidSide);
            material.SetVector("_EllipsoidUp", ellipsoidUp);
            material.SetVector("_EllipsoidForward", ellipsoidForward);
            material.SetFloat("_EllipsoidScale", ellipsoidScale);
        }
    }
    
    // Gizmos for the editor
    private void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(transform.TransformPoint(ellipsoidPosition), ellipsoidScale * Mathf.Max(ellipsoidSide.x, ellipsoidSide.y, ellipsoidSide.z));
    }
}