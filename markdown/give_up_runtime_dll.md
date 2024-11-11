# 放弃将游戏库改为 dll 的想法

## lib 或者 dll

dll 的内存分配是一个问题

然后就是跨 dll 的话，有些编译器的优化可能不行

但是 dll 的话，可以把不同的模块拆成不同的 dll，我觉得这个挺好的……

## DLL 导出符号

报错

```
game_window.obj : error LNK2019: 无法解析的外部符号 "__declspec(dllimport) public: __cdecl Meow::SwapChainData::SwapChainData(class vk::raii::PhysicalDevice const &,class vk::raii::Device const &,class vk::raii::SurfaceKHR cons
t &,struct vk::Extent2D const &,class vk::Flags<enum vk::ImageUsageFlagBits>,class vk::raii::SwapchainKHR const *,unsigned int,unsigned int)" (__imp_??0SwapChainData@Meow@@QEAA@AEBVPhysicalDevice@raii@vk@@AEBVDevice@34 
@AEBVSurfaceKHR@34@AEBUExtent2D@4@V?$Flags@W4ImageUsageFlagBits@vk@@@4@PEBVSwapchainKHR@34@II@Z)，函数 "private: void __cdecl Meow::GameWindow::CreateSwapChian(void)" (?CreateSwapChian@GameWindow@Meow@@AEAAXXZ) 中引用了该符号 [E
:\repositories\MeowEngine\build-debug\src\meow_game\MeowGame.vcxproj]
game_window.obj : error LNK2019: 无法解析的外部符号 "__declspec(dllimport) public: __cdecl Meow::SwapChainData::SwapChainData(std::nullptr_t)" (__imp_??0SwapChainData@Meow@@QEAA@$$T@Z)，函数 "public: __cdecl Meow::GameWindow::Game
Window(unsigned __int64,struct GLFWwindow *)" (??0GameWindow@Meow@@QEAA@_KPEAUGLFWwindow@@@Z) 中引用了该符号 [E:\repositories\MeowEngine\build-debug\src\meow_game\MeowGame.vcxproj]
game_window.obj : error LNK2019: 无法解析的外部符号 "__declspec(dllimport) public: __cdecl Meow::SwapChainData::~SwapChainData(void)" (__imp_??1SwapChainData@Meow@@QEAA@XZ)，函数 "public: virtual __cdecl Meow::GameWindow::~GameWin
dow(void)" (??1GameWindow@Meow@@UEAA@XZ) 中引用了该符号 [E:\repositories\MeowEngine\build-debug\src\meow_game\MeowGame.vcxproj]
game_window.obj : error LNK2019: 无法解析的外部符号 "__declspec(dllimport) public: struct Meow::SwapChainData & __cdecl Meow::SwapChainData::operator=(struct Meow::SwapChainData &&)" (__imp_??4SwapChainData@Meow@@QEAAAEAU01@$$Q
EAU01@@Z)，函数 "public: virtual __cdecl Meow::GameWindow::~GameWindow(void)" (??1GameWindow@Meow@@UEAA@XZ) 中引用了该符号 [E:\repositories\MeowEngine\build-debug\src\meow_game\MeowGame.vcxproj]
E:\repositories\MeowEngine\build-debug\src\meow_game\Debug\MeowGame.exe : fatal error LNK1120: 4 个无法解析的外部命令 [E:\repositories\MeowEngine\build-debug\src\meow_game\MeowGame.vcxproj]
editor_window.obj : error LNK2019: 无法解析的外部符号 "__declspec(dllimport) public: __cdecl Meow::SwapChainData::SwapChainData(class vk::raii::PhysicalDevice const &,class vk::raii::Device const &,class vk::raii::SurfaceKHR co
nst &,struct vk::Extent2D const &,class vk::Flags<enum vk::ImageUsageFlagBits>,class vk::raii::SwapchainKHR const *,unsigned int,unsigned int)" (__imp_??0SwapChainData@Meow@@QEAA@AEBVPhysicalDevice@raii@vk@@AEBVDevice@ 
34@AEBVSurfaceKHR@34@AEBUExtent2D@4@V?$Flags@W4ImageUsageFlagBits@vk@@@4@PEBVSwapchainKHR@34@II@Z)，函数 "private: void __cdecl Meow::EditorWindow::CreateSwapChian(void)" (?CreateSwapChian@EditorWindow@Meow@@AEAAXXZ) 中引用了
该符号 [E:\repositories\MeowEngine\build-debug\src\meow_editor\MeowEditor.vcxproj]
editor_window.obj : error LNK2019: 无法解析的外部符号 "__declspec(dllimport) public: __cdecl Meow::SwapChainData::SwapChainData(std::nullptr_t)" (__imp_??0SwapChainData@Meow@@QEAA@$$T@Z)，函数 "public: __cdecl Meow::EditorWindow::
EditorWindow(unsigned __int64,struct GLFWwindow *)" (??0EditorWindow@Meow@@QEAA@_KPEAUGLFWwindow@@@Z) 中引用了该符号 [E:\repositories\MeowEngine\build-debug\src\meow_editor\MeowEditor.vcxproj]
editor_window.obj : error LNK2019: 无法解析的外部符号 "__declspec(dllimport) public: __cdecl Meow::SwapChainData::~SwapChainData(void)" (__imp_??1SwapChainData@Meow@@QEAA@XZ)，函数 "public: virtual __cdecl Meow::EditorW引用了
该符号 [E:\repositories\MeowEngine\build-debug\src\meow_editor\MeowEditor.vcxproj]
editor_window.obj : error LNK2019: 无法解析的外部符号 "__declspec(dllimport) public: __cdecl Meow::SwapChainData::SwapChainData(std::nullptr_t)" (__imp_??0SwapChainData@Meow@@QEAA@$$T@Z)，函数 "public: __cdecl Meow::EditorWindow::
EditorWindow(unsigned __int64,struct GLFWwindow *)" (??0EditorWindow@Meow@@QEAA@_KPEAUGLFWwindow@@@Z) 中引用了该符号 [E:\repositories\MeowEngine\build-debug\src\meow_editor\MeowEditor.vcxproj]
editor_window.obj : error LNK2019: 无法解析的外部符号 "__declspec(dllimport) public: __cdecl Meow::SwapChainData::~SwapChainData(void)" (__imp_??1SwapChainData@Meow@@QEAA@XZ)，函数 "public: virtual __cdecl Meow::EditorWindow::~Edi
引用了
该符号 [E:\repositories\MeowEngine\build-debug\src\meow_editor\MeowEditor.vcxproj]
editor_window.obj : error LNK2019: 无法解析的外部符号 "__declspec(dllimport) public: __cdecl Meow::SwapChainData::SwapChainData(std::nullptr_t)" (__imp_??0SwapChainData@Meow@@QEAA@$$T@Z)，函数 "public: __cdecl Meow::EditorWindow::
EditorWindow(unsigned __int64,struct GLFWwindow *)" (??0EditorWindow@Meow@@QEAA@_KPEAUGLFWwindow@@@Z) 中引用了该符号 [E:\repositories\MeowEngine\build-debug\src\meow_editor\MeowEditor.vcxproj]
editor_window.obj : error LNK2019: 无法解析的外部符号 "__declspec(dllimport) public: __cdecl Meow::SwapChainData::~SwapChainData(void)" (__imp_??1SwapChainData@Meow@@QEAA@XZ)，函数 "public: virtual __cdecl Meow::EditorW引用了
该符号 [E:\repositories\MeowEngine\build-debug\src\meow_editor\MeowEditor.vcxproj]
editor_window.obj : error LNK2019: 无法解析的外部符号 "__declspec(dllimport) public: __cdecl Meow::SwapChainData::SwapChainData(std::nullptr_t)" (__imp_??0SwapChainData@Meow@@QEAA@$$T@Z)，函数 "public: __cdecl Meow::EditorWindow::
EditorWindow(unsigned __int64,struct GLFWwindow *)" (??0EditorWindow@Meow@@QEAA@_KPEAUGLFWwindow@@@Z) 中引用了该符号 [E:\repositories\MeowEngine\build-debug\src\meow_editor\MeowEditor.vcxproj]
引用了
该符号 [E:\repositories\MeowEngine\build-debug\src\meow_editor\MeowEditor.vcxproj]
editor_window.obj : error LNK2019: 无法解析的外部符号 "__declspec(dllimport) public: __cdecl Meow::SwapChainData::SwapChainData(std::nullptr_t)" (__imp_??0SwapChainData@Meow@@QEAA@$$T@Z)，函数 "public: __cdecl Meow::EditorWindow::
EditorWindow(unsigned __int64,struct GLFWwindow *)" (??0EditorWindow@Meow@@QEAA@_KPEAUGLFWwindow@@@Z) 中引用了该符号 [E:\repositories\MeowEngine\build-debug\src\meow_editor\MeowEditor.vcxproj]
引用了
该符号 [E:\repositories\MeowEngine\build-debug\src\meow_editor\MeowEditor.vcxproj]
editor_window.obj : error LNK2019: 无法解析的外部符号 "__declspec(dllimport) public: __cdecl Meow::SwapChainData::SwapChainData(std::nullptr_t)" (__imp_??0SwapChainData@Meow@@QEAA@$$T@Z)，函数 "public: __cdecl Meow::EditorWindow::
引用了
该符号 [E:\repositories\MeowEngine\build-debug\src\meow_editor\MeowEditor.vcxproj]
引用了
该符号 [E:\repositories\MeowEngine\build-debug\src\meow_editor\MeowEditor.vcxproj]
引用了
引用了
该符号 [E:\repositories\MeowEngine\build-debug\src\meow_editor\MeowEditor.vcxproj]
editor_window.obj : error LNK2019: 无法解析的外部符号 "__declspec(dllimport) public: __cdecl Meow::SwapChainData::SwapChainData(std::nullptr_t)" (__imp_??0SwapChainData@Meow@@QEAA@$$T@Z)，函数 "public: __cdecl Meow::EditorWindow::
EditorWindow(unsigned __int64,struct GLFWwindow *)" (??0EditorWindow@Meow@@QEAA@_KPEAUGLFWwindow@@@Z) 中引用了该符号 [E:\repositories\MeowEngine\build-debug\src\meow_editor\MeowEditor.vcxproj]
editor_window.obj : error LNK2019: 无法解析的外部符号 "__declspec(dllimport) public: __cdecl Meow::SwapChainData::~SwapChainData(void)" (__imp_??1SwapChainData@Meow@@QEAA@XZ)，函数 "public: virtual __cdecl Meow::EditorWindow::~Edi
torWindow(void)" (??1EditorWindow@Meow@@UEAA@XZ) 中引用了该符号 [E:\repositories\MeowEngine\build-debug\src\meow_editor\MeowEditor.vcxproj]
editor_window.obj : error LNK2019: 无法解析的外部符号 "__declspec(dllimport) public: struct Meow::SwapChainData & __cdecl Meow::SwapChainData::operator=(struct Meow::SwapChainData &&)" (__imp_??4SwapChainData@Meow@@QEAAAEAU01@$
$QEAU01@@Z)，函数 "public: virtual __cdecl Meow::EditorWindow::~EditorWindow(void)" (??1EditorWindow@Meow@@UEAA@XZ) 中引用了该符号 [E:\repositories\MeowEngine\build-debug\src\meow_editor\MeowEditor.vcxproj]
E:\repositories\MeowEngine\build-debug\src\meow_editor\Debug\MeowEditor.exe : fatal error LNK1120: 4 个无法解析的外部命令 [E:\repositories\MeowEngine\build-debug\src\meow_editor\MeowEditor.vcxproj]
```

于是用 dumpbin 来查看 dll 内部有的符号

```
E:\software\Microsoft Visual Studio\2022\Community>dumpbin /EXPORTS E:\repositories\MeowEngine\build-debug\src\meow_runt
ime\Debug\MeowRuntimed.dll > E:\repositories\MeowEngine\build-debug\src\meow_runtime\Debug\MeowRuntimed_dump.txt
```

结果是没有发现

于是发现是我的这个类完全是声明在头文件里面的

这个头文件不被视为一个翻译单元

并且我的 dll 内部没有 cpp include 这个头文件

所以这个头文件完全没有被编译进 dll

所以 dll 中没有这个符号

现在我加了一个 cpp 在 dll 去 include 这个头文件就好了

## 内存报错

在这里报错

```cpp
namespace Meow
{
    struct SurfaceData
    {
        vk::Extent2D         extent;
        vk::raii::SurfaceKHR surface = nullptr;

        SurfaceData(vk::raii::Instance const& instance, GLFWwindow* glfw_window, vk::Extent2D const& extent_)
            : extent(extent_)
        {
            VkSurfaceKHR _surface;
            VkResult err = glfwCreateWindowSurface(static_cast<VkInstance>(*instance), glfw_window, nullptr, &_surface);
            if (err != VK_SUCCESS)
                throw std::runtime_error("Failed to create window!");
            surface = vk::raii::SurfaceKHR(instance, _surface);
        }

        SurfaceData(std::nullptr_t) {}
    };
} // namespace Meow
```

```
Unhandled exception at 0x00007FF8C916F39C in MeowEditor.exe: Microsoft C++ exception: std::runtime_error at memory location 0x00000010034FE948.
```

这里 `glfwCreateWindowSurface` 返回 `VK_ERROR_INITIALIZATION_FAILED(-3)`，`_surface` 是 null

就很神奇

这里之前从来没有过问题

难道是因为这里没有 dllexport？

## glfwCreateWindowSurface VK_ERROR_INITIALIZATION_FAILED 

`glfwCreateWindowSurface` 这个函数说了，如果是报错 `VK_ERROR_INITIALIZATION_FAILED` 的话，可能是 vulkan loader 没加载

感觉像是 glfwinit 没调用

于是加了 glfwinit 就没这个问题了

## getVkHeaderVersion 报错

然后就是 `m_dispatcher->getVkHeaderVersion()` 的报错

感觉这个是 vulkan 加载的问题

于是把相关的定义放在 public

```cmake    
target_compile_definitions(${RUNTIME_NAME} PRIVATE
  LIBRARY_EXPORTS
)
target_compile_definitions(${RUNTIME_NAME} PUBLIC
  ENGINE_ROOT_DIR="${ENGINE_ROOT_DIR}"
  $<$<CONFIG:Debug>:MEOW_DEBUG>
  $<$<CONFIG:Release>:MEOW_RELEASE>
  $<$<CONFIG:Debug>:VKB_DEBUG>
  $<$<CONFIG:Debug>:VKB_VALIDATION_LAYERS>
  VK_USE_PLATFORM_WIN32_KHR # TODO: Config vulkan platform preprocesser
                            # according to cmake build platform
  VULKAN_HPP_STORAGE_SHARED # compile dll when using vulkan hpp
  VULKAN_HPP_STORAGE_SHARED_EXPORT # export DispatchLoaderDynamic from
                                  # vulkan hpp
  GLM_ENABLE_EXPERIMENTAL # for GLM: GLM_GTX_component_wise
  IMGUI_DEFINE_MATH_OPERATORS
  # _DISABLE_STRING_ANNOTATION # for ASAN
  # _DISABLE_VECTOR_ANNOTATION # for ASAN
  NOMINMAX # for std::numeric_limits<double>::min() and max()
)
```

就没有这个问题了

## ImGui_ImplVulkan_NewFrame 报错

```cpp
void ImGui_ImplVulkan_NewFrame()
{
    ImGui_ImplVulkan_Data* bd = ImGui_ImplVulkan_GetBackendData();
    IM_ASSERT(bd != nullptr && "Did you call ImGui_ImplVulkan_Init()?");

    if (!bd->FontDescriptorSet)
        ImGui_ImplVulkan_CreateFontsTexture();
}
```

直接在这里报错

看上去我就是没有 `ImGui_ImplVulkan_Init`

于是一路看到问题根源

```cpp
// DLL users:
// - Heaps and globals are not shared across DLL boundaries!
// - You will need to call SetCurrentContext() + SetAllocatorFunctions() for each static/DLL boundary you are calling from.
// - Same applies for hot-reloading mechanisms that are reliant on reloading DLL (note that many hot-reloading mechanisms work without DLL).
// - Using Dear ImGui via a shared library is not recommended, because of function call overhead and because we don't guarantee backward nor forward ABI compatibility.
// - Confused? In a debugger: add GImGui to your watch window and notice how its value changes depending on your current location (which DLL boundary you are in).

// Current context pointer. Implicitly used by all Dear ImGui functions. Always assumed to be != NULL.
// - ImGui::CreateContext() will automatically set this pointer if it is NULL.
//   Change to a different context by calling ImGui::SetCurrentContext().
// - Important: Dear ImGui functions are not thread-safe because of this pointer.
//   If you want thread-safety to allow N threads to access N different contexts:
//   - Change this variable to use thread local storage so each thread can refer to a different context, in your imconfig.h:
//         struct ImGuiContext;
//         extern thread_local ImGuiContext* MyImGuiTLS;
//         #define GImGui MyImGuiTLS
//     And then define MyImGuiTLS in one of your cpp files. Note that thread_local is a C++11 keyword, earlier C++ uses compiler-specific keyword.
//   - Future development aims to make this context pointer explicit to all calls. Also read https://github.com/ocornut/imgui/issues/586
//   - If you need a finite number of contexts, you may compile and use multiple instances of the ImGui code from a different namespace.
// - DLL users: read comments above.
#ifndef GImGui
ImGuiContext*   GImGui = NULL;
#endif
```

于是发现这个问题是，全局变量在 dll 边界处是不共享的

也就是说，在 exe 里面初始化了 imgui，创建的全局变量，在 dll 中访问不到

用 IDE 监视 `GImGui` 这个值，然后切换函数堆栈，堆栈在 exe 的时候，`GImGui` 有值，在 dll 的时候就没有值

于是还是放弃使用 dll 了

使用静态库就挺好的

用 dll 一个是为了节省内存，因为 dll 创建的内存是可以被多个 exe 共享；一个是为了热重载

但是游戏引擎的核心库不需要这两个功能

需要这两个功能的一般是插件