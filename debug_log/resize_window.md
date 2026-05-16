# 缩放窗口

## Couldn't find VkDescriptorSet Object

```
[MeowEngine][2024-11-13 09:42:58] Error: { Validation }:
        messageIDName   = <VUID-vkFreeDescriptorSets-pDescriptorSets-00310>
        messageIdNumber = 2094310106
        message         = <Validation Error: [ VUID-vkFreeDescriptorSets-pDescriptorSets-00310 ] Object 0: handle = 0x5ef3070000000063, type = VK_OBJECT_TYPE_DESCRIPTOR_SET; | MessageID = 0x7cd4a2da | vkFreeDescriptorSets(): pDescriptorSets[0] 
Invalid VkDescriptorSet 0x5ef3070000000063[]. The Vulkan spec states: pDescriptorSets must be a valid pointer to an array of descriptorSetCount VkDescriptorSet handles, each element of which must either be a valid handle or VK_NULL_HANDLE (https://vulkan.lunarg.com/doc/view/1.3.290.0/windows/1.3-extensions/vkspec.html#VUID-vkFreeDescriptorSets-pDescriptorSets-00310)>
        Objects:
                Object 0
                        objectType   = DescriptorSet
                        objectHandle = 6841819955487309923

[MeowEngine][2024-11-13 09:42:58] Error: { Validation }:
        messageIDName   = <UNASSIGNED-Threading-Info>
        messageIdNumber = 1567320034
        message         = <Validation Error: [ UNASSIGNED-Threading-Info ] Object 0: handle = 0x5ef3070000000063, type = VK_OBJECT_TYPE_DESCRIPTOR_SET; | MessageID = 0x5d6b67e2 | vkFreeDescriptorSets():  Couldn't find VkDescriptorSet Object 0x5ef3070000000063. This should not happen and may indicate a bug in the application.>
        Objects:
                Object 0
                        objectType   = DescriptorSet
                        objectHandle = 6841819955487309923
```

报错在

```cpp
    void ImGuiPass::RefreshOffscreenRenderTarget(VkSampler     offscreen_image_sampler,
                                                 VkImageView   offscreen_image_view,
                                                 VkImageLayout offscreen_image_layout)
    {
        ImGui_ImplVulkan_RemoveTexture(m_offscreen_image_desc);
        m_offscreen_image_desc =
            ImGui_ImplVulkan_AddTexture(offscreen_image_sampler, offscreen_image_view, offscreen_image_layout);
    }
```

`Remove` 的时候出了问题

于是发现是我的 image 就是 raii 的，所以不用显式
