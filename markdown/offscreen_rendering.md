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

## 改造

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
