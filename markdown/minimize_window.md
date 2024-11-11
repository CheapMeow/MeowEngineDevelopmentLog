## Vulkan 窗口最小化时 present outdataKHR 报错的问题

看了 [https://github.com/KhronosGroup/Vulkan-Hpp/issues/599](https://github.com/KhronosGroup/Vulkan-Hpp/issues/599)

使用了别人的包装

```cpp
/**
 * @brief vk::raii::SwapchainKHR::acquireNextImageKHR without exceptions
 */
std::pair<vk::Result, uint32_t> SwapchainNextImageWrapper(const vk::raii::SwapchainKHR &swapchain,
                                                          uint64_t timeout, vk::Semaphore semaphore,
                                                          vk::Fence fence) {
  uint32_t image_index;
  vk::Result result = static_cast<vk::Result>(swapchain.getDispatcher()->vkAcquireNextImageKHR(
      static_cast<VkDevice>(swapchain.getDevice()), static_cast<VkSwapchainKHR>(*swapchain),
      timeout, static_cast<VkSemaphore>(semaphore), static_cast<VkFence>(fence), &image_index));
  return std::make_pair(result, image_index);
}

/**
 * @brief vk::raii::Queue::presentKHR without exceptions
 */
vk::Result QueuePresentWrapper(const vk::raii::Queue &queue,
                               const vk::PresentInfoKHR &present_info) {
  return static_cast<vk::Result>(queue.getDispatcher()->vkQueuePresentKHR(
      static_cast<VkQueue>(*queue), reinterpret_cast<const VkPresentInfoKHR *>(&present_info)));
}
```

果然没有报错了

看一下 raii 原来是怎么包装的……

```cpp
VULKAN_HPP_NODISCARD VULKAN_HPP_INLINE std::pair<VULKAN_HPP_NAMESPACE::Result, uint32_t>
    SwapchainKHR::acquireNextImage( uint64_t timeout, VULKAN_HPP_NAMESPACE::Semaphore semaphore, VULKAN_HPP_NAMESPACE::Fence fence ) const
{
    VULKAN_HPP_ASSERT( getDispatcher()->vkAcquireNextImageKHR && "Function <vkAcquireNextImageKHR> requires <VK_KHR_swapchain>" );

    uint32_t                     imageIndex;
    VULKAN_HPP_NAMESPACE::Result result =
    static_cast<VULKAN_HPP_NAMESPACE::Result>( getDispatcher()->vkAcquireNextImageKHR( static_cast<VkDevice>( m_device ),
                                                                                        static_cast<VkSwapchainKHR>( m_swapchain ),
                                                                                        timeout,
                                                                                        static_cast<VkSemaphore>( semaphore ),
                                                                                        static_cast<VkFence>( fence ),
                                                                                        &imageIndex ) );
    resultCheck( result,
                VULKAN_HPP_NAMESPACE_STRING "::SwapchainKHR::acquireNextImage",
                { VULKAN_HPP_NAMESPACE::Result::eSuccess,
                    VULKAN_HPP_NAMESPACE::Result::eTimeout,
                    VULKAN_HPP_NAMESPACE::Result::eNotReady,
                    VULKAN_HPP_NAMESPACE::Result::eSuboptimalKHR } );

    return std::make_pair( static_cast<VULKAN_HPP_NAMESPACE::Result>( result ), imageIndex );
}
```

原来是因为他这里有一个 `resultCheck` 会抛出异常

为什么要这么做呢……不懂

好吧，回到应用，现在没有报错了，但是

```
VUID-VkSwapchainCreateInfoKHR-imageExtent-01689(ERROR / SPEC): msgNum: 320081257 - Validation Error: [ VUID-VkSwapchainCreateInfoKHR-imageExtent-01689 ] | MessageID = 0x13140d69 | vkCreateSwapchainKHR(): pCreateInfo->imageExtent width (0) and height (0) is invalid. The Vulkan spec states: imageExtent members width and height must both be non-zero (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkSwapchainCreateInfoKHR-imageExtent-01689)
    Objects: 0
VUID-VkImageCreateInfo-extent-00944(ERROR / SPEC): msgNum: -2006328824 - Validation Error: [ VUID-VkImageCreateInfo-extent-00944 ] | MessageID = 0x8869da08 | vkCreateImage(): pCreateInfo->extent.width is zero. The Vulkan spec states: extent.width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageCreateInfo-extent-00944)
    Objects: 0
VUID-VkImageCreateInfo-extent-00945(ERROR / SPEC): msgNum: -357987028 - Validation Error: [ VUID-VkImageCreateInfo-extent-00945 ] | MessageID = 0xeaa98d2c | vkCreateImage(): pCreateInfo->extent.height is zero. The Vulkan spec states: extent.height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageCreateInfo-extent-00945)
    Objects: 0
VUID-VkImageCreateInfo-extent-00944(ERROR / SPEC): msgNum: -2006328824 - Validation Error: [ VUID-VkImageCreateInfo-extent-00944 ] | MessageID = 0x8869da08 | vkCreateImage(): pCreateInfo->extent.width is zero. The Vulkan spec states: extent.width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageCreateInfo-extent-00944)
    Objects: 0
VUID-VkImageCreateInfo-extent-00945(ERROR / SPEC): msgNum: -357987028 - Validation Error: [ VUID-VkImageCreateInfo-extent-00945 ] | MessageID = 0xeaa98d2c | vkCreateImage(): pCreateInfo->extent.height is zero. The Vulkan spec states: extent.height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageCreateInfo-extent-00945)
    Objects: 0
VUID-VkImageCreateInfo-extent-00944(ERROR / SPEC): msgNum: -2006328824 - Validation Error: [ VUID-VkImageCreateInfo-extent-00944 ] | MessageID = 0x8869da08 | vkCreateImage(): pCreateInfo->extent.width is zero. The Vulkan spec states: extent.width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageCreateInfo-extent-00944)
    Objects: 0
VUID-VkImageCreateInfo-extent-00945(ERROR / SPEC): msgNum: -357987028 - Validation Error: [ VUID-VkImageCreateInfo-extent-00945 ] | MessageID = 0xeaa98d2c | vkCreateImage(): pCreateInfo->extent.height is zero. The Vulkan spec states: extent.height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageCreateInfo-extent-00945)
    Objects: 0
VUID-VkImageCreateInfo-extent-00944(ERROR / SPEC): msgNum: -2006328824 - Validation Error: [ VUID-VkImageCreateInfo-extent-00944 ] | MessageID = 0x8869da08 | vkCreateImage(): pCreateInfo->extent.width is zero. The Vulkan spec states: extent.width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageCreateInfo-extent-00944)
    Objects: 0
VUID-VkImageCreateInfo-extent-00945(ERROR / SPEC): msgNum: -357987028 - Validation Error: [ VUID-VkImageCreateInfo-extent-00945 ] | MessageID = 0xeaa98d2c | vkCreateImage(): pCreateInfo->extent.height is zero. The Vulkan spec states: extent.height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageCreateInfo-extent-00945)
    Objects: 0
VUID-VkFramebufferCreateInfo-width-00885(ERROR / SPEC): msgNum: -1231547098 - Validation Error: [ VUID-VkFramebufferCreateInfo-width-00885 ] | MessageID = 0xb6981526 | vkCreateFramebuffer(): pCreateInfo->width is zero. The Vulkan spec states: width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-width-00885)
    Objects: 0
VUID-VkFramebufferCreateInfo-height-00887(ERROR / SPEC): msgNum: -1513456701 - Validation Error: [ VUID-VkFramebufferCreateInfo-height-00887 ] | MessageID = 0xa5ca7bc3 | vkCreateFramebuffer(): pCreateInfo->height is zero. The Vulkan spec states: height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-height-00887)
    Objects: 0
VUID-VkFramebufferCreateInfo-width-00885(ERROR / SPEC): msgNum: -1231547098 - Validation Error: [ VUID-VkFramebufferCreateInfo-width-00885 ] | MessageID = 0xb6981526 | vkCreateFramebuffer(): pCreateInfo->width is zero. The Vulkan spec states: width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-width-00885)
    Objects: 0
VUID-VkFramebufferCreateInfo-height-00887(ERROR / SPEC): msgNum: -1513456701 - Validation Error: [ VUID-VkFramebufferCreateInfo-height-00887 ] | MessageID = 0xa5ca7bc3 | vkCreateFramebuffer(): pCreateInfo->height is zero. The Vulkan spec states: height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-height-00887)
    Objects: 0
VUID-VkFramebufferCreateInfo-width-00885(ERROR / SPEC): msgNum: -1231547098 - Validation Error: [ VUID-VkFramebufferCreateInfo-width-00885 ] | MessageID = 0xb6981526 | vkCreateFramebuffer(): pCreateInfo->width is zero. The Vulkan spec states: width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-width-00885)
    Objects: 0
VUID-VkFramebufferCreateInfo-height-00887(ERROR / SPEC): msgNum: -1513456701 - Validation Error: [ VUID-VkFramebufferCreateInfo-height-00887 ] | MessageID = 0xa5ca7bc3 | vkCreateFramebuffer(): pCreateInfo->height is zero. The Vulkan spec states: height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-height-00887)
    Objects: 0
VUID-VkImageCreateInfo-extent-00944(ERROR / SPEC): msgNum: -2006328824 - Validation Error: [ VUID-VkImageCreateInfo-extent-00944 ] | MessageID = 0x8869da08 | vkCreateImage(): pCreateInfo->extent.width is zero. The Vulkan spec states: extent.width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageCreateInfo-extent-00944)
    Objects: 0
VUID-VkImageCreateInfo-extent-00945(ERROR / SPEC): msgNum: -357987028 - Validation Error: [ VUID-VkImageCreateInfo-extent-00945 ] | MessageID = 0xeaa98d2c | vkCreateImage(): pCreateInfo->extent.height is zero. The Vulkan spec states: extent.height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageCreateInfo-extent-00945)
    Objects: 0
VUID-VkFramebufferCreateInfo-width-00885(ERROR / SPEC): msgNum: -1231547098 - Validation Error: [ VUID-VkFramebufferCreateInfo-width-00885 ] | MessageID = 0xb6981526 | vkCreateFramebuffer(): pCreateInfo->width is zero. The Vulkan spec states: width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-width-00885)
    Objects: 0
VUID-VkFramebufferCreateInfo-height-00887(ERROR / SPEC): msgNum: -1513456701 - Validation Error: [ VUID-VkFramebufferCreateInfo-height-00887 ] | MessageID = 0xa5ca7bc3 | vkCreateFramebuffer(): pCreateInfo->height is zero. The Vulkan spec states: height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-height-00887)
    Objects: 0
VUID-VkFramebufferCreateInfo-width-00885(ERROR / SPEC): msgNum: -1231547098 - Validation Error: [ VUID-VkFramebufferCreateInfo-width-00885 ] | MessageID = 0xb6981526 | vkCreateFramebuffer(): pCreateInfo->width is zero. The Vulkan spec states: width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-width-00885)
    Objects: 0
VUID-VkFramebufferCreateInfo-height-00887(ERROR / SPEC): msgNum: -1513456701 - Validation Error: [ VUID-VkFramebufferCreateInfo-height-00887 ] | MessageID = 0xa5ca7bc3 | vkCreateFramebuffer(): pCreateInfo->height is zero. The Vulkan spec states: height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-height-00887)
    Objects: 0
VUID-VkFramebufferCreateInfo-width-00885(ERROR / SPEC): msgNum: -1231547098 - Validation Error: [ VUID-VkFramebufferCreateInfo-width-00885 ] | MessageID = 0xb6981526 | vkCreateFramebuffer(): pCreateInfo->width is zero. The Vulkan spec states: width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-width-00885)
    Objects: 0
VUID-VkFramebufferCreateInfo-height-00887(ERROR / SPEC): msgNum: -1513456701 - Validation Error: [ VUID-VkFramebufferCreateInfo-height-00887 ] | MessageID = 0xa5ca7bc3 | vkCreateFramebuffer(): pCreateInfo->height is zero. The Vulkan spec states: height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-height-00887)
    Objects: 0
VUID-VkFramebufferCreateInfo-width-00885(ERROR / SPEC): msgNum: -1231547098 - Validation Error: [ VUID-VkFramebufferCreateInfo-width-00885 ] | MessageID = 0xb6981526 | vkCreateFramebuffer(): pCreateInfo->width is zero. The Vulkan spec states: width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-width-00885)
    Objects: 0
VUID-VkFramebufferCreateInfo-height-00887(ERROR / SPEC): msgNum: -1513456701 - Validation Error: [ VUID-VkFramebufferCreateInfo-height-00887 ] | MessageID = 0xa5ca7bc3 | vkCreateFramebuffer(): pCreateInfo->height is zero. The Vulkan spec states: height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-height-00887)
    Objects: 0
VUID-VkFramebufferCreateInfo-width-00885(ERROR / SPEC): msgNum: -1231547098 - Validation Error: [ VUID-VkFramebufferCreateInfo-width-00885 ] | MessageID = 0xb6981526 | vkCreateFramebuffer(): pCreateInfo->width is zero. The Vulkan spec states: width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-width-00885)
    Objects: 0
VUID-VkFramebufferCreateInfo-height-00887(ERROR / SPEC): msgNum: -1513456701 - Validation Error: [ VUID-VkFramebufferCreateInfo-height-00887 ] | MessageID = 0xa5ca7bc3 | vkCreateFramebuffer(): pCreateInfo->height is zero. The Vulkan spec states: height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-height-00887)
    Objects: 0
VUID-VkFramebufferCreateInfo-width-00885(ERROR / SPEC): msgNum: -1231547098 - Validation Error: [ VUID-VkFramebufferCreateInfo-width-00885 ] | MessageID = 0xb6981526 | vkCreateFramebuffer(): pCreateInfo->width is zero. The Vulkan spec states: width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-width-00885)
    Objects: 0
VUID-VkFramebufferCreateInfo-height-00887(ERROR / SPEC): msgNum: -1513456701 - Validation Error: [ VUID-VkFramebufferCreateInfo-height-00887 ] | MessageID = 0xa5ca7bc3 | vkCreateFramebuffer(): pCreateInfo->height is zero. The Vulkan spec states: height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-height-00887)
    Objects: 0
VUID-VkViewport-width-01770(ERROR / SPEC): msgNum: -1542042715 - Validation Error: [ VUID-VkViewport-width-01770 ] Object 0: handle = 0x26d79f27600, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0xa4164ba5 | vkCmdSetViewport(): pViewports[0].width (0.000000) is not greater than 0.0. The Vulkan spec states: width must be greater than 0.0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkViewport-width-01770)
    Objects: 1
        [0] 0x26d79f27600, type: 6, name: NULL
VUID-VkRenderPassBeginInfo-None-08996(ERROR / SPEC): msgNum: 1495210966 - Validation Error: [ VUID-VkRenderPassBeginInfo-None-08996 ] Object 0: handle = 0x26d79f27600, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0x591f1bd6 | vkCmdBeginRenderPass(): pRenderPassBegin->renderArea.extent.width is zero. The Vulkan spec states: If the pNext chain does not contain VkDeviceGroupRenderPassBeginInfo or its deviceRenderAreaCount member is equal to 0, renderArea.extent.width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkRenderPassBeginInfo-None-08996)
    Objects: 1
        [0] 0x26d79f27600, type: 6, name: NULL
VUID-VkRenderPassBeginInfo-None-08996(ERROR / SPEC): msgNum: 1495210966 - Validation Error: [ VUID-VkRenderPassBeginInfo-None-08996 ] Object 0: handle = 0x26d79f27600, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0x591f1bd6 | vkCmdBeginRenderPass(): pRenderPassBegin->renderArea.extent.width is zero. The Vulkan spec states: If the pNext chain does not contain VkDeviceGroupRenderPassBeginInfo or its deviceRenderAreaCount member is equal to 0, renderArea.extent.width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkRenderPassBeginInfo-None-08996)
    Objects: 1
        [0] 0x26d79f27600, type: 6, name: NULL
VUID-VkViewport-width-01770(ERROR / SPEC): msgNum: -1542042715 - Validation Error: [ VUID-VkViewport-width-01770 ] Object 0: handle = 0x26d7922ced0, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0xa4164ba5 | vkCmdSetViewport(): pViewports[0].width (0.000000) is not greater than 0.0. The Vulkan spec states: width must be greater than 0.0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkViewport-width-01770)
    Objects: 1
        [0] 0x26d7922ced0, type: 6, name: NULL
VUID-VkRenderPassBeginInfo-None-08996(ERROR / SPEC): msgNum: 1495210966 - Validation Error: [ VUID-VkRenderPassBeginInfo-None-08996 ] Object 0: handle = 0x26d7922ced0, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0x591f1bd6 | vkCmdBeginRenderPass(): pRenderPassBegin->renderArea.extent.width is zero. The Vulkan spec states: If the pNext chain does not contain VkDeviceGroupRenderPassBeginInfo or its deviceRenderAreaCount member is equal to 0, renderArea.extent.width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkRenderPassBeginInfo-None-08996)
    Objects: 1
        [0] 0x26d7922ced0, type: 6, name: NULL
VUID-VkRenderPassBeginInfo-None-08996(ERROR / SPEC): msgNum: 1495210966 - Validation Error: [ VUID-VkRenderPassBeginInfo-None-08996 ] Object 0: handle = 0x26d7922ced0, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0x591f1bd6 | vkCmdBeginRenderPass(): pRenderPassBegin->renderArea.extent.width is zero. The Vulkan spec states: If the pNext chain does not contain VkDeviceGroupRenderPassBeginInfo or its deviceRenderAreaCount member is equal to 0, renderArea.extent.width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkRenderPassBeginInfo-None-08996)
    Objects: 1
        [0] 0x26d7922ced0, type: 6, name: NULL
VUID-VkViewport-width-01770(ERROR / SPEC): msgNum: -1542042715 - Validation Error: [ VUID-VkViewport-width-01770 ] Object 0: handle = 0x26d79f27600, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0xa4164ba5 | vkCmdSetViewport(): pViewports[0].width (0.000000) is not greater than 0.0. The Vulkan spec states: width must be greater than 0.0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkViewport-width-01770)
    Objects: 1
        [0] 0x26d79f27600, type: 6, name: NULL
VUID-VkRenderPassBeginInfo-None-08996(ERROR / SPEC): msgNum: 1495210966 - Validation Error: [ VUID-VkRenderPassBeginInfo-None-08996 ] Object 0: handle = 0x26d79f27600, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0x591f1bd6 | vkCmdBeginRenderPass(): pRenderPassBegin->renderArea.extent.width is zero. The Vulkan spec states: If the pNext chain does not contain VkDeviceGroupRenderPassBeginInfo or its deviceRenderAreaCount member is equal to 0, renderArea.extent.width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkRenderPassBeginInfo-None-08996)
    Objects: 1
        [0] 0x26d79f27600, type: 6, name: NULL
VUID-VkRenderPassBeginInfo-None-08996(ERROR / SPEC): msgNum: 1495210966 - Validation Error: [ VUID-VkRenderPassBeginInfo-None-08996 ] Object 0: handle = 0x26d79f27600, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0x591f1bd6 | vkCmdBeginRenderPass(): pRenderPassBegin->renderArea.extent.width is zero. The Vulkan spec states: If the pNext chain does not contain VkDeviceGroupRenderPassBeginInfo or its deviceRenderAreaCount member is equal to 0, renderArea.extent.width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkRenderPassBeginInfo-None-08996)
    Objects: 1
        [0] 0x26d79f27600, type: 6, name: NULL
VUID-VkViewport-width-01770(ERROR / SPEC): msgNum: -1542042715 - Validation Error: [ VUID-VkViewport-width-01770 ] Object 0: handle = 0x26d7922ced0, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0xa4164ba5 | vkCmdSetViewport(): pViewports[0].width (0.000000) is not greater than 0.0. The Vulkan spec states: width must be greater than 0.0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkViewport-width-01770)
    Objects: 1
        [0] 0x26d7922ced0, type: 6, name: NULL
VUID-VkRenderPassBeginInfo-None-08996(ERROR / SPEC): msgNum: 1495210966 - Validation Error: [ VUID-VkRenderPassBeginInfo-None-08996 ] Object 0: handle = 0x26d7922ced0, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0x591f1bd6 | vkCmdBeginRenderPass(): pRenderPassBegin->renderArea.extent.width is zero. The Vulkan spec states: If the pNext chain does not contain VkDeviceGroupRenderPassBeginInfo or its deviceRenderAreaCount member is equal to 0, renderArea.extent.width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkRenderPassBeginInfo-None-08996)
    Objects: 1
        [0] 0x26d7922ced0, type: 6, name: NULL
VUID-VkRenderPassBeginInfo-None-08996(ERROR / SPEC): msgNum: 1495210966 - Validation Error: [ VUID-VkRenderPassBeginInfo-None-08996 ] Object 0: handle = 0x26d7922ced0, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0x591f1bd6 | vkCmdBeginRenderPass(): pRenderPassBegin->renderArea.extent.width is zero. The Vulkan spec states: If the pNext chain does not contain VkDeviceGroupRenderPassBeginInfo or its deviceRenderAreaCount member is equal to 0, renderArea.extent.width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkRenderPassBeginInfo-None-08996)
    Objects: 1
        [0] 0x26d7922ced0, type: 6, name: NULL
VUID-VkViewport-width-01770(ERROR / SPEC): msgNum: -1542042715 - Validation Error: [ VUID-VkViewport-width-01770 ] Object 0: handle = 0x26d79f27600, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0xa4164ba5 | vkCmdSetViewport(): pViewports[0].width (0.000000) is not greater than 0.0. The Vulkan spec states: width must be greater than 0.0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkViewport-width-01770)
    Objects: 1
        [0] 0x26d79f27600, type: 6, name: NULL
VUID-VkRenderPassBeginInfo-None-08996(ERROR / SPEC): msgNum: 1495210966 - Validation Error: [ VUID-VkRenderPassBeginInfo-None-08996 ] Object 0: handle = 0x26d79f27600, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0x591f1bd6 | vkCmdBeginRenderPass(): pRenderPassBegin->renderArea.extent.width is zero. The Vulkan spec states: If the pNext chain does not contain VkDeviceGroupRenderPassBeginInfo or its deviceRenderAreaCount member is equal to 0, renderArea.extent.width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkRenderPassBeginInfo-None-08996)
    Objects: 1
        [0] 0x26d79f27600, type: 6, name: NULL
VUID-VkRenderPassBeginInfo-None-08996(ERROR / SPEC): msgNum: 1495210966 - Validation Error: [ VUID-VkRenderPassBeginInfo-None-08996 ] Object 0: handle = 0x26d79f27600, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0x591f1bd6 | vkCmdBeginRenderPass(): pRenderPassBegin->renderArea.extent.width is zero. The Vulkan spec states: If the pNext chain does not contain VkDeviceGroupRenderPassBeginInfo or its deviceRenderAreaCount member is equal to 0, renderArea.extent.width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkRenderPassBeginInfo-None-08996)
    Objects: 1
        [0] 0x26d79f27600, type: 6, name: NULL
VUID-VkViewport-width-01770(ERROR / SPEC): msgNum: -1542042715 - Validation Error: [ VUID-VkViewport-width-01770 ] Object 0: handle = 0x26d7922ced0, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0xa4164ba5 | vkCmdSetViewport(): pViewports[0].width (0.000000) is not greater than 0.0. The Vulkan spec states: width must be greater than 0.0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkViewport-width-01770)
    Objects: 1
        [0] 0x26d7922ced0, type: 6, name: NULL
VUID-VkViewport-width-01770(ERROR / SPEC): msgNum: -1542042715 - Validation Error: [ VUID-VkViewport-width-01770 ] Object 0: handle = 0x26d79f27600, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0xa4164ba5 | vkCmdSetViewport(): pViewports[0].width (0.000000) is not greater than 0.0. The Vulkan spec states: width must be greater than 0.0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkViewport-width-01770)
    Objects: 1
        [0] 0x26d79f27600, type: 6, name: NULL
VUID-VkViewport-width-01770(ERROR / SPEC): msgNum: -1542042715 - Validation Error: [ VUID-VkViewport-width-01770 ] Object 0: handle = 0x26d7922ced0, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0xa4164ba5 | vkCmdSetViewport(): pViewports[0].width (0.000000) is not greater than 0.0. The Vulkan spec states: width must be greater than 0.0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkViewport-width-01770)
    Objects: 1
        [0] 0x26d7922ced0, type: 6, name: NULL
VUID-VkViewport-width-01770(ERROR / SPEC): msgNum: -1542042715 - Validation Error: [ VUID-VkViewport-width-01770 ] Object 0: handle = 0x26d79f27600, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0xa4164ba5 | vkCmdSetViewport(): pViewports[0].width (0.000000) is not greater than 0.0. The Vulkan spec states: width must be greater than 0.0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkViewport-width-01770)
    Objects: 1
        [0] 0x26d79f27600, type: 6, name: NULL
VUID-VkViewport-width-01770(ERROR / SPEC): msgNum: -1542042715 - Validation Error: [ VUID-VkViewport-width-01770 ] Object 0: handle = 0x26d7922ced0, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0xa4164ba5 | vkCmdSetViewport(): pViewports[0].width (0.000000) is not greater than 0.0. The Vulkan spec states: width must be greater than 0.0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkViewport-width-01770)
    Objects: 1
        [0] 0x26d7922ced0, type: 6, name: NULL
```

会提示 viewport 宽高不能为 0

于是加一个条件判断

```cpp
if (m_surface_data.extent.height == 0 || m_surface_data.extent.width == 0)
    return;
```

但是还是有这个问题！

于是添加 debug

```cpp
    void RenderSystem::Tick(float dt)
    {
        FUNCTION_TIMER();

        if (m_surface_data.extent.height == 0 || m_surface_data.extent.width == 0)
            return;

        auto& per_frame_data            = m_per_frame_data[m_current_frame_index];
        auto& cmd_buffer                = per_frame_data.command_buffer;
        auto& image_acquired_semaphore  = per_frame_data.image_acquired_semaphore;
        auto& render_finished_semaphore = per_frame_data.render_finished_semaphore;
        auto& in_flight_fence           = per_frame_data.in_flight_fence;

        m_render_pass_ptr->UpdateUniformBuffer();

        // ------------------- render -------------------

        auto [result, m_current_image_index] =
            SwapchainNextImageWrapper(m_swapchain_data.swap_chain, k_fence_timeout, *image_acquired_semaphore);
        if (result == vk::Result::eErrorOutOfDateKHR || result == vk::Result::eSuboptimalKHR || m_framebuffer_resized)
        {
            m_framebuffer_resized = false;
            RecreateSwapChain();
            return;
        }
        assert(result == vk::Result::eSuccess);
        assert(m_current_image_index < m_swapchain_data.images.size());

        if (m_surface_data.extent.height == 0 || m_surface_data.extent.width == 0)
            std::cout << "WTF!!!!!!!!!!" << std::endl;
        cmd_buffer.begin({});
        cmd_buffer.setViewport(0,
                               vk::Viewport(0.0f,
                                            static_cast<float>(m_surface_data.extent.height),
                                            static_cast<float>(m_surface_data.extent.width),
                                            -static_cast<float>(m_surface_data.extent.height),
                                            0.0f,
                                            1.0f));
        cmd_buffer.setScissor(0, vk::Rect2D(vk::Offset2D(0, 0), m_surface_data.extent));
```

没有输出 WTF 所以不是 `cmd_buffer.setViewport` 的问题

于是我现在才发现，虽然都是不为 0 的报错，但是内容不一样

```
VUID-VkSwapchainCreateInfoKHR-imageExtent-01689(ERROR / SPEC): msgNum: 320081257 - Validation Error: [ VUID-VkSwapchainCreateInfoKHR-imageExtent-01689 ] | MessageID = 0x13140d69 | vkCreateSwapchainKHR(): pCreateInfo->imageExtent width (0) and height (0) is invalid. The Vulkan spec states: imageExtent members width and height must both be non-zero (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkSwapchainCreateInfoKHR-imageExtent-01689)
    Objects: 0
VUID-VkImageCreateInfo-extent-00944(ERROR / SPEC): msgNum: -2006328824 - Validation Error: [ VUID-VkImageCreateInfo-extent-00944 ] | MessageID = 0x8869da08 | vkCreateImage(): pCreateInfo->extent.width is zero. The Vulkan spec states: extent.width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageCreateInfo-extent-00944)
    Objects: 0
VUID-VkImageCreateInfo-extent-00945(ERROR / SPEC): msgNum: -357987028 - Validation Error: [ VUID-VkImageCreateInfo-extent-00945 ] | MessageID = 0xeaa98d2c | vkCreateImage(): pCreateInfo->extent.height is zero. The Vulkan spec states: extent.height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageCreateInfo-extent-00945)
    Objects: 0
VUID-VkImageCreateInfo-extent-00944(ERROR / SPEC): msgNum: -2006328824 - Validation Error: [ VUID-VkImageCreateInfo-extent-00944 ] | MessageID = 0x8869da08 | vkCreateImage(): pCreateInfo->extent.width is zero. The Vulkan spec states: extent.width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageCreateInfo-extent-00944)
    Objects: 0
VUID-VkImageCreateInfo-extent-00945(ERROR / SPEC): msgNum: -357987028 - Validation Error: [ VUID-VkImageCreateInfo-extent-00945 ] | MessageID = 0xeaa98d2c | vkCreateImage(): pCreateInfo->extent.height is zero. The Vulkan spec states: extent.height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageCreateInfo-extent-00945)
    Objects: 0
VUID-VkImageCreateInfo-extent-00944(ERROR / SPEC): msgNum: -2006328824 - Validation Error: [ VUID-VkImageCreateInfo-extent-00944 ] | MessageID = 0x8869da08 | vkCreateImage(): pCreateInfo->extent.width is zero. The Vulkan spec states: extent.width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageCreateInfo-extent-00944)
    Objects: 0
VUID-VkImageCreateInfo-extent-00945(ERROR / SPEC): msgNum: -357987028 - Validation Error: [ VUID-VkImageCreateInfo-extent-00945 ] | MessageID = 0xeaa98d2c | vkCreateImage(): pCreateInfo->extent.height is zero. The Vulkan spec states: extent.height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageCreateInfo-extent-00945)
    Objects: 0
VUID-VkImageCreateInfo-extent-00944(ERROR / SPEC): msgNum: -2006328824 - Validation Error: [ VUID-VkImageCreateInfo-extent-00944 ] | MessageID = 0x8869da08 | vkCreateImage(): pCreateInfo->extent.width is zero. The Vulkan spec states: extent.width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageCreateInfo-extent-00944)
    Objects: 0
VUID-VkImageCreateInfo-extent-00945(ERROR / SPEC): msgNum: -357987028 - Validation Error: [ VUID-VkImageCreateInfo-extent-00945 ] | MessageID = 0xeaa98d2c | vkCreateImage(): pCreateInfo->extent.height is zero. The Vulkan spec states: extent.height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageCreateInfo-extent-00945)
    Objects: 0
VUID-VkFramebufferCreateInfo-width-00885(ERROR / SPEC): msgNum: -1231547098 - Validation Error: [ VUID-VkFramebufferCreateInfo-width-00885 ] | MessageID = 0xb6981526 | vkCreateFramebuffer(): pCreateInfo->width is zero. The Vulkan spec states: width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-width-00885)
    Objects: 0
VUID-VkFramebufferCreateInfo-height-00887(ERROR / SPEC): msgNum: -1513456701 - Validation Error: [ VUID-VkFramebufferCreateInfo-height-00887 ] | MessageID = 0xa5ca7bc3 | vkCreateFramebuffer(): pCreateInfo->height is zero. The Vulkan spec states: height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-height-00887)
    Objects: 0
VUID-VkFramebufferCreateInfo-width-00885(ERROR / SPEC): msgNum: -1231547098 - Validation Error: [ VUID-VkFramebufferCreateInfo-width-00885 ] | MessageID = 0xb6981526 | vkCreateFramebuffer(): pCreateInfo->width is zero. The Vulkan spec states: width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-width-00885)
    Objects: 0
VUID-VkFramebufferCreateInfo-height-00887(ERROR / SPEC): msgNum: -1513456701 - Validation Error: [ VUID-VkFramebufferCreateInfo-height-00887 ] | MessageID = 0xa5ca7bc3 | vkCreateFramebuffer(): pCreateInfo->height is zero. The Vulkan spec states: height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-height-00887)
    Objects: 0
VUID-VkFramebufferCreateInfo-width-00885(ERROR / SPEC): msgNum: -1231547098 - Validation Error: [ VUID-VkFramebufferCreateInfo-width-00885 ] | MessageID = 0xb6981526 | vkCreateFramebuffer(): pCreateInfo->width is zero. The Vulkan spec states: width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-width-00885)
    Objects: 0
VUID-VkFramebufferCreateInfo-height-00887(ERROR / SPEC): msgNum: -1513456701 - Validation Error: [ VUID-VkFramebufferCreateInfo-height-00887 ] | MessageID = 0xa5ca7bc3 | vkCreateFramebuffer(): pCreateInfo->height is zero. The Vulkan spec states: height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-height-00887)
    Objects: 0
VUID-VkImageCreateInfo-extent-00944(ERROR / SPEC): msgNum: -2006328824 - Validation Error: [ VUID-VkImageCreateInfo-extent-00944 ] | MessageID = 0x8869da08 | vkCreateImage(): pCreateInfo->extent.width is zero. The Vulkan spec states: extent.width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageCreateInfo-extent-00944)
    Objects: 0
VUID-VkImageCreateInfo-extent-00945(ERROR / SPEC): msgNum: -357987028 - Validation Error: [ VUID-VkImageCreateInfo-extent-00945 ] | MessageID = 0xeaa98d2c | vkCreateImage(): pCreateInfo->extent.height is zero. The Vulkan spec states: extent.height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageCreateInfo-extent-00945)
    Objects: 0
VUID-VkFramebufferCreateInfo-width-00885(ERROR / SPEC): msgNum: -1231547098 - Validation Error: [ VUID-VkFramebufferCreateInfo-width-00885 ] | MessageID = 0xb6981526 | vkCreateFramebuffer(): pCreateInfo->width is zero. The Vulkan spec states: width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-width-00885)
    Objects: 0
VUID-VkFramebufferCreateInfo-height-00887(ERROR / SPEC): msgNum: -1513456701 - Validation Error: [ VUID-VkFramebufferCreateInfo-height-00887 ] | MessageID = 0xa5ca7bc3 | vkCreateFramebuffer(): pCreateInfo->height is zero. The Vulkan spec states: height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-height-00887)
    Objects: 0
VUID-VkFramebufferCreateInfo-width-00885(ERROR / SPEC): msgNum: -1231547098 - Validation Error: [ VUID-VkFramebufferCreateInfo-width-00885 ] | MessageID = 0xb6981526 | vkCreateFramebuffer(): pCreateInfo->width is zero. The Vulkan spec states: width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-width-00885)
    Objects: 0
VUID-VkFramebufferCreateInfo-height-00887(ERROR / SPEC): msgNum: -1513456701 - Validation Error: [ VUID-VkFramebufferCreateInfo-height-00887 ] | MessageID = 0xa5ca7bc3 | vkCreateFramebuffer(): pCreateInfo->height is zero. The Vulkan spec states: height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-height-00887)
    Objects: 0
VUID-VkFramebufferCreateInfo-width-00885(ERROR / SPEC): msgNum: -1231547098 - Validation Error: [ VUID-VkFramebufferCreateInfo-width-00885 ] | MessageID = 0xb6981526 | vkCreateFramebuffer(): pCreateInfo->width is zero. The Vulkan spec states: width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-width-00885)
    Objects: 0
VUID-VkFramebufferCreateInfo-height-00887(ERROR / SPEC): msgNum: -1513456701 - Validation Error: [ VUID-VkFramebufferCreateInfo-height-00887 ] | MessageID = 0xa5ca7bc3 | vkCreateFramebuffer(): pCreateInfo->height is zero. The Vulkan spec states: height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-height-00887)
    Objects: 0
VUID-VkFramebufferCreateInfo-width-00885(ERROR / SPEC): msgNum: -1231547098 - Validation Error: [ VUID-VkFramebufferCreateInfo-width-00885 ] | MessageID = 0xb6981526 | vkCreateFramebuffer(): pCreateInfo->width is zero. The Vulkan spec states: width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-width-00885)
    Objects: 0
VUID-VkFramebufferCreateInfo-height-00887(ERROR / SPEC): msgNum: -1513456701 - Validation Error: [ VUID-VkFramebufferCreateInfo-height-00887 ] | MessageID = 0xa5ca7bc3 | vkCreateFramebuffer(): pCreateInfo->height is zero. The Vulkan spec states: height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-height-00887)
    Objects: 0
VUID-VkFramebufferCreateInfo-width-00885(ERROR / SPEC): msgNum: -1231547098 - Validation Error: [ VUID-VkFramebufferCreateInfo-width-00885 ] | MessageID = 0xb6981526 | vkCreateFramebuffer(): pCreateInfo->width is zero. The Vulkan spec states: width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-width-00885)
    Objects: 0
VUID-VkFramebufferCreateInfo-height-00887(ERROR / SPEC): msgNum: -1513456701 - Validation Error: [ VUID-VkFramebufferCreateInfo-height-00887 ] | MessageID = 0xa5ca7bc3 | vkCreateFramebuffer(): pCreateInfo->height is zero. The Vulkan spec states: height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-height-00887)
    Objects: 0
VUID-VkFramebufferCreateInfo-width-00885(ERROR / SPEC): msgNum: -1231547098 - Validation Error: [ VUID-VkFramebufferCreateInfo-width-00885 ] | MessageID = 0xb6981526 | vkCreateFramebuffer(): pCreateInfo->width is zero. The Vulkan spec states: width must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-width-00885)
    Objects: 0
VUID-VkFramebufferCreateInfo-height-00887(ERROR / SPEC): msgNum: -1513456701 - Validation Error: [ VUID-VkFramebufferCreateInfo-height-00887 ] | MessageID = 0xa5ca7bc3 | vkCreateFramebuffer(): pCreateInfo->height is zero. The Vulkan spec states: height must be greater than 0 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-height-00887)
    Objects: 0
```

现在这个是 image create info 的错

于是发现这似乎是窗口最小化的问题

窗口最小化之后，仍然调用了 `RecreateSwapChain()` 所以就创建了为 0 的交换链图像

于是还是用 glfw 的窗口最小化通知来解决的