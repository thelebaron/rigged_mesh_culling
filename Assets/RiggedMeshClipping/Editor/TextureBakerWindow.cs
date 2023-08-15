using System;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace RiggedMeshClipping
{
    public class TextureBakerWindow : EditorWindow
    {
        private Material   ImageMaterial;
        private string     FilePath = "Assets/MaterialImage.png";
        private Vector2Int Resolution;

        private bool hasMaterial;
        private bool hasResolution;
        private bool hasFilePath;

        [MenuItem("Tools/Bake material to texture")]
        private static void OpenWindow()
        {
            //create window
            var window = GetWindow<TextureBakerWindow>();
            window.Show();

            window.CheckInput();
        }

        private void OnGUI()
        {
            EditorGUILayout.HelpBox("Set the material you want to bake as well as the size " +
                                    "and location of the texture you want to bake to, then press the \"Bake\" button.", MessageType.None);

            using (var check = new EditorGUI.ChangeCheckScope())
            {
                ImageMaterial = (Material)EditorGUILayout.ObjectField("Material", ImageMaterial, typeof(Material), false);
                Resolution    = EditorGUILayout.Vector2IntField("Image Resolution", Resolution);
                FilePath      = FileField(FilePath);

                if (check.changed) CheckInput();
            }

            GUI.enabled = hasMaterial && hasResolution && hasFilePath;
            if (GUILayout.Button("Bake")) BakeTexture();
            GUI.enabled = true;

            //tell the user what inputs are missing
            if (!hasMaterial) EditorGUILayout.HelpBox("You're still missing a material to bake.", MessageType.Warning);
            if (!hasResolution) EditorGUILayout.HelpBox("Please set a size bigger than zero.", MessageType.Warning);
            if (!hasFilePath) EditorGUILayout.HelpBox("No file to save the image to given.", MessageType.Warning);
        }

        private void CheckInput()
        {
            //check which values are entered already
            hasMaterial   = ImageMaterial != null;
            hasResolution = Resolution.x > 0 && Resolution.y > 0;
            hasFilePath   = false;
            try
            {
                var ext = Path.GetExtension(FilePath);
                hasFilePath = ext.Equals(".png");
            }
            catch (ArgumentException)
            {
            }
        }

        private string FileField(string path)
        {
            //allow the user to enter output file both as text or via file browser
            EditorGUILayout.LabelField("Image Path");
            using (new GUILayout.HorizontalScope())
            {
                path = EditorGUILayout.TextField(path);
                if (GUILayout.Button("choose"))
                {
                    //set default values for directory, then try to override them with values of existing path
                    var directory = "Assets";
                    var fileName  = "MaterialImage.png";
                    try
                    {
                        directory = Path.GetDirectoryName(path);
                        fileName  = Path.GetFileName(path);
                    }
                    catch (ArgumentException)
                    {
                    }

                    var chosenFile = EditorUtility.SaveFilePanelInProject("Choose image file", fileName,
                        "png", "Please enter a file name to save the image to", directory);
                    if (!string.IsNullOrEmpty(chosenFile)) path = chosenFile;
                    //repaint editor because the file changed and we can't set it in the textfield retroactively
                    Repaint();
                }
            }

            return path;
        }

        private void BakeTexture()
        {
            //render material to rendertexture
            var renderTexture = RenderTexture.GetTemporary(Resolution.x, Resolution.y);
            Graphics.Blit(null, renderTexture, ImageMaterial);

            //transfer image from rendertexture to texture
            var texture = new Texture2D(Resolution.x, Resolution.y);
            RenderTexture.active = renderTexture;
            texture.ReadPixels(new Rect(Vector2.zero, Resolution), 0, 0);

            //save texture to file
            var png = texture.EncodeToPNG();
            File.WriteAllBytes(FilePath, png);
            AssetDatabase.Refresh();

            //clean up variables
            RenderTexture.active = null;
            RenderTexture.ReleaseTemporary(renderTexture);
            DestroyImmediate(texture);
        }
    }
}