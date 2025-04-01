# Shadow Map

## Debug

```
VUID-VkFramebufferCreateInfo-attachmentCount-00876(ERROR / SPEC): msgNum: -732776389 - Validation Error: [ VUID-VkFramebufferCreateInfo-attachmentCount-00876 ] Object 0: handle = 0xd10d270000000018, name = Shadow Map RenderPass, type = VK_OBJECT_TYPE_RENDER_PASS; | MessageID = 0xd452b83b | vkCreateFramebuffer(): pCreateInfo->attachmentCount 2 does not match attachmentCount of 1 of VkRenderPass 0xd10d270000000018[Shadow Map RenderPass] being used to create Framebuffer. The Vulkan spec states: attachmentCount must be equal to the attachment count specified in renderPass (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkFramebufferCreateInfo-attachmentCount-00876)
    Objects: 1
        [0] 0xd10d270000000018, type: 18, name: Shadow Map RenderPass
```

framebuffer 那边填错了

```
VUID-vkCmdResetQueryPool-renderpass(ERROR / SPEC): msgNum: -1332528324 - Validation Error: [ VUID-vkCmdResetQueryPool-renderpass ] Object 0: handle = 0x228bf59bd30, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0xb0933b3c | vkCmdResetQueryPool():  It is invalid to issue this call inside an active VkRenderPass 0xd10d270000000018[Shadow Map RenderPass]. The Vulkan spec states: This command must only be called outside of a render pass instance (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdResetQueryPool-renderpass)
    Objects: 1
        [0] 0x228bf59bd30, type: 6, name: NULL
VUID-vkCmdBeginRenderPass-renderpass(ERROR / SPEC): msgNum: 339535253 - Validation Error: [ VUID-vkCmdBeginRenderPass-renderpass ] Object 0: handle = 0x228bf59bd30, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0x143ce595 | vkCmdBeginRenderPass():  It is invalid to issue this call inside an active VkRenderPass 0xd10d270000000018[Shadow Map RenderPass]. The Vulkan spec states: This command must only be called outside of a render pass instance (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdBeginRenderPass-renderpass)
    Objects: 1
        [0] 0x228bf59bd30, type: 6, name: NULL
VUID-vkCmdResetQueryPool-renderpass(ERROR / SPEC): msgNum: -1332528324 - Validation Error: [ VUID-vkCmdResetQueryPool-renderpass ] Object 0: handle = 0x228bf5a8330, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0xb0933b3c | vkCmdResetQueryPool():  It is invalid to issue this call inside an active VkRenderPass 0xd10d270000000018[Shadow Map RenderPass]. The Vulkan spec states: This command must only be called outside of a render pass instance (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdResetQueryPool-renderpass)
    Objects: 1
        [0] 0x228bf5a8330, type: 6, name: NULL
VUID-vkCmdBeginRenderPass-renderpass(ERROR / SPEC): msgNum: 339535253 - Validation Error: [ VUID-vkCmdBeginRenderPass-renderpass ] Object 0: handle = 0x228bf5a8330, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0x143ce595 | vkCmdBeginRenderPass():  It is invalid to issue this call inside an active VkRenderPass 0xd10d270000000018[Shadow Map RenderPass]. The Vulkan spec states: This command must only be called outside of a render pass instance (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdBeginRenderPass-renderpass)
    Objects: 1
        [0] 0x228bf5a8330, type: 6, name: NULL
VUID-vkCmdResetQueryPool-renderpass(ERROR / SPEC): msgNum: -1332528324 - Validation Error: [ VUID-vkCmdResetQueryPool-renderpass ] Object 0: handle = 0x228bf59bd30, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0xb0933b3c | vkCmdResetQueryPool():  It is invalid to issue this call inside an active VkRenderPass 0xd10d270000000018[Shadow Map RenderPass]. The Vulkan spec states: This command must only be called outside of a render pass instance (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdResetQueryPool-renderpass)
    Objects: 1
        [0] 0x228bf59bd30, type: 6, name: NULL
VUID-vkCmdBeginRenderPass-renderpass(ERROR / SPEC): msgNum: 339535253 - Validation Error: [ VUID-vkCmdBeginRenderPass-renderpass ] Object 0: handle = 0x228bf59bd30, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0x143ce595 | vkCmdBeginRenderPass():  It is invalid to issue this call inside an active VkRenderPass 0xd10d270000000018[Shadow Map RenderPass]. The Vulkan spec states: This command must only be called outside of a render pass instance (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdBeginRenderPass-renderpass)
    Objects: 1
        [0] 0x228bf59bd30, type: 6, name: NULL
VUID-vkCmdResetQueryPool-renderpass(ERROR / SPEC): msgNum: -1332528324 - Validation Error: [ VUID-vkCmdResetQueryPool-renderpass ] Object 0: handle = 0x228bf5a8330, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0xb0933b3c | vkCmdResetQueryPool():  It is invalid to issue this call inside an active VkRenderPass 0xd10d270000000018[Shadow Map RenderPass]. The Vulkan spec states: This command must only be called outside of a render pass instance (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdResetQueryPool-renderpass)
    Objects: 1
        [0] 0x228bf5a8330, type: 6, name: NULL
VUID-vkCmdBeginRenderPass-renderpass(ERROR / SPEC): msgNum: 339535253 - Validation Error: [ VUID-vkCmdBeginRenderPass-renderpass ] Object 0: handle = 0x228bf5a8330, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0x143ce595 | vkCmdBeginRenderPass():  It is invalid to issue this call inside an active VkRenderPass 0xd10d270000000018[Shadow Map RenderPass]. The Vulkan spec states: This command must only be called outside of a render pass instance (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdBeginRenderPass-renderpass)
    Objects: 1
        [0] 0x228bf5a8330, type: 6, name: NULL
VUID-vkCmdResetQueryPool-renderpass(ERROR / SPEC): msgNum: -1332528324 - Validation Error: [ VUID-vkCmdResetQueryPool-renderpass ] Object 0: handle = 0x228bf59bd30, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0xb0933b3c | vkCmdResetQueryPool():  It is invalid to issue this call inside an active VkRenderPass 0xd10d270000000018[Shadow Map RenderPass]. The Vulkan spec states: This command must only be called outside of a render pass instance (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdResetQueryPool-renderpass)
    Objects: 1
        [0] 0x228bf59bd30, type: 6, name: NULL
VUID-vkCmdBeginRenderPass-renderpass(ERROR / SPEC): msgNum: 339535253 - Validation Error: [ VUID-vkCmdBeginRenderPass-renderpass ] Object 0: handle = 0x228bf59bd30, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0x143ce595 | vkCmdBeginRenderPass():  It is invalid to issue this call inside an active VkRenderPass 0xd10d270000000018[Shadow Map RenderPass]. The Vulkan spec states: This command must only be called outside of a render pass instance (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdBeginRenderPass-renderpass)
    Objects: 1
        [0] 0x228bf59bd30, type: 6, name: NULL
VUID-vkCmdResetQueryPool-renderpass(ERROR / SPEC): msgNum: -1332528324 - Validation Error: [ VUID-vkCmdResetQueryPool-renderpass ] Object 0: handle = 0x228bf5a8330, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0xb0933b3c | vkCmdResetQueryPool():  It is invalid to issue this call inside an active VkRenderPass 0xd10d270000000018[Shadow Map RenderPass]. The Vulkan spec states: This command must only be called outside of a render pass instance (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdResetQueryPool-renderpass)
    Objects: 1
        [0] 0x228bf5a8330, type: 6, name: NULL
VUID-vkCmdBeginRenderPass-renderpass(ERROR / SPEC): msgNum: 339535253 - Validation Error: [ VUID-vkCmdBeginRenderPass-renderpass ] Object 0: handle = 0x228bf5a8330, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0x143ce595 | vkCmdBeginRenderPass():  It is invalid to issue this call inside an active VkRenderPass 0xd10d270000000018[Shadow Map RenderPass]. The Vulkan spec states: This command must only be called outside of a render pass instance (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdBeginRenderPass-renderpass)
    Objects: 1
        [0] 0x228bf5a8330, type: 6, name: NULL
VUID-vkCmdResetQueryPool-renderpass(ERROR / SPEC): msgNum: -1332528324 - Validation Error: [ VUID-vkCmdResetQueryPool-renderpass ] Object 0: handle = 0x228bf59bd30, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0xb0933b3c | vkCmdResetQueryPool():  It is invalid to issue this call inside an active VkRenderPass 0xd10d270000000018[Shadow Map RenderPass]. The Vulkan spec states: This command must only be called outside of a render pass instance (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdResetQueryPool-renderpass)
    Objects: 1
        [0] 0x228bf59bd30, type: 6, name: NULL
VUID-vkCmdBeginRenderPass-renderpass(ERROR / SPEC): msgNum: 339535253 - Validation Error: [ VUID-vkCmdBeginRenderPass-renderpass ] Object 0: handle = 0x228bf59bd30, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0x143ce595 | vkCmdBeginRenderPass():  It is invalid to issue this call inside an active VkRenderPass 0xd10d270000000018[Shadow Map RenderPass]. The Vulkan spec states: This command must only be called outside of a render pass instance (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdBeginRenderPass-renderpass)
    Objects: 1
        [0] 0x228bf59bd30, type: 6, name: NULL
VUID-vkCmdResetQueryPool-renderpass(ERROR / SPEC): msgNum: -1332528324 - Validation Error: [ VUID-vkCmdResetQueryPool-renderpass ] Object 0: handle = 0x228bf5a8330, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0xb0933b3c | vkCmdResetQueryPool():  It is invalid to issue this call inside an active VkRenderPass 0xd10d270000000018[Shadow Map RenderPass]. The Vulkan spec states: This command must only be called outside of a render pass instance (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdResetQueryPool-renderpass)
    Objects: 1
        [0] 0x228bf5a8330, type: 6, name: NULL
VUID-vkCmdBeginRenderPass-renderpass(ERROR / SPEC): msgNum: 339535253 - Validation Error: [ VUID-vkCmdBeginRenderPass-renderpass ] Object 0: handle = 0x228bf5a8330, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0x143ce595 | vkCmdBeginRenderPass():  It is invalid to issue this call inside an active VkRenderPass 0xd10d270000000018[Shadow Map RenderPass]. The Vulkan spec states: This command must only be called outside of a render pass instance (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdBeginRenderPass-renderpass)
    Objects: 1
        [0] 0x228bf5a8330, type: 6, name: NULL
VUID-vkCmdResetQueryPool-renderpass(ERROR / SPEC): msgNum: -1332528324 - Validation Error: [ VUID-vkCmdResetQueryPool-renderpass ] Object 0: handle = 0x228bf59bd30, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0xb0933b3c | vkCmdResetQueryPool():  It is invalid to issue this call inside an active VkRenderPass 0xd10d270000000018[Shadow Map RenderPass]. The Vulkan spec states: This command must only be called outside of a render pass instance (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdResetQueryPool-renderpass)
    Objects: 1
        [0] 0x228bf59bd30, type: 6, name: NULL
VUID-vkCmdBeginRenderPass-renderpass(ERROR / SPEC): msgNum: 339535253 - Validation Error: [ VUID-vkCmdBeginRenderPass-renderpass ] Object 0: handle = 0x228bf59bd30, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0x143ce595 | vkCmdBeginRenderPass():  It is invalid to issue this call inside an active VkRenderPass 0xd10d270000000018[Shadow Map RenderPass]. The Vulkan spec states: This command must only be called outside of a render pass instance (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdBeginRenderPass-renderpass)
    Objects: 1
        [0] 0x228bf59bd30, type: 6, name: NULL
VUID-vkCmdResetQueryPool-renderpass(ERROR / SPEC): msgNum: -1332528324 - Validation Error: [ VUID-vkCmdResetQueryPool-renderpass ] Object 0: handle = 0x228bf5a8330, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0xb0933b3c | vkCmdResetQueryPool():  It is invalid to issue this call inside an active VkRenderPass 0xd10d270000000018[Shadow Map RenderPass]. The Vulkan spec states: This command must only be called outside of a render pass instance (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdResetQueryPool-renderpass)
    Objects: 1
        [0] 0x228bf5a8330, type: 6, name: NULL
VUID-vkCmdBeginRenderPass-renderpass(ERROR / SPEC): msgNum: 339535253 - Validation Error: [ VUID-vkCmdBeginRenderPass-renderpass ] Object 0: handle = 0x228bf5a8330, type = VK_OBJECT_TYPE_COMMAND_BUFFER; | MessageID = 0x143ce595 | vkCmdBeginRenderPass():  It is invalid to issue this call inside an active VkRenderPass 0xd10d270000000018[Shadow Map RenderPass]. The Vulkan spec states: This command must only be called outside of a render pass instance (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdBeginRenderPass-renderpass)
    Objects: 1
        [0] 0x228bf5a8330, type: 6, name: NULL
```

忘记 end render pass 了

```
VUID-vkCmdDrawIndexed-None-08600(ERROR / SPEC): msgNum: 941228658 - Validation Error: [ VUID-vkCmdDrawIndexed-None-08600 ] Object 0: handle = 0xfef35a00000000a0, name = Forward Shadow Map Material, type = VK_OBJECT_TYPE_PIPELINE; Object 1: handle = 0xe9b2ee0000000094, type = VK_OBJECT_TYPE_PIPELINE_LAYOUT; | MessageID = 0x381a0272 | vkCmdDrawIndexed():  The VkPipeline 0xfef35a00000000a0[Forward Shadow Map Material] (created with VkPipelineLayout 0xe9b2ee0000000094[]) statically uses descriptor set (index #1) which is not compatible with the currently bound descriptor set's pipeline layout (VkPipelineLayout 0xe9b2ee0000000094[]). The Vulkan spec states: For each set n that is statically used by a bound shader, a descriptor set must have been bound to n at the same pipeline bind point, with a VkPipelineLayout that is compatible for set n, with the VkPipelineLayout used to create the current VkPipeline or the VkDescriptorSetLayout array used to create the current VkShaderEXT , as described in Pipeline Layout Compatibility (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdDrawIndexed-None-08600)
    Objects: 2
        [0] 0xfef35a00000000a0, type: 19, name: Forward Shadow Map Material
        [1] 0xe9b2ee0000000094, type: 17, name: NULL
VUID-vkCmdDrawIndexed-None-08600(ERROR / SPEC): msgNum: 941228658 - Validation Error: [ VUID-vkCmdDrawIndexed-None-08600 ] Object 0: handle = 0xfef35a00000000a0, name = Forward Shadow Map Material, type = VK_OBJECT_TYPE_PIPELINE; Object 1: handle = 0xe9b2ee0000000094, type = VK_OBJECT_TYPE_PIPELINE_LAYOUT; | MessageID = 0x381a0272 | vkCmdDrawIndexed():  The VkPipeline 0xfef35a00000000a0[Forward Shadow Map Material] (created with VkPipelineLayout 0xe9b2ee0000000094[]) statically uses descriptor set (index #1) which is not compatible with the currently bound descriptor set's pipeline layout (VkPipelineLayout 0xe9b2ee0000000094[]). The Vulkan spec states: For each set n that is statically used by a bound shader, a descriptor set must have been bound to n at the same pipeline bind point, with a VkPipelineLayout that is compatible for set n, with the VkPipelineLayout used to create the current VkPipeline or the VkDescriptorSetLayout array used to create the current VkShaderEXT , as described in Pipeline Layout Compatibility (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdDrawIndexed-None-08600)
    Objects: 2
        [0] 0xfef35a00000000a0, type: 19, name: Forward Shadow Map Material
        [1] 0xe9b2ee0000000094, type: 17, name: NULL
VUID-vkCmdDrawIndexed-None-08600(ERROR / SPEC): msgNum: 941228658 - Validation Error: [ VUID-vkCmdDrawIndexed-None-08600 ] Object 0: handle = 0xfef35a00000000a0, name = Forward Shadow Map Material, type = VK_OBJECT_TYPE_PIPELINE; Object 1: handle = 0xe9b2ee0000000094, type = VK_OBJECT_TYPE_PIPELINE_LAYOUT; | MessageID = 0x381a0272 | vkCmdDrawIndexed():  The VkPipeline 0xfef35a00000000a0[Forward Shadow Map Material] (created with VkPipelineLayout 0xe9b2ee0000000094[]) statically uses descriptor set (index #1) which is not compatible with the currently bound descriptor set's pipeline layout (VkPipelineLayout 0xe9b2ee0000000094[]). The Vulkan spec states: For each set n that is statically used by a bound shader, a descriptor set must have been bound to n at the same pipeline bind point, with a VkPipelineLayout that is compatible for set n, with the VkPipelineLayout used to create the current VkPipeline or the VkDescriptorSetLayout array used to create the current VkShaderEXT , as described in Pipeline Layout Compatibility (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdDrawIndexed-None-08600)
    Objects: 2
        [0] 0xfef35a00000000a0, type: 19, name: Forward Shadow Map Material
        [1] 0xe9b2ee0000000094, type: 17, name: NULL
VUID-vkCmdDrawIndexed-None-08600(ERROR / SPEC): msgNum: 941228658 - Validation Error: [ VUID-vkCmdDrawIndexed-None-08600 ] Object 0: handle = 0xfef35a00000000a0, name = Forward Shadow Map Material, type = VK_OBJECT_TYPE_PIPELINE; Object 1: handle = 0xe9b2ee0000000094, type = VK_OBJECT_TYPE_PIPELINE_LAYOUT; | MessageID = 0x381a0272 | vkCmdDrawIndexed():  The VkPipeline 0xfef35a00000000a0[Forward Shadow Map Material] (created with VkPipelineLayout 0xe9b2ee0000000094[]) statically uses descriptor set (index #1) which is not compatible with the currently bound descriptor set's pipeline layout (VkPipelineLayout 0xe9b2ee0000000094[]). The Vulkan spec states: For each set n that is statically used by a bound shader, a descriptor set must have been bound to n at the same pipeline bind point, with a VkPipelineLayout that is compatible for set n, with the VkPipelineLayout used to create the current VkPipeline or the VkDescriptorSetLayout array used to create the current VkShaderEXT , as described in Pipeline Layout Compatibility (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdDrawIndexed-None-08600)
    Objects: 2
        [0] 0xfef35a00000000a0, type: 19, name: Forward Shadow Map Material
        [1] 0xe9b2ee0000000094, type: 17, name: NULL
VUID-vkCmdDrawIndexed-None-08600(ERROR / SPEC): msgNum: 941228658 - Validation Error: [ VUID-vkCmdDrawIndexed-None-08600 ] Object 0: handle = 0xfef35a00000000a0, name = Forward Shadow Map Material, type = VK_OBJECT_TYPE_PIPELINE; Object 1: handle = 0xe9b2ee0000000094, type = VK_OBJECT_TYPE_PIPELINE_LAYOUT; | MessageID = 0x381a0272 | vkCmdDrawIndexed():  The VkPipeline 0xfef35a00000000a0[Forward Shadow Map Material] (created with VkPipelineLayout 0xe9b2ee0000000094[]) statically uses descriptor set (index #1) which is not compatible with the currently bound descriptor set's pipeline layout (VkPipelineLayout 0xe9b2ee0000000094[]). The Vulkan spec states: For each set n that is statically used by a bound shader, a descriptor set must have been bound to n at the same pipeline bind point, with a VkPipelineLayout that is compatible for set n, with the VkPipelineLayout used to create the current VkPipeline or the VkDescriptorSetLayout array used to create the current VkShaderEXT , as described in Pipeline Layout Compatibility (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdDrawIndexed-None-08600)
    Objects: 2
        [0] 0xfef35a00000000a0, type: 19, name: Forward Shadow Map Material
        [1] 0xe9b2ee0000000094, type: 17, name: NULL
VUID-vkCmdDrawIndexed-None-08600(ERROR / SPEC): msgNum: 941228658 - Validation Error: [ VUID-vkCmdDrawIndexed-None-08600 ] Object 0: handle = 0xfef35a00000000a0, name = Forward Shadow Map Material, type = VK_OBJECT_TYPE_PIPELINE; Object 1: handle = 0xe9b2ee0000000094, type = VK_OBJECT_TYPE_PIPELINE_LAYOUT; | MessageID = 0x381a0272 | vkCmdDrawIndexed():  The VkPipeline 0xfef35a00000000a0[Forward Shadow Map Material] (created with VkPipelineLayout 0xe9b2ee0000000094[]) statically uses descriptor set (index #1) which is not compatible with the currently bound descriptor set's pipeline layout (VkPipelineLayout 0xe9b2ee0000000094[]). The Vulkan spec states: For each set n that is statically used by a bound shader, a descriptor set must have been bound to n at the same pipeline bind point, with a VkPipelineLayout that is compatible for set n, with the VkPipelineLayout used to create the current VkPipeline or the VkDescriptorSetLayout array used to create the current VkShaderEXT , as described in Pipeline Layout Compatibility (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdDrawIndexed-None-08600)
    Objects: 2
        [0] 0xfef35a00000000a0, type: 19, name: Forward Shadow Map Material
        [1] 0xe9b2ee0000000094, type: 17, name: NULL
VUID-vkCmdDrawIndexed-None-08600(ERROR / SPEC): msgNum: 941228658 - Validation Error: [ VUID-vkCmdDrawIndexed-None-08600 ] Object 0: handle = 0xfef35a00000000a0, name = Forward Shadow Map Material, type = VK_OBJECT_TYPE_PIPELINE; Object 1: handle = 0xe9b2ee0000000094, type = VK_OBJECT_TYPE_PIPELINE_LAYOUT; | MessageID = 0x381a0272 | vkCmdDrawIndexed():  The VkPipeline 0xfef35a00000000a0[Forward Shadow Map Material] (created with VkPipelineLayout 0xe9b2ee0000000094[]) statically uses descriptor set (index #1) which is not compatible with the currently bound descriptor set's pipeline layout (VkPipelineLayout 0xe9b2ee0000000094[]). The Vulkan spec states: For each set n that is statically used by a bound shader, a descriptor set must have been bound to n at the same pipeline bind point, with a VkPipelineLayout that is compatible for set n, with the VkPipelineLayout used to create the current VkPipeline or the VkDescriptorSetLayout array used to create the current VkShaderEXT , as described in Pipeline Layout Compatibility (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdDrawIndexed-None-08600)
    Objects: 2
        [0] 0xfef35a00000000a0, type: 19, name: Forward Shadow Map Material
        [1] 0xe9b2ee0000000094, type: 17, name: NULL
VUID-vkCmdDrawIndexed-None-08600(ERROR / SPEC): msgNum: 941228658 - Validation Error: [ VUID-vkCmdDrawIndexed-None-08600 ] Object 0: handle = 0xfef35a00000000a0, name = Forward Shadow Map Material, type = VK_OBJECT_TYPE_PIPELINE; Object 1: handle = 0xe9b2ee0000000094, type = VK_OBJECT_TYPE_PIPELINE_LAYOUT; | MessageID = 0x381a0272 | vkCmdDrawIndexed():  The VkPipeline 0xfef35a00000000a0[Forward Shadow Map Material] (created with VkPipelineLayout 0xe9b2ee0000000094[]) statically uses descriptor set (index #1) which is not compatible with the currently bound descriptor set's pipeline layout (VkPipelineLayout 0xe9b2ee0000000094[]). The Vulkan spec states: For each set n that is statically used by a bound shader, a descriptor set must have been bound to n at the same pipeline bind point, with a VkPipelineLayout that is compatible for set n, with the VkPipelineLayout used to create the current VkPipeline or the VkDescriptorSetLayout array used to create the current VkShaderEXT , as described in Pipeline Layout Compatibility (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdDrawIndexed-None-08600)
    Objects: 2
        [0] 0xfef35a00000000a0, type: 19, name: Forward Shadow Map Material
        [1] 0xe9b2ee0000000094, type: 17, name: NULL
VUID-vkCmdDrawIndexed-None-08600(ERROR / SPEC): msgNum: 941228658 - Validation Error: [ VUID-vkCmdDrawIndexed-None-08600 ] Object 0: handle = 0xfef35a00000000a0, name = Forward Shadow Map Material, type = VK_OBJECT_TYPE_PIPELINE; Object 1: handle = 0xe9b2ee0000000094, type = VK_OBJECT_TYPE_PIPELINE_LAYOUT; | MessageID = 0x381a0272 | vkCmdDrawIndexed():  The VkPipeline 0xfef35a00000000a0[Forward Shadow Map Material] (created with VkPipelineLayout 0xe9b2ee0000000094[]) statically uses descriptor set (index #1) which is not compatible with the currently bound descriptor set's pipeline layout (VkPipelineLayout 0xe9b2ee0000000094[]). The Vulkan spec states: For each set n that is statically used by a bound shader, a descriptor set must have been bound to n at the same pipeline bind point, with a VkPipelineLayout that is compatible for set n, with the VkPipelineLayout used to create the current VkPipeline or the VkDescriptorSetLayout array used to create the current VkShaderEXT , as described in Pipeline Layout Compatibility (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdDrawIndexed-None-08600)
    Objects: 2
        [0] 0xfef35a00000000a0, type: 19, name: Forward Shadow Map Material
        [1] 0xe9b2ee0000000094, type: 17, name: NULL
VUID-vkCmdDrawIndexed-None-08600(ERROR / SPEC): msgNum: 941228658 - Validation Error: [ VUID-vkCmdDrawIndexed-None-08600 ] Object 0: handle = 0xfef35a00000000a0, name = Forward Shadow Map Material, type = VK_OBJECT_TYPE_PIPELINE; Object 1: handle = 0xe9b2ee0000000094, type = VK_OBJECT_TYPE_PIPELINE_LAYOUT; | MessageID = 0x381a0272 | vkCmdDrawIndexed():  The VkPipeline 0xfef35a00000000a0[Forward Shadow Map Material] (created with VkPipelineLayout 0xe9b2ee0000000094[]) statically uses descriptor set (index #1) which is not compatible with the currently bound descriptor set's pipeline layout (VkPipelineLayout 0xe9b2ee0000000094[]). The Vulkan spec states: For each set n that is statically used by a bound shader, a descriptor set must have been bound to n at the same pipeline bind point, with a VkPipelineLayout that is compatible for set n, with the VkPipelineLayout used to create the current VkPipeline or the VkDescriptorSetLayout array used to create the current VkShaderEXT , as described in Pipeline Layout Compatibility (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdDrawIndexed-None-08600)
    Objects: 2
        [0] 0xfef35a00000000a0, type: 19, name: Forward Shadow Map Material
        [1] 0xe9b2ee0000000094, type: 17, name: NULL
VUID-vkCmdDraw-None-08600(ERROR / SPEC): msgNum: 1198051129 - Validation Error: [ VUID-vkCmdDraw-None-08600 ] Object 0: handle = 0xfef35a00000000a0, name = Forward Shadow Map Material, type = VK_OBJECT_TYPE_PIPELINE; Object 1: handle = 0xe9b2ee0000000094, type = VK_OBJECT_TYPE_PIPELINE_LAYOUT; | MessageID = 0x4768cf39 | vkCmdDraw():  The VkPipeline 0xfef35a00000000a0[Forward Shadow Map Material] (created with VkPipelineLayout 0xe9b2ee0000000094[]) statically uses descriptor set (index #1) which is not compatible with the currently bound descriptor set's pipeline layout (VkPipelineLayout 0xe9b2ee0000000094[]). The Vulkan spec states: For each set n that is statically used by a bound shader, a descriptor set must have been bound to n at the same pipeline bind point, with a VkPipelineLayout that is compatible for set n, with the VkPipelineLayout used to create the current VkPipeline or the VkDescriptorSetLayout array used to create the current VkShaderEXT , as described in Pipeline Layout Compatibility (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdDraw-None-08600)
    Objects: 2
        [0] 0xfef35a00000000a0, type: 19, name: Forward Shadow Map Material
        [1] 0xe9b2ee0000000094, type: 17, name: NULL
VUID-vkCmdDraw-None-08600(ERROR / SPEC): msgNum: 1198051129 - Validation Error: [ VUID-vkCmdDraw-None-08600 ] Object 0: handle = 0xfef35a00000000a0, name = Forward Shadow Map Material, type = VK_OBJECT_TYPE_PIPELINE; Object 1: handle = 0xe9b2ee0000000094, type = VK_OBJECT_TYPE_PIPELINE_LAYOUT; | MessageID = 0x4768cf39 | vkCmdDraw():  The VkPipeline 0xfef35a00000000a0[Forward Shadow Map Material] (created with VkPipelineLayout 0xe9b2ee0000000094[]) statically uses descriptor set (index #1) which is not compatible with the currently bound descriptor set's pipeline layout (VkPipelineLayout 0xe9b2ee0000000094[]). The Vulkan spec states: For each set n that is statically used by a bound shader, a descriptor set must have been bound to n at the same pipeline bind point, with a VkPipelineLayout that is compatible for set n, with the VkPipelineLayout used to create the current VkPipeline or the VkDescriptorSetLayout array used to create the current VkShaderEXT , as described in Pipeline Layout Compatibility (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdDraw-None-08600)
    Objects: 2
        [0] 0xfef35a00000000a0, type: 19, name: Forward Shadow Map Material
        [1] 0xe9b2ee0000000094, type: 17, name: NULL
VUID-vkCmdDraw-None-08600(ERROR / SPEC): msgNum: 1198051129 - Validation Error: [ VUID-vkCmdDraw-None-08600 ] Object 0: handle = 0xfef35a00000000a0, name = Forward Shadow Map Material, type = VK_OBJECT_TYPE_PIPELINE; Object 1: handle = 0xe9b2ee0000000094, type = VK_OBJECT_TYPE_PIPELINE_LAYOUT; | MessageID = 0x4768cf39 | vkCmdDraw():  The VkPipeline 0xfef35a00000000a0[Forward Shadow Map Material] (created with VkPipelineLayout 0xe9b2ee0000000094[]) statically uses descriptor set (index #1) which is not compatible with the currently bound descriptor set's pipeline layout (VkPipelineLayout 0xe9b2ee0000000094[]). The Vulkan spec states: For each set n that is statically used by a bound shader, a descriptor set must have been bound to n at the same pipeline bind point, with a VkPipelineLayout that is compatible for set n, with the VkPipelineLayout used to create the current VkPipeline or the VkDescriptorSetLayout array used to create the current VkShaderEXT , as described in Pipeline Layout Compatibility (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdDraw-None-08600)
    Objects: 2
        [0] 0xfef35a00000000a0, type: 19, name: Forward Shadow Map Material
        [1] 0xe9b2ee0000000094, type: 17, name: NULL
VUID-vkCmdDraw-None-08600(ERROR / SPEC): msgNum: 1198051129 - Validation Error: [ VUID-vkCmdDraw-None-08600 ] Object 0: handle = 0xfef35a00000000a0, name = Forward Shadow Map Material, type = VK_OBJECT_TYPE_PIPELINE; Object 1: handle = 0xe9b2ee0000000094, type = VK_OBJECT_TYPE_PIPELINE_LAYOUT; | MessageID = 0x4768cf39 | vkCmdDraw():  The VkPipeline 0xfef35a00000000a0[Forward Shadow Map Material] (created with VkPipelineLayout 0xe9b2ee0000000094[]) statically uses descriptor set (index #1) which is not compatible with the currently bound descriptor set's pipeline layout (VkPipelineLayout 0xe9b2ee0000000094[]). The Vulkan spec states: For each set n that is statically used by a bound shader, a descriptor set must have been bound to n at the same pipeline bind point, with a VkPipelineLayout that is compatible for set n, with the VkPipelineLayout used to create the current VkPipeline or the VkDescriptorSetLayout array used to create the current VkShaderEXT , as described in Pipeline Layout Compatibility (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdDraw-None-08600)
    Objects: 2
        [0] 0xfef35a00000000a0, type: 19, name: Forward Shadow Map Material
        [1] 0xe9b2ee0000000094, type: 17, name: NULL
VUID-vkCmdDraw-None-08600(ERROR / SPEC): msgNum: 1198051129 - Validation Error: [ VUID-vkCmdDraw-None-08600 ] Object 0: handle = 0xfef35a00000000a0, name = Forward Shadow Map Material, type = VK_OBJECT_TYPE_PIPELINE; Object 1: handle = 0xe9b2ee0000000094, type = VK_OBJECT_TYPE_PIPELINE_LAYOUT; | MessageID = 0x4768cf39 | vkCmdDraw():  The VkPipeline 0xfef35a00000000a0[Forward Shadow Map Material] (created with VkPipelineLayout 0xe9b2ee0000000094[]) statically uses descriptor set (index #1) which is not compatible with the currently bound descriptor set's pipeline layout (VkPipelineLayout 0xe9b2ee0000000094[]). The Vulkan spec states: For each set n that is statically used by a bound shader, a descriptor set must have been bound to n at the same pipeline bind point, with a VkPipelineLayout that is compatible for set n, with the VkPipelineLayout used to create the current VkPipeline or the VkDescriptorSetLayout array used to create the current VkShaderEXT , as described in Pipeline Layout Compatibility (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdDraw-None-08600)
    Objects: 2
        [0] 0xfef35a00000000a0, type: 19, name: Forward Shadow Map Material
        [1] 0xe9b2ee0000000094, type: 17, name: NULL
VUID-vkCmdDraw-None-08600(ERROR / SPEC): msgNum: 1198051129 - Validation Error: [ VUID-vkCmdDraw-None-08600 ] Object 0: handle = 0xfef35a00000000a0, name = Forward Shadow Map Material, type = VK_OBJECT_TYPE_PIPELINE; Object 1: handle = 0xe9b2ee0000000094, type = VK_OBJECT_TYPE_PIPELINE_LAYOUT; | MessageID = 0x4768cf39 | vkCmdDraw():  The VkPipeline 0xfef35a00000000a0[Forward Shadow Map Material] (created with VkPipelineLayout 0xe9b2ee0000000094[]) statically uses descriptor set (index #1) which is not compatible with the currently bound descriptor set's pipeline layout (VkPipelineLayout 0xe9b2ee0000000094[]). The Vulkan spec states: For each set n that is statically used by a bound shader, a descriptor set must have been bound to n at the same pipeline bind point, with a VkPipelineLayout that is compatible for set n, with the VkPipelineLayout used to create the current VkPipeline or the VkDescriptorSetLayout array used to create the current VkShaderEXT , as described in Pipeline Layout Compatibility (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdDraw-None-08600)
    Objects: 2
        [0] 0xfef35a00000000a0, type: 19, name: Forward Shadow Map Material
        [1] 0xe9b2ee0000000094, type: 17, name: NULL
VUID-vkCmdDraw-None-08600(ERROR / SPEC): msgNum: 1198051129 - Validation Error: [ VUID-vkCmdDraw-None-08600 ] Object 0: handle = 0xfef35a00000000a0, name = Forward Shadow Map Material, type = VK_OBJECT_TYPE_PIPELINE; Object 1: handle = 0xe9b2ee0000000094, type = VK_OBJECT_TYPE_PIPELINE_LAYOUT; | MessageID = 0x4768cf39 | vkCmdDraw():  The VkPipeline 0xfef35a00000000a0[Forward Shadow Map Material] (created with VkPipelineLayout 0xe9b2ee0000000094[]) statically uses descriptor set (index #1) which is not compatible with the currently bound descriptor set's pipeline layout (VkPipelineLayout 0xe9b2ee0000000094[]). The Vulkan spec states: For each set n that is statically used by a bound shader, a descriptor set must have been bound to n at the same pipeline bind point, with a VkPipelineLayout that is compatible for set n, with the VkPipelineLayout used to create the current VkPipeline or the VkDescriptorSetLayout array used to create the current VkShaderEXT , as described in Pipeline Layout Compatibility (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdDraw-None-08600)
    Objects: 2
        [0] 0xfef35a00000000a0, type: 19, name: Forward Shadow Map Material
        [1] 0xe9b2ee0000000094, type: 17, name: NULL
VUID-vkCmdDraw-None-08600(ERROR / SPEC): msgNum: 1198051129 - Validation Error: [ VUID-vkCmdDraw-None-08600 ] Object 0: handle = 0xfef35a00000000a0, name = Forward Shadow Map Material, type = VK_OBJECT_TYPE_PIPELINE; Object 1: handle = 0xe9b2ee0000000094, type = VK_OBJECT_TYPE_PIPELINE_LAYOUT; | MessageID = 0x4768cf39 | vkCmdDraw():  The VkPipeline 0xfef35a00000000a0[Forward Shadow Map Material] (created with VkPipelineLayout 0xe9b2ee0000000094[]) statically uses descriptor set (index #1) which is not compatible with the currently bound descriptor set's pipeline layout (VkPipelineLayout 0xe9b2ee0000000094[]). The Vulkan spec states: For each set n that is statically used by a bound shader, a descriptor set must have been bound to n at the same pipeline bind point, with a VkPipelineLayout that is compatible for set n, with the VkPipelineLayout used to create the current VkPipeline or the VkDescriptorSetLayout array used to create the current VkShaderEXT , as described in Pipeline Layout Compatibility (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdDraw-None-08600)
    Objects: 2
        [0] 0xfef35a00000000a0, type: 19, name: Forward Shadow Map Material
        [1] 0xe9b2ee0000000094, type: 17, name: NULL
VUID-vkCmdDraw-None-08600(ERROR / SPEC): msgNum: 1198051129 - Validation Error: [ VUID-vkCmdDraw-None-08600 ] Object 0: handle = 0xfef35a00000000a0, name = Forward Shadow Map Material, type = VK_OBJECT_TYPE_PIPELINE; Object 1: handle = 0xe9b2ee0000000094, type = VK_OBJECT_TYPE_PIPELINE_LAYOUT; | MessageID = 0x4768cf39 | vkCmdDraw():  The VkPipeline 0xfef35a00000000a0[Forward Shadow Map Material] (created with VkPipelineLayout 0xe9b2ee0000000094[]) statically uses descriptor set (index #1) which is not compatible with the currently bound descriptor set's pipeline layout (VkPipelineLayout 0xe9b2ee0000000094[]). The Vulkan spec states: For each set n that is statically used by a bound shader, a descriptor set must have been bound to n at the same pipeline bind point, with a VkPipelineLayout that is compatible for set n, with the VkPipelineLayout used to create the current VkPipeline or the VkDescriptorSetLayout array used to create the current VkShaderEXT , as described in Pipeline Layout Compatibility (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdDraw-None-08600)
    Objects: 2
        [0] 0xfef35a00000000a0, type: 19, name: Forward Shadow Map Material
        [1] 0xe9b2ee0000000094, type: 17, name: NULL
VUID-vkCmdDraw-None-08600(ERROR / SPEC): msgNum: 1198051129 - Validation Error: [ VUID-vkCmdDraw-None-08600 ] Object 0: handle = 0xfef35a00000000a0, name = Forward Shadow Map Material, type = VK_OBJECT_TYPE_PIPELINE; Object 1: handle = 0xe9b2ee0000000094, type = VK_OBJECT_TYPE_PIPELINE_LAYOUT; | MessageID = 0x4768cf39 | vkCmdDraw():  The VkPipeline 0xfef35a00000000a0[Forward Shadow Map Material] (created with VkPipelineLayout 0xe9b2ee0000000094[]) statically uses descriptor set (index #1) which is not compatible with the currently bound descriptor set's pipeline layout (VkPipelineLayout 0xe9b2ee0000000094[]). The Vulkan spec states: For each set n that is statically used by a bound shader, a descriptor set must have been bound to n at the same pipeline bind point, with a VkPipelineLayout that is compatible for set n, with the VkPipelineLayout used to create the current VkPipeline or the VkDescriptorSetLayout array used to create the current VkShaderEXT , as described in Pipeline Layout Compatibility (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdDraw-None-08600)
    Objects: 2
        [0] 0xfef35a00000000a0, type: 19, name: Forward Shadow Map Material
        [1] 0xe9b2ee0000000094, type: 17, name: NULL
```

没 UpdateUniformBuffer 导致没有绑 dynamic uniform buffer offset

## size

画出来的 shadow map 都是一片白色

并且 shadow map 绘制的尺寸没有全屏绘制

因为我对 shadow map 的尺寸要求还是 swap chain 的尺寸

于是 framebuffer 的尺寸和 render pass start 的尺寸都要跟着改

这样看来的话，确实是需要一个 render target 作为 render pass 的接口参数比较好

## 绘制范围

绘制范围出错

![alt text](../assets/shadow_map_error_range.png)

看了别人是怎么做的

[https://github.com/SaschaWillems/Vulkan.git](https://github.com/SaschaWillems/Vulkan.git)

examples\shadowmapping\shadowmapping.cpp

```cpp
void buildCommandBuffers()
{
    VkCommandBufferBeginInfo cmdBufInfo = vks::initializers::commandBufferBeginInfo();

    VkClearValue clearValues[2];
    VkViewport viewport;
    VkRect2D scissor;

    for (int32_t i = 0; i < drawCmdBuffers.size(); ++i)
    {
        VK_CHECK_RESULT(vkBeginCommandBuffer(drawCmdBuffers[i], &cmdBufInfo));

        /*
            First render pass: Generate shadow map by rendering the scene from light's POV
        */
        {
            clearValues[0].depthStencil = { 1.0f, 0 };

            VkRenderPassBeginInfo renderPassBeginInfo = vks::initializers::renderPassBeginInfo();
            renderPassBeginInfo.renderPass = offscreenPass.renderPass;
            renderPassBeginInfo.framebuffer = offscreenPass.frameBuffer;
            renderPassBeginInfo.renderArea.extent.width = offscreenPass.width;
            renderPassBeginInfo.renderArea.extent.height = offscreenPass.height;
            renderPassBeginInfo.clearValueCount = 1;
            renderPassBeginInfo.pClearValues = clearValues;

            vkCmdBeginRenderPass(drawCmdBuffers[i], &renderPassBeginInfo, VK_SUBPASS_CONTENTS_INLINE);

            viewport = vks::initializers::viewport((float)offscreenPass.width, (float)offscreenPass.height, 0.0f, 1.0f);
            vkCmdSetViewport(drawCmdBuffers[i], 0, 1, &viewport);

            scissor = vks::initializers::rect2D(offscreenPass.width, offscreenPass.height, 0, 0);
            vkCmdSetScissor(drawCmdBuffers[i], 0, 1, &scissor);

            // Set depth bias (aka "Polygon offset")
            // Required to avoid shadow mapping artifacts
            vkCmdSetDepthBias(
                drawCmdBuffers[i],
                depthBiasConstant,
                0.0f,
                depthBiasSlope);

            vkCmdBindPipeline(drawCmdBuffers[i], VK_PIPELINE_BIND_POINT_GRAPHICS, pipelines.offscreen);
            vkCmdBindDescriptorSets(drawCmdBuffers[i], VK_PIPELINE_BIND_POINT_GRAPHICS, pipelineLayout, 0, 1, &descriptorSets.offscreen, 0, nullptr);
            scenes[sceneIndex].draw(drawCmdBuffers[i]);

            vkCmdEndRenderPass(drawCmdBuffers[i]);
        }

        /*
            Note: Explicit synchronization is not required between the render pass, as this is done implicit via sub pass dependencies
        */

        /*
            Second pass: Scene rendering with applied shadow map
        */

        {
            clearValues[0].color = defaultClearColor;
            clearValues[1].depthStencil = { 1.0f, 0 };

            VkRenderPassBeginInfo renderPassBeginInfo = vks::initializers::renderPassBeginInfo();
            renderPassBeginInfo.renderPass = renderPass;
            renderPassBeginInfo.framebuffer = frameBuffers[i];
            renderPassBeginInfo.renderArea.extent.width = width;
            renderPassBeginInfo.renderArea.extent.height = height;
            renderPassBeginInfo.clearValueCount = 2;
            renderPassBeginInfo.pClearValues = clearValues;

            vkCmdBeginRenderPass(drawCmdBuffers[i], &renderPassBeginInfo, VK_SUBPASS_CONTENTS_INLINE);

            viewport = vks::initializers::viewport((float)width, (float)height, 0.0f, 1.0f);
            vkCmdSetViewport(drawCmdBuffers[i], 0, 1, &viewport);

            scissor = vks::initializers::rect2D(width, height, 0, 0);
            vkCmdSetScissor(drawCmdBuffers[i], 0, 1, &scissor);

            // Visualize shadow map
            if (displayShadowMap) {
                vkCmdBindDescriptorSets(drawCmdBuffers[i], VK_PIPELINE_BIND_POINT_GRAPHICS, pipelineLayout, 0, 1, &descriptorSets.debug, 0, nullptr);
                vkCmdBindPipeline(drawCmdBuffers[i], VK_PIPELINE_BIND_POINT_GRAPHICS, pipelines.debug);
                vkCmdDraw(drawCmdBuffers[i], 3, 1, 0, 0);
            } else {
                // Render the shadows scene
                vkCmdBindDescriptorSets(drawCmdBuffers[i], VK_PIPELINE_BIND_POINT_GRAPHICS, pipelineLayout, 0, 1, &descriptorSets.scene, 0, nullptr);
                vkCmdBindPipeline(drawCmdBuffers[i], VK_PIPELINE_BIND_POINT_GRAPHICS, (filterPCF) ? pipelines.sceneShadowPCF : pipelines.sceneShadow);
                scenes[sceneIndex].draw(drawCmdBuffers[i]);
            }

            drawUI(drawCmdBuffers[i]);

            vkCmdEndRenderPass(drawCmdBuffers[i]);
        }

        VK_CHECK_RESULT(vkEndCommandBuffer(drawCmdBuffers[i]));
    }
}
```

他这个就是启动两个 render pass，然后在每一个 render pass 的开头设置裁剪大小

于是我把 viewport 和 scissor 放到 render pass 里面就好了

## 阴影质量很差

调一下阴影的角度就知道现在的阴影质量很差

![](../assets/bad_shadow.png)

截帧发现，使用的 shadow map 渲染的结果非常差

![alt text](../assets/bad_shadow_map.png)
