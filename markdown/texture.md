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