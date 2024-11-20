## 着色器类 Shader

### 直接规定了 uniform buffer 为 dynamic

如果一个 descriptor set 里面没有 dynamic uniform buffer 类型的 descriptor，但是在 bind descriptor sets 又传入了动态偏移，就会出错

为了统一非 dynamic buffer 和 dynamic buffer 的 bind descriptor sets 的逻辑，直接令所有找到的 uniform buffer 都是 dynamic 了

这样可能导致内存浪费，比如一个用于 debug 的材质，它只需要一个 block，但是为了支持 dynamic 却给他分配了 32KB 的内存

### 反编译顶点属性，缓冲区和纹理输入

需要有一个东西管理 `vk::raii::ShaderModule` 和对应的 `vk::ShaderStageFlagBits`

DescriptorSet 需要负责从内存接受描述符对应的资源，上传到 gpu

因此 Shader 存储自己的对应的 DescriptorSet

DescriptorSet 和 DescriptorSetLayout 如果由人来指定的话，就会很麻烦，需要人手设置与 shader 一一对应的值，并且容易出错

例如模型文件的顶点数据的结构，需要和 shader 的顶点数据结构相匹配

不匹配的结果就会是一团糟，比如原本模型文件里面只有 position 和 normal，现在你用一个 position, normal, color, uv 输入的顶点着色器

那么就会把原来是 position 和 normal 的数据读一部分到 color, uv，这就全部乱了

vertex 数据错误读取了，原来能画 100 个三角形的数据现在错误地读成了画 50 个的，那剩下 50 个三角形的绘制没有数据了，vulkan 也不会报错

所以这可能一开始令人一头雾水……明明没有报错，文件读取也没有问题……

创建管线的时候会设置顶点数据的 stride，这个也跟顶点数据结构有关

这些都会导致错误……所以这些确实应该有一个自动化配置的方法

所以需要用一个类负责反编译 spv，自动生成 DescriptorSetLayout

这里也就直接用 Shader 类来处理

目前的反编译是直接识别顶点属性的名称

所以 glsl 里面的顶点属性的名称必须是特定的值，例如 inPosition, inUV0

### 使用 pool 数量可变的 Descriptor Allocator

创建 descriptor pool 的时候，可以初始指定可能需要的 descriptor 的种类和对应的数量。具体到 API 来说，这些是通过 pool size 来设置的

如果材质个数已知，那么其实 pool size 和 set count 都已知，那就不需要动态的 descriptor allocator 了

所以很多教程代码上面是直接通过某个 shader 对应的 descriptor set layout 算出对应的 pool size，得到的 descriptor pool 只用分配一次 descriptor，永远不会出错

因为 shader 数量是未知的，所以 descriptor set 的数量也是未知的

所以固定 set count 的 descriptor pool 可能会出错

所以使用动态大小的分配器，在 set count 不足的情况下动态创建 descriptor pool

那么这个动态大小的分配器内含的 descriptor pool 的初始的 pool size 怎么确定呢？既然现在你不想暴力通过某些 shader 的 descriptor set layout 来算

我感觉……应该没有标准做法，就是自己设定吧

我看到有一个做法是，在 `Shader` 类里面存动态数量的 descriptor pool 的

我在想，这个和有一个全局的 allocator，allocator 里面存很多个 descriptor pool，有什么区别

也就是，每个 `Shader` 有一堆 descriptor pool，和全局的一个 allocator 里面存一堆 descriptor pool，之间的区别

### 分配 descriptor set

从 descriptor pool 创建 descriptor set 需要 descriptor set layout

这个 set layout 是存储在 `Shader` 中的，是 `Shader` 对 spv 反编译的结果，描述了 `Shader` 所需的资源

获取 descriptor set 这个操作应该是在渲染主循环里面，原则上应该是程序员来控制，而不是在某个 struct 里面？

从最简单的情景开始想起：

假设一个程序员现在已经把反编译 spv 创建 descriptor set layout 的流程写完了，除此之外就没有别的自动化逻辑了

那么他仍然需要知道，自己要读取什么 spv shader，仍然要 hard code 从哪个 spv shader 来获取 descriptor，然后再根据这个 descriptor 来写入纹理或者 buffer

或许之后能够达到：在编辑器里面创建任意数量的 `Shader`，都不用程序员自己 hard code 要读取什么了，你有什么我就读什么

当然这里肯定涉及到资源加载的问题，在游戏运行时要读取什么 `Shader`

假设先不管这个，那么之后肯定是可以有这么一个自动化的东西的

不管怎么说，创建 descriptor set 的这个位置，不管是 hard code 还是自动化流程，位置应该是在主循环的

### 存储 descriptor set

根据 [vulkan_best_practice_for_mobile_developers/samples/performance/descriptor_management
/descriptor_management_tutorial.md](https://github.com/ARM-software/vulkan_best_practice_for_mobile_developers/blob/master/samples/performance/descriptor_management/descriptor_management_tutorial.md)

一般来说，只有当出现新的资源组合的时候，才需要创建新的 descriptor set

而不是在每帧渲染的时候 reset descriptor pool 然后重新为各个 `Shader` allocate descriptor set

那么其实"出现新的资源组合"就相当于出现新的 `Shader` 吧？

那么这种情况下，descriptor set 在主循环中获取，也应该是存储在全局的？

虽然我看大部分教程都是这么做的，但是我感觉这样做是不是不太好

因为本质上这也是一个 hard code，你需要写下

```cpp
class Renderer{
public:
    VkDescriptorSet descriptor_set_0 = nullptr;
    VkDescriptorSet descriptor_set_1 = nullptr;
    ...

    void Init(){
        // Create shader
        ...

        // Allocate descriptor set

        descriptor_set_0 = m_Shader0->AllocateDescriptorSet();
        descriptor_set_1 = m_Shader1->AllocateDescriptorSet();

        // Write descriptor set
        ...
    }
};
```

当然，如果用 vector 的话，似乎也不是不能接受？

```cpp
class Renderer{
public:
    std::vector<VkDescriptorSet> descriptor_set_vec;
    ...

    void Init(){
        // Create shader
        ...

        // Allocate descriptor set

        descriptor_set_vec.push_back(m_Shader0->AllocateDescriptorSet());
        descriptor_set_vec.push_back(m_Shader1->AllocateDescriptorSet());

        // Write descriptor set
        ...
    }
};
```

但是实际上我还是需要知道 descriptor set 和 `Shader` 的对应关系的，比如某个 `Shader` 需要写入 ubo 和一些特定的纹理，那我需要知道这个 `Shader` 对应的是哪个 descriptor set 才能导入

所以继续用容器的话，似乎还要用 map 啊之类的

这么一想似乎就没有必要，真的要保存对应关系那还不如用 struct。那就更进一步，为什么他不是一个类的部分？那更进一步，为什么不是 `Shader` 类的一部分？

所以最终还是决定把 descriptor set 放到 `Shader` 里面

### 更新 descriptor set

#### 不提前创建 `VkDescriptorBufferInfo`, `VkDescriptorImageInfo`

`VkWriteDescriptorSet` 完成的是绑定的工作，核心就是，对于 buffer 是 `pBufferInfo，对于` texture 是 `pImageInfo`

`pBufferInfo` 需要缓冲区句柄，`pImageInfo` 需要 sampler 句柄，这就把资源句柄绑定到了 descriptor set 上面

这里是不涉及怎么更新资源本身的，比如摄像机在每帧运动，View 矩阵时刻在变，那么 UBO 这个 uniform buffer 应该每帧用 memory copy 来更新。资源数据的更新和 `VkWriteDescriptorSet` 这里的绑定不是一个东西。

pBufferInfo, pImageInfo 需要的 `VkDescriptorBufferInfo`, `VkDescriptorImageInfo` 可以提前创建好，所以有的教程会把它们和 `VkBuffer`, `VkImage` 都封装在一个类里面

但是我感觉，这个东西，在创建 `VkWriteDescriptorSet` 的时候创建就好了，这样就显得 `pBufferInfo`, `pImageInfo` 的意义比较明确

#### 创建出 `vk::WriteDescriptorSet` 之后立即 `updateDescriptorSets`

我原本希望能够创建一个 `std::vector<vk::WriteDescriptorSet>` ，然后收集起所有的 `vk::WriteDescriptorSet`，最后只使用一个 `updateDescriptorSets`

外部使用例如

```cpp
quad_mat.SetImage("inputColor", m_color_attachment);
quad_mat.SetImage("inputNormal", m_normal_attachment);
quad_mat.SetImage("inputDepth", m_depth_attachment);
quad_mat.UpdateDescriptorSets(device);
```

但因为 `vk::WriteDescriptorSet` 没有实现移动构造和拷贝构造，会导致 `vk::WriteDescriptorSet` 出错。

例如在容器扩容的时候只有赋值构造，处于旧内存中的 `vk::WriteDescriptorSet` 被删除之后，处于新内存的 `vk::WriteDescriptorSet` 中的资源也一并被删除了

或者是复制构造的时候根本没有成功深拷贝元素？这也不对，按理来说指针也是拷贝了，非指针的也是深拷贝的

但是总之会出现问题。一个解决方法当然是不使用 vector 而是 list，但是这样也太麻烦了

所以现在创建出 `vk::WriteDescriptorSet` 之后立即 `updateDescriptorSets`，接口改成了

```cpp
quad_mat.SetImage(device, "inputColor", m_color_attachment);
quad_mat.SetImage(device, "inputNormal", m_normal_attachment);
quad_mat.SetImage(device, "inputDepth", m_depth_attachment);
```

我觉得 `updateDescriptorSets` 接受一个数组的用法应该是，明确了我接受的是一个数组的更新，例如

```cpp
quad_mat.SetImage(device,
                  {{"inputColor", m_color_attachment},
                    {"inputNormal", m_normal_attachment},
                    {"inputDepth", m_depth_attachment}});
```

但是这么写似乎……看上去紧凑，但是没有必要

## 可变容量的描述符分配器类 DescriptorAllocatorGrowable

pool 数量可变的 descriptor set 分配器

内部存储了两个 vector，保存 descriptor pool。第一个 vector 是 `readyPools`，存储可用于分配 descriptor set 的 pool，第二个 vector 是 `fullPools`，存储已经分配满了的 pool

descriptor pool 的 `std::vector<vk::DescriptorPoolSize> pool_sizes` 都是相同的，暂时不去细究

## 材质类 Material

### 管理 Uniform Buffer 

从更新频率来说，有逐场景的和逐帧的 uniform buffer，它们的更新频率不一样；

从 shader 来说，每一个 shader 对应的物体的数量都是不确定的，那么对应的 uniform buffer 的数据量是不一样的；

从 uniform buffer 的存储结构来说，可能一个物体对应一个 VkBuffer，也可以所有物体共同使用同一个大的 VkBuffer，使用基地址和偏移量来区分各自的数据

那么其实我们需要一个抽象类，控制属于同一个 shader 的不同物体的 uniform buffer 的更新，还有就是控制 descriptor set 的绑定

#### 更新 Uniform Buffer

因为每一个 shader 对应的物体的数量都是不确定的，所以使用一个 ring buffer 来存储逐帧的 uniform buffer

在渲染主循环中，每帧提交每个物体的 uniform buffer 数据

```cpp
material_ins.UploadUniformData("uniform_data_name", uniform_data_ptr, uniform_data_size);
```

此时提交的数据会被拷贝到 ring buffer

如果一个物体具有多个需要提交的数据，那么就要上传多次

```cpp
material_ins.UploadUniformData("uniform_data_name1", uniform_data_ptr1, uniform_data_size1);
material_ins.UploadUniformData("uniform_data_name2", uniform_data_ptr2, uniform_data_size2);
```

那么多次上传之前，需要区分哪些上传对应哪些物体

这里，设计一对 begin 和 end 来确定每个物体对应在 ring buffer 中的 offset

```cpp
// object 1
material_ins.BeginObject();
material_ins.UploadUniformData("uniform_data_name1", uniform_data_ptr1, uniform_data_size1);
material_ins.EndObject();

// object 2
material_ins.BeginObject();
material_ins.UploadUniformData("uniform_data_name2", uniform_data_ptr2, uniform_data_size2);
material_ins.EndObject();
```

有一些 uniform buffer 是对所有物体生效的，他可能每帧刷新也可能不是每帧刷新，这里非正式地称为 global 的。

```cpp
material_ins.UploadGlobalUniformData("uniform_data_name1", uniform_data_ptr1, uniform_data_size1);

// object 1
material_ins.BeginObject();
material_ins.UploadLocalUniformData("uniform_data_name2", uniform_data_ptr2, uniform_data_size2);
material_ins.EndObject();

// object 2
material_ins.BeginObject();
material_ins.UploadLocalUniformData("uniform_data_name3", uniform_data_ptr3, uniform_data_size3);
material_ins.EndObject();
```

因为使用了 ring buffer，所以这些 global uniform buffer 哪怕只在渲染器前端只更新一次，在后端，每帧都要把 global uniform buffer 拷贝到 ring buffer 的最前面，并且保存首地址

这通过另外一组 begin 和 end 来完成

```cpp
material_ins.UploadGlobalUniformData("uniform_data_name1", uniform_data_ptr1, uniform_data_size1);

material_ins.BeginFrame();

// object 1
material_ins.BeginObject();
material_ins.UploadLocalUniformData("uniform_data_name2", uniform_data_ptr2, uniform_data_size2);
material_ins.EndObject();

// object 2
material_ins.BeginObject();
material_ins.UploadLocalUniformData("uniform_data_name3", uniform_data_ptr3, uniform_data_size3);
material_ins.EndObject();

material_ins.EndFrame();
```

### Global 和 Local Uniform Buffer 与 Unity SRP 的对比

|        本仓库         |          Unity SRP shader 变量           |
| :-------------------: | :--------------------------------------: |
| Local Uniform Buffer  |                无特殊声明                |
| Global Uniform Buffer | 添加 UnityPerDraw, UnityPerMaterial 声明 |

## 新的材质类

现在这么想

我发现 descriptor set 应该放在 material

然后一套参数对应一套 material

唯一可变的就是 dynamic uniform buffer

游戏引擎就是这么做的

不考虑 material variant 的话

## 资源的安排

很明显，uniform buffer 是不应该放在材质外面的，所以应该是最外层控制渲染的那个东西来管理

但是贴图这种东西，就是应该跟着材质走

那么其实材质还是要记录自己的逐材质的东西的

而 uniform buffer 要么是逐场景的，需要在外面，避免重复，要么就是 dynamic 的，直接分配一块大的，也避免重复，所以在外面

那么既然是逐材质的，贴图就写在 material 类里面

一个对使用者友好的方法当然是，反射 shader 获得 descriptor 信息，然后根据这个信息创建出逐材质的 resource 槽位

外部去填充这个 resource 槽位，并且外部控制绑定到 pipeline 的频率

resource 槽位是一个基类指针，但是根据反射可以取到子类信息，因而可以编辑器中看到本材质需要什么类型的资源

编辑器中也可以对应选择相应类型的资源

但是目前的话就写死在 material 里面吧

但是其实资源基类写起来还是挺快的，也就几行

重要的是要抽象出什么代码

或许是可以抽象出，传入 resource 的派生类的指针，然后就把指针存在 material 然后绑定

那和直接绑定也没有什么区别

何必要存在 material

然后我还发现我似乎是应该把贴图存在 resource system 里面的

我都快忘了有这个东西

他应该管理资源加载与释放的

## 纹理资源的加载

实际上之前一直在纠结这些资源放哪

好的，不用纠结了，就放资源系统里面

然后还有一个资源的信息放在哪里的问题

正经的引擎里面肯定是 inspector 里面配好

那么代码中这个信息放在哪里

实际上我还以为要跟着 material

确实是要跟着，但是应该放在 meta info 里面

还有资源什么时候加载的问题

这就应该是资源系统来控制

应该是资源系统会扫描的

现在我们没有这个编辑器的工具链支持

那么就直接 hard code 吧