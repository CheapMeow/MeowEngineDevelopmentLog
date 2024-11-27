# Render Pass

## 信息依赖

更改渲染通道，例如做延迟渲染的时候，我需要某一个 pass 输出到三个纹理附件，然后下一个 pass 使用这三个纹理附件

那么 render pass 和 frame buffer 都需要更改

render pass 需要知道：

1.各个 subpass 总共要使用到的所有附件的信息

通过 `vk::AttachmentDescription` 存储

2.各个 subpass 对附件集合的引用。正如其名，是一个引用，或者说索引

通过 `vk::AttachmentReference` 存储

之后 subpass 就通过 `vk::AttachmentReference` 来知道，自己使用的是前面 `vk::AttachmentDescription` 中的第几个

3.每一个 subpass 是什么，每一个 subpass 使用的附件

通过 `vk::SubpassDescription` 存储

比如你是什么额外操作都没有，那么就只有一个单独的 subpass

但是比如延迟渲染的话，就需要两个 subpass，一个是输出颜色、法线、深度，一个是读取这些附件做着色

4.每个 subpass 之间的依赖关系

通过 `vk::SubpassDependency` 存储

比如延迟渲染的第二个 pass 需要依赖第一个 pass 的各个附件都输出完

5.最终汇总上面所有的信息，制作一个 render pass

通过 `vk::RenderPassCreateInfo` 存储

render pass 和 frame buffer 都需要知道附件信息

render pass 要知道的是附件的配置，而 frame buffer 要保存附件的 `vk::raii::ImageView` 引用

因为其实是 render pass 决定了附件的配置，所以 frame buffer 应该是 render pass 的数据成员

因为 frame buffer 要保存附件的 `vk::raii::ImageView` 引用，所以 `vk::raii::ImageView` 应该是 frame buffer 的成员

但是既然已经有 `vk::raii::Framebuffer` 了，那我觉得让 `vk::raii::Framebuffer` 和 `vk::raii::ImageView` 平级，都属于 render pass 也无所谓

## 多个 Render Pass 与单独一个 Render Pass 多个 subpass 之前的区别

如果 command 提交过程中你需要切换 framebufferview，则你需要一个新的 renderpass(vkBeginRenderPass),这是 renderpass 的作用。

而 subpass 则是一种加速手段。如果你的 shader 要读取上一个 pass 的输出，并且只读取当前 uv 位置的数据，则可以在 shader 中使用 InputAttachment.load,在满足一定条件下，subpass 可以直接从片上缓存读取到上一个 pass 的输出。

## 结构设计

Pipeline 的创建需要知道颜色附件的信息，存储在 `vk::PipelineColorBlendAttachmentState`

一个颜色附件对应一个 `vk::PipelineColorBlendAttachmentState`

`vk::PipelineColorBlendStateCreateInfo` 汇总这些 `vk::PipelineColorBlendAttachmentState`

也就是 Material 创建 Pipeline 的时候，需要知道对应 subpass 的附件信息

因此 Material 应该是附属于 subpass 的数据结构

一个 render pass 的各个 subpass 应该是独立的类实例

```cpp
DeferredPass::DeferredPass(vk::raii::PhysicalDevice const& physical_device,
                            vk::raii::Device const&         device,
                            SurfaceData&                    surface_data,
                            vk::raii::CommandPool const&    command_pool,
                            vk::raii::Queue const&          queue,
                            DescriptorAllocatorGrowable&    m_descriptor_allocator)
{
    // Create a set to store all information of attachments

    vk::Format color_format =
        PickSurfaceFormat((physical_device).getSurfaceFormatsKHR(*surface_data.surface)).format;
    assert(color_format != vk::Format::eUndefined);

    std::vector<vk::AttachmentDescription> attachment_descriptions;
    // swap chain attachment
    attachment_descriptions.emplace_back(vk::AttachmentDescriptionFlags(), /* flags */
                                          color_format,                     /* format */
                                          sample_count,                     /* samples */
                                          vk::AttachmentLoadOp::eClear,     /* loadOp */
                                          vk::AttachmentStoreOp::eStore,    /* storeOp */
                                          vk::AttachmentLoadOp::eDontCare,  /* stencilLoadOp */
                                          vk::AttachmentStoreOp::eDontCare, /* stencilStoreOp */
                                          vk::ImageLayout::eUndefined,      /* initialLayout */
                                          vk::ImageLayout::ePresentSrcKHR); /* finalLayout */
    // color attachment
    attachment_descriptions.emplace_back(vk::AttachmentDescriptionFlags(),          /* flags */
                                          color_format,                              /* format */
                                          sample_count,                              /* samples */
                                          vk::AttachmentLoadOp::eClear,              /* loadOp */
                                          vk::AttachmentStoreOp::eDontCare,          /* storeOp */
                                          vk::AttachmentLoadOp::eDontCare,           /* stencilLoadOp */
                                          vk::AttachmentStoreOp::eDontCare,          /* stencilStoreOp */
                                          vk::ImageLayout::eUndefined,               /* initialLayout */
                                          vk::ImageLayout::eColorAttachmentOptimal); /* finalLayout */
    // normal attachment
    attachment_descriptions.emplace_back(vk::AttachmentDescriptionFlags(),          /* flags */
                                          vk::Format::eR8G8B8A8Unorm,                /* format */
                                          sample_count,                              /* samples */
                                          vk::AttachmentLoadOp::eClear,              /* loadOp */
                                          vk::AttachmentStoreOp::eDontCare,          /* storeOp */
                                          vk::AttachmentLoadOp::eDontCare,           /* stencilLoadOp */
                                          vk::AttachmentStoreOp::eDontCare,          /* stencilStoreOp */
                                          vk::ImageLayout::eUndefined,               /* initialLayout */
                                          vk::ImageLayout::eColorAttachmentOptimal); /* finalLayout */
    // depth attachment
    attachment_descriptions.emplace_back(vk::AttachmentDescriptionFlags(),                 /* flags */
                                          depth_format,                                     /* format */
                                          sample_count,                                     /* samples */
                                          vk::AttachmentLoadOp::eClear,                     /* loadOp */
                                          vk::AttachmentStoreOp::eDontCare,                 /* storeOp */
                                          vk::AttachmentLoadOp::eDontCare,                  /* stencilLoadOp */
                                          vk::AttachmentStoreOp::eDontCare,                 /* stencilStoreOp */
                                          vk::ImageLayout::eUndefined,                      /* initialLayout */
                                          vk::ImageLayout::eDepthStencilAttachmentOptimal); /* finalLayout */

    // Create reference to attachment information set

    vk::AttachmentReference swapchain_attachment_reference(0, vk::ImageLayout::eColorAttachmentOptimal);

    std::vector<vk::AttachmentReference> color_attachment_references;
    color_attachment_references.emplace_back(1, vk::ImageLayout::eColorAttachmentOptimal);
    color_attachment_references.emplace_back(2, vk::ImageLayout::eColorAttachmentOptimal);

    vk::AttachmentReference depth_attachment_reference(3, vk::ImageLayout::eDepthStencilAttachmentOptimal);

    std::vector<vk::AttachmentReference> input_attachment_references;
    input_attachment_references.emplace_back(1, vk::ImageLayout::eShaderReadOnlyOptimal);
    input_attachment_references.emplace_back(2, vk::ImageLayout::eShaderReadOnlyOptimal);
    input_attachment_references.emplace_back(3, vk::ImageLayout::eShaderReadOnlyOptimal);

    // Create subpass

    std::vector<vk::SubpassDescription> subpass_descriptions;
    subpass_descriptions.push_back(vk::SubpassDescription(vk::SubpassDescriptionFlags(),    /* flags */
                                                          vk::PipelineBindPoint::eGraphics, /* pipelineBindPoint */
                                                          {},                               /* pInputAttachments */
                                                          color_attachment_references,      /* pColorAttachments */
                                                          {},                          /* pResolveAttachments */
                                                          &depth_attachment_reference, /* pDepthStencilAttachment */
                                                          nullptr));                   /* pPreserveAttachments */
    subpass_descriptions.push_back(vk::SubpassDescription(vk::SubpassDescriptionFlags(),    /* flags */
                                                          vk::PipelineBindPoint::eGraphics, /* pipelineBindPoint */
                                                          input_attachment_references,      /* pInputAttachments */
                                                          swapchain_attachment_reference,   /* pColorAttachments */
                                                          {},        /* pResolveAttachments */
                                                          {},        /* pDepthStencilAttachment */
                                                          nullptr)); /* pPreserveAttachments */

    // Create subpass dependency

    std::vector<vk::SubpassDependency> dependencies;
    dependencies.emplace_back(VK_SUBPASS_EXTERNAL,                               /* srcSubpass */
                              0,                                                 /* dstSubpass */
                              vk::PipelineStageFlagBits::eBottomOfPipe,          /* srcStageMask */
                              vk::PipelineStageFlagBits::eColorAttachmentOutput, /* dstStageMask */
                              vk::AccessFlagBits::eMemoryRead,                   /* srcAccessMask */
                              vk::AccessFlagBits::eColorAttachmentWrite,         /* dstAccessMask */
                              vk::DependencyFlagBits::eByRegion);                /* dependencyFlags */
    dependencies.emplace_back(0,                                                 /* srcSubpass */
                              1,                                                 /* dstSubpass */
                              vk::PipelineStageFlagBits::eColorAttachmentOutput, /* srcStageMask */
                              vk::PipelineStageFlagBits::eFragmentShader,        /* dstStageMask */
                              vk::AccessFlagBits::eColorAttachmentWrite,         /* srcAccessMask */
                              vk::AccessFlagBits::eShaderRead,                   /* dstAccessMask */
                              vk::DependencyFlagBits::eByRegion);                /* dependencyFlags */
    dependencies.emplace_back(1,                                                 /* srcSubpass */
                              VK_SUBPASS_EXTERNAL,                               /* dstSubpass */
                              vk::PipelineStageFlagBits::eColorAttachmentOutput, /* srcStageMask */
                              vk::PipelineStageFlagBits::eBottomOfPipe,          /* dstStageMask */
                              vk::AccessFlagBits::eColorAttachmentWrite,         /* srcAccessMask */
                              vk::AccessFlagBits::eMemoryRead,                   /* dstAccessMask */
                              vk::DependencyFlagBits::eByRegion);                /* dependencyFlags */

    // Create render pass
    vk::RenderPassCreateInfo render_pass_create_info(vk::RenderPassCreateFlags(), /* flags */
                                                      attachment_descriptions,     /* pAttachments */
                                                      subpass_descriptions,        /* pSubpasses */
                                                      dependencies);               /* pDependencies */

    render_pass = vk::raii::RenderPass(device, render_pass_create_info);

    // Create Material

    std::shared_ptr<Shader> obj_shader_ptr = std::make_shared<Shader>(physical_device,
                                                                      device,
                                                                      m_descriptor_allocator,
                                                                      "builtin/shaders/obj.vert.spv",
                                                                      "builtin/shaders/obj.frag.spv");

    obj2attachment_mat                        = Material(physical_device, device, obj_shader_ptr);
    obj2attachment_mat.color_attachment_count = 2;
    obj2attachment_mat.UpdateDescriptorSets(device);
    obj2attachment_mat.CreatePipeline(device, render_pass, vk::FrontFace::eClockwise, true);

    std::shared_ptr<Shader> quad_shader_ptr = std::make_shared<Shader>(physical_device,
                                                                        device,
                                                                        m_descriptor_allocator,
                                                                        "builtin/shaders/quad.vert.spv",
                                                                        "builtin/shaders/quad.frag.spv");

    quad_mat         = Material(physical_device, device, quad_shader_ptr);
    quad_mat.subpass = 1;
    quad_mat.CreatePipeline(device, render_pass, vk::FrontFace::eClockwise, true);

    // Create quad model
    std::vector<float>    vertices = {-1.0f, 1.0f,  0.0f, 0.0f, 0.0f, 1.0f,  1.0f,  0.0f, 1.0f, 0.0f,
                                      1.0f,  -1.0f, 0.0f, 1.0f, 1.0f, -1.0f, -1.0f, 0.0f, 0.0f, 1.0f};
    std::vector<uint16_t> indices  = {0, 1, 2, 0, 2, 3};

    quad_model = std::move(Model(physical_device,
                                  device,
                                  command_pool,
                                  queue,
                                  vertices,
                                  indices,
                                  quad_mat.shader_ptr->per_vertex_attributes));
}
```

例如这里的 `attachment_descriptions` `color_attachment_references` `input_attachment_references` 都应该是由各个 subpass 分别添加的

`subpass_descriptions` `dependencies` 更不用说了

各个 subpass 都添加完了之后，render pass 再 create

`VkClearValue` 也应该存储在 render pass 里面，一个 `VkClearValue` 对应一个 attachment

什么时候使用 `cmd_buffer.nextSubpass(vk::SubpassContents::eInline);` 也应该由 render pass 来决定，因为他知道自己有多少个 subpass 

## pending command

因为使用了 subpass，pending command 的执行位置需要额外考虑了

例如我现在得到一个报错

```
[16:37:34] RUNTIME: Error: { Validation }:
        messageIDName   = <VUID-vkCmdPipelineBarrier-None-07889>
        messageIdNumber = -616663606
        message         = <Validation Error: [ VUID-vkCmdPipelineBarrier-None-07889 ] Object 0: handle = 0x9fde6b0000000014, type = VK_OBJECT_TYPE_RENDER_PASS; | MessageID = 0xdb3e75ca | vkCmdPipelineBarrier():  Barriers cannot be set during subpass 0 of VkRenderPass 0x9fde6b0000000014[] with no self-dependency specified. The Vulkan spec states: If vkCmdPipelineBarrier is called within a render pass instance using a VkRenderPass object, the render pass must have been created with at least one subpass dependency that expresses a dependency from the current subpass to itself, does not include VK_DEPENDENCY_BY_REGION_BIT if this command does not, does not include VK_DEPENDENCY_VIEW_LOCAL_BIT if this command does not, and has synchronization scopes and access scopes that are all supersets of the scopes defined in this command (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdPipelineBarrier-None-07889)>
        Objects:
                Object 0
                        objectType   = RenderPass
                        objectHandle = 11519762544604479508
```

这个报错的意思是，如果我在某个 subpass 里面做 `vkCmdPipelineBarrier`，那么这个 render pass 中应该有一个 subpass dependency， `srcSubpass` `dstSubpass` 都是这个 subpass 自己

如果真的要这么做，就有点复杂了我觉得。在自定义类里面，render pass 还要去管 command buffer 的事，有点耦合了。

他看上去就像是，其实可以不在 render pass 里面做 `vkCmdPipelineBarrier`

那么我为什么要这么做呢。因为我以前的遇到过错误是，command buffer 的使用需要在 command buffer 的录制阶段，然后我一看我的代码，只有 render pass 的 begin 和 end 之间有写 command buffer 的 begin 和 end，所以我就把所有跟 command buffer 有关的执行都存储起来，统一推迟到 render pass 里面执行，以此实现位于 command buffer 的 begin 和 end 之间

现在我才突然发现，其实 command buffer 的 begin 和 end 跟 render pass 没有关系，倒不如说是为了 `cmd_buffer.beginRenderPass` 才需要启动 command buffer 的录制

或许其实 command buffer 它本身就是一个 buffer，所以理论上就是要随时录制的，我这么做再加多一层肯定有问题

所以我把那个 pending command 删了，要用到 command buffer 的地方直接录制就好了

之后再看 command buffer 的使用，发现它的使用方法真的和我的想法一模一样。submit 之前，记录的命令就一直留在 command buffer 里面，submit 之后用 reset 清空就好了

我之前都是在 render pass 的记录之前清空，那是因为简单案例里面，render pass 前面没有 command buffer 相关的其他东西

现在搞懂之后觉得，应该是 submit 之后，wait for fence 结束之后 reset 最合理

这样，一帧里面的所有命令都保存下来了

## 附件不需要为 frames in flight 而备份

[Why is a single depth buffer sufficient for multiple frames in flight?](https://www.reddit.com/r/vulkan/comments/aavxl4/why_is_a_single_depth_buffer_sufficient_for/)

[What exactly is the definition of "frames in flight"?](https://www.reddit.com/r/vulkan/comments/nbu94q/what_exactly_is_the_definition_of_frames_in_flight/)

虽然我们有飞行中的多个帧 multiple frames in flight，但是这并不意味着我们在同时渲染多个帧

实际上，multiple frames in flight 的意思是，一个帧具有三个阶段

1. 记录命令缓冲，上传数据
   
2. GPU 渲染

3. 呈现到屏幕

我们可以有两个帧同时位于不同的阶段，但是我们不会有两个帧同时位于同一个阶段

所以我们在给 frame buffer 提供 `vk::raii::ImageView` 引用的时候，多个 frame buffer 引用不同的 swapchain 的 image view，但是引用同一个深度缓冲

那么如果你再添加其他附件，也是无需为了多个 frame buffer 而备份的

## 动态渲染 Dynamic rendering

[https://www.khronos.org/blog/streamlining-render-passes](https://www.khronos.org/blog/streamlining-render-passes)

[https://www.khronos.org/blog/streamlining-subpasses](https://www.khronos.org/blog/streamlining-subpasses)

现在是可以用动态渲染实现 local read 了

于是完全可以转向动态渲染

## subpass 和 render pass 之间的区别

看到 picoolo 的渲染是

```cpp
static_cast<DirectionalLightShadowPass*>(m_directional_light_pass.get())->draw();

static_cast<PointLightShadowPass*>(m_point_light_shadow_pass.get())->draw();

ColorGradingPass& color_grading_pass = *(static_cast<ColorGradingPass*>(m_color_grading_pass.get()));
FXAAPass&         fxaa_pass          = *(static_cast<FXAAPass*>(m_fxaa_pass.get()));
ToneMappingPass&  tone_mapping_pass  = *(static_cast<ToneMappingPass*>(m_tone_mapping_pass.get()));
UIPass&           ui_pass            = *(static_cast<UIPass*>(m_ui_pass.get()));
CombineUIPass&    combine_ui_pass    = *(static_cast<CombineUIPass*>(m_combine_ui_pass.get()));
ParticlePass&     particle_pass      = *(static_cast<ParticlePass*>(m_particle_pass.get()));

static_cast<ParticlePass*>(m_particle_pass.get())
    ->setRenderCommandBufferHandle(
        static_cast<MainCameraPass*>(m_main_camera_pass.get())->getRenderCommandBuffer());

static_cast<MainCameraPass*>(m_main_camera_pass.get())
    ->draw(color_grading_pass,
            fxaa_pass,
            tone_mapping_pass,
            ui_pass,
            combine_ui_pass,
            particle_pass,
            vulkan_rhi->m_current_swapchain_image_index);
            
g_runtime_global_context.m_debugdraw_manager->draw(vulkan_rhi->m_current_swapchain_image_index);
```

阴影的 pass 是独立的，其他的都是 subpass

为什么呢

哦，因为是用于创建阴影贴图而不是使用颜色附件

所以阴影的 pass 利用不了颜色附件

其他的就可以

## 别人怎么抽象 subpass

于是发现他这个 subpass dependency 就是 hard code 在 `void MainCameraPass::setupRenderPass()` 里面的

并不是我以为的，可以各自单独配置

## dynamic rendering 的意义

看了 [https://www.reddit.com/r/vulkan/comments/sd93nm/the_future_of_renderpass_mechanism_vs_dynamic/](https://www.reddit.com/r/vulkan/comments/sd93nm/the_future_of_renderpass_mechanism_vs_dynamic/)

所说，大部分观点是，动态渲染使得图像布局转换变得清晰了

然后还有说，pipeline 和 render pass 解耦

也就是着色器和渲染状态（储存在 pipeline）和附件（储存在 render pass）解耦

怎么说呢，创建 pipeline 的时候，你还是会需要知道附件信息

只是这个附件信息现在是格式，而不是附件 image 指针

来自 Vulkan-Samples

samples\extensions\dynamic_rendering\dynamic_rendering.cpp

```cpp
// Provide information for dynamic rendering
VkPipelineRenderingCreateInfoKHR pipeline_create{VK_STRUCTURE_TYPE_PIPELINE_RENDERING_CREATE_INFO_KHR};
pipeline_create.pNext                   = VK_NULL_HANDLE;
pipeline_create.colorAttachmentCount    = 1;
pipeline_create.pColorAttachmentFormats = &color_rendering_format;
pipeline_create.depthAttachmentFormat   = depth_format;
if (!vkb::is_depth_only_format(depth_format))
{
    pipeline_create.stencilAttachmentFormat = depth_format;
}

// Use the pNext to point to the rendering create struct
VkGraphicsPipelineCreateInfo graphics_create{VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO};
graphics_create.pNext               = &pipeline_create;
graphics_create.renderPass          = VK_NULL_HANDLE;
graphics_create.pInputAssemblyState = &input_assembly_state;
graphics_create.pRasterizationState = &rasterization_state;
graphics_create.pColorBlendState    = &color_blend_state;
graphics_create.pMultisampleState   = &multisample_state;
graphics_create.pViewportState      = &viewport_state;
graphics_create.pDepthStencilState  = &depth_stencil_state;
graphics_create.pDynamicState       = &dynamic_state;
graphics_create.pVertexInputState   = &vertex_input_state;
graphics_create.stageCount          = static_cast<uint32_t>(shader_stages.size());
graphics_create.pStages             = shader_stages.data();
graphics_create.layout              = pipeline_layout;

// Skybox pipeline (background cube)
VkSpecializationInfo                    specialization_info;
std::array<VkSpecializationMapEntry, 1> specialization_map_entries{};
specialization_map_entries[0]        = vkb::initializers::specialization_map_entry(0, 0, sizeof(uint32_t));
uint32_t shadertype                  = 0;
specialization_info                  = vkb::initializers::specialization_info(1, specialization_map_entries.data(), sizeof(shadertype), &shadertype);
shader_stages[0].pSpecializationInfo = &specialization_info;
shader_stages[1].pSpecializationInfo = &specialization_info;

if (!enable_dynamic)
{
    graphics_create.pNext      = VK_NULL_HANDLE;
    graphics_create.renderPass = render_pass;
}

vkCreateGraphicsPipelines(get_device().get_handle(), VK_NULL_HANDLE, 1, &graphics_create, VK_NULL_HANDLE, &skybox_pipeline);
```

我倒觉得这个解耦体现在不需要传入 render pass 了

（因为你已经没有 render pass 对象了）

也就是体现在

```cpp
graphics_create.renderPass          = VK_NULL_HANDLE;
```

和 render pass 解耦之后，你就可以用在颜色格式相同的任何 pass 了

在 pass 之间共享的意义并不大，因为你不是完全自由的，因为你还是需要客户端知晓哪些是颜色格式相同的 pass

还是有一层心智负担的

但是能够脱离 render pass 来创建 pipeline 还是很爽的

比如你的设计如果是不从你对 pass 的抽象类里面获取颜色附件的格式、深度附件的格式

而是从别人地方获取，比如使用默认值，或者从自己创建的 meta 文件中获取

那么创建 material 这种包含 pipeline 的抽象类的时候，就与 render pass 的抽象类完全无关了

现在想想似乎还有第三点

就是推出了 local read 之后，你不需要在创建 render pass 的时候就知道 subpass 的所有信息

这使得 render pass 和 subpass 之间是可以解耦的，这其实我觉得是最大的意义

综合这些的话：

1. 由程序客户端控制图像布局转换

2. 拥有 pipeline 的抽象类（如 material）与 render pass 抽象类之间解耦

3. render pass 和 subpass 之间解耦

## 启动 dynamic rendering

想通过这个来启动

```cpp
// prepare for create vk::InstanceCreateInfo
std::vector<vk::ExtensionProperties> available_instance_extensions =
    m_vulkan_context.enumerateInstanceExtensionProperties();
std::vector<const char*> required_instance_extensions = GetRequiredInstanceExtensions({
    VK_KHR_SURFACE_EXTENSION_NAME,
    VK_KHR_DYNAMIC_RENDERING_EXTENSION_NAME,
});
if (!ValidateExtensions(required_instance_extensions, available_instance_extensions))
{
    throw std::runtime_error("Required instance extensions are missing.");
}
```

但是看上去 1.3 里面已经不是 extension 了，我找不到

于是发现是在 device extension 里面而不是 instance extension 里面

```cpp
std::vector<const char*> k_required_device_extensions = {
    VK_KHR_SWAPCHAIN_EXTENSION_NAME,
    VK_KHR_DYNAMIC_RENDERING_EXTENSION_NAME,
};

void RenderSystem::CreateLogicalDevice()
{
    // Logical Device

    std::vector<vk::ExtensionProperties> device_extensions = m_physical_device.enumerateDeviceExtensionProperties();
    if (!ValidateExtensions(k_required_device_extensions, device_extensions))
    {
        throw std::runtime_error("Required device extensions are missing, will try without.");
    }
```

这样检查就好了

## 创建用于 dynamic rendering 的 pipeline

现在 `vk::GraphicsPipelineCreateInfo` 不需要 `renderPass` 和 `subpass` 了

但是需要一个额外的用于 dynamic rendering 的 info

在创建 `vk::PipelineRenderingCreateInfoKHR` 的时候就发现了

不管是 render pass 还是 dynamic rendering

始终都是要知道附件信息传入的

所以 dynamic rendering 并不能和抽象的 render pass 之间分来

附件信息始终是需要输入的

所以优势或许可以总结为

1. 由客户端控制图像布局转换，不需要静态地定义出完整 render pass 的抽象的图像布局

2. 客户端对 subpass 的抽象之间解耦

客户端对 vulkan render pass 的抽象之间在 dynamic 之前自然就是解耦的

看到这些 pipeline 的状态就感觉会有很多都可以用数据驱动的

就不用我 hard code material 类的变体，或者是构造函数的变体，或者之类的

比如 `vk::PipelineColorBlendAttachmentState` 管理 alpha 混合的，和 `vk::PipelineDepthStencilStateCreateInfo` 管理模板测试的之类的，都可以用数据驱动啊

但是这仅仅是想想

现在在写 dynamic rendering 的时候还是不要做这些了

## vkCmdBeginRenderingKHR 时需要的附件信息

使用 `vkCmdBeginRenderingKHR` 时需要转变附件布局，也需要传入 image view 到 info 里面

原来的 vulkan render pass 体系中，这些附件是通过 frame buffer 传入的

现在只是转变成了自己传入附件

并且你传入的附件数实际上跟 framebuffer 时期应该是一样的

如果你自己创建一个 frame buffer 的抽象类的话，甚至可以认为 framebuffer 还在

但是以这么来看的话，subpass 似乎也并没有单独抽象的价值

因为毕竟如果要抽象成单独的类，那么还需要协调怎么传递附件信息

那还不如不协调

那么其实 subpass 并没有抽象解耦的优势

所以优势仅仅是由客户端控制图像布局转换，不需要静态地定义出完整 render pass 的抽象的图像布局，这一点

所以他对代码架构组织并没有帮助

仅仅会影响对 vulkan 的调用风格而已