# 纹理

## 加载纹理

看了 VulkanDemos 的

```cpp
    void LoadAssets()
    {
        vk_demo::DVKCommandBuffer* cmdBuffer = vk_demo::DVKCommandBuffer::Create(m_VulkanDevice, m_CommandPool);

        m_Model = vk_demo::DVKModel::LoadFromFile(
            "assets/models/head.obj",
            m_VulkanDevice,
            cmdBuffer,
            { VertexAttribute::VA_Position, VertexAttribute::VA_UV0, VertexAttribute::VA_Normal, VertexAttribute::VA_Tangent }
        );

        m_TexDiffuse       = vk_demo::DVKTexture::Create2D("assets/textures/head_diffuse.jpg", m_VulkanDevice, cmdBuffer);
        m_TexNormal        = vk_demo::DVKTexture::Create2D("assets/textures/head_normal.jpg", m_VulkanDevice, cmdBuffer);
        m_TexCurvature     = vk_demo::DVKTexture::Create2D("assets/textures/curvatureLUT.png", m_VulkanDevice, cmdBuffer);
        m_TexPreIntegrated = vk_demo::DVKTexture::Create2D("assets/textures/preIntegratedLUT.png", m_VulkanDevice, cmdBuffer);

        delete cmdBuffer;
    }

```

他还是自己显式创建的

或许我可以用一个方法可以在读取模型的时候自动读取纹理

但是想做一个鲁棒的系统还是费力的

那还是算了

## assimp 读取纹理路径

本来我是希望这样读取纹理路径的

```cpp
    ModelMesh* Model::LoadMesh(vk::raii::PhysicalDevice const& physical_device,
                               vk::raii::Device const&         device,
                               vk::raii::CommandPool const&    command_pool,
                               vk::raii::Queue const&          queue,
                               const aiMesh*                   ai_mesh,
                               const aiScene*                  ai_scene)
    {
        ModelMesh* mesh = new ModelMesh();

        // load material
        aiMaterial* material = ai_scene->mMaterials[ai_mesh->mMaterialIndex];
        if (material)
        {
            FillMaterialTextures(material, mesh->material);
        }
```

```cpp
    void FillMaterialTextures(aiMaterial* ai_material, MaterialInfo& material)
    {
        if (ai_material->GetTextureCount(aiTextureType::aiTextureType_DIFFUSE))
        {
            aiString texture_path;
            ai_material->GetTexture(aiTextureType::aiTextureType_DIFFUSE, 0, &texture_path);
            material.diffuse = texture_path.C_Str();
            SimplifyTexturePath(material.diffuse);
        }

        if (ai_material->GetTextureCount(aiTextureType::aiTextureType_NORMALS))
        {
            aiString texture_path;
            ai_material->GetTexture(aiTextureType::aiTextureType_NORMALS, 0, &texture_path);
            material.normalmap = texture_path.C_Str();
            SimplifyTexturePath(material.normalmap);
        }

        if (ai_material->GetTextureCount(aiTextureType::aiTextureType_SPECULAR))
        {
            aiString texture_path;
            ai_material->GetTexture(aiTextureType::aiTextureType_SPECULAR, 0, &texture_path);
            material.specular = texture_path.C_Str();
            SimplifyTexturePath(material.specular);
        }
    }
```

但是对于这种把数据存到 mtl 的，完全读不到啊

于是为了做出效果，这些东西还是之后做把

看了别人说的

[https://stackoverflow.com/questions/16134605/assimp-does-not-import-textures](https://stackoverflow.com/questions/16134605/assimp-does-not-import-textures)

[https://www.reddit.com/r/GraphicsProgramming/comments/fl37tc/assimp_doesnt_like_blender_obj_files/](https://www.reddit.com/r/GraphicsProgramming/comments/fl37tc/assimp_doesnt_like_blender_obj_files/)

我看了一下我的 mtl 文件，看上去非常正常啊

但是就是得不到纹理

于是看到了 `ReadFileFromMemory` 的注释

> This is a straightforward way to decode models from memory buffers, but it doesn't handle model formats that spread their data across multiple files or even directories. Examples include OBJ or MD3, which outsource parts of their material info into external scripts. If you need full functionality, provide a custom IOSystem to make Assimp find these files and use the regular ReadFile() API.

所以我应该用一个带有 IO 的函数

```cpp
        Assimp::Importer importer;
        const aiScene*   scene = importer.ReadFileFromMemory((void*)data_ptr, data_size, assimpFlags);
```

现在换成

```cpp
        Assimp::Importer importer;
        const aiScene*   scene =
            importer.ReadFile(g_runtime_context.file_system->GetAbsolutePath(file_path), assimpFlags);
        if (scene == nullptr)
        {
            MEOW_ERROR("Read model file {} failed!", file_path);
            return;
        }
```

就好了