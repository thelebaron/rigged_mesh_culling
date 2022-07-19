using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class MeshClipper : MonoBehaviour
{
    SkinnedMeshRenderer skinnedMeshRenderer;
    private Shader      shader;
    private Material    material;
    public  Vector3     position;
    public  float       radius = 1;

    void OnEnable()
    {
        skinnedMeshRenderer = GetComponent<SkinnedMeshRenderer>();
        material = skinnedMeshRenderer.sharedMaterial;
        shader = material.shader;
    }

    
    void Update()
    {
        
    }

    private void OnDrawGizmosSelected()
    {
        var color = Color.red;
        color.a = 0.5f;
        Gizmos.color = color;
        
        position = (Vector3)material.GetVector("_Position");
        radius = material.GetFloat("_Radius");
        
        //set radius in material
        //material.SetFloat("_ClipSphereRadius", radius);
        //material.SetVector("_ClipSpherePosition", position);
        
        Gizmos.DrawSphere(transform.position + position, radius);
    }
}
