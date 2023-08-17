
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;

namespace Junk.MeshCulling
{
    public class CharacterRigPostProcessor : AssetPostprocessor
    {
        private void OnPreprocessModel()
        {
            var modelImporter = assetImporter as ModelImporter;
            if (modelImporter == null) 
                return;
            modelImporter.isReadable = true;
            modelImporter.SaveAndReimport();
        }
        
        private void OnPostprocessModel(GameObject g)
        {
            ApplyUVs(g.transform);
        }

        private static void ApplyUVs(Transform t)
        {
            // Delete maya rig controls
            if (t.name.Contains("_Ctrl_Reference"))
                Object.DestroyImmediate(t.gameObject);

            // Get SkinnedMeshRenderer
            var skinnedMeshRenderer = t.gameObject.GetComponent<SkinnedMeshRenderer>();
            if (skinnedMeshRenderer != null)
            {
                // Get the source mesh in its default pose
                var mesh = skinnedMeshRenderer.sharedMesh;
                var vertices  = mesh.vertices;
                
                // https://forum.unity.com/threads/preskinned-bindpose-vertex-position.861220/#post-5697853
                // Set TEXCOORD3 to the object's vertex positions, thanks mr bgolus!
                
                var uvs = new Vector3[mesh.vertices.Length];
                for (int i = 0; i < mesh.vertices.Length; i++)
                {
                    uvs[i] =  mesh.vertices[i];
                    uvs[i] *= 0.5f;
                }
                mesh.SetUVs(3, uvs);
                mesh.SetVertices(vertices);

                skinnedMeshRenderer.sharedMesh = mesh;

                var postProcessedUvs = t.gameObject.AddComponent<MeshHasBindPoseUv>();
                postProcessedUvs.UV3Modified = true;
            }
            
            // Recurse
            foreach (Transform child in t)
                ApplyUVs(child);
        }
    }
    
}
#endif