# compute shader

## 参考

[https://vulkan-tutorial.com/Compute_Shader](https://vulkan-tutorial.com/Compute_Shader)

## 报错 1

```
Validation Error: [ VUID-vkCmdBindVertexBuffers-pBuffers-00627 ] | MessageID = 0x9ae31e79
vkCmdBindVertexBuffers(): pBuffers[0] (VkBuffer 0x40000000004) was created with VK_BUFFER_USAGE_2_TRANSFER_DST_BIT|VK_BUFFER_USAGE_2_STORAGE_BUFFER_BIT but requires VK_BUFFER_USAGE_2_VERTEX_BUFFER_BIT.
The Vulkan spec states: All elements of pBuffers must have been created with the VK_BUFFER_USAGE_VERTEX_BUFFER_BIT flag (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/fxvertex.html#VUID-vkCmdBindVertexBuffers-pBuffers-00627)
Objects: 2
    [0] VkCommandBuffer 0x1e6f3775f70
    [1] VkBuffer 0x40000000004
```

这个是我 storage buffer 后面用来做 vertex buffer 了，但是没有加 usage

```
Validation Error: [ VUID-VkSubpassDependency-dstAccessMask-00869 ] | MessageID = 0x8ab30c42
vkCreateRenderPass(): pDependencies[1].dstAccessMask (VK_ACCESS_SHADER_READ_BIT) is not supported by stage mask (VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT).
The Vulkan spec states: Any access flag included in dstAccessMask must be supported by one of the pipeline stages in dstStageMask, as specified in the table of supported access types (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/renderpass.html#VUID-VkSubpassDependency-dstAccessMask-00869)
```

官方 spec 看不到 VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT 对应的 access 可以是啥哦

改成 eMemoryRead 好了

```
Validation Error: [ VUID-vkCmdDispatch-None-08600 ] | MessageID = 0x3450abd3
vkCmdDispatch(): The VkPipeline 0xb000000000b[GPUParticleData2D compute material Pipeline] statically uses descriptor set 0, but because a descriptor was never bound, the pipeline layouts are not compatible.
If using a descriptor, make sure to call one of vkCmdBindDescriptorSets, vkCmdPushDescriptorSet, vkCmdSetDescriptorBufferOffset, etc for VK_PIPELINE_BIND_POINT_COMPUTE.
The Vulkan spec states: For each set n that is statically used by a bound shader, a descriptor set must have been bound to n at the same pipeline bind point, with a VkPipelineLayout that is compatible for set n, with the VkPipelineLayout used to create the current VkPipeline or the VkDescriptorSetLayout array used to create the current VkShaderEXT , as described in Pipeline Layout Compatibility (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/dispatch.html#VUID-vkCmdDispatch-None-08600)
Objects: 2
    [0] VkCommandBuffer 0x1857ee799c0
    [1] VkPipeline 0xb000000000b[GPUParticleData2D compute material Pipeline]
```

这个不太合理啊……我明明给两个 descriptor set 都创建了 uniform buffer

我的 uniform buffer 创建函数里面就会带绑定的

后面记错了，创建 uniform buffer 那个是 write，bind 是我写了一个函数的，这个函数里面一眼看到 bind point 写死了是 graphics，改了之后再测试就好了

## 同步问题 semaphore already in use 报错

```
Validation Error: [ VUID-vkResetCommandBuffer-commandBuffer-00045 ] | MessageID = 0x1e7883ea
vkResetCommandBuffer(): (VkCommandBuffer 0x13761fc5c30[PerFrameData compute command buffer frame 1]) is in use.
The Vulkan spec states: commandBuffer must not be in the pending state (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/cmdbuffers.html#VUID-vkResetCommandBuffer-commandBuffer-00045)
Objects: 2
    [0] VkCommandBuffer 0x13761fc5c30[PerFrameData compute command buffer frame 1]
    [1] VkCommandPool 0x200000000020[PerFrameData command pool frame 1]

Validation Error: [ VUID-vkBeginCommandBuffer-commandBuffer-00049 ] | MessageID = 0x84029a9f
vkBeginCommandBuffer(): on active VkCommandBuffer 0x13761fc5c30[PerFrameData compute command buffer frame 1] before it has completed. You must check command buffer fence before this call.
The Vulkan spec states: commandBuffer must not be in the recording or pending state (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/cmdbuffers.html#VUID-vkBeginCommandBuffer-commandBuffer-00049)
Objects: 1
    [0] VkCommandBuffer 0x13761fc5c30[PerFrameData compute command buffer frame 1]

Validation Error: [ VUID-vkQueueSubmit-pSignalSemaphores-00067 ] | MessageID = 0x539277af
vkQueueSubmit(): pSubmits[0].pSignalSemaphores[0] (VkSemaphore 0x220000000022[PerFrameData render finished semaphore frame 1]) is being signaled by VkQueue 0x1375b943830, but it may still be in use by VkSwapchainKHR 0x130000000013.
Here are the most recently acquired image indices: 0, [1], 2, 0.
(brackets mark the last use of VkSemaphore 0x220000000022[PerFrameData render finished semaphore frame 1] in a presentation operation)
Swapchain image 1 was presented but was not re-acquired, so VkSemaphore 0x220000000022[PerFrameData render finished semaphore frame 1] may still be in use and cannot be safely reused with image index 0.
Vulkan insight: One solution is to assign each image its own semaphore. Here are some common methods to ensure that a semaphore passed to vkQueuePresentKHR is not in use and can be safely reused:
	a) Use a separate semaphore per swapchain image. Index these semaphores using the index of the acquired image.
	b) Consider the VK_KHR_swapchain_maintenance1 extension. It allows using a VkFence with the presentation operation.
The Vulkan spec states: Each binary semaphore element of the pSignalSemaphores member of any element of pSubmits must be unsignaled when the semaphore signal operation it defines is executed on the device (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/cmdbuffers.html#VUID-vkQueueSubmit-pSignalSemaphores-00067)
Objects: 2
    [0] VkSemaphore 0x220000000022[PerFrameData render finished semaphore frame 1]
    [1] VkQueue 0x1375b943830

Validation Error: [ VUID-vkQueueSubmit-pCommandBuffers-00071 ] | MessageID = 0x2e2f4d65
vkQueueSubmit(): pSubmits[0].pCommandBuffers[0] VkCommandBuffer 0x13761fc5c30[PerFrameData compute command buffer frame 1] is already in use and is not marked for simultaneous use.
The Vulkan spec states: If any element of the pCommandBuffers member of any element of pSubmits was not recorded with the VK_COMMAND_BUFFER_USAGE_SIMULTANEOUS_USE_BIT, it must not be in the pending state (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/cmdbuffers.html#VUID-vkQueueSubmit-pCommandBuffers-00071)

Validation Error: [ VUID-vkResetCommandBuffer-commandBuffer-00045 ] | MessageID = 0x1e7883ea
vkResetCommandBuffer(): (VkCommandBuffer 0x13761fa3060[PerFrameData compute command buffer frame 0]) is in use.
The Vulkan spec states: commandBuffer must not be in the pending state (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/cmdbuffers.html#VUID-vkResetCommandBuffer-commandBuffer-00045)
Objects: 2
    [0] VkCommandBuffer 0x13761fa3060[PerFrameData compute command buffer frame 0]
    [1] VkCommandPool 0x1a000000001a[PerFrameData command pool frame 0]

Validation Error: [ VUID-vkBeginCommandBuffer-commandBuffer-00049 ] | MessageID = 0x84029a9f
vkBeginCommandBuffer(): on active VkCommandBuffer 0x13761fa3060[PerFrameData compute command buffer frame 0] before it has completed. You must check command buffer fence before this call.
The Vulkan spec states: commandBuffer must not be in the recording or pending state (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/cmdbuffers.html#VUID-vkBeginCommandBuffer-commandBuffer-00049)
Objects: 1
    [0] VkCommandBuffer 0x13761fa3060[PerFrameData compute command buffer frame 0]

Validation Error: [ VUID-vkQueueSubmit-pCommandBuffers-00071 ] | MessageID = 0x2e2f4d65
vkQueueSubmit(): pSubmits[0].pCommandBuffers[0] VkCommandBuffer 0x13761fa3060[PerFrameData compute command buffer frame 0] is already in use and is not marked for simultaneous use.
The Vulkan spec states: If any element of the pCommandBuffers member of any element of pSubmits was not recorded with the VK_COMMAND_BUFFER_USAGE_SIMULTANEOUS_USE_BIT, it must not be in the pending state (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/cmdbuffers.html#VUID-vkQueueSubmit-pCommandBuffers-00071)

...

Validation Error: [ VUID-vkBeginCommandBuffer-commandBuffer-00049 ] | MessageID = 0x84029a9f
(Warning - This VUID has now been reported 10 times, which is the duplicated_message_limit value, this will be the last time reporting it).
vkBeginCommandBuffer(): on active VkCommandBuffer 0x13761fa3060[PerFrameData compute command buffer frame 0] before it has completed. You must check command buffer fence before this call.
The Vulkan spec states: commandBuffer must not be in the recording or pending state (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/cmdbuffers.html#VUID-vkBeginCommandBuffer-commandBuffer-00049)
Objects: 1
    [0] VkCommandBuffer 0x13761fa3060[PerFrameData compute command buffer frame 0]

Validation Error: [ VUID-vkQueueSubmit-pCommandBuffers-00071 ] | MessageID = 0x2e2f4d65
(Warning - This VUID has now been reported 10 times, which is the duplicated_message_limit value, this will be the last time reporting it).
vkQueueSubmit(): pSubmits[0].pCommandBuffers[0] VkCommandBuffer 0x13761fa3060[PerFrameData compute command buffer frame 0] is already in use and is not marked for simultaneous use.
The Vulkan spec states: If any element of the pCommandBuffers member of any element of pSubmits was not recorded with the VK_COMMAND_BUFFER_USAGE_SIMULTANEOUS_USE_BIT, it must not be in the pending state (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/cmdbuffers.html#VUID-vkQueueSubmit-pCommandBuffers-00071)

```

我的 Tick 函数

```cpp
void EditorWindow::Tick(float dt)
{
    FUNCTION_TIMER();

    m_wait_until_next_tick_signal();
    m_wait_until_next_tick_signal.clear();

    if (m_iconified)
        return;

    const vk::raii::Device& logical_device            = g_runtime_context.render_system->GetLogicalDevice();
    const vk::raii::Queue&  graphics_queue            = g_runtime_context.render_system->GetGraphicsQueue();
    const vk::raii::Queue&  present_queue             = g_runtime_context.render_system->GetPresentQueue();
    const vk::raii::Queue&  compute_queue             = g_runtime_context.render_system->GetComputeQueue();
    auto&                   per_frame_data            = m_per_frame_data[m_frame_index];
    auto&                   command_buffer            = per_frame_data.graphics_command_buffer;
    auto&                   image_acquired_semaphore  = per_frame_data.image_acquired_semaphore;
    auto&                   render_finished_semaphore = per_frame_data.render_finished_semaphore;
    auto&                   in_flight_fence           = per_frame_data.in_flight_fence;
    const auto              k_max_frames_in_flight    = g_runtime_context.render_system->GetMaxFramesInFlight();

    auto& compute_command_buffer     = per_frame_data.compute_command_buffer;
    auto& compute_acquired_semaphore = per_frame_data.compute_acquired_semaphore;
    auto& compute_finished_semaphore = per_frame_data.compute_finished_semaphore;

    m_shadow_map_pass.UpdateUniformBuffer(m_frame_index);
    m_shadow_coord_to_color_pass.UpdateUniformBuffer(m_frame_index);
    m_render_pass_ptr->UpdateUniformBuffer(m_frame_index);
    m_compute_particle_pass.UpdateUniformBuffer(m_frame_index);
    m_forward_pass.PopulateDirectionalLightData(m_shadow_map_pass.GetShadowMap(), m_frame_index);

    // ------------------- render -------------------

    while (vk::Result::eTimeout == logical_device.waitForFences({*in_flight_fence}, VK_TRUE, k_fence_timeout))
        ;
    logical_device.resetFences({*in_flight_fence});

    auto [result, m_image_index] =
        SwapchainNextImageWrapper(m_swapchain_data.swap_chain, k_fence_timeout, *image_acquired_semaphore);
    if (result == vk::Result::eErrorOutOfDateKHR || result == vk::Result::eSuboptimalKHR || m_framebuffer_resized)
    {
        m_framebuffer_resized = false;
        RecreateSwapChain();
        return;
    }
    assert(result == vk::Result::eSuccess);
    assert(m_image_index < m_swapchain_data.images.size());

    command_buffer.reset();
    command_buffer.begin({});

    compute_command_buffer.reset();
    compute_command_buffer.begin({});

    m_shadow_map_pass.Start(command_buffer, m_surface_data.extent, m_image_index);
    m_shadow_map_pass.RecordGraphicsCommand(command_buffer, m_frame_index);
    m_shadow_map_pass.End(command_buffer);

    m_depth_to_color_pass.Start(command_buffer, m_surface_data.extent, m_image_index);
    m_depth_to_color_pass.RecordGraphicsCommand(command_buffer, m_frame_index);
    m_depth_to_color_pass.End(command_buffer);

    m_shadow_coord_to_color_pass.Start(command_buffer, m_surface_data.extent, m_image_index);
    m_shadow_coord_to_color_pass.RecordGraphicsCommand(command_buffer, m_frame_index);
    m_shadow_coord_to_color_pass.End(command_buffer);

    m_render_pass_ptr->Start(command_buffer, m_surface_data.extent, m_image_index);
    m_render_pass_ptr->RecordGraphicsCommand(command_buffer, m_frame_index);
    m_render_pass_ptr->End(command_buffer);

    m_compute_particle_pass.Start(command_buffer, m_surface_data.extent, m_image_index);
    m_compute_particle_pass.RecordComputeCommand(compute_command_buffer, m_frame_index);
    m_compute_particle_pass.RecordGraphicsCommand(command_buffer, m_frame_index);
    m_compute_particle_pass.End(command_buffer);

    m_imgui_pass.Start(command_buffer, m_surface_data.extent, m_image_index);
    m_imgui_pass.RecordGraphicsCommand(command_buffer, m_frame_index);
    m_imgui_pass.End(command_buffer);

    command_buffer.end();

    compute_command_buffer.end();

    {
        std::array<const vk::PipelineStageFlags, 2> wait_destination_stage_masks {
            vk::PipelineStageFlagBits::eColorAttachmentOutput, vk::PipelineStageFlagBits::eVertexInput};
        std::array<const vk::Semaphore, 2> wait_semaphores {*image_acquired_semaphore, *compute_finished_semaphore};
        std::array<const vk::Semaphore, 2> signal_emaphores {*render_finished_semaphore,
                                                                *compute_acquired_semaphore};
        vk::SubmitInfo                     submit_info(
            wait_semaphores, wait_destination_stage_masks, *command_buffer, signal_emaphores);
        graphics_queue.submit(submit_info, *in_flight_fence);
    }

    {
        vk::PipelineStageFlags wait_destination_stage_mask(vk::PipelineStageFlagBits::eComputeShader);
        vk::SubmitInfo         submit_info(*compute_acquired_semaphore,
                                    wait_destination_stage_mask,
                                    *compute_command_buffer,
                                    *compute_finished_semaphore);
        compute_queue.submit(submit_info, nullptr);
    }

    vk::PresentInfoKHR present_info(*render_finished_semaphore, *m_swapchain_data.swap_chain, m_image_index);
    result = QueuePresentWrapper(present_queue, present_info);
    switch (result)
    {
        case vk::Result::eSuccess:
            break;
        case vk::Result::eSuboptimalKHR:
            MEOW_ERROR("vk::Queue::presentKHR returned vk::Result::eSuboptimalKHR !\n");
            break;
        default:
            assert(false); // an unexpected result is returned !
    }

    m_frame_index = (m_frame_index + 1) % k_max_frames_in_flight;

    m_render_pass_ptr->AfterPresent();
    m_imgui_pass.AfterPresent();

    Window::Tick(dt);
}
```

我创建 semaphore 的时候还触发了

```cpp
// Signal compute_finished_semaphore at first
// Because graphics queue submit is ahead of compute queue in tick
// and graphics queue waits for compute_finished_semaphore
m_per_frame_data[i].graphics_command_buffer.reset();
m_per_frame_data[i].graphics_command_buffer.begin({});
vk::SubmitInfo submit_info(
    {}, {}, *m_per_frame_data[i].graphics_command_buffer, *m_per_frame_data[i].compute_finished_semaphore);
m_per_frame_data[i].graphics_command_buffer.end();
graphics_queue.submit(submit_info);
```

这有啥问题吗

好吧我知道了，还是需要 fence 的，queue submit 可以触发 semaphore 和 fence，semaphore 是用来触发别的 queue submit 的，fence 是用来给 cpu 等待的

简单画了个图，其实没有整理完结构，但是大概是这样的

![](../assets/compute_shader_sync_error.drawio.svg)

就是 compute 这里只有 semaphore 触发，但是没有 fence 拦截，那么你 cpu 不知道他什么时候完成

现在的设计是在 render 完成的时候去改 compute command，实际上时机就不对了

## 同步问题 2

compute 这边改成了一个 fence 一个 semaphore 之后，新出现一个，只报一次的错误

```
Validation Error: [ VUID-vkQueueSubmit-pSignalSemaphores-00067 ] | MessageID = 0x539277af
vkQueueSubmit(): pSubmits[0].pSignalSemaphores[0] (VkSemaphore 0x220000000022[PerFrameData render finished semaphore frame 1]) is being signaled by VkQueue 0x179e9b86540, but it may still be in use by VkSwapchainKHR 0x130000000013.
Here are the most recently acquired image indices: 0, [1], 2, 0.
(brackets mark the last use of VkSemaphore 0x220000000022[PerFrameData render finished semaphore frame 1] in a presentation operation)
Swapchain image 1 was presented but was not re-acquired, so VkSemaphore 0x220000000022[PerFrameData render finished semaphore frame 1] may still be in use and cannot be safely reused with image index 0.
Vulkan insight: One solution is to assign each image its own semaphore. Here are some common methods to ensure that a semaphore passed to vkQueuePresentKHR is not in use and can be safely reused:
	a) Use a separate semaphore per swapchain image. Index these semaphores using the index of the acquired image.
	b) Consider the VK_KHR_swapchain_maintenance1 extension. It allows using a VkFence with the presentation operation.
The Vulkan spec states: Each binary semaphore element of the pSignalSemaphores member of any element of pSubmits must be unsignaled when the semaphore signal operation it defines is executed on the device (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/cmdbuffers.html#VUID-vkQueueSubmit-pSignalSemaphores-00067)
Objects: 2
    [0] VkSemaphore 0x220000000022[PerFrameData render finished semaphore frame 1]
    [1] VkQueue 0x179e9b86540
```

此时的 Tick

```cpp
void EditorWindow::Tick(float dt)
{
    FUNCTION_TIMER();

    m_wait_until_next_tick_signal();
    m_wait_until_next_tick_signal.clear();

    if (m_iconified)
        return;

    const vk::raii::Device& logical_device            = g_runtime_context.render_system->GetLogicalDevice();
    const vk::raii::Queue&  graphics_queue            = g_runtime_context.render_system->GetGraphicsQueue();
    const vk::raii::Queue&  present_queue             = g_runtime_context.render_system->GetPresentQueue();
    const vk::raii::Queue&  compute_queue             = g_runtime_context.render_system->GetComputeQueue();
    auto&                   per_frame_data            = m_per_frame_data[m_frame_index];
    auto&                   command_buffer            = per_frame_data.graphics_command_buffer;
    auto&                   image_acquired_semaphore  = per_frame_data.image_acquired_semaphore;
    auto&                   render_finished_semaphore = per_frame_data.render_finished_semaphore;
    auto&                   graphics_in_flight_fence  = per_frame_data.graphics_in_flight_fence;
    const auto              k_max_frames_in_flight    = g_runtime_context.render_system->GetMaxFramesInFlight();

    auto& compute_command_buffer     = per_frame_data.compute_command_buffer;
    auto& compute_finished_semaphore = per_frame_data.compute_finished_semaphore;
    auto& compute_in_flight_fence    = per_frame_data.compute_in_flight_fence;

    m_shadow_map_pass.UpdateUniformBuffer(m_frame_index);
    m_shadow_coord_to_color_pass.UpdateUniformBuffer(m_frame_index);
    m_render_pass_ptr->UpdateUniformBuffer(m_frame_index);
    m_compute_particle_pass.UpdateUniformBuffer(m_frame_index);
    m_forward_pass.PopulateDirectionalLightData(m_shadow_map_pass.GetShadowMap(), m_frame_index);

    // ------------------- compute -------------------

    while (vk::Result::eTimeout ==
            logical_device.waitForFences({*compute_in_flight_fence}, VK_TRUE, k_fence_timeout))
        ;
    logical_device.resetFences({*compute_in_flight_fence});

    compute_command_buffer.reset();
    compute_command_buffer.begin({});

    m_compute_particle_pass.RecordComputeCommand(compute_command_buffer, m_frame_index);

    compute_command_buffer.end();

    {
        vk::SubmitInfo submit_info({}, {}, *compute_command_buffer, *compute_finished_semaphore);
        compute_queue.submit(submit_info, *compute_in_flight_fence);
    }

    // ------------------- render -------------------

    while (vk::Result::eTimeout ==
            logical_device.waitForFences({*graphics_in_flight_fence}, VK_TRUE, k_fence_timeout))
        ;
    logical_device.resetFences({*graphics_in_flight_fence});

    auto [result, m_image_index] =
        SwapchainNextImageWrapper(m_swapchain_data.swap_chain, k_fence_timeout, *image_acquired_semaphore);
    if (result == vk::Result::eErrorOutOfDateKHR || result == vk::Result::eSuboptimalKHR || m_framebuffer_resized)
    {
        m_framebuffer_resized = false;
        RecreateSwapChain();
        return;
    }
    assert(result == vk::Result::eSuccess);
    assert(m_image_index < m_swapchain_data.images.size());

    command_buffer.reset();
    command_buffer.begin({});

    m_shadow_map_pass.Start(command_buffer, m_surface_data.extent, m_image_index);
    m_shadow_map_pass.RecordGraphicsCommand(command_buffer, m_frame_index);
    m_shadow_map_pass.End(command_buffer);

    m_depth_to_color_pass.Start(command_buffer, m_surface_data.extent, m_image_index);
    m_depth_to_color_pass.RecordGraphicsCommand(command_buffer, m_frame_index);
    m_depth_to_color_pass.End(command_buffer);

    m_shadow_coord_to_color_pass.Start(command_buffer, m_surface_data.extent, m_image_index);
    m_shadow_coord_to_color_pass.RecordGraphicsCommand(command_buffer, m_frame_index);
    m_shadow_coord_to_color_pass.End(command_buffer);

    m_render_pass_ptr->Start(command_buffer, m_surface_data.extent, m_image_index);
    m_render_pass_ptr->RecordGraphicsCommand(command_buffer, m_frame_index);
    m_render_pass_ptr->End(command_buffer);

    m_compute_particle_pass.Start(command_buffer, m_surface_data.extent, m_image_index);
    m_compute_particle_pass.RecordGraphicsCommand(command_buffer, m_frame_index);
    m_compute_particle_pass.End(command_buffer);

    m_imgui_pass.Start(command_buffer, m_surface_data.extent, m_image_index);
    m_imgui_pass.RecordGraphicsCommand(command_buffer, m_frame_index);
    m_imgui_pass.End(command_buffer);

    command_buffer.end();

    {
        std::array<const vk::PipelineStageFlags, 2> wait_destination_stage_masks {
            vk::PipelineStageFlagBits::eColorAttachmentOutput, vk::PipelineStageFlagBits::eVertexInput};
        std::array<const vk::Semaphore, 2> wait_semaphores {*image_acquired_semaphore, *compute_finished_semaphore};
        vk::SubmitInfo                     submit_info(
            wait_semaphores, wait_destination_stage_masks, *command_buffer, *render_finished_semaphore);
        graphics_queue.submit(submit_info, *graphics_in_flight_fence);
    }

    vk::PresentInfoKHR present_info(*render_finished_semaphore, *m_swapchain_data.swap_chain, m_image_index);
    result = QueuePresentWrapper(present_queue, present_info);
    switch (result)
    {
        case vk::Result::eSuccess:
            break;
        case vk::Result::eSuboptimalKHR:
            MEOW_ERROR("vk::Queue::presentKHR returned vk::Result::eSuboptimalKHR !\n");
            break;
        default:
            assert(false); // an unexpected result is returned !
    }

    m_frame_index = (m_frame_index + 1) % k_max_frames_in_flight;

    m_render_pass_ptr->AfterPresent();
    m_imgui_pass.AfterPresent();

    Window::Tick(dt);
}
```

然后理解了

PresentInfoKHR 把 render_finished_semaphore 和 m_image_index 绑定

```cpp
vk::PresentInfoKHR present_info(*render_finished_semaphore, *m_swapchain_data.swap_chain, m_image_index);
```

image index 0 1 2 0

frame index 0 1 0 1