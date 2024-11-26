# 天空盒

## 渲染顺序

天空盒应该在渲染不透明物体之后，避免 overdraw

天空盒应该在渲染透明物体之前，因为渲染透明物体不写入深度，如果天空盒在渲染透明物体之后渲染，那么原先透明物体对应的没有写入深度的部分就会被写入天空盒的深度，颜色缓冲也同时被覆盖为天空盒的颜色

所以渲染顺序是

1.不透明物体

2.天空盒

3.透明物体

## cubemap error

```
[MeowEngine][2024-11-26 00:30:28] Error: { Validation }:
	messageIDName   = <VUID-VkImageCreateInfo-imageCreateMaxMipLevels-02251>
	messageIdNumber = -1094930823
	message         = <Validation Error: [ VUID-VkImageCreateInfo-imageCreateMaxMipLevels-02251 ] | MessageID = 0xbebcae79 | vkCreateImage(): pCreateInfo The following parameters -
format (VK_FORMAT_R8G8B8A8_UNORM)
type (VK_IMAGE_TYPE_2D)
tiling (VK_IMAGE_TILING_LINEAR)
usage (VK_IMAGE_USAGE_SAMPLED_BIT)
flags (VK_IMAGE_CREATE_CUBE_COMPATIBLE_BIT)
returned (VK_ERROR_FORMAT_NOT_SUPPORTED) when calling vkGetPhysicalDeviceImageFormatProperties2. The Vulkan spec states: Each of the following values (as described in Image Creation Limits) must not be undefined : imageCreateMaxMipLevels, imageCreateMaxArrayLayers, imageCreateMaxExtent, and imageCreateSampleCounts (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageCreateInfo-imageCreateMaxMipLevels-02251)>

VUID-VkImageCreateInfo-imageCreateMaxMipLevels-02251(ERROR / SPEC): msgNum: -1094930823 - Validation Error: [ VUID-VkImageCreateInfo-imageCreateMaxMipLevels-02251 ] | MessageID = 0xbebcae79 | vkCreateImage(): pCreateInfo The following parameters -
format (VK_FORMAT_R8G8B8A8_UNORM)
type (VK_IMAGE_TYPE_2D)
tiling (VK_IMAGE_TILING_LINEAR)
usage (VK_IMAGE_USAGE_SAMPLED_BIT)
flags (VK_IMAGE_CREATE_CUBE_COMPATIBLE_BIT)
returned (VK_ERROR_FORMAT_NOT_SUPPORTED) when calling vkGetPhysicalDeviceImageFormatProperties2. The Vulkan spec states: Each of the following values (as described in Image Creation Limits) must not be undefined : imageCreateMaxMipLevels, imageCreateMaxArrayLayers, imageCreateMaxExtent, and imageCreateSampleCounts (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageCreateInfo-imageCreateMaxMipLevels-02251)
    Objects: 0
异常: Exception 0xe06d7363 encountered at address 0x7fffb549fe4c
```

怎么就 `vk::ImageCreateInfo` 出错了？

于是发现是我的图像格式和布局设错了

## VkImageViewCreateInfo error

```
[MeowEngine][2024-11-26 00:55:55] Error: { Validation }:
	messageIDName   = <VUID-VkImageViewCreateInfo-imageViewType-04973>
	messageIdNumber = -1968073940
	message         = <Validation Error: [ VUID-VkImageViewCreateInfo-imageViewType-04973 ] Object 0: handle = 0xa182620000000079, type = VK_OBJECT_TYPE_IMAGE; | MessageID = 0x8ab1932c | vkCreateImageView(): pCreateInfo->subresourceRange.layerCount (6) must be 1 when using viewType VK_IMAGE_VIEW_TYPE_2D (try looking into VK_IMAGE_VIEW_TYPE_*_ARRAY). The Vulkan spec states: If viewType is VK_IMAGE_VIEW_TYPE_1D, VK_IMAGE_VIEW_TYPE_2D, or VK_IMAGE_VIEW_TYPE_3D; and subresourceRange.layerCount is not VK_REMAINING_ARRAY_LAYERS, then subresourceRange.layerCount must be 1 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageViewCreateInfo-imageViewType-04973)>
	Objects:
		Object 0
			objectType   = Image
			objectHandle = 11637972139218305145

VUID-VkImageViewCreateInfo-imageViewType-04973(ERROR / SPEC): msgNum: -1968073940 - Validation Error: [ VUID-VkImageViewCreateInfo-imageViewType-04973 ] Object 0: handle = 0xa182620000000079, type = VK_OBJECT_TYPE_IMAGE; | MessageID = 0x8ab1932c | vkCreateImageView(): pCreateInfo->subresourceRange.layerCount (6) must be 1 when using viewType VK_IMAGE_VIEW_TYPE_2D (try looking into VK_IMAGE_VIEW_TYPE_*_ARRAY). The Vulkan spec states: If viewType is VK_IMAGE_VIEW_TYPE_1D, VK_IMAGE_VIEW_TYPE_2D, or VK_IMAGE_VIEW_TYPE_3D; and subresourceRange.layerCount is not VK_REMAINING_ARRAY_LAYERS, then subresourceRange.layerCount must be 1 (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-VkImageViewCreateInfo-imageViewType-04973)
    Objects: 1
        [0] 0xa182620000000079, type: 10, name: NULL
VUID-vkCmdCopyBufferToImage-pRegions-00171(ERROR / SPEC): msgNum: 1867332608 - Validation Error: [ VUID-vkCmdCopyBufferToImage-pRegions-00171 ] Object 0: handle = 0x233ce89a0c0, type = VK_OBJECT_TYPE_COMMAND_BUFFER; Object 1: handle = 0xb82de40000000077, type = VK_OBJECT_TYPE_BUFFER; | MessageID = 0x6f4d3c00 | vkCmdCopyBufferToImage(): pRegions[3] is trying to copy 262144 bytes plus 196608 offset to/from the VkBuffer (VkBuffer 0xb82de40000000077[]) which exceeds the VkBuffer total size of 393216 bytes. The Vulkan spec states: srcBuffer must be large enough to contain all buffer locations that are accessed according to Buffer and Image Addressing, for each element of pRegions (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdCopyBufferToImage-pRegions-00171)
    Objects: 2
        [0] 0x233ce89a0c0, type: 6, name: NULL
        [1] 0xb82de40000000077, type: 9, name: NULL
```

是因为 `vk::ImageViewCreateInfo` 的 `vk::ImageViewType` 要设为 `vk::ImageViewType::eCube`

## vkCmdCopyBufferToImage exceeds the VkBuffer total size

```
VUID-vkCmdCopyBufferToImage-pRegions-00171(ERROR / SPEC): msgNum: 1867332608 - Validation Error: [ VUID-vkCmdCopyBufferToImage-pRegions-00171 ] Object 0: handle = 0x2d36c6683d0, type = VK_OBJECT_TYPE_COMMAND_BUFFER; Object 1: handle = 0xb82de40000000077, type = VK_OBJECT_TYPE_BUFFER; | MessageID = 0x6f4d3c00 | vkCmdCopyBufferToImage(): pRegions[3] is trying to copy 262144 bytes plus 196608 offset to/from the VkBuffer (VkBuffer 0xb82de40000000077[]) which   the VkBuffer total size of 393216 bytes. The Vulkan spec states: srcBuffer must be large enough to contain all buffer locations that are accessed according to Buffer and Image Addressing, for each element of pRegions (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkCmdCopyBufferToImage-pRegions-00171)
    Objects: 2
        [0] 0x2d36c6683d0, type: 6, name: NULL
        [1] 0xb82de40000000077, type: 9, name: NULL
```

于是输出了总数据量

```cpp
        if (image_data_ptr->need_staging)
        {
            assert((format_properties.optimalTilingFeatures & format_feature_flags) == format_feature_flags);
            image_data_ptr->staging_buffer_data =
                BufferData(physical_device,
                           logical_device,
                           extent.width * extent.height * 4 * 6, // cubemap have 6 images
                           vk::BufferUsageFlagBits::eTransferSrc);
            MEOW_INFO("extent.width * extent.height * 4 * 6 = {}", extent.width * extent.height * 4 * 6);
            image_tiling = vk::ImageTiling::eOptimal;
            usage_flags |= vk::ImageUsageFlagBits::eTransferDst;
            initial_layout = vk::ImageLayout::eUndefined;
        }
```

确实是 393216

于是再输出每个 copy region 的 offset

```cpp
        OneTimeSubmit(
            logical_device,
            onetime_submit_command_pool,
            graphics_queue,
            [&](const vk::raii::CommandBuffer& command_buffer) {
                if (image_data_ptr->need_staging)
                {
                    // Since we're going to blit to the texture image, set its layout to eTransferDstOptimal
                    image_data_ptr->SetLayout(
                        command_buffer, vk::ImageLayout::eUndefined, vk::ImageLayout::eTransferDstOptimal);
                    std::vector<vk::BufferImageCopy> copy_regions;
                    // cubemap have 6 images
                    for (std::size_t i = 0; i < 6; ++i)
                    {
                        copy_regions.emplace_back(extent.width * extent.height * 4 * i, /* bufferOffset */
                                                  image_data_ptr->extent.width,
                                                  image_data_ptr->extent.height,
                                                  vk::ImageSubresourceLayers(aspect_mask, 0, i, 1),
                                                  vk::Offset3D(0, 0, 0),
                                                  vk::Extent3D(image_data_ptr->extent, 1));
                        MEOW_INFO("i = {}", i);
                        MEOW_INFO("extent.width * extent.height * 4 * i = {}", extent.width * extent.height * 4 * i);
                    }
```

结果

```
[MeowEngine][2024-11-26 09:19:36] extent.width * extent.height * 4 * 6 = 393216
[MeowEngine][2024-11-26 09:19:36] i = 0
[MeowEngine][2024-11-26 09:19:36] extent.width * extent.height * 4 * i = 0
[MeowEngine][2024-11-26 09:19:36] i = 1
[MeowEngine][2024-11-26 09:19:36] extent.width * extent.height * 4 * i = 65536
[MeowEngine][2024-11-26 09:19:36] i = 2
[MeowEngine][2024-11-26 09:19:36] extent.width * extent.height * 4 * i = 131072
[MeowEngine][2024-11-26 09:19:36] i = 3
[MeowEngine][2024-11-26 09:19:36] extent.width * extent.height * 4 * i = 196608
[MeowEngine][2024-11-26 09:19:36] i = 4
[MeowEngine][2024-11-26 09:19:36] extent.width * extent.height * 4 * i = 262144
[MeowEngine][2024-11-26 09:19:36] i = 5
[MeowEngine][2024-11-26 09:19:36] extent.width * extent.height * 4 * i = 327680
```

那确实没问题啊

为什么会 `trying to copy 262144 bytes`

65536*4=262144

于是发现是我的图像格式是 16B 的，之前是 4B 的所以乘 4，现在应该乘 16

copy region 按照图像格式算出来的是对的，我自己的是错的