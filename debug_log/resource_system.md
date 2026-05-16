# 资源系统

## 资源系统

我发现还是要限制一下资源系统的自由度

Load 类的函数就是接受一个文件地址的

然后维护一个文件地址对应 uuid 的 map

然后 unload 的时候就再删减这个 map

get 的时候应该拿 uuid 来查，而不是用文件地址来查

因为之后要添加一个创建本地资源的功能

之前是根据文件地址这个字符串来找资源，现在你增加内置资源的时候，就没有文件地址这个东西了，那你要用什么来分别不同的本地资源呢

如果是自己再给本地资源加一个命名的话，你还需要每一次创建本地资源时传入的名字不同，如果是内部创建名字的话，首先你就要根据传入的资源是什么来创建不同的字符串，或者也是单纯的不看种类，单纯在返回值里面放一个与之前的资源都不同的字符串

但是这样的话，这个传出的字符串仅仅是起到标识的作用，完全就看上去很多余

还不如直接用一个 uuid 来辨识资源

那么既然都有了 uuid，那就没有必要再用字符串来分别了

然后程序内部在查找资源的时候，就只用 uuid 来查找

然后资源系统里面会有一份资源的 shared ptr

即使是没有任何一个地方用到这个资源，他也不会被销毁，只能是程序退出时资源系统析构，或者是手动删除这个 shared ptr 导致资源释放

手动删除就通过 uuid 来做

这样就完成了 Load 和 Unload

那么如果我全部都用 cpp 来写的话，我自然是可以注意其他地方只存 uuid

但是如果是从编辑器拖拽文件的这种方式呢

我觉得应该是，拖拽的时候就是传入文件地址，然后会尝试 load，所以 load 里面需要检查这个文件地址是否已经 load 过了，如果没有，那么加载，返回 uuid，如果有，那么直接返回 uuid

那么这里就需要一个 string 指向 uuid 的 map

然后但是你要通过 uuid 来查资源 shared ptr，所以这也需要一个 map

那么在 shared_ptr 销毁的时候，对应的这个 string 指向 uuid 的 map 中对应的条目也要销毁

好吧，甚至是即使是不考虑这个 string 指向 uuid 的 map，单看 uuid 指向 shared_ptr 的 map 中对应的条目也要销毁

但是问题是你不知道 shared_ptr 什么时候销毁

虽然你可以做一些侵入式的设计，比如在你自己的代码里面有类 A，那么在 A 的构造和析构里面使用订阅观察者模式，来通知资源系统删除这个条目，但是很丑……

好吧，这么想是无稽之谈，因为不是因为 shared_ptr 引用计数 0 了才去销毁 uuid 指向 shared_ptr 的 map 中对应的条目

而是别人调用了 Unload，传入 uuid，删除 uuid 指向 shared_ptr 的 map 中对应的条目，然后 shared_ptr 释放了，就这样

要关心的是别的事情，比如怎么删除 string 指向 uuid 的 map 中对应的条目

那就好办了，直接在 Unload 里面一起处理就好了

因为可能直接从 ModelComponent 拖动，来实现一个资源共享，所以要在 Model Component 里面也加 uuid

至于其他地方的 uuid 有效性管理，就交给后面吧，比如如果我不删这个 ModelComponent 但是单独删掉这个 Model 的 shared_ptr 的时候，那么这个肯定是一个单独的函数来完成，里面肯定也是考虑这些，所以不需要我忧心

## Model 的创建

我现在需要从顶点数据直接创建 model

于是外层调用

```cpp
        const float*       cube_vertex_data = reinterpret_cast<const float*>(k_colored_cube_data);
        std::vector<float> cube_vertex;
        for (int i = 0; i < 36 * 6; i++)
        {
            cube_vertex.push_back(cube_vertex_data[i]);
        }
        model_go_ptr->TryAddComponent<ModelComponent>(
            "ModelComponent",
            std::make_shared<ModelComponent>(
                std::move(cube_vertex), std::vector<uint32_t>(), m_render_pass_ptr->input_vertex_attributes));
```

给 gameobject 创建 ModelComponent

```cpp
    class [[reflectable_class()]] ModelComponent : public Component
    {
    public:
        UUIDv4::UUID         uuid;
        std::weak_ptr<Model> model_ptr;

        ModelComponent(std::vector<float>&&        vertices,
                       std::vector<uint32_t>&&     indices,
                       BitMask<VertexAttributeBit> attributes)
        {
            if (g_runtime_global_context.resource_system->LoadModel(
                    std::move(vertices), std::move(indices), attributes, uuid))
                model_ptr = g_runtime_global_context.resource_system->GetModel(uuid);
        }

```

ModelComponent 内是向资源系统加载资源
 
```cpp
    bool ResourceSystem::LoadModel(std::vector<float>&&        vertices,
                                   std::vector<uint32_t>&&     indices,
                                   BitMask<VertexAttributeBit> attributes,
                                   UUIDv4::UUID&               uuid)
    {
        FUNCTION_TIMER();

        if (m_models_id2data.find(uuid) != m_models_id2data.end())
        {
            return true;
        }

        std::shared_ptr<Model> model_ptr =
            g_runtime_global_context.render_system->CreateModel(std::move(vertices), std::move(indices), attributes);

        if (model_ptr)
        {
            uuid                   = m_uuid_generator.getUUID();
            m_models_id2data[uuid] = model_ptr;
            return true;
        }
        else
        {
            return false;
        }
    }
```

ResourceSystem 内是调用渲染系统来创建渲染相关的资源

```cpp
    std::shared_ptr<Model> RenderSystem::CreateModel(std::vector<float>&&        vertices,
                                                     std::vector<uint32_t>&&     indices,
                                                     BitMask<VertexAttributeBit> attributes)
    {
        FUNCTION_TIMER();

        return std::make_shared<Model>(m_gpu,
                                       m_logical_device,
                                       m_upload_context.command_pool,
                                       m_present_queue,
                                       std::move(vertices),
                                       std::move(indices),
                                       attributes);
    }
```

RenderSystem 内实际创建这个资源

```cpp
    Model::Model(vk::raii::PhysicalDevice const& physical_device,
                 vk::raii::Device const&         device,
                 vk::raii::CommandPool const&    command_pool,
                 vk::raii::Queue const&          queue,
                 std::vector<float>&&            vertices,
                 std::vector<uint32_t>&&         indices,
                 BitMask<VertexAttributeBit>     attributes)
    {
        vk::IndexType index_type = vk::IndexType::eUint32;
        uint32_t      stride     = VertexAttributesToSize(attributes);
        ModelMesh*    mesh       = new ModelMesh();
        mesh->vertices           = std::move(vertices);
        mesh->indices            = std::move(indices);
        mesh->vertex_count       = vertices.size() / stride * 4;

        if (vertices.size() > 0)
        {
            mesh->vertex_buffer_ptr = std::make_shared<VertexBuffer>(
                physical_device, device, command_pool, queue, vk::MemoryPropertyFlagBits::eDeviceLocal, mesh->vertices);
        }
        if (indices.size() > 0)
        {
            mesh->index_buffer_ptr = std::make_shared<IndexBuffer>(
                physical_device, device, command_pool, queue, vk::MemoryPropertyFlagBits::eDeviceLocal, mesh->indices);
        }

        mesh->bounding.min = glm::vec3(-1.0f, -1.0f, 0.0f);
        mesh->bounding.max = glm::vec3(1.0f, 1.0f, 0.0f);

        root_node       = new ModelNode();
        root_node->name = "RootNode";
        root_node->meshes.push_back(mesh);
        root_node->local_matrix = glm::mat4(1.0f);
        mesh->link_node         = root_node;

        meshes.push_back(mesh);
    }
```

创建这个资源的时候我就发现传入的 vertex 居然是空的

好吧，最后发现了，是因为我没有用 `mesh->vertices` 来判断

修改了这个之后，就没有出错了，但是绘制的时候，renderdoc 调试显示我没有绘制顶点

看了一下，我确实是把顶点数据传进去了，但是 draw 里面只绘制 0 个顶点

Debug 一下，确实

```cpp
    void ModelMesh::DrawOnly(const vk::raii::CommandBuffer& cmd_buffer)
    {
        FUNCTION_TIMER();

        if (vertex_buffer_ptr && index_buffer_ptr)
        {
            cmd_buffer.drawIndexed(index_buffer_ptr->index_count, 1, 0, 0, 0);
        }
        else if (vertex_buffer_ptr)
        {
            MEOW_INFO("vertex_count = {}", vertex_count);
            cmd_buffer.draw(vertex_count, 1, 0, 0);
        }
    }
```

于是还是这个模型顶点的问题

改成

```cpp
        mesh->vertex_count       = mesh->vertices.size() / stride * 4;
```

然后就好了

## API 设计

我是不希望资源类的内部去调用 global context 的

所以资源类的构造函数会包含很多 vulkan 资源句柄

但是这样就导致 resource system 的头文件中会用到 global context

但是 global context 又是包含各个 system 的

所以就有 include 循环了

想想还是放弃了这种坚持

什么能跑通就用什么

于是还是把调用 global context 放在了资源类内部

但是 model 本身的构造也是模板的

于是也要在头文件中调用 global context 

于是多写一个辅助函数，把调用的放在 cpp

## 希望设计统一的存储方法

```cpp
class ResourceSystem final : public System
{
public:
    ResourceSystem()  = default;
    ~ResourceSystem() = default;

    void Start() override {}

    void Tick(float dt) override {}

    template<typename ResourceType, typename... Args>
    UUID Register(Args&&... args)
    {
        auto res_ptr = std::make_shared<ResourceType>(std::forward<Args>(args)...);
        UUID res_uuid(res_ptr->uuid);
        m_resources[res_uuid] = res_ptr;
        return res_uuid;
    }

    template<typename ResourceType>
    std::shared_ptr<ResourceType> GetResource(UUID uuid)
    {
        auto it = m_resources.find(uuid);
        if (it == m_resources.end())
            return nullptr;

        return std::dynamic_pointer_cast<ResourceType>(it->second);
    }

private:
    std::unordered_map<UUID, std::shared_ptr<RenderResourceBase>> m_resources;
};
```

但是让 resource system 本身来思考怎么构造并不好

因为我在 image data 这里还会有

```cpp
static std::shared_ptr<ImageData> CreateDepthBuffer(vk::Format format, const vk::Extent2D& extent);

static std::shared_ptr<ImageData>
CreateTexture(const std::string&     file_path,
                vk::Format             format               = vk::Format::eR8G8B8A8Unorm,
                vk::ImageUsageFlags    usage_flags          = {},
                vk::ImageAspectFlags   aspect_mask          = vk::ImageAspectFlagBits::eColor,
                vk::FormatFeatureFlags format_feature_flags = {},
                bool                   anisotropy_enable    = false,
                bool                   force_staging        = false);

static std::shared_ptr<ImageData>
CreateAttachment(vk::Format             format               = vk::Format::eR8G8B8A8Unorm,
                    const vk::Extent2D&    extent               = {256, 256},
                    vk::ImageUsageFlags    usage_flags          = {},
                    vk::ImageAspectFlags   aspect_mask          = vk::ImageAspectFlagBits::eColor,
                    vk::FormatFeatureFlags format_feature_flags = {},
                    bool                   anisotropy_enable    = false);

static std::shared_ptr<ImageData>
CreateRenderTarget(vk::Format             format               = vk::Format::eR8G8B8A8Unorm,
                    const vk::Extent2D&    extent               = {256, 256},
                    vk::ImageUsageFlags    usage_flags          = {},
                    vk::ImageAspectFlags   aspect_mask          = vk::ImageAspectFlagBits::eColor,
                    vk::FormatFeatureFlags format_feature_flags = {},
                    bool                   anisotropy_enable    = false);

static std::shared_ptr<ImageData>
CreateCubemap(const std::vector<std::string>& file_paths,
                vk::Format                      format               = vk::Format::eR8G8B8A8Unorm,
                vk::ImageUsageFlags             usage_flags          = {},
                vk::ImageAspectFlags            aspect_mask          = vk::ImageAspectFlagBits::eColor,
                vk::FormatFeatureFlags          format_feature_flags = {},
                bool                            anisotropy_enable    = false,
                bool                            force_staging        = false);
```

这样的构造的辅助函数

于是就不好和传参数包配合

于是还是把构造这个工作交给外部实现吧