# 离屏渲染

## Command pool

不知道为什么，我之间抄了 vkguide 的一个 upload context，这里面就是单独一个 context 装 command pool

但是我 per frame data 里面已经有了，我就不知道他们怎么协调

果然还是统一用 per frame data 先吧

## 离屏渲染

### 之前的尝试

之前以为是不使用交换链，只是用 attachment 来代替交换链

```cpp
    OffscreenForwardPass::OffscreenForwardPass(vk::raii::PhysicalDevice const& physical_device,
                                               vk::raii::Device const&         device,
                                               SurfaceData&                    surface_data,
                                               vk::raii::CommandPool const&    command_pool,
                                               vk::raii::Queue const&          queue,
                                               DescriptorAllocatorGrowable&    m_descriptor_allocator)
        : RenderPass(device)
    {
        m_pass_name = "Offscreen Forward Pass";

        // Create a set to store all information of attachments

        vk::Format color_format =
            PickSurfaceFormat((physical_device).getSurfaceFormatsKHR(*surface_data.surface)).format;
        assert(color_format != vk::Format::eUndefined);

        std::vector<vk::AttachmentDescription> attachment_descriptions;
        // color attachment
        attachment_descriptions.emplace_back(vk::AttachmentDescriptionFlags(),          /* flags */
                                             color_format,                              /* format */
                                             m_sample_count,                            /* samples */
                                             vk::AttachmentLoadOp::eClear,              /* loadOp */
                                             vk::AttachmentStoreOp::eStore,             /* storeOp */
                                             vk::AttachmentLoadOp::eDontCare,           /* stencilLoadOp */
                                             vk::AttachmentStoreOp::eDontCare,          /* stencilStoreOp */
                                             vk::ImageLayout::eUndefined,               /* initialLayout */
                                             vk::ImageLayout::eColorAttachmentOptimal); /* finalLayout */
        // depth attachment
        attachment_descriptions.emplace_back(vk::AttachmentDescriptionFlags(),                 /* flags */
                                             m_depth_format,                                   /* format */
                                             m_sample_count,                                   /* samples */
                                             vk::AttachmentLoadOp::eClear,                     /* loadOp */
                                             vk::AttachmentStoreOp::eStore,                    /* storeOp */
                                             vk::AttachmentLoadOp::eClear,                     /* stencilLoadOp */
                                             vk::AttachmentStoreOp::eStore,                    /* stencilStoreOp */
                                             vk::ImageLayout::eUndefined,                      /* initialLayout */
                                             vk::ImageLayout::eDepthStencilAttachmentOptimal); /* finalLayout */

        // Create reference to attachment information set

        vk::AttachmentReference color_attachment_reference(0, vk::ImageLayout::eColorAttachmentOptimal);
        vk::AttachmentReference depth_attachment_reference(1, vk::ImageLayout::eDepthStencilAttachmentOptimal);

        // Create subpass

        std::vector<vk::SubpassDescription> subpass_descriptions;
        // obj2attachment pass
        subpass_descriptions.push_back(vk::SubpassDescription(vk::SubpassDescriptionFlags(),    /* flags */
                                                              vk::PipelineBindPoint::eGraphics, /* pipelineBindPoint */
                                                              {},                               /* pInputAttachments */
                                                              color_attachment_reference,       /* pColorAttachments */
                                                              {},                          /* pResolveAttachments */
                                                              &depth_attachment_reference, /* pDepthStencilAttachment */
                                                              nullptr));                   /* pPreserveAttachments */

        // Create subpass dependency

        std::vector<vk::SubpassDependency> dependencies;
        // externel -> forward pass
        dependencies.emplace_back(VK_SUBPASS_EXTERNAL,                               /* srcSubpass */
                                  0,                                                 /* dstSubpass */
                                  vk::PipelineStageFlagBits::eBottomOfPipe,          /* srcStageMask */
                                  vk::PipelineStageFlagBits::eColorAttachmentOutput, /* dstStageMask */
                                  vk::AccessFlagBits::eMemoryRead,                   /* srcAccessMask */
                                  vk::AccessFlagBits::eColorAttachmentWrite |
                                      vk::AccessFlagBits::eColorAttachmentRead, /* dstAccessMask */
                                  vk::DependencyFlagBits::eByRegion);           /* dependencyFlags */
        // forward -> externel
        dependencies.emplace_back(0,                                                 /* srcSubpass */
                                  VK_SUBPASS_EXTERNAL,                               /* dstSubpass */
                                  vk::PipelineStageFlagBits::eColorAttachmentOutput, /* srcStageMask */
                                  vk::PipelineStageFlagBits::eBottomOfPipe,          /* dstStageMask */
                                  vk::AccessFlagBits::eColorAttachmentWrite |
                                      vk::AccessFlagBits::eColorAttachmentRead, /* srcAccessMask */
                                  vk::AccessFlagBits::eMemoryRead,              /* dstAccessMask */
                                  vk::DependencyFlagBits::eByRegion);           /* dependencyFlags */

        // Create render pass
        vk::RenderPassCreateInfo render_pass_create_info(vk::RenderPassCreateFlags(), /* flags */
                                                         attachment_descriptions,     /* pAttachments */
                                                         subpass_descriptions,        /* pSubpasses */
                                                         dependencies);               /* pDependencies */

        render_pass = vk::raii::RenderPass(device, render_pass_create_info);

        // Create Material

        std::shared_ptr<Shader> mesh_shader_ptr = std::make_shared<Shader>(physical_device,
                                                                           device,
                                                                           m_descriptor_allocator,
                                                                           "builtin/shaders/mesh.vert.spv",
                                                                           "builtin/shaders/mesh.frag.spv");

        m_forward_mat = Material(physical_device, device, mesh_shader_ptr);
        m_forward_mat.CreatePipeline(device, render_pass, vk::FrontFace::eClockwise, true);

        input_vertex_attributes = m_forward_mat.shader_ptr->per_vertex_attributes;

        m_render_stat.vertex_attribute_metas = m_forward_mat.shader_ptr->vertex_attribute_metas;
        m_render_stat.buffer_meta_map        = m_forward_mat.shader_ptr->buffer_meta_map;
        m_render_stat.image_meta_map         = m_forward_mat.shader_ptr->image_meta_map;

        clear_values.resize(2);
        clear_values[0].color        = vk::ClearColorValue(0.2f, 0.2f, 0.2f, 0.2f);
        clear_values[1].depthStencil = vk::ClearDepthStencilValue(1.0f, 0);

        // Debug

        VkQueryPoolCreateInfo query_pool_create_info = {.sType              = VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO,
                                                        .queryType          = VK_QUERY_TYPE_PIPELINE_STATISTICS,
                                                        .queryCount         = 1,
                                                        .pipelineStatistics = (1 << 11) - 1};

        query_pool = device.createQueryPool(query_pool_create_info, nullptr);
    }

    void OffscreenForwardPass::RefreshFrameBuffers(vk::raii::PhysicalDevice const&         physical_device,
                                                   vk::raii::Device const&                 device,
                                                   vk::raii::CommandBuffer const&          command_buffer,
                                                   SurfaceData&                            surface_data,
                                                   std::vector<vk::raii::ImageView> const& swapchain_image_views,
                                                   vk::Extent2D const&                     extent)
    {
        // clear

        framebuffers.clear();

        m_color_attachments.clear();
        m_depth_attachment = nullptr;

        // Create attachment

        vk::Format color_format =
            PickSurfaceFormat((physical_device).getSurfaceFormatsKHR(*surface_data.surface)).format;

        m_color_attachments.reserve(g_runtime_global_context.render_system->GetMaxFrames());
        for (uint32_t i = 0; i < g_runtime_global_context.render_system->GetMaxFrames(); i++)
        {
            m_color_attachments.push_back(ImageData::CreateAttachment(physical_device,
                                                                      device,
                                                                      command_buffer,
                                                                      color_format,
                                                                      extent,
                                                                      vk::ImageUsageFlagBits::eColorAttachment |
                                                                          vk::ImageUsageFlagBits::eInputAttachment,
                                                                      vk::ImageAspectFlagBits::eColor,
                                                                      {},
                                                                      false));
        }

        m_depth_attachment = ImageData::CreateAttachment(physical_device,
                                                         device,
                                                         command_buffer,
                                                         m_depth_format,
                                                         extent,
                                                         vk::ImageUsageFlagBits::eDepthStencilAttachment,
                                                         vk::ImageAspectFlagBits::eDepth,
                                                         {},
                                                         false);

        // Provide attachment information to frame buffer

        vk::ImageView attachments[2];
        attachments[1] = *m_depth_attachment->image_view;

        vk::FramebufferCreateInfo framebuffer_create_info(vk::FramebufferCreateFlags(), /* flags */
                                                          *render_pass,                 /* renderPass */
                                                          2,                            /* attachmentCount */
                                                          attachments,                  /* pAttachments */
                                                          extent.width,                 /* width */
                                                          extent.height,                /* height */
                                                          1);                           /* layers */

        framebuffers.reserve(swapchain_image_views.size());
        for (auto const& imageView : swapchain_image_views)
        {
            attachments[0] = *imageView;
            framebuffers.push_back(vk::raii::Framebuffer(device, framebuffer_create_info));
        }
    }
```

之后看了不是的

### easy vulkan

感觉这个讲得很详细

[https://easyvulkan.github.io/Ch8-1%20%E7%A6%BB%E5%B1%8F%E6%B8%B2%E6%9F%93.html](https://easyvulkan.github.io/Ch8-1%20%E7%A6%BB%E5%B1%8F%E6%B8%B2%E6%9F%93.html)

我大概的理解就是交换链是用来呈现图像的，所以如果要离屏渲染的话，传入的 color attachment 就不能是交换链图像

然后遇到一个问题是，在有交换链的时候，是先从交换链请求可用的图像的编号，顺便启动以一个 semaphore 的

easyvulkan 里面的代码是

```cpp
graphicsBase::Base().SwapImage(semaphore_imageIsAvailable);
auto i = graphicsBase::Base().CurrentImageIndex();
commandBuffer.Begin(VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT);
```

但是他是希望用来之后还是在交换链图像上面画

```cpp
graphicsBase::Base().SwapImage(semaphore_imageIsAvailable);
auto i = graphicsBase::Base().CurrentImageIndex();

commandBuffer.Begin(VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT);

if (clearCanvas)
    easyVulkan::CmdClearCanvas(commandBuffer, VkClearColorValue{}),
    clearCanvas = false;

//Offscreen
renderPass_offscreen.CmdBegin(commandBuffer, framebuffer_offscreen, { {}, canvasSize });
vkCmdBindPipeline(commandBuffer, VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline_line);
vkCmdPushConstants(commandBuffer, pipelineLayout_line, VK_SHADER_STAGE_VERTEX_BIT, 0, 24, &pushConstants_offscreen);
vkCmdDraw(commandBuffer, 2, 1, 0, 0);
renderPass_offscreen.CmdEnd(commandBuffer);

//Screen
renderPass_screen.CmdBegin(commandBuffer, framebuffers_screen[i], { {}, windowSize }, VkClearValue{ .color = { 1.f, 1.f, 1.f, 1.f } });
vkCmdBindPipeline(commandBuffer, VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline_screen);
glm::vec2 windowSize = { ::windowSize.width, ::windowSize.height };
vkCmdPushConstants(commandBuffer, pipelineLayout_screen, VK_SHADER_STAGE_VERTEX_BIT, 0, 8, &windowSize);
vkCmdPushConstants(commandBuffer, pipelineLayout_screen, VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_FRAGMENT_BIT, 8, 8, &pushConstants_offscreen.viewportSize);
vkCmdBindDescriptorSets(commandBuffer, VK_PIPELINE_BIND_POINT_GRAPHICS, pipelineLayout_screen, 0, 1, descriptorSet_texture.Address(), 0, nullptr);
vkCmdDraw(commandBuffer, 4, 1, 0, 0);
renderPass_screen.CmdEnd(commandBuffer);

commandBuffer.End();

graphicsBase::Base().SubmitCommandBuffer_Graphics(commandBuffer, semaphore_imageIsAvailable, semaphore_renderingIsOver, fence);
graphicsBase::Base().PresentImage(semaphore_renderingIsOver);
```

所以我感觉似乎并不是完全是我想做的

### 使用 imgui 的交换链

一个窗口关联的交换链中，只能有一个是有效的

[https://computergraphics.stackexchange.com/questions/8909/multiple-swapchains-in-vulkan-app-with-imgui](https://computergraphics.stackexchange.com/questions/8909/multiple-swapchains-in-vulkan-app-with-imgui)

于是如果我不想自己创建窗口的话，那么就应该让 imgui 创建窗口，我是这么理解的

然后 fork 了别人的现成的渲染到 imgui 的代码 [https://github.com/CheapMeow/ImGuiVulkanHppImage](https://github.com/CheapMeow/ImGuiVulkanHppImage)

仔细一看，发现里面有很多 imgui impl 的东西

就感觉……他这个似乎是从 imgui 官方示例改过来的

于是对比了 imgui 的官方示例

确实……就是 imgui 官方示例

编译了之后，可以看到主窗口是没有东西的，然后有 imgui 的控件

这是很合理的

但是 imgui 的示例里面没有详细讲 pipeline 相关的，我觉得

应该是因为 imgui 内部本来就有自己的 pipeline

于是还是去看 ImGuiVulkanHppImage

他这里得到的是 resolved 之后的 image view 也就是渲染出来的图像

```cpp
if (Windows.Scene.Visible) {
    PushStyleVar(ImGuiStyleVar_WindowPadding, {0, 0});
    Begin(Windows.Scene.Name, &Windows.Scene.Visible);
    const auto content_region = GetContentRegionAvail();
    if (MainScene->Render(content_region.x, content_region.y, ImVec4ToClearColor(GetStyleColorVec4(ImGuiCol_WindowBg)))) {
        ImGui_ImplVulkan_RemoveTexture(MainSceneDescriptorSet);
        MainSceneDescriptorSet = ImGui_ImplVulkan_AddTexture(MainScene->TC.TextureSampler.get(), MainScene->TC.ResolveImageView.get(), VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);
    }

    Image((ImTextureID)MainSceneDescriptorSet, ImGui::GetContentRegionAvail());
    End();
    PopStyleVar();
}
```

到他这个 `Scene::Scene(const VulkanContext &vc)` 看，就可以看到他这个 resolve 在 pipeline 中的应用

所以是时候该自己试试了

## 最佳实践检查

我才发现原来有检查最佳实践的东西

[https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/main/docs/best_practices.md](https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/main/docs/best_practices.md)

## 离屏渲染开发

报错是 vulkan instance 为空？

```cpp
    RenderSystem::RenderSystem()
    {
        CreateVulkanInstance();

        std::cout << "Testing" << std::endl;
        std::cout << &m_vulkan_instance << std::endl;

        g_runtime_global_context.window_system->AddWindow(std::make_shared<RuntimeWindow>(0));

```

```cpp
    void RuntimeWindow::CreateSurface()
    {
        const vk::raii::Instance& vulkan_instance = g_runtime_global_context.render_system->GetInstance();

        std::cout << "RuntimeWindow::CreateSurface()" << std::endl;
        std::cout << &vulkan_instance << std::endl;

        auto         size = GetSize();
        vk::Extent2D extent(size.x, size.y);
        m_surface_data = SurfaceData(vulkan_instance, GetGLFWWindow(), extent);
    }
```

输出

```
Testing
0x1ebb98ee840
RuntimeWindow::CreateSurface()
0x40
```

好吧，于是发现 RenderSystem 是空

于是懂了……我是在 RenderSystem 构造函数里面还去获取 RenderSystem 实例，这个时候 RenderSystem 还没创建完成呢

于是把事情挪到 Start 里面就好了

## 不用 imgui 的结构

别人是，渲染场景就是用自己的 `render pass`

离屏渲染的纹理作为 `framebuffer`

发现这个最终 `RefreshFrameBuffers` 的纹理我是默认 `swapchain` 传入

或许需要改一下

然后看到 `ImGuiVulkanHppImage` 里面的 `FrameRender` 都是直接用 `wd` 的 `swapchain` 和 `framebuffer`

我在想要不要跟着他的做……

不过最后觉得还是一样的

比如我一开始还是这样写

```cpp
    void EditorWindow::CreateSwapChian()
    {
        const vk::raii::Instance&       vulkan_instance = g_runtime_context.render_system->GetInstance();
        const vk::raii::PhysicalDevice& physical_device = g_runtime_context.render_system->GetPhysicalDevice();
        const vk::raii::Device&         logical_device  = g_runtime_context.render_system->GetLogicalDevice();
        const uint32_t graphics_queue_family_index = g_runtime_context.render_system->GetGraphicsQueueFamiliyIndex();

        m_igmui_window.Surface = *m_surface_data.surface;

        m_igmui_window.SurfaceFormat = PickSurfaceFormat(physical_device.getSurfaceFormatsKHR(*m_surface_data.surface));
        m_igmui_window.PresentMode   = static_cast<VkPresentModeKHR>(
            PickPresentMode(physical_device.getSurfacePresentModesKHR(*m_surface_data.surface)));

        ImGui_ImplVulkanH_CreateOrResizeWindow(**vulkan_instance,
                                               **physical_device,
                                               **logical_device,
                                               &m_igmui_window,
                                               graphics_queue_family_index,
                                               nullptr,
                                               m_surface_data.extent.width m_surface_data.extent.height,
                                               k_max_frames_in_flight);
    }
```

这样 `ImGui_ImplVulkanH_CreateOrResizeWindow` 会不会有什么特别的……

进去看确实没有什么特别的

那么唯一能够导致不同的确实就是， editor pass 不用 swapchain image 而是 imgui pass 来用 swapchain 

于是还是需要重来

## 改造 render pass

传入 render pass 的用来制作 framebuffer 的 image

之前是固定死 swapchain

现在改成也可以传入任意的 image

这样就方便我传入离屏渲染的 image

vulkan 离屏渲染的纹理应该不需要准备跟 swapchain 一样的份数

我先试试只用一个

那么这就有一个问题

之前的 render pass 都是因为 swapchain image 有多张，所以创建了多个 framebuffer

那么现在离屏渲染的纹理只有一个

离屏渲染的的 framebuffer 还需要多个吗？

不需要了

但是我又不想改现在的结构

于是给现在的前向或者后向的 render pass 的 current_image_index 设为 0 就好了

原来在 windows 里面是

```cpp
        m_render_pass_ptr->Start(cmd_buffer, m_surface_data, m_current_image_index);
        m_render_pass_ptr->Draw(cmd_buffer);
        m_render_pass_ptr->End(cmd_buffer);
```

改为

```cpp
        m_render_pass_ptr->Start(cmd_buffer, m_surface_data, 0);
        m_render_pass_ptr->Draw(cmd_buffer);
        m_render_pass_ptr->End(cmd_buffer);
```

## imgui vulkan info

```cpp
// Register a texture
// FIXME: This is experimental in the sense that we are unsure how to best design/tackle this problem, please post to https://github.com/ocornut/imgui/pull/914 if you have suggestions.
VkDescriptorSet ImGui_ImplVulkan_AddTexture(VkSampler sampler, VkImageView image_view, VkImageLayout image_layout)
{
    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();
    ImGui_ImplVulkan_InitInfo* v = &bd->VulkanInitInfo;

    // Create Descriptor Set:
    VkDescriptorSet descriptor_set;
    {
        VkDescriptorSetAllocateInfo alloc_info = {};
        alloc_info.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
        alloc_info.descriptorPool = v->DescriptorPool;
        alloc_info.descriptorSetCount = 1;
        alloc_info.pSetLayouts = &bd->DescriptorSetLayout;
        VkResult err = vkAllocateDescriptorSets(v->Device, &alloc_info, &descriptor_set);
        check_vk_result(err);
    }
```

这里报错 v 是 null

是我 `ImGui_ImplVulkan_Init` 的时机的问题

我想要所有东西都创建完了之后再 `ImGui_ImplVulkan_Init`

但是在这之前我还想调用 `ImGui_ImplVulkan_AddTexture` 就出错了

于是用一种肮脏的方法来实现……用一个 bool 表示什么时候是可以调用 `ImGui_ImplVulkan_AddTexture` 的

## render target

我创建的 input attachment 居然是默认没有 sampler 的

哦……于是看到了

我创建 attachment 和 texture 的策略是不一样的

attachment 是纯粹用于渲染的输入输出的

texture 是可以纹理映射的

于是现在我缺少一个两者都有的东西

于是这就是 render target 了

## vulkan validation error: invalid imageLayout VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
 
```
[MeowEngine][2024-11-11 19:57:41] Error: { Validation }:
	messageIDName   = <VUID-VkWriteDescriptorSet-descriptorType-04150>
	messageIdNumber = -148208968
	message         = <Validation Error: [ VUID-VkWriteDescriptorSet-descriptorType-04150 ] Object 0: handle = 0xe7e6d0000000000f, type = VK_OBJECT_TYPE_IMAGE_VIEW; Object 1: handle = 0xcad092000000000d, type = VK_OBJECT_TYPE_IMAGE; | MessageID = 0xf72a82b8 | vkUpdateDescriptorSets(): pDescriptorWrites[0].pImageInfo[0] Descriptor update with descriptorType VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER is being updated with invalid imageLayout VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL for image VkImage 0xcad092000000000d[] in imageView VkImageView 0xe7e6d0000000000f[]. Allowed layouts are: VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, VK_IMAGE_LAYOUT_GENERAL, VK_IMAGE_LAYOUT_DEPTH_READ_ONLY_STENCIL_ATTACHMENT_OPTIMAL, VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_STENCIL_READ_ONLY_OPTIMAL, VK_IMAGE_LAYOUT_READ_ONLY_OPTIMAL, VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL, VK_IMAGE_LAYOUT_DEPTH_READ_ONLY_OPTIMAL, VK_IMAGE_LAYOUT_STENCIL_READ_ONLY_OPTIMAL. The Vulkan spec states: If descriptorType is VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER the imageLayout member of each element of pImageInfo must be a member of the list given in Combined Image Sampler (https://vulkan.lunarg.com/doc/view/1.3.290.0/windows/1.3-extensions/vkspec.html#VUID-VkWriteDescriptorSet-descriptorType-04150)>
	Objects:
		Object 0
			objectType   = ImageView
			objectHandle = 16710272165823381519
		Object 1
			objectType   = Image
			objectHandle = 14614341319514914829

```

图像格式的问题

创建 image 的时候可以改图像格式

render pass 内部也会改图像格式

deferred pass 里面把图像输出格式改成 `eShaderReadOnlyOptimal` 就好了

## vulkan validation error: pAttachments[0] format is VK_FORMAT_B8G8R8A8_UNORM but initialLayout is VK_IMAGE_LAYOUT_UNDEFINED

```
[MeowEngine][2024-11-11 20:06:24] Error: { Validation }:
	messageIDName   = <VUID-VkAttachmentDescription-format-06699>
	messageIdNumber = 1387471518
	message         = <Validation Error: [ VUID-VkAttachmentDescription-format-06699 ] | MessageID = 0x52b3229e | vkCreateRenderPass(): pCreateInfo->pAttachments[0] format is VK_FORMAT_B8G8R8A8_UNORM and loadOp is VK_ATTACHMENT_LOAD_OP_LOAD, but initialLayout is VK_IMAGE_LAYOUT_UNDEFINED. The Vulkan spec states: If format includes a color or depth component and loadOp is VK_ATTACHMENT_LOAD_OP_LOAD, then initialLayout must not be VK_IMAGE_LAYOUT_UNDEFINED (https://vulkan.lunarg.com/doc/view/1.3.290.0/windows/1.3-extensions/vkspec.html#VUID-VkAttachmentDescription-format-06699)>

```

是 imgui pass 的问题

```cpp
    ImGuiPass::ImGuiPass(const vk::raii::PhysicalDevice& physical_device,
                         const vk::raii::Device&         device,
                         SurfaceData&                    surface_data,
                         const vk::raii::CommandPool&    command_pool,
                         const vk::raii::Queue&          queue,
                         DescriptorAllocatorGrowable&    m_descriptor_allocator)
        : RenderPass(device)
    {
        m_pass_name = "ImGui Pass";

        vk::Format color_format =
            PickSurfaceFormat((physical_device).getSurfaceFormatsKHR(*surface_data.surface)).format;
        assert(color_format != vk::Format::eUndefined);

        vk::AttachmentReference swapchain_attachment_reference(0, vk::ImageLayout::eColorAttachmentOptimal);

        // swap chain attachment
        vk::AttachmentDescription attachment_description(vk::AttachmentDescriptionFlags(), /* flags */
                                                         color_format,                     /* format */
                                                         vk::SampleCountFlagBits::e1,      /* samples */
                                                         vk::AttachmentLoadOp::eLoad,      /* loadOp */
                                                         vk::AttachmentStoreOp::eStore,    /* storeOp */
                                                         vk::AttachmentLoadOp::eDontCare,  /* stencilLoadOp */
                                                         vk::AttachmentStoreOp::eDontCare, /* stencilStoreOp */
                                                         vk::ImageLayout::eUndefined,      /* initialLayout */
                                                         vk::ImageLayout::ePresentSrcKHR); /* finalLayout */
```

改成

```cpp
vk::AttachmentLoadOp::eClear,     /* loadOp */
```

## vulkan validation error: invalid imageLayout VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL 又出现

```
[MeowEngine][2024-11-11 20:21:18] Error: { Validation }:
	messageIDName   = <VUID-VkWriteDescriptorSet-descriptorType-04150>
	messageIdNumber = -148208968
	message         = <Validation Error: [ VUID-VkWriteDescriptorSet-descriptorType-04150 ] Object 0: handle = 0xe7e6d0000000000f, type = VK_OBJECT_TYPE_IMAGE_VIEW; Object 1: handle = 0xcad092000000000d, type = VK_OBJECT_TYPE_IMAGE; | MessageID = 0xf72a82b8 | vkUpdateDescriptorSets(): pDescriptorWrites[0].pImageInfo[0] Descriptor update with descriptorType VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER is being updated with invalid imageLayout VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL for image VkImage 0xcad092000000000d[] in imageView VkImageView 0xe7e6d0000000000f[]. Allowed layouts are: VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, VK_IMAGE_LAYOUT_GENERAL, VK_IMAGE_LAYOUT_DEPTH_READ_ONLY_STENCIL_ATTACHMENT_OPTIMAL, VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_STENCIL_READ_ONLY_OPTIMAL, VK_IMAGE_LAYOUT_READ_ONLY_OPTIMAL, VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL, VK_IMAGE_LAYOUT_DEPTH_READ_ONLY_OPTIMAL, VK_IMAGE_LAYOUT_STENCIL_READ_ONLY_OPTIMAL. The Vulkan spec states: If descriptorType is VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER the imageLayout member of each element of pImageInfo must be a member of the list given in Combined Image Sampler (https://vulkan.lunarg.com/doc/view/1.3.290.0/windows/1.3-extensions/vkspec.html#VUID-VkWriteDescriptorSet-descriptorType-04150)>
	Objects:
		Object 0
			objectType   = ImageView
			objectHandle = 16710272165823381519
		Object 1
			objectType   = Image
			objectHandle = 14614341319514914829
```

好吧我如果依靠 render pass 来转换的话，那么就会导致一开始不满足要求，后面才满足要求

那么还不如一开始是 `VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL` 然后 deferred 里面为了第二个 pass 转成 `VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL` 然后第二个 pass结束时转成 `VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL`

但是现在发现 render pass 对图像格式的转换是根据整个 render pass 的，subpass 不处理这个

好吧

那我直接

```cpp
    EditorDeferredPass::EditorDeferredPass(const vk::raii::PhysicalDevice& physical_device,
                                           const vk::raii::Device&         device,
                                           SurfaceData&                    surface_data,
                                           const vk::raii::CommandPool&    command_pool,
                                           const vk::raii::Queue&          queue,
                                           DescriptorAllocatorGrowable&    m_descriptor_allocator)
        : RenderPass(device)
    {
        m_pass_name = "Deferred Pass";

        m_pass_names[0] = m_pass_name + " - Obj2Attachment Subpass";
        m_pass_names[1] = m_pass_name + " - Quad Subpass";

        // Create a set to store all information of attachments

        vk::Format color_format =
            PickSurfaceFormat((physical_device).getSurfaceFormatsKHR(*surface_data.surface)).format;
        assert(color_format != vk::Format::eUndefined);

        m_color_format = color_format;

        std::vector<vk::AttachmentDescription> attachment_descriptions;
        // swap chain attachment
        attachment_descriptions.emplace_back(vk::AttachmentDescriptionFlags(),         /* flags */
                                             color_format,                             /* format */
                                             m_sample_count,                           /* samples */
                                             vk::AttachmentLoadOp::eClear,             /* loadOp */
                                             vk::AttachmentStoreOp::eStore,            /* storeOp */
                                             vk::AttachmentLoadOp::eDontCare,          /* stencilLoadOp */
                                             vk::AttachmentStoreOp::eDontCare,         /* stencilStoreOp */
                                             vk::ImageLayout::eShaderReadOnlyOptimal,  /* initialLayout */
                                             vk::ImageLayout::eShaderReadOnlyOptimal); /* finalLayout */
```

并且 render target 构建的时候就

```cpp
        // Transit Layout
        OneTimeSubmit(device, command_pool, queue, [&](const vk::raii::CommandBuffer& command_buffer) {
            image_data_ptr->SetImageLayout(
                command_buffer, vk::ImageLayout::eUndefined, vk::ImageLayout::eShaderReadOnlyOptimal);
        });
```

这下似乎解决问题了

## vulkan validation error: extent

```
[MeowEngine][2024-11-11 20:41:28] Error: { Validation }:
	messageIDName   = <VUID-VkRenderPassBeginInfo-pNext-02852>
	messageIdNumber = -617851033
	message         = <Validation Error: [ VUID-VkRenderPassBeginInfo-pNext-02852 ] Object 0: handle = 0x27d60e0000000019, type = VK_OBJECT_TYPE_RENDER_PASS; Object 1: handle = 0x73a850000000004d, type = VK_OBJECT_TYPE_FRAMEBUFFER; | MessageID = 0xdb2c5767 | vkCmdBeginRenderPass(): pRenderPassBegin->renderArea offset.x (0) + extent.width (1080) is greater than framebuffer width (540). The Vulkan spec states: If the pNext chain does not contain VkDeviceGroupRenderPassBeginInfo or its deviceRenderAreaCount member is equal to 0, renderArea.offset.x + renderArea.extent.width must be less than or equal to VkFramebufferCreateInfo::width the framebuffer was created with (https://vulkan.lunarg.com/doc/view/1.3.290.0/windows/1.3-extensions/vkspec.html#VUID-VkRenderPassBeginInfo-pNext-02852)>
	Objects:
		Object 0
			objectType   = RenderPass
			objectHandle = 2870497205658058777
		Object 1
			objectType   = Framebuffer
			objectHandle = 8333999071379325005
```

是我 api 设计的问题

```cpp
    void RenderPass::Start(vk::raii::CommandBuffer const& command_buffer,
                           Meow::SurfaceData const&       surface_data,
                           uint32_t                       current_image_index)
    {
        FUNCTION_TIMER();

        vk::RenderPassBeginInfo render_pass_begin_info(*render_pass,
                                                       *framebuffers[current_image_index],
                                                       vk::Rect2D(vk::Offset2D(0, 0), surface_data.extent),
                                                       clear_values);
        command_buffer.beginRenderPass(render_pass_begin_info, vk::SubpassContents::eInline);
    }
```

`RenderPass` 的启动里面写死了是用 `surface_data` 的 extent

实际上应该可以任意 extent

## alpha 的问题

我的附件和交换链图像的颜色格式都是 `VK_FORMAT_R8G8B8A8_UNORM`

但是渲染出来的结果是，不渲染到 imgui 纹理的话就是正常的颜色，渲染的话就会变灰

于是发现似乎是因为我的渲染结果的 alpha 都是 0.2，然后 imgui 纹理的 alpha 都是 1

于是发现是我的 shader 里面写的有问题

```glsl
vec4 ambient  = vec4(0.20);
```

这个不对

## 编译 ImGuiVulkanHppImage

忘记之前是怎么编译的了

删掉 msvc 识别不了的选项

```cmake
target_compile_options(${PROJECT_NAME} PRIVATE -Wall)
```

使用 cstdint 提供的定义

```cpp
#include <cstdint>

#include "Log.h"

using uint = std::uint32_t;
```

然后是 Debug 和 Release 不匹配

```
aderc_combined.lib(shaderc.obj) : error LNK2038: 检测到“_ITERATOR_DEBUG_LEVEL”的不匹配项: 值“0”不匹配值“2”(Scene.obj 中) [E:\repositories\ImGuiVulkanHppImage\build-release\ImGuiVulkanHppImage.vcxproj]
shaderc_combined.lib(shaderc.obj) : error LNK2038: 检测到“RuntimeLibrary”的不匹配项: 值“MD_DynamicRelease”不匹配值“MDd_DynamicDebug”(Scene.obj 中) [E:\repositories\ImGuiVulkanHppImage\build-release\ImGuiVulkanHppImage.vcxproj]
shaderc_combined.lib(compiler.obj) : error LNK2038: 检测到“_ITERATOR_DEBUG_LEVEL”的不匹配项: 值“0”不匹配值“2”(Scene.obj 中) [E:\repositories\ImGuiVulkanHppImage\build-release\ImGuiVulkanHppImage.vcxproj]
shaderc_combined.lib(compiler.obj) : error LNK2038: 检测到“RuntimeLibrary”的不匹配项: 值“MD_DynamicRelease”不匹配值“MDd_DynamicDebug”(Scene.obj 中) [E:\repositories\ImGuiVulkanHppImage\build-release\ImGuiVulkanHppImage.vcxproj]
...
shaderc_combined.lib(loop_dependence_helpers.obj) : error LNK2038: 检测到“_ITERATOR_DEBUG_LEVEL”的不匹配项: 值“0”不匹配值“2”(Scene.obj 中) [E:\repositories\ImGuiVulkanHppImage\build-debug\ImGuiVulkanHppImage.vcxproj]
shaderc_combined.lib(loop_dependence_helpers.obj) : error LNK2038: 检测到“RuntimeLibrary”的不匹配项: 值“MD_DynamicRelease”不匹配值“MDd_DynamicDebug”(Scene.obj 中) [E:\repositories\ImGuiVulkanHppImage\build-debug\ImGuiVulkanHppImage.vcxproj]
LINK : warning LNK4098: 默认库“MSVCRT”与其他库的使用冲突；请使用 /NODEFAULTLIB:library [E:\repositories\ImGuiVulkanHppImage\build-debug\ImGuiVulkanHppImage.vcxproj]
E:\repositories\ImGuiVulkanHppImage\build-debug\Debug\ImGuiVulkanHppImage.exe : fatal error LNK1319: 检测到 466 个不匹配项 [E:\repositories\ImGuiVulkanHppImage\build-debug\ImGuiVulkanHppImage.vcxproj]
```

很神奇，构建配置不应该传递到第三方库吗

于是我设置 debug 构建还是有问题

好吧，那我不指定构建设置，还是有问题
