

using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class EllipsoidMesh : MonoBehaviour
{
    public int resolution = 32; // Number of subdivisions along each axis
    public Vector3 scale = new Vector3(1.0f, 1.0f, 1.0f); // Ellipsoid scale factors
    public Vector3 center = Vector3.zero; // Center of the ellipsoid
    public Vector3 sideVector = Vector3.right; // Vector defining the side of the ellipsoid
    public Vector3 upVector = Vector3.up; // Vector defining the up direction of the ellipsoid
    public Vector3 forwardVector = Vector3.forward; // Vector defining the forward direction of the ellipsoid

    private MeshFilter meshFilter;
    private GameObject meshObject;

    private void OnEnable()
    {
        meshObject = new GameObject("Ellipsoid Mesh");
        meshObject.hideFlags = HideFlags.HideAndDontSave;
        meshFilter = meshObject.AddComponent<MeshFilter>();
        meshObject.AddComponent<MeshRenderer>();
        meshObject.GetComponent<MeshRenderer>().material = new Material(Shader.Find("Universal Render Pipeline/Lit"));
    }

    private void OnDisable()
    {
        DestroyImmediate(meshObject);
    }

    private void Update()
    {
        meshObject.transform.position = transform.position;
        var mesh = new Mesh();
        GenerateMesh(mesh);
        meshFilter.mesh = mesh;
    }

    public void GenerateMesh(Mesh mesh)
    {
        List<Vector3> vertices = new List<Vector3>();
        List<int> triangles = new List<int>();
        List<Vector3> normals = new List<Vector3>();

        //Vector3 forwardVector = Vector3.Cross(sideVector, upVector).normalized;

        for (int i = 0; i <= resolution; i++)
        {
            for (int j = 0; j <= resolution; j++)
            {
                float u = (float)i / resolution;
                float v = (float)j / resolution;

                float phi = u * Mathf.PI * 2;
                float theta = v * Mathf.PI;

                /*                // Subtract off ellipsoid center
                float3 vLocalPosition = ( vPreSkinnedPosition.xyz - vEllipsoidCenter.xyz );
                float3 vEllipsoidPosition;
                
                // Apply rotation and ellipsoid scale. Ellipsoid basis is the orthonormal basis
                // of the ellipsoid divided by the per-axis ellipsoid size.
                vEllipsoidPosition.x = dot( vEllipsoidSide.xyz, vLocalPosition.xyz );
                vEllipsoidPosition.y = dot( vEllipsoidUp.xyz, vLocalPosition.xyz );
                vEllipsoidPosition.z = dot( vEllipsoidForward.xyz, vLocalPosition.xyz );*/
                
                Vector3 dir = sideVector * Mathf.Sin(theta) * Mathf.Cos(phi)
                            + upVector * Mathf.Cos(theta)
                            + forwardVector * Mathf.Sin(theta) * Mathf.Sin(phi);

                // center + dir.x * scale.x + dir.y * scale.y + dir.z * scale.z;
                float x = center.x + dir.x * scale.x;
                float y = center.y + dir.y * scale.y;
                float z = center.z + dir.z * scale.z;
                var point = new Vector3(x, y, z);
                
                vertices.Add(point);
                normals.Add(dir.normalized);

                if (i < resolution && j < resolution)
                {
                    int index = i * (resolution + 1) + j;
                    triangles.Add(index);
                    triangles.Add(index + 1);
                    triangles.Add(index + resolution + 1);

                    triangles.Add(index + 1);
                    triangles.Add(index + resolution + 2);
                    triangles.Add(index + resolution + 1);
                }
            }
        }

        mesh.vertices = vertices.ToArray();
        mesh.triangles = triangles.ToArray();
        mesh.normals = normals.ToArray();
    }

    public static void GenerateMesh(Mesh mesh, Vector3 center, Vector3 sideVector, Vector3 upVector, Vector3 forward)
    {
        List<Vector3> vertices  = new List<Vector3>();
        List<int>     triangles = new List<int>();
        List<Vector3> normals   = new List<Vector3>();

        Vector3 forwardVector = Vector3.Cross(sideVector, upVector).normalized;
var             resolution    = 32;
var             scale         = Vector3.one;
        for (int i = 0; i <= resolution; i++)
        {
            for (int j = 0; j <= resolution; j++)
            {
                float u = (float)i / resolution;
                float v = (float)j / resolution;

                float phi   = u * Mathf.PI * 2;
                float theta = v * Mathf.PI;

                Vector3 dir = sideVector * Mathf.Sin(theta) * Mathf.Cos(phi)
                              + upVector * Mathf.Cos(theta)
                              + forwardVector * Mathf.Sin(theta) * Mathf.Sin(phi);

                // center + dir.x * scale.x + dir.y * scale.y + dir.z * scale.z;
                float x = center.x + dir.x * scale.x;
                float y = center.y + dir.y * scale.y;
                float z = center.z + dir.z * scale.z;

                Vector3 point = new Vector3(x, y, z);
                
                vertices.Add(point);
                normals.Add(-dir.normalized);

                if (i < resolution && j < resolution)
                {
                    int index = i * (resolution + 1) + j;
                    triangles.Add(index);
                    triangles.Add(index + 1);
                    triangles.Add(index + resolution + 1);

                    triangles.Add(index + 1);
                    triangles.Add(index + resolution + 2);
                    triangles.Add(index + resolution + 1);
                }
            }
        }

        mesh.vertices  = vertices.ToArray();
        mesh.triangles = triangles.ToArray();
        mesh.normals   = normals.ToArray();
    }
}