
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
        Apply(g.transform);
    }

    void Apply(Transform t)
    {
        if (t.name.Contains("_Ctrl_Reference"))
            Object.DestroyImmediate(t.gameObject);

        var skinnedMeshRenderer = t.gameObject.GetComponent<SkinnedMeshRenderer>();
        if (skinnedMeshRenderer != null)
        {
            var mesh = skinnedMeshRenderer.sharedMesh;
            
            // https://forum.unity.com/threads/preskinned-bindpose-vertex-position.861220/#post-5697853
            // set TEXCOORD3 to the object's vertex positions, thanks mr bgolus!
            mesh.SetUVs(3, mesh.vertices);

            skinnedMeshRenderer.sharedMesh = mesh;

            t.gameObject.AddComponent<ModifiedRigUvs>();
        }
        
        
        if (t.name.ToLower().Contains("collider"))
            t.gameObject.AddComponent<MeshCollider>();
                
        // Recurse
        foreach (Transform child in t)
            Apply(child);
    }
}
#endif