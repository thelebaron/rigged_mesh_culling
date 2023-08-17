using System.Collections.Generic;
using UnityEngine;

namespace Junk.MeshCulling
{
    
    [CreateAssetMenu(fileName = "Character Culling List", menuName = "ScriptableObjects/CharacterCullingList", order = 1)]
    public class CharacterCullingList : ScriptableObject
    {
        public List<Texture2D> cullingTextures = new List<Texture2D>();
        

        public Texture2DArray ListToArray()
        {
            Texture2DArray cullingTextureArray = new Texture2DArray(cullingTextures[0].width, cullingTextures[0].height, cullingTextures.Count, TextureFormat.ARGB32, false);
            for (int i = 0; i < cullingTextures.Count; i++)
            {
                cullingTextureArray.SetPixels(cullingTextures[i].GetPixels(), i);
            }
            cullingTextureArray.Apply();
            return cullingTextureArray;
        }
    }
}