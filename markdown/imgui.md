# ImGui

## 停靠在 dockspace

希望有一些窗口可以停靠在 dockspace 也可以自由地拉出来变成 viewport

于是发现所有的 imgui 绘制都在 dockspace 之后就好了

## Alpha 禁用

```cpp
    void ImGuiPass::RefreshOffscreenRenderTarget(VkSampler     offscreen_image_sampler,
                                                 VkImageView   offscreen_image_view,
                                                 VkImageLayout offscreen_image_layout)
    {
        m_offscreen_image_desc =
            ImGui_ImplVulkan_AddTexture(offscreen_image_sampler, offscreen_image_view, offscreen_image_layout);
    }
```

对于这里会导致一个问题，当传入的图像有不为 1 的透明度的时候，imgui 会和背景混合，使得呈现出来的图像变黑

对于 vulkan 怎么禁用 imgui 的混合？

参考这个

[How to disable alpha in ImGui::Image?](https://github.com/ocornut/imgui/issues/4730)

这个是调整窗口的透明度的

[ImGuiStyleVar_Alpha is unused](https://github.com/ocornut/imgui/issues/1198)

```cpp
ImGui::PushStyleVar(ImGuiStyleVar_Alpha, 1.0f);
ImGui::PopStyleVar();
```

### 尝试把定义搬出来

我直接把这些定义从 cpp 移到 h

imgui\backends\imgui_impl_vulkan.h

```cpp

// Reusable buffers used for rendering 1 current in-flight frame, for ImGui_ImplVulkan_RenderDrawData()
// [Please zero-clear before use!]
struct ImGui_ImplVulkan_FrameRenderBuffers
{
    VkDeviceMemory      VertexBufferMemory;
    VkDeviceMemory      IndexBufferMemory;
    VkDeviceSize        VertexBufferSize;
    VkDeviceSize        IndexBufferSize;
    VkBuffer            VertexBuffer;
    VkBuffer            IndexBuffer;
};

// Each viewport will hold 1 ImGui_ImplVulkanH_WindowRenderBuffers
// [Please zero-clear before use!]
struct ImGui_ImplVulkan_WindowRenderBuffers
{
    uint32_t            Index;
    uint32_t            Count;
    ImVector<ImGui_ImplVulkan_FrameRenderBuffers> FrameRenderBuffers;
};

struct ImGui_ImplVulkan_Texture
{
    VkDeviceMemory              Memory;
    VkImage                     Image;
    VkImageView                 ImageView;
    VkDescriptorSet             DescriptorSet;

    ImGui_ImplVulkan_Texture() { memset((void*)this, 0, sizeof(*this)); }
};

// For multi-viewport support:
// Helper structure we store in the void* RendererUserData field of each ImGuiViewport to easily retrieve our backend data.
struct ImGui_ImplVulkan_ViewportData
{
    ImGui_ImplVulkanH_Window                Window;                 // Used by secondary viewports only
    ImGui_ImplVulkan_WindowRenderBuffers    RenderBuffers;          // Used by all viewports
    bool                                    WindowOwned;
    bool                                    SwapChainNeedRebuild;   // Flag when viewport swapchain resized in the middle of processing a frame
    bool                                    SwapChainSuboptimal;    // Flag when VK_SUBOPTIMAL_KHR was returned.

    ImGui_ImplVulkan_ViewportData() { WindowOwned = SwapChainNeedRebuild = SwapChainSuboptimal = false; memset(&RenderBuffers, 0, sizeof(RenderBuffers)); }
    ~ImGui_ImplVulkan_ViewportData() { }
};

// Vulkan data
struct ImGui_ImplVulkan_Data
{
    ImGui_ImplVulkan_InitInfo   VulkanInitInfo;
    VkDeviceSize                BufferMemoryAlignment;
    VkPipelineCreateFlags       PipelineCreateFlags;
    VkDescriptorSetLayout       DescriptorSetLayout;
    VkPipelineLayout            PipelineLayout;
    VkPipeline                  Pipeline;               // pipeline for main render pass (created by app)
    VkPipeline                  PipelineForViewports;   // pipeline for secondary viewports (created by backend)
    VkShaderModule              ShaderModuleVert;
    VkShaderModule              ShaderModuleFrag;
    VkDescriptorPool            DescriptorPool;

    // Texture management
    ImGui_ImplVulkan_Texture    FontTexture;
    VkSampler                   TexSampler;
    VkCommandPool               TexCommandPool;
    VkCommandBuffer             TexCommandBuffer;

    // Render buffers for main window
    ImGui_ImplVulkan_WindowRenderBuffers MainWindowRenderBuffers;

    ImGui_ImplVulkan_Data()
    {
        memset((void*)this, 0, sizeof(*this));
        BufferMemoryAlignment = 256;
    }
};

ImGui_ImplVulkan_Data* ImGui_ImplVulkan_GetBackendData();

#endif // #ifndef IMGUI_DISABLE
```

然后方便我在外部访问

在应用程序里面

```cpp
struct ImguiPipelineSwitchingContext
{
    VkCommandBuffer command_buffer;
    VkPipeline      pipeline;
};

static void ImguiSwitchPipeline(const ImDrawList* parent_list, const ImDrawCmd* cmd)
{
    ImguiPipelineSwitchingContext* switching_context =
        static_cast<ImguiPipelineSwitchingContext*>(cmd->UserCallbackData);
    if (switching_context)
        vkCmdBindPipeline(
            switching_context->command_buffer, VK_PIPELINE_BIND_POINT_GRAPHICS, switching_context->pipeline);
}

void ImGuiPass::PostInit()
{
    // create no color blend pipeline

    ImGui_ImplVulkan_Data*     bd = ImGui_ImplVulkan_GetBackendData();
    ImGui_ImplVulkan_InitInfo* v  = &bd->VulkanInitInfo;
    ImGui_ImplVulkan_CreatePipelineNoColorBlend(v->Device,
                                                v->Allocator,
                                                v->PipelineCache,
                                                v->RenderPass,
                                                v->MSAASamples,
                                                &m_imgui_pipeline_no_color_blend,
                                                v->Subpass);

    switching_default_context.pipeline        = bd->Pipeline;
    switching_no_color_blend_context.pipeline = m_imgui_pipeline_no_color_blend;
}
```

最终像这样使用

```cpp
switching_default_context.command_buffer        = *command_buffer;
switching_no_color_blend_context.command_buffer = *command_buffer;

ImDrawList* draw_list = ImGui::GetWindowDrawList();
draw_list->AddCallback(&ImguiSwitchPipeline, &switching_no_color_blend_context);
ImGui::Image((ImTextureID)m_offscreen_image_desc, image_size);
draw_list->AddCallback(&ImguiSwitchPipeline, &switching_default_context);
```

但是就是会导致访问空的问题，在

```cpp
bool ImGui_ImplVulkan_CreateDeviceObjects()
{
    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();
    ImGui_ImplVulkan_InitInfo* v = &bd->VulkanInitInfo;
    VkResult err;

    if (!bd->TexSampler)
    {
        // Bilinear sampling is required by default. Set 'io.Fonts->Flags |= ImFontAtlasFlags_NoBakedLines' or 'style.AntiAliasedLinesUseTex = false' to allow point/nearest sampling.
        VkSamplerCreateInfo info = {};
        info.sType = VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO;
        info.magFilter = VK_FILTER_LINEAR;
        info.minFilter = VK_FILTER_LINEAR;
        info.mipmapMode = VK_SAMPLER_MIPMAP_MODE_LINEAR;
        info.addressModeU = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
        info.addressModeV = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
        info.addressModeW = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
        info.minLod = -1000;
        info.maxLod = 1000;
        info.maxAnisotropy = 1.0f;
        err = vkCreateSampler(v->Device, &info, v->Allocator, &bd->TexSampler);
        check_vk_result(err);
    }
```

明明每个量都是正确的

于是又改

改成

imgui\backends\imgui_impl_vulkan.h

```cpp
void ImGui_ImplVulkan_SwitchToDefaultPipeline(VkCommandBuffer command_buffer);
void ImGui_ImplVulkan_SwitchToNoColorBlendPipeline(VkCommandBuffer command_buffer);
```

src\3rdparty\imgui\backends\imgui_impl_vulkan.cpp

```cpp
bool ImGui_ImplVulkan_CreateDeviceObjects()
{
    ...

    ImGui_ImplVulkan_CreatePipeline(v->Device, v->Allocator, v->PipelineCache, v->RenderPass, v->MSAASamples, &bd->Pipeline, v->Subpass);
    ImGui_ImplVulkan_CreatePipelineNoColorBlend(v->Device, v->Allocator, v->PipelineCache, v->RenderPass, v->MSAASamples, &bd->PipelineNoColorBlend, v->Subpass);

    return true;
}

static void ImGui_ImplVulkan_CreatePipelineNoColorBlend(VkDevice device, const VkAllocationCallbacks* allocator, VkPipelineCache pipelineCache, VkRenderPass renderPass, VkSampleCountFlagBits MSAASamples, VkPipeline* pipeline, uint32_t subpass)
{
    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();
    ImGui_ImplVulkan_CreateShaderModules(device, allocator);

    VkPipelineShaderStageCreateInfo stage[2] = {};
    stage[0].sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
    stage[0].stage = VK_SHADER_STAGE_VERTEX_BIT;
    stage[0].module = bd->ShaderModuleVert;
    stage[0].pName = "main";
    stage[1].sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
    stage[1].stage = VK_SHADER_STAGE_FRAGMENT_BIT;
    stage[1].module = bd->ShaderModuleFrag;
    stage[1].pName = "main";

    VkVertexInputBindingDescription binding_desc[1] = {};
    binding_desc[0].stride = sizeof(ImDrawVert);
    binding_desc[0].inputRate = VK_VERTEX_INPUT_RATE_VERTEX;

    VkVertexInputAttributeDescription attribute_desc[3] = {};
    attribute_desc[0].location = 0;
    attribute_desc[0].binding = binding_desc[0].binding;
    attribute_desc[0].format = VK_FORMAT_R32G32_SFLOAT;
    attribute_desc[0].offset = offsetof(ImDrawVert, pos);
    attribute_desc[1].location = 1;
    attribute_desc[1].binding = binding_desc[0].binding;
    attribute_desc[1].format = VK_FORMAT_R32G32_SFLOAT;
    attribute_desc[1].offset = offsetof(ImDrawVert, uv);
    attribute_desc[2].location = 2;
    attribute_desc[2].binding = binding_desc[0].binding;
    attribute_desc[2].format = VK_FORMAT_R8G8B8A8_UNORM;
    attribute_desc[2].offset = offsetof(ImDrawVert, col);

    VkPipelineVertexInputStateCreateInfo vertex_info = {};
    vertex_info.sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
    vertex_info.vertexBindingDescriptionCount = 1;
    vertex_info.pVertexBindingDescriptions = binding_desc;
    vertex_info.vertexAttributeDescriptionCount = 3;
    vertex_info.pVertexAttributeDescriptions = attribute_desc;

    VkPipelineInputAssemblyStateCreateInfo ia_info = {};
    ia_info.sType = VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
    ia_info.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;

    VkPipelineViewportStateCreateInfo viewport_info = {};
    viewport_info.sType = VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO;
    viewport_info.viewportCount = 1;
    viewport_info.scissorCount = 1;

    VkPipelineRasterizationStateCreateInfo raster_info = {};
    raster_info.sType = VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
    raster_info.polygonMode = VK_POLYGON_MODE_FILL;
    raster_info.cullMode = VK_CULL_MODE_NONE;
    raster_info.frontFace = VK_FRONT_FACE_COUNTER_CLOCKWISE;
    raster_info.lineWidth = 1.0f;

    VkPipelineMultisampleStateCreateInfo ms_info = {};
    ms_info.sType = VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
    ms_info.rasterizationSamples = (MSAASamples != 0) ? MSAASamples : VK_SAMPLE_COUNT_1_BIT;

    VkPipelineColorBlendAttachmentState color_attachment[1] = {};
    color_attachment[0].blendEnable = VK_FALSE;
    color_attachment[0].srcColorBlendFactor = VK_BLEND_FACTOR_SRC_ALPHA;
    color_attachment[0].dstColorBlendFactor = VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;
    color_attachment[0].colorBlendOp = VK_BLEND_OP_ADD;
    color_attachment[0].srcAlphaBlendFactor = VK_BLEND_FACTOR_ONE;
    color_attachment[0].dstAlphaBlendFactor = VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;
    color_attachment[0].alphaBlendOp = VK_BLEND_OP_ADD;
    color_attachment[0].colorWriteMask = VK_COLOR_COMPONENT_R_BIT | VK_COLOR_COMPONENT_G_BIT | VK_COLOR_COMPONENT_B_BIT | VK_COLOR_COMPONENT_A_BIT;

    VkPipelineDepthStencilStateCreateInfo depth_info = {};
    depth_info.sType = VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO;

    VkPipelineColorBlendStateCreateInfo blend_info = {};
    blend_info.sType = VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
    blend_info.attachmentCount = 1;
    blend_info.pAttachments = color_attachment;

    VkDynamicState dynamic_states[2] = { VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR };
    VkPipelineDynamicStateCreateInfo dynamic_state = {};
    dynamic_state.sType = VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO;
    dynamic_state.dynamicStateCount = (uint32_t)IM_ARRAYSIZE(dynamic_states);
    dynamic_state.pDynamicStates = dynamic_states;

    VkGraphicsPipelineCreateInfo info = {};
    info.sType = VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
    info.flags = bd->PipelineCreateFlags;
    info.stageCount = 2;
    info.pStages = stage;
    info.pVertexInputState = &vertex_info;
    info.pInputAssemblyState = &ia_info;
    info.pViewportState = &viewport_info;
    info.pRasterizationState = &raster_info;
    info.pMultisampleState = &ms_info;
    info.pDepthStencilState = &depth_info;
    info.pColorBlendState = &blend_info;
    info.pDynamicState = &dynamic_state;
    info.layout = bd->PipelineLayout;
    info.renderPass = renderPass;
    info.subpass = subpass;

#ifdef IMGUI_IMPL_VULKAN_HAS_DYNAMIC_RENDERING
    if (bd->VulkanInitInfo.UseDynamicRendering)
    {
        IM_ASSERT(bd->VulkanInitInfo.PipelineRenderingCreateInfo.sType == VK_STRUCTURE_TYPE_PIPELINE_RENDERING_CREATE_INFO_KHR && "PipelineRenderingCreateInfo sType must be VK_STRUCTURE_TYPE_PIPELINE_RENDERING_CREATE_INFO_KHR");
        IM_ASSERT(bd->VulkanInitInfo.PipelineRenderingCreateInfo.pNext == nullptr && "PipelineRenderingCreateInfo pNext must be nullptr");
        info.pNext = &bd->VulkanInitInfo.PipelineRenderingCreateInfo;
        info.renderPass = VK_NULL_HANDLE; // Just make sure it's actually nullptr.
    }
#endif

    VkResult err = vkCreateGraphicsPipelines(device, pipelineCache, 1, &info, allocator, pipeline);
    check_vk_result(err);
}

void ImGui_ImplVulkan_SwitchToDefaultPipeline(VkCommandBuffer command_buffer)
{
    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();

    if(!bd)
    {
        //std::cerr << "ImGui_ImplVulkan_Data is nullptr!" << std::endl;
        return;
    }

    if(command_buffer == VK_NULL_HANDLE)
    {
        //std::cerr << "command_buffer is VK_NULL_HANDLE!" << std::endl;
        return;
    }

    if(bd->Pipeline == VK_NULL_HANDLE)
    {
        //std::cerr << "bd->Pipeline is VK_NULL_HANDLE!" << std::endl;
        return;
    }

    vkCmdBindPipeline(command_buffer, VK_PIPELINE_BIND_POINT_GRAPHICS, bd->Pipeline);
}

void ImGui_ImplVulkan_SwitchToNoColorBlendPipeline(VkCommandBuffer command_buffer)
{
    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();

    if(!bd)
    {
        //std::cerr << "ImGui_ImplVulkan_Data is nullptr!" << std::endl;
        return;
    }

    if(command_buffer == VK_NULL_HANDLE)
    {
        //std::cerr << "command_buffer is VK_NULL_HANDLE!" << std::endl;
        return;
    }

    if(bd->PipelineNoColorBlend == VK_NULL_HANDLE)
    {
        //std::cerr << "bd->PipelineNoColorBlend is VK_NULL_HANDLE!" << std::endl;
        return;
    }

    vkCmdBindPipeline(command_buffer, VK_PIPELINE_BIND_POINT_GRAPHICS, bd->PipelineNoColorBlend);
}
```

应用中这样用

```cpp
ImDrawList* draw_list = ImGui::GetWindowDrawList();
VkCommandBuffer command_buffer_raw = *command_buffer;
draw_list->AddCallback([](const ImDrawList* parent_list, const ImDrawCmd* cmd) {
    VkCommandBuffer* command_buffer_ptr = static_cast<VkCommandBuffer*>(cmd->UserCallbackData);
    if (command_buffer_ptr)
    {
        ImGui_ImplVulkan_SwitchToNoColorBlendPipeline(*command_buffer_ptr);
    }
}, &command_buffer_raw);
```

这样在实际绑定的时候 `vkCmdBindPipeline(command_buffer, VK_PIPELINE_BIND_POINT_GRAPHICS, bd->PipelineNoColorBlend);` 报访问空指针的错

因为其他量都没有变，所以 `bd` 肯定是没有错的，于是肯定是我的 command buffer 出错了，于是我改成这样就不会报错

```cpp
ImDrawList* draw_list = ImGui::GetWindowDrawList();
draw_list->AddCallback(
    [](const ImDrawList* parent_list, const ImDrawCmd* cmd) {
        vk::raii::CommandBuffer* command_buffer_ptr =
            static_cast<vk::raii::CommandBuffer*>(cmd->UserCallbackData);
        if (command_buffer_ptr)
        {
            ImGui_ImplVulkan_SwitchToNoColorBlendPipeline(**command_buffer_ptr);
        }
    },
    reinterpret_cast<void*>(const_cast<vk::raii::CommandBuffer*>(&command_buffer)));
```

于是最终完整使用方法是

```cpp
ImDrawList* draw_list = ImGui::GetWindowDrawList();
draw_list->AddCallback(
    [](const ImDrawList* parent_list, const ImDrawCmd* cmd) {
        vk::raii::CommandBuffer* command_buffer_ptr =
            static_cast<vk::raii::CommandBuffer*>(cmd->UserCallbackData);
        if (command_buffer_ptr)
        {
            ImGui_ImplVulkan_SwitchToNoColorBlendPipeline(**command_buffer_ptr);
        }
    },
    reinterpret_cast<void*>(const_cast<vk::raii::CommandBuffer*>(&command_buffer)));
ImGui::Image((ImTextureID)m_offscreen_image_desc, image_size);
draw_list->AddCallback(
    [](const ImDrawList* parent_list, const ImDrawCmd* cmd) {
        vk::raii::CommandBuffer* command_buffer_ptr =
            static_cast<vk::raii::CommandBuffer*>(cmd->UserCallbackData);
        if (command_buffer_ptr)
        {
            ImGui_ImplVulkan_SwitchToDefaultPipeline(**command_buffer_ptr);
        }
    },
    reinterpret_cast<void*>(const_cast<vk::raii::CommandBuffer*>(&command_buffer)));
```