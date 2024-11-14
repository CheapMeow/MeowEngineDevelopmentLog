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

然后去找别人有没有写现成的

看到一个人管理资源要处理很多依赖，还要考虑能不能合并成 subpass

[https://themaister.net/blog/2017/08/15/render-graphs-and-vulkan-a-deep-dive/](https://themaister.net/blog/2017/08/15/render-graphs-and-vulkan-a-deep-dive/)

这个确实好复杂啊

完全没有做过这些东西，所以想象不到他的应用场合

这里也提到了根据频率来渲染的

[https://zeux.io/2020/02/27/writing-an-efficient-vulkan-renderer/](https://zeux.io/2020/02/27/writing-an-efficient-vulkan-renderer/)

但是后面还有 bindless 的

根据频率来渲染的他说劣势是 mipmap 之类的……？我也不太懂

## 看 Acid 引擎

试试构建 Acid 引擎

下载 OpenAL SDK 配置 `OPENALDIR` 环境变量

然后是找不到 python

于是传入了 msvc 的

```bat
 -D@echo off

cls

REM Configure a debug build
cmake -S . -B build-debug/ -G "Visual Studio 17 2022" -A x64 -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Debug -DPYTHON_EXECUTABLE="e:\software\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\VC\SecurityIssueAnalysis\python\python.exe"
cmake --build build-debug/ --parallel 8

pause
```

然后是 OpenAL 又有问题

```
-- Could NOT find OpenALSoft (missing: OPENALSOFT_LIBRARY OPENALSOFT_INCLUDE_DIR) 
CMake Error at Sources/CMakeLists.txt:31 (add_library):
  add_library cannot create imported target "OpenAL::OpenAL" because another
  target with the same name already exists.
```

是 openal target 重复

于是那个部分改成

```cmake
# OpenAL must be installed on the system, env "OPENALDIR" must be set
find_package(OpenALSoft)
find_package(OpenAL)
if(OPENALSOFT_FOUND)
	#if(OPENALSOFT_FOUND AND NOT TARGET OpenAL::OpenAL)
		add_library(OpenAL::OpenAL UNKNOWN IMPORTED)
		set_target_properties(OpenAL::OpenAL PROPERTIES
				IMPORTED_LOCATION "${OPENALSOFT_LIBRARY}"
				INTERFACE_INCLUDE_DIRECTORIES "${OPENALSOFT_INCLUDE_DIR}"
				)
	#endif()
elseif(OPENAL_FOUND)
	if(NOT TARGET OpenAL::OpenAL)
		add_library(OpenAL::OpenAL UNKNOWN IMPORTED)
	endif()
	set_target_properties(OpenAL::OpenAL PROPERTIES
	IMPORTED_LOCATION "${OPENAL_LIBRARY}"
	INTERFACE_INCLUDE_DIRECTORIES "${OPENAL_INCLUDE_DIR}"
	)
else()
	message(FATAL_ERROR "Could not find OpenAL or OpenAL-Soft")
endif()

```

就可以编译了

但是很多可执行文件都会报错

于是还是放弃了

直接看看他的源码

### descriptor

根据 pipeline 来创建的 descriptor

```cpp
DescriptorsHandler::DescriptorsHandler(const Pipeline &pipeline) :
	shader(pipeline.GetShader()),
	pushDescriptors(pipeline.IsPushDescriptors()),
	descriptorSet(std::make_unique<DescriptorSet>(pipeline)),
	changed(true) {
}
```

然后添加 descriptor 的时候就是根据 material 的 pipeline 来创建

更新数据的时候看上去是要先把数据堆在一个 `map` 里面

```cpp
void DescriptorsHandler::Push(const std::string &descriptorName, UniformHandler &uniformHandler, const std::optional<OffsetSize> &offsetSize) {
	if (shader) {
		uniformHandler.Update(shader->GetUniformBlock(descriptorName));
		Push(descriptorName, uniformHandler.GetUniformBuffer(), offsetSize);
	}
}

void DescriptorsHandler::Push(const std::string &descriptorName, StorageHandler &storageHandler, const std::optional<OffsetSize> &offsetSize) {
	if (shader) {
		storageHandler.Update(shader->GetUniformBlock(descriptorName));
		Push(descriptorName, storageHandler.GetStorageBuffer(), offsetSize);
	}
}

void DescriptorsHandler::Push(const std::string &descriptorName, PushHandler &pushHandler, const std::optional<OffsetSize> &offsetSize) {
	if (shader) {
		pushHandler.Update(shader->GetUniformBlock(descriptorName));
	}
}
```

底层就是这个 `map`

```cpp
	template<typename T>
	void Push(const std::string &descriptorName, const T &descriptor, const std::optional<OffsetSize> &offsetSize = std::nullopt) {
		if (!shader)
			return;

		// Finds the local value given to the descriptor name.
		auto it = descriptors.find(descriptorName);

		if (it != descriptors.end()) {
			// If the descriptor and size have not changed then the write is not modified.
			if (it->second.descriptor == to_address(descriptor) && it->second.offsetSize == offsetSize) {
				return;
			}

			descriptors.erase(it);
		}

		// Only non-null descriptors can be mapped.
		if (!to_address(descriptor)) {
			return;
		}

		// When adding the descriptor find the location in the shader.
		auto location = shader->GetDescriptorLocation(descriptorName);

		if (!location) {
#ifdef ACID_DEBUG
			if (shader->ReportedNotFound(descriptorName, true)) {
				Log::Error("Could not find descriptor in shader ", shader->GetName(), " of name ", std::quoted(descriptorName), '\n');
			}
#endif

			return;
		}

		auto descriptorType = shader->GetDescriptorType(*location);

		if (!descriptorType) {
#ifdef ACID_DEBUG
			if (shader->ReportedNotFound(descriptorName, true)) {
				Log::Error("Could not find descriptor in shader ", shader->GetName(), " of name ", std::quoted(descriptorName), " at location ", *location, '\n');
			}
#endif
			return;
		}

		// Adds the new descriptor value.
		auto writeDescriptor = to_address(descriptor)->GetWriteDescriptor(*location, *descriptorType, offsetSize);
		descriptors.emplace(descriptorName, DescriptorValue{to_address(descriptor), std::move(writeDescriptor), offsetSize, *location});
		changed = true;
	}
```

如果已经有值了，那么就删掉旧值 `descriptors.erase(it);`

更新新值就这个 `descriptors.emplace`

然后 descriptor 的 value 还做了封装 `DescriptorValue`

实际更新的时候

```cpp
bool DescriptorsHandler::Update(const Pipeline &pipeline) {
	if (shader != pipeline.GetShader()) {
		shader = pipeline.GetShader();
		pushDescriptors = pipeline.IsPushDescriptors();
		descriptors.clear();
		writeDescriptorSets.clear();

		if (!pushDescriptors) {
			descriptorSet = std::make_unique<DescriptorSet>(pipeline);
		}

		changed = false;
		return false;
	}

	if (changed) {
		writeDescriptorSets.clear();
		writeDescriptorSets.reserve(descriptors.size());

		for (const auto &[descriptorName, descriptor] : descriptors) {
			auto writeDescriptorSet = descriptor.writeDescriptor.GetWriteDescriptorSet();
			writeDescriptorSet.dstSet = VK_NULL_HANDLE;

			if (!pushDescriptors)
				writeDescriptorSet.dstSet = descriptorSet->GetDescriptorSet();

			writeDescriptorSets.emplace_back(writeDescriptorSet);
		}

		if (!pushDescriptors)
			descriptorSet->Update(writeDescriptorSets);

		changed = false;
	}

	return true;
}
```

是否是 push 的这个选项我还不太懂

然后这个 `descriptors` 变量就是之前 push 过的

看看他的接口是怎么使用的

```cpp
void DeferredSubrender::Render(const CommandBuffer &commandBuffer) {
	auto camera = Scenes::Get()->GetScene()->GetCamera();

	// TODO probably use a cubemap image directly instead of scene components.
	std::shared_ptr<ImageCube> skybox = nullptr;
	auto meshes = Scenes::Get()->GetScene()->QueryComponents<Mesh>();
	for (const auto &mesh : meshes) {
		if (auto materialSkybox = dynamic_cast<const SkyboxMaterial *>(mesh->GetMaterial())) {
			skybox = materialSkybox->GetImage();
			break;
		}
	}

	if (this->skybox != skybox) {
		this->skybox = skybox;
		irradiance = Resources::Get()->GetThreadPool().Enqueue(ComputeIrradiance, skybox, 64);
		prefiltered = Resources::Get()->GetThreadPool().Enqueue(ComputePrefiltered, skybox, 512);
	}

	// Updates uniforms.
	std::vector<DeferredLight> deferredLights(MAX_LIGHTS);
	uint32_t lightCount = 0;

	auto sceneLights = Scenes::Get()->GetScene()->QueryComponents<Light>();

	for (const auto &light : sceneLights) {
		//auto position = *light->GetPosition();
		//float radius = light->GetRadius();

		//if (radius >= 0.0f && !camera.GetViewFrustum()->SphereInFrustum(position, radius))
		//{
		//	continue;
		//}

		DeferredLight deferredLight = {};
		deferredLight.colour = light->GetColour();

		if (auto transform = light->GetEntity()->GetComponent<Transform>())
			deferredLight.position = transform->GetPosition();

		deferredLight.radius = light->GetRadius();
		deferredLights[lightCount] = deferredLight;
		lightCount++;

		if (lightCount >= MAX_LIGHTS)
			break;
	}

	// Updates uniforms.
	uniformScene.Push("view", camera->GetViewMatrix());
	if (auto shadows = Scenes::Get()->GetScene()->GetSystem<Shadows>())
		uniformScene.Push("shadowSpace", shadows->GetShadowBox().GetToShadowMapSpaceMatrix());
	uniformScene.Push("cameraPosition", camera->GetPosition());
	uniformScene.Push("lightsCount", lightCount);
	uniformScene.Push("fogColour", fog.GetColour());
	uniformScene.Push("fogDensity", fog.GetDensity());
	uniformScene.Push("fogGradient", fog.GetGradient());

	// Updates storage buffers.
	storageLights.Push(deferredLights.data(), sizeof(DeferredLight) * MAX_LIGHTS);

	// Updates descriptors.
	descriptorSet.Push("UniformScene", uniformScene);
	descriptorSet.Push("BufferLights", storageLights);
	descriptorSet.Push("samplerShadows", Graphics::Get()->GetAttachment("shadows"));
	descriptorSet.Push("samplerPosition", Graphics::Get()->GetAttachment("position"));
	descriptorSet.Push("samplerDiffuse", Graphics::Get()->GetAttachment("diffuse"));
	descriptorSet.Push("samplerNormal", Graphics::Get()->GetAttachment("normal"));
	descriptorSet.Push("samplerMaterial", Graphics::Get()->GetAttachment("material"));
	descriptorSet.Push("samplerBRDF", *brdf);
	descriptorSet.Push("samplerIrradiance", *irradiance);
	descriptorSet.Push("samplerPrefiltered", *prefiltered);

	if (!descriptorSet.Update(pipeline))
		return;

	// Draws the object.
	pipeline.BindPipeline(commandBuffer);

	descriptorSet.BindDescriptor(commandBuffer, pipeline);
	vkCmdDraw(commandBuffer, 3, 1, 0, 0);
}
```

那么这个就看上去很正常

但是还是没有按照频率来更新啊

fine，或许这些东西都是性能测量之后才需要做的事情

现在回过来看的话，我的 descriptor 都是直接一次绑定所有

所以我需要的也仅仅是单独绑定某些 set

这就真的需要我自己约定了

总之先试试

## 再看 global uniform buffer

这是加载数据

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

这是在渲染之前的事情，把数据先自己存起来

渲染帧开始时，把存着的全局 uniform 数据存到 uniform 缓冲里面

```cpp
    void Material::BeginFrame()
    {
        FUNCTION_TIMER();

        if (actived)
        {
            return;
        }
        actived = true;

        // clear per obj data

        obj_count = 0;
        per_obj_dynamic_offsets.clear();

        // copy global uniform buffer data to ring buffer

        // global uniform buffer should be set before BeginFrame() is called
        // so copy global uniform buffer to ring buffer here
        // then it does not need to copy global uniform buffer later during this frame

        for (auto& global_uniform_buffer_info : global_uniform_buffer_infos)
        {
            uint8_t* ringCPUData = (uint8_t*)(ring_buffer.mapped_data_ptr);
            uint64_t bufferSize  = global_uniform_buffer_info.data.size();
            uint64_t ringOffset  = ring_buffer.AllocateMemory(bufferSize);

            memcpy(ringCPUData + ringOffset, global_uniform_buffer_info.data.data(), bufferSize);

            global_uniform_buffer_info.dynamic_offset = (uint32_t)ringOffset;
        }
    }
```

得到的 offset 只需要在这里一次了

这是对每一个物体都加载那个 global uniform buffer 的位置

```cpp
    void Material::BeginObject()
    {
        FUNCTION_TIMER();

        per_obj_dynamic_offsets.push_back(
            std::vector<uint32_t>(shader_ptr->uniform_buffer_count, std::numeric_limits<uint32_t>::max()));

        // copy global uniform buffer offset

        for (auto& global_uniform_buffer_info : global_uniform_buffer_infos)
        {
            per_obj_dynamic_offsets[obj_count][global_uniform_buffer_info.dynamic_offset_index] =
                global_uniform_buffer_info.dynamic_offset;
        }
    }
```

这是如果没有位置的时候，那么就只有全局 uniform

```cpp
    void Material::EndFrame()
    {
        FUNCTION_TIMER();

        actived = false;

        // if no object
        // all elements of per_obj_dynamic_offsets[0] are global uniform buffer offset

        if (per_obj_dynamic_offsets.size() == 0)
        {
            per_obj_dynamic_offsets.push_back(
                std::vector<uint32_t>(shader_ptr->uniform_buffer_count, std::numeric_limits<uint32_t>::max()));

            // copy global uniform buffer offset

            for (auto& global_uniform_buffer_info : global_uniform_buffer_infos)
            {
                per_obj_dynamic_offsets[0][global_uniform_buffer_info.dynamic_offset_index] =
                    global_uniform_buffer_info.dynamic_offset;
            }
        }
    }
```

所以这个和 dynamic 的 uniform 混合的方法还是，需要一段时间理解

之前我懂了，现在还是需要时间再想

然后想想还是不符合

于是删了

## 单独处理 uniform buffer

shader 里面要特别处理哪些是 dynamic

```cpp
    void Shader::GetUniformBuffersMeta(spirv_cross::Compiler&        compiler,
                                       spirv_cross::ShaderResources& resources,
                                       vk::ShaderStageFlags          stageFlags)
    {
        for (int32_t i = 0; i < resources.uniform_buffers.size(); ++i)
        {
            spirv_cross::Resource& res                        = resources.uniform_buffers[i];
            spirv_cross::SPIRType  type                       = compiler.get_type(res.type_id);
            spirv_cross::SPIRType  base_type                  = compiler.get_type(res.base_type_id);
            const std::string&     var_name                   = compiler.get_name(res.id);
            const std::string&     type_name                  = compiler.get_name(res.base_type_id);
            uint32_t               uniform_buffer_struct_size = (uint32_t)compiler.get_declared_struct_size(type);

            uint32_t set     = compiler.get_decoration(res.id, spv::DecorationDescriptorSet);
            uint32_t binding = compiler.get_decoration(res.id, spv::DecorationBinding);

            vk::DescriptorSetLayoutBinding set_layout_binding {binding,
                                                               (type_name.find("Dynamic") != std::string::npos) ?
                                                                   vk::DescriptorType::eUniformBufferDynamic :
                                                                   vk::DescriptorType::eUniformBuffer,
                                                               1,
                                                               stageFlags,
                                                               nullptr};
```

然后生成 uniform buffer 的 dynamic offset 时

加上 `if (descriptor_layout_binding.descriptorType == vk::DescriptorType::eUniformBufferDynamic)` 的条件判断

而不像之前那样直接认为所有的 uniform buffer 都是 dynamic

```cpp
    void Shader::GenerateDynamicUniformBufferOffset()
    {
        // metas has been sort acrroding to
        std::vector<DescriptorSetLayoutMeta>& metas = set_layout_metas.metas;

        // set uniform buffer offset index
        // for the use of dynamic uniform buffer
        // the offset index is related about set and binding
        // so it is wrong to iterate like:
        // for (auto& buffer_meta : buffer_meta_map)
        // instead, use double layer looping

        uniform_buffer_count = 0;
        for (auto& meta : metas)
        {
            for (auto& descriptor_layout_binding : meta.bindings)
            {
                if (descriptor_layout_binding.descriptorType == vk::DescriptorType::eUniformBufferDynamic)
                {
                    for (auto& buffer_meta : buffer_meta_map)
                    {
                        if (buffer_meta.second.set == meta.set &&
                            buffer_meta.second.binding == descriptor_layout_binding.binding &&
                            buffer_meta.second.descriptorType == descriptor_layout_binding.descriptorType &&
                            buffer_meta.second.stageFlags == descriptor_layout_binding.stageFlags)
                        {
                            buffer_meta.second.dynamic_offset_index = uniform_buffer_count;
                            uniform_buffer_count += 1;
                            break;
                        }
                    }
                }
            }
        }
    }
```

这个 `dynamic_offset_index` 并不是 vulkan 的，而是用来记录当前这个 dynamic uniform buffer 在所有的 dynamic uniform buffer 中排第几个

它的使用就是

```cpp
    void Material::PopulateDynamicUniformBuffer(const std::string& name, void* dataPtr, uint32_t size)
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

        // copy local uniform buffer to ring buffer

        uint8_t* ringCPUData = (uint8_t*)(ring_buffer.mapped_data_ptr);
        uint64_t bufferSize  = buffer_meta_iter->second.bufferSize;
        uint64_t ringOffset  = ring_buffer.AllocateMemory(bufferSize);

        memcpy(ringCPUData + ringOffset, dataPtr, bufferSize);

        per_obj_dynamic_offsets[obj_count][buffer_meta_iter->second.dynamic_offset_index] = (uint32_t)ringOffset;
    }
```

的

`per_obj_dynamic_offsets[obj_count][buffer_meta_iter->second.dynamic_offset_index] = (uint32_t)ringOffset;` 这里

这个每个物体的 offsets 最终的使用是

```cpp
    void Material::BindAllDescriptorSets(vk::raii::CommandBuffer const& command_buffer, int32_t obj_index)
    {
        FUNCTION_TIMER();

        if (obj_index >= per_obj_dynamic_offsets.size())
        {
            return;
        }

        command_buffer.bindDescriptorSets(vk::PipelineBindPoint::eGraphics,
                                          *shader_ptr->pipeline_layout,
                                          0,
                                          descriptor_sets,
                                          per_obj_dynamic_offsets[obj_index]);
    }
```

也就是说 vulkan 对于多个 dynamic uniform buffer 的使用就是这样的

`per_obj_dynamic_offsets[obj_index]` 的大小就是这个 shader 所有的 dynamic uniform buffer 的数量

根据规范

[https://docs.vulkan.org/spec/latest/chapters/descriptorsets.html#descriptorsets-binding]

> If any of the sets being bound include dynamic uniform or storage buffers, then pDynamicOffsets includes one element for each array element in each dynamic descriptor type binding in each set. Values are taken from pDynamicOffsets in an order such that all entries for set N come before set N+1; within a set, entries are ordered by the binding numbers in the descriptor set layouts; and within a binding array, elements are in order. dynamicOffsetCount must equal the total number of dynamic descriptors in the sets being bound.

他的意思就是，`pDynamicOffsets` 的取法是，多个集合之间，根据 `set` 从小到大排序，集合内根据 `binding` 从小到大排序

所以我们生成 `dynamic_offset_index` 也是这个顺序