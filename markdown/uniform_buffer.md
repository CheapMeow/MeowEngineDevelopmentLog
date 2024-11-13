# uniform buffer

## 环形缓冲类 Ring Buffer

### 内存分配方法

Ring buffer 内部存储一个 offset，记录已经分配的内存的数据量

该数据量不一定是内存对齐值的整数倍

从 Ring buffer 分配内存的时候，返回当前的 offset 的对齐之后的值作为分配的内存的首地址，同时 Ring buffer 内部存储的 offset 是这个首地址 + 分配的 size

对齐的首地址 + 不一定是内存对齐值的整数倍的分配的 size，得到的值又不一定是内存对齐值的整数倍了

如果新的 offset 超出了 Ring buffer 内部的数据区的长度，那么就不返回当前的 offset 的对齐之后的值，而是直接返回

### 内存分配结构

理想情况下，在一帧的末尾，ring buffer 对应于这一帧分配的内存的结构是

```
[...] 

[global buffer] 

[object 1 local buffer 1] [object 1 local buffer 2] [...] [object 1 local buffer n1] 

[object 2 local buffer 1] [object 2 local buffer 2] [...] [object 2 local buffer n2] 

[...]

[object m local buffer 1] [object m local buffer 2] [...] [object m local buffer nm] 
```

实际内存是线性的，这里为了方便理解就做了换行

因为你无法确定在这一帧提交 local uniform buffer 的顺序，而每次提交都会线性分配 ring buffer

所以你只能保证 global uniform buffer 在所有 local uniform buffer 的前面，因为 global uniform buffer 是在这一帧开始之前就知道的；还有你可以确定序号小的 object 提交的 buffer 一定在序号大的 object 之前，其他的顺序无法保证

### 内存分配记录

所以你可能有

```
[...] [global buffer] [object 1 local buffer 3] [object 1 local buffer 1] [...] [object 2 local buffer 1] [object 2 local buffer 4] [...]
```

所以在后端，每一次提交时都要记录下当前分配的 ring buffer 首地址，最后提供给 `vkCmdBindDescriptorSets` 的 `pDynamicOffsets` 字段

这个字段接受一个指针，指向一个存储 uniform buffer 偏移量的数组。对于我们的数据结构，就是存储 ring buffer 分配的内存的首地址的数组。

也就是说，我们认为 `pDynamicOffsets` 指向的数组要存储所有 object 的 offset

这个数组在每帧开始时清空，然后接受每一个 object 的 uniform buffer 对应的 offset

因为这一个材质对应的所有 object 都共用同一个 shader，所以显然所有 object 的 uniform buffer 的 descriptor 的数量都是一样的

所以如果这一帧有 N 个 object，每一个 object 的 uniform buffer 的 descriptor 的数量是 `dynamicOffsetCount` 那么 `pDynamicOffsets` 指向的数组的大小就是 `N * dynamicOffsetCount`

在每一帧，这个数组的每个元素都必须分配到正确的偏移量，否则就说明对应的 uniform buffer 没有提交。

当然，可以添加一个机制，为每一个 local uniform buffer 缓存最后一次提交的数据，如果这一帧没有提交对应的 local uniform buffer，那么就提交缓存。或者是提交缺省值。

N 个 object 对应 N 次 `vkCmdBindDescriptorSets` 和 draw，假设不考虑优化。

第 i 次 `vkCmdBindDescriptorSets` 需要传入 `pDynamicOffsets` 指向的数组的第 i 段区间，那么 `Material` 类需要对此进行封装

是否能够将这个设计简化，现在我们 `pDynamicOffsets` 指向的数组不再是存储所有 object 的 offset，而仅仅是一个指向某一个 object 的所有 offset 的数组

那么现在它的大小为 `dynamicOffsetCount`，不再是在 `BeginFrame` 中初始化，而是在 `BeginObject` 中初始化

`vkCmdBindDescriptorSets` 的 `pDynamicOffsets` 字段接受的就直接是数组的首地址，而不需要计算某一个大数组的某个区间的首地址

这样当然可以，但是因为不管是 `BeginFrame` 还是 `BeginObject`，都是在 render pass 启动之前的

那么每一个 object 对应的 offset 数组都要缓存

最后还是要做一个 `vector<vector<uint32_t>> per_obj_dynamic_offsets` 来存储每个物体在 ring buffer 上分配的内存的首地址

但是这个 `per_obj_dynamic_offsets` 并不能直接传入 `vkCmdBindDescriptorSets` 的 `pDynamicOffsets` 字段

因为可能存在一种情况：某一个 `Material` 并不需要绘制网格，而只是单纯的接受 uniform 输入并输出

那么这时，外部并不会对这个 `Material` 类实例调用 `BeginObject()` `EndObject()`

这时，`per_obj_dynamic_offsets` 为空，如果还坚持要将 `per_obj_dynamic_offsets` 的元素赋给`vkCmdBindDescriptorSets` 的 `pDynamicOffsets` 字段，就会出错

所以应该有一个判断，当 `per_obj_dynamic_offsets` 为空时，给 `per_obj_dynamic_offsets` 添加一个元素，并且把 global 的 offset 复制进去

这时，外部在绑定描述符集的时候直接传入 `obj_index = 0` 就好了

## 超内存限制了

单独一个物体是正常的

于是要测试一下最多渲染多少个物体不会卡

一开始做 101 个物体的时候就包了超出内存限制的错误，然后等待几分钟才出现渲染截面，并且才 10 帧

```
[12:58:40] RUNTIME: Error: { Validation }:
        messageIDName   = <VUID-vkAllocateMemory-maxMemoryAllocationCount-04101>
        messageIdNumber = 1318213324
        message         = <Validation Error: [ VUID-vkAllocateMemory-maxMemoryAllocationCount-04101 ] | MessageID = 0x4e9256cc | vkAllocateMemory():  vkAllocateMemory: Number of currently valid memory objects is not less than maxMemoryAllocationCount (4096). The Vulkan spec states: There must be less than VkPhysicalDeviceLimits::maxMemoryAllocationCount device memory allocations currently allocated on the device (https://vulkan.lunarg.com/doc/view/1.3.275.0/windows/1.3-extensions/vkspec.html#VUID-vkAllocateMemory-maxMemoryAllocationCount-04101)>
```

这个 `memory object` 它也没告诉我具体是什么样的 object

搜了一下，别人说可能是 uniform buffer 的数量超出限制了

[https://www.reddit.com/r/vulkan/comments/10uqjpl/vulkan_memory_allocator_number_of_currently_valid/](https://www.reddit.com/r/vulkan/comments/10uqjpl/vulkan_memory_allocator_number_of_currently_valid/)

开 renderdoc 看了一下，与渲染一个背包相关的渲染指令有 (351-39)/4+1 = 79 个，每一个渲染指令创建两个 buffer

也就是说，这个背包也需要 160 个 buffer 左右

怪不得我会超出限制

所以我做环形 uniform buffer 的目的是减小 uniform buffer 的数量？

不是

## 为什么要用环形缓冲呢

好吧我承认我没多想

就是单纯看到博客就跟着做了

实际上并不需要环形啊……

因为你每一次分配内存肯定是，要一次把所有的数据都装到内存里

那么你的环形缓冲的最大内存量肯定是要大于每一次需要的最大内存

那么既然你的缓冲的大小都会大于每一次分配的内存大小了

那么为什么还要环形

直接每一次都复用那块内存就好了

环形内存应该是用在尾部不断增长，头部随着需要可以删除，并且不希望不断分配内存的场景

比如通信

这个 uniform buffer 确实不是这个场合
 
uniform buffer 并不是为了减小 uniform buffer 的数量……本身之前对一个物体创建一个 uniform buffer 的做法就是，仅仅适用于少量物体的

本身 uniform buffer 就是为了一个 buffer 用于多个物体

## Uniform Buffer offset debug

发现我每个物体绑定的 UBO 都是同一个……

于是输出一下我的 offset

```cpp
    void Material::BindDescriptorSets(vk::raii::CommandBuffer const& command_buffer, int32_t obj_index)
    {
        FUNCTION_TIMER();

        if (obj_index >= per_obj_dynamic_offsets.size())
        {
            return;
        }

        std::cout << "per_obj_dynamic_offsets[obj_index]" << std::endl;
        for (int i = 0; i < per_obj_dynamic_offsets[obj_index].size(); i++)
        {
            std::cout << "per_obj_dynamic_offsets[obj_index][i] = " << per_obj_dynamic_offsets[obj_index][i]
                      << std::endl;
        }

        std::cout << std::endl;

        command_buffer.bindDescriptorSets(vk::PipelineBindPoint::eGraphics,
                                          *shader_ptr->pipeline_layout,
                                          0,
                                          descriptor_sets,
                                          per_obj_dynamic_offsets[obj_index]);
    }
```

对应的 draw 是

```cpp
    void DeferredPass::Draw(vk::raii::CommandBuffer const& command_buffer)
    {
        FUNCTION_TIMER();

        m_obj2attachment_mat.BindPipeline(command_buffer);

        // Debug
        if (m_query_enabled)
            command_buffer.beginQuery(*query_pool, 0, {});

        std::shared_ptr<Level> level_ptr = g_runtime_global_context.level_system->GetCurrentActiveLevel().lock();
        const auto&            all_gameobjects_map = level_ptr->GetAllGameObjects();
        for (const auto& kv : all_gameobjects_map)
        {
            std::shared_ptr<GameObject>     model_go_ptr = kv.second;
            std::shared_ptr<ModelComponent> model_comp_ptr =
                model_go_ptr->TryGetComponent<ModelComponent>("ModelComponent").lock();

            if (!model_comp_ptr)
                continue;

            for (int32_t i = 0; i < model_comp_ptr->model_ptr.lock()->meshes.size(); ++i)
            {
                m_obj2attachment_mat.BindDescriptorSets(command_buffer, i);
                model_comp_ptr->model_ptr.lock()->meshes[i]->BindDrawCmd(command_buffer);

                ++m_render_stat[0].draw_call;
            }
        }
```

于是发现了问题在哪……输入的是 mesh 的序号还要加上 gameobject 的序号

于是改了

```cpp
    void DeferredPass::Draw(vk::raii::CommandBuffer const& command_buffer)
    {
        FUNCTION_TIMER();

        m_obj2attachment_mat.BindPipeline(command_buffer);

        // Debug
        if (m_query_enabled)
            command_buffer.beginQuery(*query_pool, 0, {});

        std::shared_ptr<Level> level_ptr = g_runtime_global_context.level_system->GetCurrentActiveLevel().lock();
        const auto&            all_gameobjects_map = level_ptr->GetAllGameObjects();
        for (const auto& kv : all_gameobjects_map)
        {
            std::shared_ptr<GameObject>     model_go_ptr = kv.second;
            std::shared_ptr<ModelComponent> model_comp_ptr =
                model_go_ptr->TryGetComponent<ModelComponent>("ModelComponent").lock();

            if (!model_comp_ptr)
                continue;

            for (int32_t i = 0; i < model_comp_ptr->model_ptr.lock()->meshes.size(); ++i)
            {
                m_obj2attachment_mat.BindDescriptorSets(command_buffer, m_render_stat[0].draw_call);
                model_comp_ptr->model_ptr.lock()->meshes[i]->BindDrawCmd(command_buffer);

                ++m_render_stat[0].draw_call;
            }
        }
```

但是输出还是不对

```cpp
    void Material::BindDescriptorSets(vk::raii::CommandBuffer const& command_buffer, int32_t obj_index)
    {
        FUNCTION_TIMER();

        if (obj_index >= per_obj_dynamic_offsets.size())
        {
            return;
        }

        std::cout << "obj_index = " << obj_index << std::endl;
        std::cout << "per_obj_dynamic_offsets[obj_index]" << std::endl;
        for (int i = 0; i < per_obj_dynamic_offsets[obj_index].size(); i++)
        {
            std::cout << "per_obj_dynamic_offsets[obj_index][i] = " << per_obj_dynamic_offsets[obj_index][i]
                      << std::endl;
        }

        std::cout << std::endl;

        command_buffer.bindDescriptorSets(vk::PipelineBindPoint::eGraphics,
                                          *shader_ptr->pipeline_layout,
                                          0,
                                          descriptor_sets,
                                          per_obj_dynamic_offsets[obj_index]);
    }
```

```
obj_index = 3
per_obj_dynamic_offsets[obj_index]
per_obj_dynamic_offsets[obj_index][i] = 0

obj_index = 4
per_obj_dynamic_offsets[obj_index]
per_obj_dynamic_offsets[obj_index][i] = 0

obj_index = 5
per_obj_dynamic_offsets[obj_index]
per_obj_dynamic_offsets[obj_index][i] = 0

obj_index = 6
per_obj_dynamic_offsets[obj_index]
per_obj_dynamic_offsets[obj_index][i] = 0

obj_index = 7
per_obj_dynamic_offsets[obj_index]
per_obj_dynamic_offsets[obj_index][i] = 0

obj_index = 8
per_obj_dynamic_offsets[obj_index]
per_obj_dynamic_offsets[obj_index][i] = 0

obj_index = 9
```

offset 还是都是 0

于是 debug 内存分配

```cpp
    void Material::SetLocalUniformBuffer(const std::string& name, void* dataPtr, uint32_t size)
    {
        FUNCTION_TIMER();

        auto buffer_meta_iter = shader_ptr->buffer_meta_map.find(name);
        if (buffer_meta_iter == shader_ptr->buffer_meta_map.end())
        {
            RUNTIME_ERROR("Uniform {} not found.", name);
            return;
        }

        if (buffer_meta_iter->second.bufferSize != size)
        {
            RUNTIME_WARN("Uniform {} size not match, dst={} src={}", name, buffer_meta_iter->second.bufferSize, size);
        }

        // copy local uniform buffer to ring buffer

        uint8_t* ringCPUData = (uint8_t*)(ring_buffer.mapped_data_ptr);
        uint64_t bufferSize  = buffer_meta_iter->second.bufferSize;
        uint64_t ringOffset  = ring_buffer.AllocateMemory(bufferSize);

        memcpy(ringCPUData + ringOffset, dataPtr, bufferSize);

        std::cout << "obj_count = " << obj_count << std::endl;
        std::cout << "size = " << size << std::endl;
        std::cout << "buffer_meta_iter->second.dynamic_offset_index = " << buffer_meta_iter->second.dynamic_offset_index
                  << std::endl;
        std::cout << "ringOffset = " << ringOffset << std::endl;

        per_obj_dynamic_offsets[obj_count][buffer_meta_iter->second.dynamic_offset_index] = (uint32_t)ringOffset;
    }
```

部分输出

```
obj_count = 15
size = 192
buffer_meta_iter->second.dynamic_offset_index = 0
ringOffset = 0
obj_count = 16
size = 192
buffer_meta_iter->second.dynamic_offset_index = 0
ringOffset = 0
obj_count = 17
size = 192
buffer_meta_iter->second.dynamic_offset_index = 0
ringOffset = 0
obj_count = 18
size = 192
buffer_meta_iter->second.dynamic_offset_index = 0
ringOffset = 0
obj_count = 19
size = 192
buffer_meta_iter->second.dynamic_offset_index = 0
ringOffset = 0
obj_count = 20
size = 192
buffer_meta_iter->second.dynamic_offset_index = 0
ringOffset = 0
obj_count = 0
size = 2048
buffer_meta_iter->second.dynamic_offset_index = 0
```

确实发现每次分配都返回 0……为什么呢

于是发现是我的 debug stat 这里人为给分配的地址赋值成 0 了

```cpp
    uint64_t RingUniformBuffer::AllocateMemory(uint64_t size)
    {
        uint64_t new_memory_start = Align<uint64_t>(allocated_memory, min_alignment);

        if (new_memory_start + size <= buffer_size)
        {
            allocated_memory = new_memory_start + size;

            // stat
            begin = new_memory_start;
            usage = size;

            return new_memory_start;
        }
```

现在改好了，之前是 `new_memory_start = 0`

## global uniform buffer 在干什么

这个 global uniform buffer 为什么是把输入的数据再复制到自己那里？

```cpp
    void Material::SetGlobalUniformBuffer(const std::string& name, void* dataPtr, uint32_t size)
    {
        FUNCTION_TIMER();

        auto buffer_meta_iter = shader_ptr->buffer_meta_map.find(name);
        if (buffer_meta_iter == shader_ptr->buffer_meta_map.end())
        {
            MEOW_ERROR("Uniform {} not found.", name);
            return;
        }

        if (buffer_meta_iter->second.bufferSize != size)
        {
            MEOW_WARN("Uniform {} size not match, dst={} src={}", name, buffer_meta_iter->second.bufferSize, size);
        }

        // store data into info class instance

        auto global_uniform_buffer_info_iter = std::find_if(
            global_uniform_buffer_infos.begin(), global_uniform_buffer_infos.end(), [&](auto& rhs) -> bool {
                return rhs.dynamic_offset_index == buffer_meta_iter->second.dynamic_offset_index;
            });

        if (global_uniform_buffer_info_iter == global_uniform_buffer_infos.end())
        {
            GlobalUniformBufferInfo global_uniform_buffer_info;
            global_uniform_buffer_info.dynamic_offset_index = buffer_meta_iter->second.dynamic_offset_index;
            memcpy(global_uniform_buffer_info.data.data(), dataPtr, size);

            global_uniform_buffer_infos.push_back(global_uniform_buffer_info);
        }
        else
        {
            memcpy(global_uniform_buffer_info_iter->data.data(), dataPtr, size);
        }
    }
```

假设先不管为什么还要复制

`global_uniform_buffer_infos` 是怎么填充的？
 
是先在 `buffer_meta_map` 里面找，找到了之后看看和 `global_uniform_buffer_infos` 里面存的偏移是不是一个东西

## 他的加载逻辑

可以设置 dynamic uniform 或者普通 uniform

我现在才发现

然后他似乎在同一个地方同时能够处理 dynamic 和 uniform 的

但是这两个 offset 又混合在一起

算了，放弃

感觉这个直接写死了绑定的就是有问题

于是看到别人说的是，要根据频率来更新不同的 set

[https://www.reddit.com/r/vulkan/comments/avv808/multiple_descriptor_sets_vs_multiple_bindings_in/](https://www.reddit.com/r/vulkan/comments/avv808/multiple_descriptor_sets_vs_multiple_bindings_in/)

原始文章

[https://developer.nvidia.com/vulkan-shader-resource-binding](https://developer.nvidia.com/vulkan-shader-resource-binding)

说得非常对啊……而我现在这个抄的这个算是粗暴的做法

现在这个混合在一起的我确实看的很乱

果然还是要根据这个来

