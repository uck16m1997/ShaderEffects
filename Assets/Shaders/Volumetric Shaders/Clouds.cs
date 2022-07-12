using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Clouds : MonoBehaviour
{
    public Shader CloudShader;
    public float MinHeight = 0.0f;
    public float MaxHeight = 5.0f;
    public float FadeDist = 2;
    public float Scale = 5;
    public float Steps = 50;
    public Texture ValueNoiseImage;
    public Transform Sun;
    Camera _Cam;
    public Material Material
    {
        get
        {
            if (_Material == null && CloudShader != null)
            {
                _Material = new Material(CloudShader);
            }
            if (_Material != null && CloudShader == null)
            {
                DestroyImmediate(_Material);
            }
            if (_Material != null && CloudShader != null && CloudShader != _Material.shader)
            {
                DestroyImmediate(_Material);
                _Material = new Material(CloudShader);

            }
            return _Material;
        }
    }
    Material _Material;
    // Start is called before the first frame update
    void Start()
    {
        if (_Material)
        {
            DestroyImmediate(_Material);
        }
    }

    Matrix4x4 GetFrustumCorners()
    {
        Matrix4x4 frustumCorners = Matrix4x4.identity;
        Vector3[] fCorners = new Vector3[4];

        // Given viewport coordinates, calculates the view space vectors pointing to the four frustum corners at the specified camera depth.    
        _Cam.CalculateFrustumCorners(new Rect(0, 0, 1, 1), _Cam.farClipPlane, Camera.MonoOrStereoscopicEye.Mono, fCorners);

        frustumCorners.SetRow(0, fCorners[1]);
        frustumCorners.SetRow(1, fCorners[2]);
        frustumCorners.SetRow(2, fCorners[3]);
        frustumCorners.SetRow(3, fCorners[0]);
        return frustumCorners;
    }

    // OnRenderImage (Everytime the camera gets rendered)
    // Blend the background with the clouds 
    [ImageEffectOpaque]
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (_Material == null || ValueNoiseImage == null)
        {
            // If no material or noise Image then just render the scene directly from source
            // Blit is bit block transfer. It merges bitmaps
            Graphics.Blit(source, destination);
            return;
        }
        if (_Cam == null)
        {
            // do it here ???
            _Cam = GetComponent<Camera>();

        }
        // ?? Don't need _Material here 
        Material.SetTexture("_ValueNoise", ValueNoiseImage);
        if (Sun != null)
        {
            Material.SetVector("_SunDir", -Sun.forward);
        }
        else
        {
            Material.SetVector("_SunDir", Vector3.up);

        }
        Material.SetFloat("_MinHeight", MinHeight);
        Material.SetFloat("_MaxHeight", MaxHeight);
        Material.SetFloat("_FadeDistance", FadeDist);
        Material.SetFloat("_Scale", Scale);
        Material.SetFloat("_StepScale", Steps);

        Material.SetMatrix("_FrustumCornersWS", GetFrustumCorners());
        Material.SetMatrix("_CameraInverseMatrix", _Cam.cameraToWorldMatrix);
        Material.SetVector("_CameraPosWS", _Cam.transform.position);

        CustomGraphicsBlit(source, destination, Material, 0);
    }

    static void CustomGraphicsBlit(RenderTexture source, RenderTexture dest, Material fxMaterial, int passNr)
    {
        RenderTexture.active = dest;

        fxMaterial.SetTexture("_MainTex", source);

        GL.PushMatrix();
        GL.LoadOrtho();

        fxMaterial.SetPass(passNr);

        GL.Begin(GL.QUADS);

        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.Vertex3(0.0f, 0.0f, 3.0f); // BL

        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.Vertex3(1.0f, 0.0f, 2.0f); // BR

        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.Vertex3(1.0f, 1.0f, 1.0f); // TR

        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.Vertex3(0.0f, 1.0f, 0.0f); // TL

        GL.End();
        GL.PopMatrix();
    }

    protected virtual void OnDisable()
    {
        if (_Material)
        {
            DestroyImmediate(_Material);
        }
    }

}
