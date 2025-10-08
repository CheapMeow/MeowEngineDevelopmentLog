# frames in flight

## Material 的变量声明

本来是想

```cpp
using UniformBufferMap = std::unordered_map<std::string, std::unique_ptr<UniformBuffer>>;
```

然后搞个 vector<UniformBufferMap>

结果发现 resize 调用会导致模板报错

自己测试了一下

```cpp
#include <iostream>
#include <memory>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

int main()
{
    // Ok
    std::vector<std::unique_ptr<int>> test1;
    test1.resize(2);
    std::cout << "std::is_copy_constructible_v<std::unique_ptr<int>> : " << std::is_copy_constructible_v<std::unique_ptr<int>> << "\n";
    std::cout << "std::is_copy_assignable_v<std::unique_ptr<int>> : " << std::is_copy_assignable_v<std::unique_ptr<int>> << "\n";
    std::cout << "std::is_move_constructible_v<std::unique_ptr<int>> : " << std::is_move_constructible_v<std::unique_ptr<int>> << "\n";
    std::cout << "std::is_move_assignable_v<std::unique_ptr<int>> : " << std::is_move_assignable_v<std::unique_ptr<int>> << "\n";
    
    // Ok
    std::vector<std::vector<std::unique_ptr<int>>> test2;
    test2.reserve(2);
    std::cout << "\n";
    std::cout << "std::is_copy_constructible_v<std::vector<std::unique_ptr<int>>> : " << std::is_copy_constructible_v<std::vector<std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_copy_assignable_v<std::vector<std::unique_ptr<int>>> : " << std::is_copy_assignable_v<std::vector<std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_move_constructible_v<std::vector<std::unique_ptr<int>>> : " << std::is_move_constructible_v<std::vector<std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_move_assignable_v<std::vector<std::unique_ptr<int>>> : " << std::is_move_assignable_v<std::vector<std::unique_ptr<int>>> << "\n";
    
    // Ok
    std::vector<std::pair<std::string, std::unique_ptr<int>>> test3;
    test3.resize(2);
    std::cout << "\n";
    std::cout << "std::is_copy_constructible_v<std::pair<std::string, std::unique_ptr<int>>> : " << std::is_copy_constructible_v<std::pair<std::string, std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_copy_assignable_v<std::pair<std::string, std::unique_ptr<int>>> : " << std::is_copy_assignable_v<std::pair<std::string, std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_move_constructible_v<std::pair<std::string, std::unique_ptr<int>>> : " << std::is_move_constructible_v<std::pair<std::string, std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_move_assignable_v<std::pair<std::string, std::unique_ptr<int>>> : " << std::is_move_assignable_v<std::pair<std::string, std::unique_ptr<int>>> << "\n";
    
    // Ok
    std::vector<std::pair<const std::string, std::unique_ptr<int>>> test4;
    test4.resize(2);
    std::cout << "\n";
    std::cout << "std::is_copy_constructible_v<std::pair<const std::string, std::unique_ptr<int>>> : " << std::is_copy_constructible_v<std::pair<const std::string, std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_copy_assignable_v<std::pair<const std::string, std::unique_ptr<int>>> : " << std::is_copy_assignable_v<std::pair<const std::string, std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_move_constructible_v<std::pair<const std::string, std::unique_ptr<int>>> : " << std::is_move_constructible_v<std::pair<const std::string, std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_move_assignable_v<std::pair<const std::string, std::unique_ptr<int>>> : " << std::is_move_assignable_v<std::pair<const std::string, std::unique_ptr<int>>> << "\n";
    
    // Error
    // Error C2280 : “std::pair<const std::string,std::unique_ptr<int,std::default_delete<int>>>::
    // pair(const std::pair<const std::string,std::unique_ptr<int,std::default_delete<int>>> &)”: is deleted
    //std::vector<std::unordered_map<std::string, std::unique_ptr<int>>> test5;
    //test5.resize(2);
    std::cout << "\n";
    std::cout << "std::is_copy_constructible_v<std::unordered_map<std::string, std::unique_ptr<int>>> : " << std::is_copy_constructible_v<std::unordered_map<std::string, std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_copy_assignable_v<std::unordered_map<std::string, std::unique_ptr<int>>> : " << std::is_copy_assignable_v<std::unordered_map<std::string, std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_move_constructible_v<std::unordered_map<std::string, std::unique_ptr<int>>> : " << std::is_move_constructible_v<std::unordered_map<std::string, std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_move_assignable_v<std::unordered_map<std::string, std::unique_ptr<int>>> : " << std::is_move_assignable_v<std::unordered_map<std::string, std::unique_ptr<int>>> << "\n";
    
    return 0;
}
```

最后输出的 copyable movable 那些都是 1，居然还会模板报错？

问了大佬，说是

因为 vector::resize 要求元素类型 CopyInsertable

msvc 的 unordered_map 实现在 V 不能复制的时候不满足 CopyInsertable

并且标准允许这种实现

所以 vector 就不能 resize

这个是看 spec 看的，但是我……还不知道怎么看

## image 同步问题

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

所以改成了

```cpp
struct PerSwapChainImageData
{
    vk::raii::Semaphore image_acquired_semaphore  = nullptr;
    vk::raii::Semaphore render_finished_semaphore = nullptr;

    PerSwapChainImageData() {}

    PerSwapChainImageData(std::nullptr_t) {}
};
```

现在的 tick 是

```cpp
void EditorWindow::Tick(float dt)
{
    FUNCTION_TIMER();

    m_wait_until_next_tick_signal();
    m_wait_until_next_tick_signal.clear();

    if (m_iconified)
        return;

    const vk::raii::Device& logical_device             = g_runtime_context.render_system->GetLogicalDevice();
    const vk::raii::Queue&  graphics_queue             = g_runtime_context.render_system->GetGraphicsQueue();
    const vk::raii::Queue&  present_queue              = g_runtime_context.render_system->GetPresentQueue();
    const vk::raii::Queue&  compute_queue              = g_runtime_context.render_system->GetComputeQueue();
    auto&                   frame_data                 = m_per_frame_data[m_frame_index];
    auto&                   command_buffer             = frame_data.graphics_command_buffer;
    auto&                   image_data                 = m_per_image_data[m_image_semaphore_index];
    auto&                   present_finished_semaphore = image_data.present_finished_semaphore;
    auto&                   render_finished_semaphore  = image_data.render_finished_semaphore;
    auto&                   graphics_in_flight_fence   = frame_data.graphics_in_flight_fence;
    const auto              k_max_frames_in_flight     = g_runtime_context.render_system->GetMaxFramesInFlight();

    auto& compute_command_buffer     = frame_data.compute_command_buffer;
    auto& compute_finished_semaphore = frame_data.compute_finished_semaphore;
    auto& compute_in_flight_fence    = frame_data.compute_in_flight_fence;

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

    auto [result, image_index] =
        SwapchainNextImageWrapper(m_swapchain_data.swap_chain, k_fence_timeout, *present_finished_semaphore);
    if (result == vk::Result::eErrorOutOfDateKHR || result == vk::Result::eSuboptimalKHR || m_framebuffer_resized)
    {
        m_framebuffer_resized = false;
        RecreateSwapChain();
        return;
    }
    assert(result == vk::Result::eSuccess);
    assert(image_index < m_swapchain_data.images.size());

    command_buffer.reset();
    command_buffer.begin({});

    m_shadow_map_pass.Start(command_buffer, m_surface_data.extent, image_index);
    m_shadow_map_pass.RecordGraphicsCommand(command_buffer, m_frame_index);
    m_shadow_map_pass.End(command_buffer);

    m_depth_to_color_pass.Start(command_buffer, m_surface_data.extent, image_index);
    m_depth_to_color_pass.RecordGraphicsCommand(command_buffer, m_frame_index);
    m_depth_to_color_pass.End(command_buffer);

    m_shadow_coord_to_color_pass.Start(command_buffer, m_surface_data.extent, image_index);
    m_shadow_coord_to_color_pass.RecordGraphicsCommand(command_buffer, m_frame_index);
    m_shadow_coord_to_color_pass.End(command_buffer);

    m_render_pass_ptr->Start(command_buffer, m_surface_data.extent, image_index);
    m_render_pass_ptr->RecordGraphicsCommand(command_buffer, m_frame_index);
    m_render_pass_ptr->End(command_buffer);

    m_compute_particle_pass.Start(command_buffer, m_surface_data.extent, image_index);
    m_compute_particle_pass.RecordGraphicsCommand(command_buffer, m_frame_index);
    m_compute_particle_pass.End(command_buffer);

    m_imgui_pass.Start(command_buffer, m_surface_data.extent, image_index);
    m_imgui_pass.RecordGraphicsCommand(command_buffer, m_frame_index);
    m_imgui_pass.End(command_buffer);

    command_buffer.end();

    {
        std::array<const vk::PipelineStageFlags, 2> wait_destination_stage_masks {
            vk::PipelineStageFlagBits::eColorAttachmentOutput, vk::PipelineStageFlagBits::eVertexInput};
        std::array<const vk::Semaphore, 2> wait_semaphores {*present_finished_semaphore,
                                                            *compute_finished_semaphore};
        vk::SubmitInfo                     submit_info(
            wait_semaphores, wait_destination_stage_masks, *command_buffer, *render_finished_semaphore);
        graphics_queue.submit(submit_info, *graphics_in_flight_fence);
    }

    vk::PresentInfoKHR present_info(*render_finished_semaphore, *m_swapchain_data.swap_chain, image_index);
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

    m_frame_index           = (m_frame_index + 1) % k_max_frames_in_flight;
    m_image_semaphore_index = (m_image_semaphore_index + 1) % m_swapchain_image_number;

    m_render_pass_ptr->AfterPresent();
    m_imgui_pass.AfterPresent();

    Window::Tick(dt);
}

```

但是改完之后又出现新的问题，启动程序的时候没问题，关闭程序的时候报错，是销毁对象方面的错误

```
Validation Error: [ VUID-vkFreeMemory-memory-00677 ] | MessageID = 0x485c8ea2
vkFreeMemory(): can't be called on VkDeviceMemory 0x60000000006 that is currently in use by VkBuffer 0x50000000005.
The Vulkan spec states: All submitted commands that refer to memory (via images or buffers) must have completed execution (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/memory.html#VUID-vkFreeMemory-memory-00677)

Validation Error: [ VUID-vkFreeMemory-memory-00677 ] | MessageID = 0x485c8ea2
vkFreeMemory(): can't be called on VkDeviceMemory 0x80000000008 that is currently in use by VkBuffer 0x70000000007.
The Vulkan spec states: All submitted commands that refer to memory (via images or buffers) must have completed execution (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/memory.html#VUID-vkFreeMemory-memory-00677)

Validation Error: [ VUID-vkDestroyPipeline-pipeline-00765 ] | MessageID = 0x6bdce5fd
vkDestroyPipeline(): can't be called on VkPipeline 0xc000000000c[GPUParticleData2D compute material Pipeline 0] that is currently in use by VkCommandBuffer 0x19c54c1b9a0[PerFrameData compute command buffer 1].
The Vulkan spec states: All submitted commands that refer to pipeline must have completed execution (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/pipelines.html#VUID-vkDestroyPipeline-pipeline-00765)

Validation Error: [ VUID-vkFreeMemory-memory-00677 ] | MessageID = 0x485c8ea2
vkFreeMemory(): can't be called on VkDeviceMemory 0x25e000000025e that is currently in use by VkBuffer 0x25d000000025d.
The Vulkan spec states: All submitted commands that refer to memory (via images or buffers) must have completed execution (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/memory.html#VUID-vkFreeMemory-memory-00677)

Validation Error: [ VUID-vkFreeMemory-memory-00677 ] | MessageID = 0x485c8ea2
vkFreeMemory(): can't be called on VkDeviceMemory 0x2620000000262 that is currently in use by VkBuffer 0x2610000000261.
The Vulkan spec states: All submitted commands that refer to memory (via images or buffers) must have completed execution (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/memory.html#VUID-vkFreeMemory-memory-00677)

Validation Error: [ VUID-vkFreeMemory-memory-00677 ] | MessageID = 0x485c8ea2
vkFreeMemory(): can't be called on VkDeviceMemory 0x1fe00000001fe that is currently in use by VkBuffer 0x1fd00000001fd.
The Vulkan spec states: All submitted commands that refer to memory (via images or buffers) must have completed execution (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/memory.html#VUID-vkFreeMemory-memory-00677)

Validation Error: [ VUID-vkFreeMemory-memory-00677 ] | MessageID = 0x485c8ea2
vkFreeMemory(): can't be called on VkDeviceMemory 0x2020000000202 that is currently in use by VkBuffer 0x2010000000201.
The Vulkan spec states: All submitted commands that refer to memory (via images or buffers) must have completed execution (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/memory.html#VUID-vkFreeMemory-memory-00677)

Validation Error: [ VUID-vkFreeMemory-memory-00677 ] | MessageID = 0x485c8ea2
vkFreeMemory(): can't be called on VkDeviceMemory 0x1960000000196 that is currently in use by VkBuffer 0x1950000000195.
The Vulkan spec states: All submitted commands that refer to memory (via images or buffers) must have completed execution (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/memory.html#VUID-vkFreeMemory-memory-00677)

Validation Error: [ VUID-vkFreeMemory-memory-00677 ] | MessageID = 0x485c8ea2
vkFreeMemory(): can't be called on VkDeviceMemory 0x19a000000019a that is currently in use by VkBuffer 0x1990000000199.
The Vulkan spec states: All submitted commands that refer to memory (via images or buffers) must have completed execution (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/memory.html#VUID-vkFreeMemory-memory-00677)

Validation Error: [ VUID-vkDestroySampler-sampler-01082 ] | MessageID = 0xcca99934
vkDestroySampler(): sampler can't be called on VkSampler 0xea00000000ea that is currently in use by VkDescriptorSet 0xc300000000c3[Forward Opaque Material DescriptorSet 3 frame 0].
The Vulkan spec states: All submitted commands that refer to sampler must have completed execution (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/samplers.html#VUID-vkDestroySampler-sampler-01082)

Validation Error: [ VUID-vkFreeMemory-memory-00677 ] | MessageID = 0x485c8ea2
vkFreeMemory(): can't be called on VkDeviceMemory 0x4460000000446 that is currently in use by VkBuffer 0x4450000000445.
The Vulkan spec states: All submitted commands that refer to memory (via images or buffers) must have completed execution (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/memory.html#VUID-vkFreeMemory-memory-00677)

Validation Error: [ VUID-vkFreeMemory-memory-00677 ] | MessageID = 0x485c8ea2
(Warning - This VUID has now been reported 10 times, which is the duplicated_message_limit value, this will be the last time reporting it).
vkFreeMemory(): can't be called on VkDeviceMemory 0x44a000000044a that is currently in use by VkBuffer 0x4490000000449.
The Vulkan spec states: All submitted commands that refer to memory (via images or buffers) must have completed execution (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/memory.html#VUID-vkFreeMemory-memory-00677)

Validation Error: [ VUID-vkDestroySampler-sampler-01082 ] | MessageID = 0xcca99934
vkDestroySampler(): sampler can't be called on VkSampler 0xf600000000f6 that is currently in use by VkDescriptorSet 0xc100000000c1[Forward Opaque Material DescriptorSet 1 frame 0].
The Vulkan spec states: All submitted commands that refer to sampler must have completed execution (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/samplers.html#VUID-vkDestroySampler-sampler-01082)

Validation Error: [ VUID-vkDestroySampler-sampler-01082 ] | MessageID = 0xcca99934
vkDestroySampler(): sampler can't be called on VkSampler 0x10b000000010b that is currently in use by VkDescriptorSet 0x1040000000104[Forward Skybox Material DescriptorSet 1 frame 0].
The Vulkan spec states: All submitted commands that refer to sampler must have completed execution (https://vulkan.lunarg.com/doc/view/1.4.321.1/windows/antora/spec/latest/chapters/samplers.html#VUID-vkDestroySampler-sampler-01082)

```

不过后续用 wait idle 在所有析构之前调用来解决的

应该是粒子系统这边有些 vk 结构体析构导致了问题