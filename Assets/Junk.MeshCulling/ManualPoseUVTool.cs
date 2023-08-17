using UnityEngine;

namespace Junk.MeshCulling
{
    public class ManualPoseUVTool : MonoBehaviour
    {
        
        public enum UVChannel
        {
            UV0,
            UV1,
            UV2,
            UV3
        }
        
        public UVChannel uvChannel = UVChannel.UV0;
        
        [ContextMenu("SetPoseUV")]
        void Execute()
        {
            ApplyUVs(transform);
        }
        
        void ApplyUVs(Transform t)
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
            
                // https://forum.unity.com/threads/preskinned-bindpose-vertex-position.861220/#post-5697853
                // Set TEXCOORD3 to the object's vertex positions, thanks mr bgolus!
                
                
                mesh.SetUVs((int)uvChannel, mesh.vertices);

                skinnedMeshRenderer.sharedMesh = mesh;

                if (t.gameObject.TryGetComponent<MeshHasBindPoseUv>(out var postProcessedUv))
                {
                    if(uvChannel == UVChannel.UV0)
                        postProcessedUv.UV0Modified = true;
                    else if(uvChannel == UVChannel.UV1)
                        postProcessedUv.UV1Modified = true;
                    else if(uvChannel == UVChannel.UV2)
                        postProcessedUv.UV2Modified = true;
                    else if(uvChannel == UVChannel.UV3)
                        postProcessedUv.UV3Modified = true;
                }
                else
                {
                    postProcessedUv = t.gameObject.AddComponent<MeshHasBindPoseUv>();
                    
                    if(uvChannel == UVChannel.UV0)
                        postProcessedUv.UV0Modified = true;
                    else if(uvChannel == UVChannel.UV1)
                        postProcessedUv.UV1Modified = true;
                    else if(uvChannel == UVChannel.UV2)
                        postProcessedUv.UV2Modified = true;
                    else if(uvChannel == UVChannel.UV3)
                        postProcessedUv.UV3Modified = true;
                }
                
            }
        
            // Dont know why this was here
            /*if (t.name.ToLower().Contains("collider"))
                t.gameObject.AddComponent<MeshCollider>();*/
                
            // Recurse
            foreach (Transform child in t)
                ApplyUVs(child);
        }
    }
}