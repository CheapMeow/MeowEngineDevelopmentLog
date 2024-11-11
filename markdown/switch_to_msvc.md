# 转到 msvc 编译器

## 启动 exe 失败

```shell
 gdb --args E:\repository\MeowEngine\build-debug\src\code_generator\CodeGenerator.exe -IE:/repository/MeowEngine/src/code_generator/src -IE:/repository/MeowEngine/src/runtime -IE:/repository/MeowEngine/src/3rdparty/glm -IE:/repository/MeowEngine/src/3rdparty/glfw/include -IE:/repository/MeowEngine/src/3rdparty/volk -IE:/software/VulkanSDK/1.3.290.0/Include -IE:/repository/MeowEngine/src/3rdparty/SPIRV-Cross -IE:/repository/MeowEngine/src/3rdparty/stb -IE:/repository/MeowEngine/src/3rdparty/assimp/include -IE:/repository/MeowEngine/build-debug/src/3rdparty/assimp/include -IE:/repository/MeowEngine/src/3rdparty/imgui -SE:/repository/MeowEngine/src/runtime -OE:/repository/MeowEngine/src/runtime/generated
```

```
(gdb) run
Starting program: E:\repository\MeowEngine\build-debug\src\code_generator\CodeGenerator.exe -IE:/repository/MeowEngine/src/code_generator/src -IE:/repository/MeowEngine/src/runtime -IE:/repository/MeowEngine/src/3rdparty/glm -IE:/repository/MeowEngine/src/3rdparty/glfw/include -IE:/repository/MeowEngine/src/3rdparty/volk -IE:/software/VulkanSDK/1.3.290.0/Include -IE:/repository/MeowEngine/src/3rdparty/SPIRV-Cross -IE:/repository/MeowEngine/src/3rdparty/stb -IE:/repository/MeowEngine/src/3rdparty/assimp/include -IE:/repository/MeowEngine/build-debug/src/3rdparty/assimp/include -IE:/repository/MeowEngine/src/3rdparty/imgui -SE:/repository/MeowEngine/src/runtime -OE:/repository/MeowEngine/src/runtime/generated
[New Thread 18060.0x51ec]
[New Thread 18060.0x53f4]
[New Thread 18060.0x94c]
[Thread 18060.0x53f0 exited with code 3221225781]
[Thread 18060.0x94c exited with code 3221225781]
[Thread 18060.0x51ec exited with code 3221225781]
During startup program exited with code 0xc0000135.
```

用 dependency walker 看了一下，似乎是 urt 库找不到

![](../assets/dependency_walker_profile_code_generator.png)

于是我加了一个 link

```cmake
target_link_directories(${CODE_GENERATOR_NAME} PUBLIC "C:/Program Files (x86)/Windows Kits/10/Redist/10.0.22621.0/ucrt/DLLs/x64")
```

也没有用

于是用 msvc 编译

```
E:\software\Microsoft Visual Studio\2022\Community\MSBuild\Microsoft\VC\v170\Microsoft.CppCommon.targets(254,5): error
MSB8066: “E:\repository\MeowEngine\build-debug\CMakeFiles\2d671ee5f42a60e9a73b806408c44d60\register_all.cpp.rule;E:\rep
ository\MeowEngine\build-debug\CMakeFiles\79af65e9bcaf32f02b60478ec74a6c9e\GenerateRegisterFile.rule;E:\repository\Meow
Engine\src\code_generator\CMakeLists.txt”的自定义生成已退出，代码为 -1073741515。 [E:\repository\MeowEngine\build-debug\src\code_gene
rator\GenerateRegisterFile.vcxproj]
```

也是这个 dll 找不到的问题

所以这和编译器无关

于是再上网查是为什么，查到了修复 Redistribution 的选项

![alt text](../assets/repair_vc_redis.png)

重启了之后，运行进程就会弹出缺少的 dll 了

所以还是需要修复 Redistribution，然后才能正常报错

## CodeGenerator DLL 缺失的问题

又出现了这个问题

```
E:\repositories\MeowEngine\build-debug\src\code_generator\CodeGenerator.exe -IE:/repositories/MeowEngine/src/code_generator/src -IE:/repositories/MeowEngine/src/meow_runtime -IE:/repositories/MeowEngine/src/3rdparty/glm -IE:/repositories/MeowEngine/src/3rdparty/glfw/include -IE:/repositories/MeowEngine/src/3rdparty/volk -IE:/software/VulkanSDK/1.3.275.0/Include -IE:/repositories/MeowEngine/src/3rdparty/SPIRV-Cross -IE:/repositories/MeowEngine/src/3rdparty/stb -IE:/repositories/MeowEngine/src/3rdparty/assimp/include -IE:/repositories/MeowEngine/build-debug/src/3rdparty/assimp/include -IE:/repositories/MeowEngine/src/3rdparty/imgui -SE:/repositories/MeowEngine/src/meow_runtime -OE:/repositories/MeowEngine/src/meow_runtime/generated
```

会没有结果

然后表现上看就是缺失了 dll

网上搜到的解释都是说更改 lib 的 MTd

但是问题是，它仅仅是一个 exe 啊，对任何我自己的 lib 都没有依赖啊

于是还是用二分法来排除把

原来的 CMakeLists.txt

```cmake
set(CODE_GENERATOR_HEADER_FILES
    src/parser/parser.h
    src/utils/code_gen_utils.h
    src/parse_result/class_parse_result.h
    src/parse_result/field_parse_result.h
    src/parse_result/method_parse_result.h
    src/generator/code_generator.h)
set(CODE_GENERATOR_SOURCE_FILES
    src/main.cpp
    src/parser/parser.cpp
    src/utils/code_gen_utils.cpp
    src/generator/code_generator.cpp)

set(HEADER_FILES_DEPEND
<all_headers_place_holder>)

source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}" FILES ${CODE_GENERATOR_HEADER_FILES}
                                                      ${CODE_GENERATOR_SOURCE_FILES})

add_executable(${CODE_GENERATOR_NAME} ${CODE_GENERATOR_HEADER_FILES} ${CODE_GENERATOR_SOURCE_FILES})

find_package(Vulkan REQUIRED) # export vars

target_include_directories(${CODE_GENERATOR_NAME} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/src)
target_include_directories(${CODE_GENERATOR_NAME} PUBLIC ${RUNTIME_DIR})
target_include_directories(${CODE_GENERATOR_NAME} PUBLIC ${3RD_PARTY_ROOT_DIR}/glm)
target_include_directories(${CODE_GENERATOR_NAME} PUBLIC ${3RD_PARTY_ROOT_DIR}/glfw/include)
target_include_directories(${CODE_GENERATOR_NAME} PUBLIC ${3RD_PARTY_ROOT_DIR}/volk)
target_include_directories(${CODE_GENERATOR_NAME} PUBLIC ${Vulkan_INCLUDE_DIRS})
target_include_directories(${CODE_GENERATOR_NAME} PUBLIC ${3RD_PARTY_ROOT_DIR}/SPIRV-Cross)
target_include_directories(${CODE_GENERATOR_NAME} PUBLIC ${3RD_PARTY_ROOT_DIR}/stb)
target_include_directories(${CODE_GENERATOR_NAME} PUBLIC ${3RD_PARTY_ROOT_DIR}/assimp/include)
target_include_directories(${CODE_GENERATOR_NAME} PUBLIC ${CMAKE_BINARY_DIR}/src/3rdparty/assimp/include) # for config.h
target_include_directories(${CODE_GENERATOR_NAME} PUBLIC ${3RD_PARTY_ROOT_DIR}/imgui)

function(get_target_include_directories TARGET VAR_NAME)  
    set(INCLUDE_DIRS "")  
    get_target_property(TMP_DIRS ${TARGET} INCLUDE_DIRECTORIES)    
    foreach(DIR ${TMP_DIRS})  
        # If DIR is a generator expression, there will be no expansion here
        # Here we assume they are direct paths 
        list(APPEND INCLUDE_DIRS "-I${DIR}")  
    endforeach()   
    set(${VAR_NAME} "${INCLUDE_DIRS}" PARENT_SCOPE)  
endfunction()  

get_target_include_directories(${CODE_GENERATOR_NAME} INCLUDE_PATH_COLLECTION)  

set_target_properties(${CODE_GENERATOR_NAME} PROPERTIES CXX_STANDARD 20)
set_target_properties(${CODE_GENERATOR_NAME} PROPERTIES FOLDER "Engine")

# being a cross-platform target, we enforce standards conformance on MSVC
target_compile_options(${CODE_GENERATOR_NAME}
                       PUBLIC "$<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/permissive->")
target_compile_options(${CODE_GENERATOR_NAME}
                       PUBLIC "$<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/WX->")

target_link_libraries(${CODE_GENERATOR_NAME} PUBLIC $ENV{LLVM_DIR}/lib/libclang.lib)
target_include_directories(${CODE_GENERATOR_NAME}
                           PUBLIC $ENV{LLVM_DIR}/include)

add_custom_command(
    OUTPUT ${RUNTIME_DIR}/generated/register_all.cpp
    COMMAND ${CODE_GENERATOR_NAME} ${INCLUDE_PATH_COLLECTION} "-S${RUNTIME_DIR}" "-O${RUNTIME_DIR}/generated"
    DEPENDS ${HEADER_FILES_DEPEND}
    COMMENT "Generating register_all.cpp"
)
add_custom_target(${GENERATED_FILE_TARGET_NAME}
    DEPENDS ${RUNTIME_DIR}/generated/register_all.cpp
)
```

现在把后面的都删掉

```cmake
set(CODE_GENERATOR_HEADER_FILES
    src/parser/parser.h
    src/utils/code_gen_utils.h
    src/parse_result/class_parse_result.h
    src/parse_result/field_parse_result.h
    src/parse_result/method_parse_result.h
    src/generator/code_generator.h)
set(CODE_GENERATOR_SOURCE_FILES
    src/main.cpp
    src/parser/parser.cpp
    src/utils/code_gen_utils.cpp
    src/generator/code_generator.cpp)

set(HEADER_FILES_DEPEND
<all_headers_place_holder>)

source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}" FILES ${CODE_GENERATOR_HEADER_FILES}
                                                    ${CODE_GENERATOR_SOURCE_FILES})

add_executable(${CODE_GENERATOR_NAME} ${CODE_GENERATOR_HEADER_FILES} ${CODE_GENERATOR_SOURCE_FILES})
```

于是结果是一样的。这也是合理的，include 不会影响什么

那就是纯粹的代码上的问题？

于是用了 [https://github.com/lucasg/Dependencies](https://github.com/lucasg/Dependencies)

的工具，就没有这些问题了

根据这里所说 [https://stackoverflow.com/questions/33969123/why-are-all-my-c-programs-exiting-with-0xc0000139](https://stackoverflow.com/questions/33969123/why-are-all-my-c-programs-exiting-with-0xc0000139)

我确实用的 gcc 编译，于是把环境变量 mingw bin 的优先级调最高，也没用

于是还是放弃 gcc，试试 msvc

## incomplete type

```cpp
#include <cstdint>
#include <type_traits>

enum class VertexAttributeBit : uint32_t
{
    None     = 0x00000000,
    Position = 0x00000001,
    UV0      = 0x00000002,
    ALL      = 0x00000003,
};

#pragma once

#include <vector>

template<typename BitType>
class BitMask
{
public:
    using UnderlyingType = typename std::underlying_type<BitType>::type;

    constexpr BitMask() noexcept
        : m_mask(0)
    {}

    constexpr BitMask(BitType bit) noexcept
        : m_mask(static_cast<UnderlyingType>(bit))
    {}

    constexpr BitMask(BitMask<BitType> const& rhs) noexcept = default;

    constexpr explicit BitMask(UnderlyingType mask) noexcept
        : m_mask(mask)
    {}

    // This line cause Compilation failed in msvc
    // use of undefined type 'BitMask<VertexAttributeBit>'
    inline static BitMask<BitType> all_mask = static_cast<BitMask<BitType>>(BitType::ALL);

    // This line pass Compilation
    // inline static UnderlyingType all_mask = static_cast<UnderlyingType>(BitType::ALL);

private:
    UnderlyingType m_mask;
};

int main() { BitMask<VertexAttributeBit> attr; }
```

最终发现是这一行的问题

虽然不知道为什么我在 gcc 里面都可以编译

但是现在既然换成了 msvc，那么就还是跟着他来吧

## pointer to memebr

调用栈

```cpp
reflect::AddClass<ModelComponent>("ModelComponent")
    .AddArray("m_image_paths", "std::vector<std::string>", "std::string", &ModelComponent::m_image_paths);
```

```cpp
template<typename ArrayType>
TypeDescriptorBuilder& AddArray(const std::string& name,
                                const std::string& type_name,
                                const std::string& inner_type_name,
                                ArrayType ClassType::*array_ptr)
{
    m_type_descriptor.AddArray(ArrayAccessor(name, type_name, inner_type_name, array_ptr));
    return *this;
}
```

然后这里报错

```cpp
E:\repositories\MeowEngine\src\meow_runtime\core\reflect\type_descriptor_builder.hpp(38,57): error C2440: “<function-style-cast>”: 无法从“initializer list”转换为“Meow::reflect::ArrayAccessor” [E:\repositories\MeowEngine\build-
debug\src\meow_runtime\MeowRuntime.vcxproj]
  (编译源文件“../../../../src/meow_runtime/generated/register_all.cpp”)
      E:\repositories\MeowEngine\src\meow_runtime\core\reflect\type_descriptor_builder.hpp(38,57):
      “Meow::reflect::ArrayAccessor::ArrayAccessor”: 函数不接受 4 个参数
          E:\repositories\MeowEngine\src\meow_runtime\core\reflect\reflect.hpp(62,13):
          可能是“Meow::reflect::ArrayAccessor::ArrayAccessor(const std::string &,const std::string &,const std::string &,ArrayType<InnerType> ClassType::* )”
          E:\repositories\MeowEngine\src\meow_runtime\core\reflect\type_descriptor_builder.hpp(38,57):
          尝试匹配参数列表“(const std::string, const std::string, const std::string, ArrayType Meow::ModelComponent::* )”时
          with
          [
              ArrayType=std::vector<std::string,std::allocator<std::string>>
          ]
      E:\repositories\MeowEngine\src\meow_runtime\core\reflect\type_descriptor_builder.hpp(38,57):
      模板实例化上下文(最早的实例化上下文)为
          E:\repositories\MeowEngine\src\meow_runtime\generated\register_all.cpp(24,4):
          查看对正在编译的函数 模板 实例化“Meow::reflect::TypeDescriptorBuilder<Meow::ModelComponent> &Meow::reflect::TypeDescriptorBuilder<Meow::ModelComponent>::AddArray<std::vector<std::string,std::allocator<std::string>>>(const std
  ::string &,const std::string &,const std::string &,ArrayType Meow::ModelComponent::* )”的引用
          with
          [
              ArrayType=std::vector<std::string,std::allocator<std::string>>
          ]
              E:\repositories\MeowEngine\src\meow_runtime\generated\register_all.cpp(24,13):
              请参阅 "Meow::RegisterAll" 中对 "Meow::reflect::TypeDescriptorBuilder<Meow::ModelComponent>::AddArray" 的第一个引用
```

可能是函数类型不匹配……？

或者单纯是推导不了

但是明明 gcc 也是可以推导的

于是还是把模板类型改成简单的

```cpp
template<typename ClassType, typename InnerType>
ArrayAccessor(const std::string&     name,
                const std::string&     type_name,
                const std::string&     inner_type_name,
                std::vector<InnerType> ClassType::*array_ptr)
```

## j 未声明的标识符

```cpp
    void Model::LoadSkin(std::unordered_map<size_t, ModelVertexSkin>& skin_info_map,
                         ModelMesh*                                   mesh,
                         const aiMesh*                                ai_mesh,
                         const aiScene*                               ai_scene)
    {
        std::unordered_map<size_t, size_t> bone_index_map;

        for (size_t i = 0; i < (size_t)ai_mesh->mNumBones; ++i)
        {
            aiBone*     bone_info = ai_mesh->mBones[i];
            std::string bone_name(bone_info->mName.C_Str());
            size_t      bone_index = bones_map[bone_name]->index;

            // bone在mesh中的索引
            size_t mesh_bone_index = 0;
            auto   it              = bone_index_map.find(bone_index);
            if (it == bone_index_map.end())
            {
                mesh_bone_index = (size_t)mesh->bones.size();
                mesh->bones.push_back(bone_index);
                bone_index_map.insert(std::make_pair(bone_index, mesh_bone_index));
            }
            else
            {
                mesh_bone_index = it->second;
            }

            // 收集被Bone影响的顶点信息
            for (size_t j = 0; j < bone_info->mNumWeights; ++j)
            {
                size_t vertexID = bone_info->mWeights[j].mVertexId;
                float  weight   = bone_info->mWeights[j].mWeight;
                // 顶点->Bone
                if (skin_info_map.find(vertexID) == skin_info_map.end())
                {
                    skin_info_map.insert(std::make_pair(vertexID, ModelVertexSkin()));
                }
                ModelVertexSkin* info     = &(skin_info_map[vertexID]);
                info->indices[info->used] = mesh_bone_index;
                info->weights[info->used] = weight;
                info->used += 1;
                // 只允许最多四个骨骼影响顶点
                if (info->used >= 4)
                {
                    break;
                }
            }
        }
```

最后发现是编码的问题

vscode中保存为utf-8,然后MSVC中国大陆地区默认用gbk导致的

## error C2589: “(”:“::”右边的非法标记

看上去是 max 的问题

但是我已经定义了 NOMINMAX 仍然报错

于是把这个定义定在了 public 上

```cmake
target_compile_definitions(${RUNTIME_NAME} PUBLIC
  NOMINMAX) # for std::numeric_limits<double>::min() and max()
```

然后就没错了

看上去 public 是可以传播给第三方库？

## model ptr 为 empty

```cpp
    bool Camera3DComponent::FrustumCulling(std::shared_ptr<GameObject> gameobject)
    {
        auto transform_shared_ptr = gameobject->TryGetComponent<Transform3DComponent>("Transform3DComponent");
        if (!transform_shared_ptr)
            return false;

        auto model_shared_ptr = gameobject->TryGetComponent<ModelComponent>("ModelComponent");
        if (!model_shared_ptr)
            return false;
        
        MEOW_INFO("{} is pass!", gameobject->GetName());

        auto bounding = model_shared_ptr->model_ptr.lock()->GetBounding();
        bounding.min  = bounding.min * transform_shared_ptr->scale + transform_shared_ptr->position;
        bounding.max  = bounding.max * transform_shared_ptr->scale + transform_shared_ptr->position;

        return CheckVisibility(&bounding);
    }
```

中

```cpp
auto bounding = model_shared_ptr->model_ptr.lock()->GetBounding();
```

会报错，`model_ptr` 为空

但是前面的 `ModelComponent` 都找得到

按道理来说，一个 `ModelComponent` 就会有一个对应资源的指针啊

于是给所有 mesh 标号

```cpp
        for (int i = 0; i < 200; i++)
        {
            UUID                        model_go_id1  = level_ptr->CreateObject();
            std::shared_ptr<GameObject> model_go_ptr1 = level_ptr->GetGameObjectByID(model_go_id1).lock();

            model_go_ptr1->SetName("Backpack" + std::to_string(i + 1));
```

并且输出通过判断的所有物体

```cpp
MEOW_INFO("{} is pass!", gameobject->GetName());
```

输出结果

```
[MeowEngine][2024-10-27 22:37:31] Backpack3 is pass!
[MeowEngine][2024-10-27 22:37:31] Backpack158 is pass!
[MeowEngine][2024-10-27 22:37:31] Backpack is pass!
```

然后就是在 `Backpack` 报错的

就很神奇，为什么

然后这个 go 本身带的 weak ptr 还进入了循环依赖

```
+		[ptr]	0x0000025370b60370 {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr {self_weak_ptr=weak_ptr  [2 strong refs, 3 weak refs] [] m_id={...} m_name="Backpack" ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...} [2 strong refs, 3 weak refs] [make_shared] ...}	Meow::GameObject *

```

然后才发现为什么我写了这个玩意啊

我到底在想什么

```cpp
    UUID Level::CreateObject()
    {
        FUNCTION_TIMER();

        UUID object_id;

        std::shared_ptr<GameObject> gobject;
        try
        {
            gobject = std::make_shared<GameObject>(object_id);
        }
        catch (const std::bad_alloc&)
        {
            MEOW_ERROR("cannot allocate memory for new gobject");
        }

        m_gameobjects.insert({object_id, gobject});
        gobject->self_weak_ptr = gobject;

        return object_id;
    }
```

于是删了

然后发现我似乎是想要在 gameobject 里面定义 addcomponent 的方法

```cpp
component_ptr->m_parent_object = self_weak_ptr;
```

所以才这么写

太蠢了……