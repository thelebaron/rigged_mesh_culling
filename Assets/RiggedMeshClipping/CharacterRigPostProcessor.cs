
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
public class CharacterRigPostProcessor : AssetPostprocessor
{
    void OnPreprocessModel()
    {
        var modelImporter = assetImporter as ModelImporter;
        if (modelImporter == null) 
            return;
        modelImporter.isReadable = true;
        //modelImporter.materialName = ModelImporterMaterialName.BasedOnMaterialName;
        //modelImporter.materialSearch = ModelImporterMaterialSearch.Everywhere;
        //modelImporter.SearchAndRemapMaterials(ModelImporterMaterialName.BasedOnMaterialName, ModelImporterMaterialSearch.Everywhere);
        modelImporter.SaveAndReimport();
    }
    
    void OnPostprocessModel(GameObject g)
    {
        ApplyUVs(g.transform);
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
            mesh.SetUVs(3, mesh.vertices);

            skinnedMeshRenderer.sharedMesh = mesh;

            var postProcessedUvs = t.gameObject.AddComponent<MeshHasBindPoseUv>();
            postProcessedUvs.UV3Modified = true;
        }
        
        // Dont know why this was here
        /*if (t.name.ToLower().Contains("collider"))
            t.gameObject.AddComponent<MeshCollider>();*/
                
        // Recurse
        foreach (Transform child in t)
            ApplyUVs(child);
    }
}
#endif