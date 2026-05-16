# ID 问题

## model ptr weak ptr == nullptr

在创建的时候就测试

```cpp
UUID                        model_go_id  = level_ptr->CreateObject();
std::shared_ptr<GameObject> model_go_ptr = level_ptr->GetGameObjectByID(model_go_id).lock();

#ifdef MEOW_DEBUG
if (!model_go_ptr)
    MEOW_ERROR("GameObject is invalid!");
#endif
model_go_ptr->SetName("Backpack");
TryAddComponent(model_go_ptr, "Transform3DComponent", std::make_shared<Transform3DComponent>());
TryAddComponent(model_go_ptr,
                "ModelComponent",
                std::make_shared<ModelComponent>("builtin/models/backpack/backpack.obj",
                                                    m_render_pass_ptr->input_vertex_attributes));
MEOW_INFO("Is model ptr null: {}", (model_go_ptr->TryGetComponent<ModelComponent>("ModelComponent"))->model_ptr.lock() == nullptr);
```

结果是 true

说明创建的时候就有问题

但是为什么其他模型没问题呢？我们调用的都是相同的 api 啊

于是在

```cpp
    template<typename TComponent>
    std::shared_ptr<TComponent> TryAddComponent(std::shared_ptr<GameObject> gameobject,
                                                const std::string&          component_type_name,
                                                std::shared_ptr<TComponent> component_ptr)
```

设断点，发现进到这里的时候，`ModelComponent` ptr 就已经 model ptr 为 empty 了

于是在

```cpp
    ModelComponent::ModelComponent(const std::string& file_path, BitMask<VertexAttributeBit> attributes)
    {
        if (g_runtime_global_context.resource_system->LoadModel(file_path, attributes, uuid))
            model_ptr = g_runtime_global_context.resource_system->GetModel(uuid);
    }
```

设断点，发现加载第一个 backpack 的时候，经过了 `GetModel` 还是 `model_ptr` 为 empty

然后之后就都正常了

好吧，最后发现问题了

`m_models_id2data` 用的是 model 的 ID 作为 key

但是我找的时候我用 ModelComponent 的 ID 来找

这就不对了

然后之后第二次找的时候，根据 string 的 path 来找因为他已经在 map 里面了，所以就能找到