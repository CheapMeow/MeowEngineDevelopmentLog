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

## 一个纹理一个 descriptor

之前记得 `vkUpdateDescriptorSets` 不可以在 command buffer 录制的时候更新

但是我这样做没错

```cpp
    void DeferredPass::DrawQuadOnly(const vk::raii::CommandBuffer& command_buffer)
    {
        FUNCTION_TIMER();

        const vk::raii::Device& logical_device = g_runtime_context.render_system->GetLogicalDevice();

        m_quad_mat.GetShader()->BindImageToDescriptor(logical_device, "inputDepth", *m_depth_attachment);

        m_quad_mat.GetShader()->BindUniformBufferToPipeline(command_buffer, "lightDatas");
        for (int32_t i = 0; i < m_quad_model.meshes.size(); ++i)
        {
            m_quad_model.meshes[i]->BindDrawCmd(command_buffer);

            ++draw_call[1];
        }
    }
```

但是似乎就是不行

> A freshly allocated descriptor set is just a bit of GPU memory, you need to make it point to your buffers. For that you use vkUpdateDescriptorSets(), which takes an array of VkWriteDescriptorSet for each of the resources that a descriptor set points to. If you were using the Update After Bind flag, it is possible to use descriptor sets, and bind them in command buffers, and update it right before submitting the command buffer. This is mostly a niche use case, and not commonly used. You can only update a descriptor set before it’s bound for the first time, unless you use that flag, in which case you can only update it before you submit the command buffer into a queue. When a descriptor set is being used, it’s immutable, and trying to update it will cause errors. The validation layers catch that. To be able to update the descriptor sets again, you need to wait until the command has finished executing.
> 新分配的描述符集只是一点 GPU 内存，您需要将其指向您的缓冲区。为此，您可以使用vkUpdateDescriptorSets() ，它为描述符集指向的每个资源采用VkWriteDescriptorSet数组。如果您使用“绑定后更新”标志，则可以使用描述符集，并将它们绑定在命令缓冲区中，并在提交命令缓冲区之前更新它。这主要是一个利基用例，并不常用。您只能在第一次绑定之前更新描述符集，除非您使用该标志，在这种情况下，您只能在将命令缓冲区提交到队列之前更新它。当使用描述符集时，它是不可变的，尝试更新它会导致错误。验证层抓住了这一点。为了能够再次更新描述符集，您需要等待命令执行完毕。

## bindless

看到一些 bindless 的介绍

[https://docs.vulkan.org/samples/latest/samples/extensions/descriptor_indexing/README.html](https://docs.vulkan.org/samples/latest/samples/extensions/descriptor_indexing/README.html)

[https://dev.to/gasim/implementing-bindless-design-in-vulkan-34no](https://dev.to/gasim/implementing-bindless-design-in-vulkan-34no)

[https://www.reddit.com/r/vulkan/comments/17fpico/i_kinda_dont_think_i_understand_descriptor/](https://www.reddit.com/r/vulkan/comments/17fpico/i_kinda_dont_think_i_understand_descriptor/)

还是 vulkan 官方文档讲的详细

但是现在我似乎都用不到这些