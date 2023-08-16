using System.Collections.Generic;
using UnityEngine;

namespace UnityTemplateProjects
{
    [ExecuteAlways]
    public class HidePolygons : MonoBehaviour
    {
        private Mesh      mesh;
        private int[]     triangles;
        private List<int> hideTriangleList = new List<int>();
        
        void OnEnable()
        {
            mesh      = GetComponent<MeshFilter>().sharedMesh;
            triangles = mesh.triangles;
        
            int[] randomTriangles = GetRandomTriangles();
            HideTrianglesInShader(randomTriangles);
        }
        
        // Get a random set of triangles
        public int[] GetRandomTriangles()
        {
            int count     = mesh.triangles.Length / 3;
            int hideCount = count / 2; // change this as required

            HashSet<int> hideTriangleSet = new HashSet<int>();
            while (hideTriangleSet.Count < hideCount)
            {
                int t = Random.Range(0, count);
                hideTriangleSet.Add(t);
            }

            hideTriangleList = new List<int>(hideTriangleSet);
            return hideTriangleList.ToArray();
        }

        // Hide marked triangles
        public void HideTrianglesInShader(int[] randomTriangles)
        {
            Vector3[] vertices = mesh.vertices;

            Color[] colors = new Color[vertices.Length];
            for (int i = 0; i < colors.Length; i++)
            {
                colors[i] = Color.white;
            }
        
            for (int i = 0; i < randomTriangles.Length; i++)
            {
                // Set triangle color to transparent
                for (int j = 0; j < 3; j++)
                {
                    colors[triangles[randomTriangles[i] * 3 + j]] = new Color(1, 1, 1, 0);
                }
            }

            mesh.colors = colors;
        }
    }
}