using Unity.Mathematics;
using UnityEngine;

namespace Junk.MeshCulling
{
    [ExecuteAlways]
    public class VertexColorPainter : MonoBehaviour
    {
        public Vector3 paintPosition = Vector3.zero;
        public float   paintRadius   = 1.0f;
        public Color   paintColor    = Color.black;

        private SkinnedMeshRenderer meshRenderer;
        private Mesh                mesh;
        private Vector3[]           originalVertices;
        private Color[]             vertexColors;

        private void Start()
        {
            meshRenderer = GetComponent<SkinnedMeshRenderer>();
            if (meshRenderer == null)
            {
                Debug.LogError("SkinnedMeshRenderer component not found!");
                return;
            }

            mesh             = meshRenderer.sharedMesh;
            originalVertices = mesh.vertices;
            vertexColors     = new Color[originalVertices.Length];

            // Initialize vertex colors
            for (int i = 0; i < vertexColors.Length; i++)
            {
                vertexColors[i] = Color.white;
            }

            mesh.colors = vertexColors;
        }

        private void Update()
        {
            Vector3 position = paintPosition + transform.position;

            for (int i = 0; i < originalVertices.Length; i++)
            {
                Vector3 vertexWorldPos = transform.TransformPoint(originalVertices[i]);

                float distance = Vector3.Distance(position, vertexWorldPos);
                if (distance <= paintRadius)
                {
                    vertexColors[i] = paintColor;
                }
                else
                {
                    vertexColors[i] = Color.white;
                }
            }

            mesh.colors = vertexColors;
        }

        // Gizmos for the editor
        private void OnDrawGizmosSelected()
        {
            Gizmos.color = Color.red;
            Gizmos.DrawWireSphere(paintPosition + transform.position, paintRadius);
        }
    }
}