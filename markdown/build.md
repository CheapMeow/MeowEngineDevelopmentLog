# 构建

## 脚本

使用 `file(GLOB_RECURSE ...)` 获取文件列表的方法不值得采纳，因为 CMake 是一个构建系统生成器，而不是构建系统。

`GLOB_RECURSE` 是在构建的时候生成文件列表，那么 CMake 在生成构建系统的时候就没有办法知道文件列表，也就没有办法利用文件信息

比如我觉得是因为他没有办法利用时间戳，才导致每次都要重新构建

所以想要增量构建，还是直接在 CMakeLists 里面直接给出所有文件的列表更稳妥

我不想手动维护所有文件列表，所以写了一个 python 脚本，递归获取指定文件夹下以特定后缀为结尾的所有文件

然后再用 cmake-format 来格式化

我在想……为什么不直接写到 bat 里面

做一个 CMakeLists.template 获取文件列表，替换进去，产生 CMakeList，还能加个格式化

最后发现，不如手写

## editor 构建

最后果然还是使用宏定义来区分编辑器构建和游戏构建比较好

如果是分文件写的话，那么就代表着相关的文件都要写两份，并且这两份都是派生类

很多时候，编辑器相关的行为是需要嵌入到 runtime 的类里面的

所以不得不用派生类重写相关的逻辑

就，更加难以组织文件了

宏的话，劣势主要是，不同的逻辑流写在同一个文件里面

但是方便写

果然还是写宏吧？

## 添加构建类型

根据

[https://cmake.cmake.narkive.com/pJ6ukYrz/custom-configuration-types-in-visual-studio]

添加构建类型需要在 project() 之前

于是我写

```cmake
set(CMAKE_CONFIGURATION_TYPES "EditorDebug;EditorRelease;GameDebug;GameRelease" CACHE STRING "Available build types")

project(MeowEngine CXX)
```

没有用

于是还是要清理构建缓存才行

结果

```
E:\software\Microsoft Visual Studio\2022\Community\MSBuild\Microsoft\VC\v170\Microsoft.Cp
pBuild.targets(452,5): error MSB8013: 此项目不包含配置和平台组合 Debug|x64。 [E:\repositories\MeowEngin
e\build\ZERO_CHECK.vcxproj]
```

我是不知道为什么他还要找 Debug 了

看上去像是他识别不到我自定义的构建类型

还可以写

```
project(MeowEngine)
set(CMAKE_CONFIGURATION_TYPES "EditorDebug;EditorRelease;GameDebug;GameRelease" CACHE STRING "Available build types")
enable_language(CXX)
```

另外看到一个问题也是这么说的

[https://stackoverflow.com/questions/20638963/cmake-behaviour-custom-configuration-types-with-visual-studio-need-multiple-cma](https://stackoverflow.com/questions/20638963/cmake-behaviour-custom-configuration-types-with-visual-studio-need-multiple-cma)

我自己试了，还是没有用

```cmake
project(MeowEngine LANGUAGES NONE)
set(CMAKE_CONFIGURATION_TYPES "EditorDebug;EditorRelease;GameDebug;GameRelease" CACHE STRING "Available build types")
enable_language(CXX)
```

也没有用

## xmake

尝试替换成 xmake

```lua
-- 设置项目
set_project("MeowEngine")
set_languages("c++20")

-- 设置全局的第三方库路径
local thirdparty_dir = "$(projectdir)/src/3rdparty"
local code_generator_dir = "$(projectdir)/src/code_generator"
local runtime_dir = "$(projectdir)/src/meow_runtime"
local editor_dir = "$(projectdir)/src/meow_editor"

rule("EditorDebug", function()
    after_load(function(target)
        if is_mode("debug") then
            if not target:get("symbols") then
                target:set("symbols", "debug")
            end
            if not target:get("optimize") then
                target:set("optimize", "none")
            end
            target:set("targetdir", "$(projectdir)/build/EditorDebug")
            target:set("defines", { "MEOW_EDITOR", "MEOW_DEBUG" })
        end
    end)
end)

rule("EditorRelease", function()
    after_load(function(target)
        if is_mode("EditorRelease") then
            if not target:get("symbols") and target:targetkind() ~= "shared" then
                target:set("symbols", "hidden")
            end
            if not target:get("optimize") then
                if is_plat("android", "iphoneos") then
                    target:set("optimize", "smallest")
                else
                    target:set("optimize", "fastest")
                end
            end
            if not target:get("strip") then
                target:set("strip", "all")
            end
            target:set("targetdir", "$(projectdir)/build/EditorRelease")
            target:set("defines", { "MEOW_EDITOR" })
        end
    end)
end)

add_rules("EditorDebug", "EditorRelease")

add_requires("vulkansdk", "glm", "glfw", "volk", "spirv-cross", "stb", "assimp", "imgui docking", "llvm")

target("code_generator", function()
    set_kind("binary")
    add_files("$(code_generator_dir)/**.cpp")
    add_includedirs("$(code_generator_dir)")
    add_packages("llvm")

    -- after_build(function (target)
    --     local include_dir_list = ""
    --     -- include_dir_list = include_dir_list .. "-I$(env VULKAN_SDK)/Include"
    --     -- include_dir_list = include_dir_list .. " -I" .. target:pkg("glfw"):installdir() .. "/include"
    --     -- include_dir_list = include_dir_list .. " -I" .. target:pkg("glm"):installdir()
    --     -- include_dir_list = include_dir_list .. " -I" .. target:pkg("glm"):installdir()
    --     -- include_dir_list = include_dir_list .. " -I" .. target:pkg("volk"):installdir()
    --     -- include_dir_list = include_dir_list .. " -I" .. target:pkg("spirv-cross"):installdir()
    --     -- include_dir_list = include_dir_list .. " -I" .. target:pkg("stb"):installdir()
    --     -- include_dir_list = include_dir_list .. " -I" .. target:pkg("assimp"):installdir() .. "/include"
    --     -- include_dir_list = include_dir_list .. " -I" .. target:pkg("llvm"):installdir() .. "/include"
    --     print(include_dir_list)

    --     os.execv(target:targetfile(), { target:targetfile(), { "$(include_dir_list)", "-S$(runtime_dir)", "-O$(runtime_dir)/generated" } })
    -- end)
end)

-- target("meow_runtime", function()
--     set_kind("binary")
--     set_languages("c++20")
--     add_files(path.join(src_dir, "**", "*.cpp"))
--     add_includedirs(src_dir, { public = true })
--     add_defines("ENGINE_ROOT_DIR=\"" .. os.scriptdir() .. "\"")

--     -- 添加链接的库
--     add_links("vulkan", "clang", "glm", "glfw", "volk", "spirv-cross-glsl", "spirv-cross-hlsl",
--         "spirv-cross-cpp", "spirv-cross-reflect", "spirv-cross-msl", "spirv-cross-util",
--         "spirv-cross-core", "stb", "assimp", "imgui")

--     if has_config("vulkan") then
--         add_includedirs(path.join(os.getenv("Vulkan_INCLUDE_DIRS")), { public = true })
--     end
--     add_includedirs(path.join(thirdparty_dir, "glm"), { public = true })
--     add_includedirs(path.join(thirdparty_dir, "glfw", "include"), { public = true })
--     add_includedirs(path.join(thirdparty_dir, "volk"), { public = true })
--     add_includedirs(path.join(thirdparty_dir, "SPIRV-Cross"), { public = true })
--     add_includedirs(path.join(thirdparty_dir, "stb"), { public = true })
--     add_includedirs(path.join(thirdparty_dir, "assimp", "include"), { public = true })
--     add_includedirs(path.join(thirdparty_dir, "imgui"), { public = true })
-- end)

```

最小复现

```lua
set_project("MeowEngine")
set_languages("c++20")

add_rules("mode.debug")

add_requires("llvm")

target("code_generator", function()
    set_kind("binary")
    add_files("$(code_generator_dir)/**.cpp")
    add_includedirs("$(code_generator_dir)")
    add_packages("llvm")
end)

```

最后发现是 add_includedirs 报错 nil

不能在 add_xxx 里面用格式化啊

算了，那就 hard code 吧？

试试 xrepo 的模板

```shell
xmake l scripts/new.lua github:llvm/llvm-project
```

报错没有 gh

要下载 github cli

然后

```
(base) PS E:\repositories\xmake-repo> xmake l scripts/new.lua github:llvm/llvm-project
downloading https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-19.1.5.tar.gz
error: cannot remove directory C:\Users\blizz\AppData\Local\Temp\.xmake\241208\_8230A9F7248147108D1B0647DF7DF460.tar.gz.dir Unknown Error (145)
(base) PS E:\repositories\xmake-repo> xmake l scripts/new.lua github:llvm/llvm-project
downloading https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-19.1.5.tar.gz
error: curl: (16) Error in the HTTP2 framing layer

(base) PS E:\repositories\xmake-repo> xmake l scripts/new.lua github:llvm/llvm-project
downloading https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-19.1.5.tar.gz
error: curl: (6) Could not resolve host: codeload.github.com
```

搜了解决方法是

```shell
git config --global http.version HTTP/1.1
```

然后错误是 `curl: (6) Could not resolve host: codeload.github.com`

算了，还是自己加 include 吧

```lua
target("code_generator", function()
    set_kind("binary")
    add_files("src/code_generator/**.cpp")
    add_includedirs("src/code_generator")
    add_links("$(env LLVM_DIR)/lib/libclang.lib")
    add_includedirs("$(env LLVM_DIR)/include")
```

然后

```lua
include_dir_list = include_dir_list .. " -I" .. target:pkg("glfw"):installdir() .. "/include"
```

坏了，因为我的 code_generator 没有依赖这些库

## install 的作用

坏了，现在才知道 install 的作用

之前 assimp 的构建是会生成一个 config.h 的

```cmake
list(APPEND INCLUDE_DIRS "-I${3RD_PARTY_ROOT_DIR}/assimp/include")
list(APPEND INCLUDE_DIRS "-I${CMAKE_BINARY_DIR}/src/3rdparty/assimp/include") # for config.h
```

这个东西仅仅出现在构建目录，是被生成的

然后我一般的逻辑是直接取源码的 include 和 build 中的 lib

实际上应该取 install 的 include 和 build 的

这样库的编写者就会为你写好他自己的一些生成代码的逻辑，都放在合适的地方

还有就是这解释了我的一个问题

为什么有的时候也可以把 cpp 和 头文件 写在一起

如果分开写不是更方便 include 吗

原来是这样，就是我们自己可以控制生成到 install 是怎么样的

所以源码里面怎么样都好

怪不得，是我的问题

## execv

```lua
set_project("MeowEngine")
set_languages("c++20")

-- 设置全局的第三方库路径
local thirdparty_dir = "$(projectdir)/src/3rdparty"
local code_generator_dir = "$(projectdir)/src/code_generator"
local runtime_dir = "$(projectdir)/src/meow_runtime"
local editor_dir = "$(projectdir)/src/meow_editor"

rule("EditorDebug", function()
    after_load(function(target)
        if is_mode("debug") then
            if not target:get("symbols") then
                target:set("symbols", "debug")
            end
            if not target:get("optimize") then
                target:set("optimize", "none")
            end
            target:set("targetdir", "build/EditorDebug")
            target:set("defines", { "MEOW_EDITOR", "MEOW_DEBUG" })
        end
    end)
end)

rule("EditorRelease", function()
    after_load(function(target)
        if is_mode("EditorRelease") then
            if not target:get("symbols") and target:targetkind() ~= "shared" then
                target:set("symbols", "hidden")
            end
            if not target:get("optimize") then
                if is_plat("android", "iphoneos") then
                    target:set("optimize", "smallest")
                else
                    target:set("optimize", "fastest")
                end
            end
            if not target:get("strip") then
                target:set("strip", "all")
            end
            target:set("targetdir", "build/EditorRelease")
            target:set("defines", { "MEOW_EDITOR" })
        end
    end)
end)


add_rules("EditorDebug", "EditorRelease")

add_requires("vulkansdk")
add_requires("llvm")
add_requires("glm", "glfw", "volk", "spirv-cross", "stb", "assimp", "imgui docking")

target("code_generator", function()
    set_kind("binary")
    add_files("src/code_generator/**.cpp")
    add_includedirs("src/code_generator")
    add_links("$(env LLVM_DIR)/lib/libclang.lib")
    add_includedirs("$(env LLVM_DIR)/include")
    add_packages("glm", "glfw", "volk", "spirv-cross", "stb", "assimp", "imgui")
    after_build(function (target)
        local include_dir_list = ""
        include_dir_list = include_dir_list .. "-I$(env VULKAN_SDK)/Include"
        include_dir_list = include_dir_list .. " -I" .. target:pkg("glfw"):installdir() .. "/include"
        include_dir_list = include_dir_list .. " -I" .. target:pkg("glm"):installdir()
        include_dir_list = include_dir_list .. " -I" .. target:pkg("volk"):installdir()
        include_dir_list = include_dir_list .. " -I" .. target:pkg("spirv-cross"):installdir()
        include_dir_list = include_dir_list .. " -I" .. target:pkg("stb"):installdir()
        include_dir_list = include_dir_list .. " -I" .. target:pkg("assimp"):installdir() .. "/include"
        include_dir_list = include_dir_list .. " -I" .. target:pkg("imgui"):installdir()
        include_dir_list = include_dir_list .. " -I$(env LLVM_DIR)/include"
        include_dir_list = include_dir_list .. " -I$(env LLVM_DIR)/lib/clang/19/include"

        os.execv(target:targetfile(), { target:targetfile(), { "$(include_dir_list)", "-S$(projectdir)/src/code_generator", "-O$(projectdir)/src/meow_runtime/generated" } })
    end)
end)

```

我自己的代码报错

```
[CodeGenerator] src_path "" does not exist!
```

说明这个命令行参数根本没有传进来啊

于是发现是我 execv 用错了

## include path

旧的 CMakeLists 的传入参数

```
  [CodeGenerator] src_path is
  E:/repositories/MeowEngine/src/meow_runtime
  [CodeGenerator] output_path is
  E:/repositories/MeowEngine/src/meow_runtime/generated
  [CodeGenerator] include_path is
  -IE:/repositories/MeowEngine/src/code_generator
  -IE:/repositories/MeowEngine/src/meow_runtime
  -IE:/repositories/MeowEngine/src/3rdparty/glm
  -IE:/repositories/MeowEngine/src/3rdparty/glfw/include
  -IE:/repositories/MeowEngine/src/3rdparty/volk
  -IE:/software/VulkanSDK/1.3.275.0/Include
  -IE:/repositories/MeowEngine/src/3rdparty/SPIRV-Cross
  -IE:/repositories/MeowEngine/src/3rdparty/stb
  -IE:/repositories/MeowEngine/src/3rdparty/assimp/include
  -IE:/repositories/MeowEngine/build/src/3rdparty/assimp/include
  -IE:/repositories/MeowEngine/src/3rdparty/imgui
  -IE:\software\LLVM/include
  -IE:\software\LLVM/lib/clang/19/include
```

能够正常运行

我的 xmake

```
[CodeGenerator] src_path is
E:\repositories\MeowEngine\src\meow_runtime
[CodeGenerator] output_path is
E:\repositories\MeowEngine\src\meow_runtime\generated
[CodeGenerator] include_path is
-IE:\\software\\VulkanSDK\\1.3.275.0/Include -IC:\\Users\\blizz\\AppData\\Local\\.xmake\\packages\\g\\glfw\\3.4\\fc47358da159466996f7d289b4cf1b4e/include -IC:\\Users\\blizz\\AppData\\Local\\.xmake\\packages\\g\\glm\\1.0.1\\788496219b2d40629f92bac6907b6bba -IC:\\Users\\blizz\\AppData\\Local\\.xmake\\packages\\v\\volk\\1.3.290+0\\890254b3c2b544a6aa8de9f4bf6a217d -IC:\\Users\\blizz\\AppData\\Local\\.xmake\\packages\\s\\spirv-cross\\1.3.268+0\\940818ca23704860952c2c9caf1e3a12 -IC:\\Users\\blizz\\AppData\\Local\\.xmake\\packages\\s\\stb\\2024.06.01\\50b5205a30f145adb70e146a5d0967dc -IC:\\Users\\blizz\\AppData\\Local\\.xmake\\packages\\a\\assimp\\v5.4.3\\8976be04e29244f8a7e3b979bc504e54/include -IC:\\Users\\blizz\\AppData\\Local\\.xmake\\packages\\i\\imgui\\docking\\a7c0343391364abb9cdfa3c1d538af70 -IE:\\software\\LLVM/include -IE:\\software\\LLVM/lib/clang/19/include -IE:\\repositories\\MeowEngine/src/meow_runtime
```

看上去这些参数被合成了一个 string

于是输出了 `include_paths.size()` 果然是 1

于是应该使用 table

```lua
add_requires("vulkansdk")
-- add_requires("llvm") llvm isn't supported well now, so hard code dependency on env
add_requires("glm", "glfw", "volk", "spirv-cross", "stb", "assimp", "imgui docking")

target("code_generator", function()
    set_kind("binary")
    add_files("src/code_generator/**.cpp")
    add_includedirs("src/code_generator")
    add_links("$(env LLVM_DIR)/lib/libclang.lib")
    add_includedirs("$(env LLVM_DIR)/include")
    add_packages("glm", "glfw", "volk", "spirv-cross", "stb", "assimp", "imgui")
    after_build(function (target)
        local vulkan_sdk = os.getenv("VULKAN_SDK")
        local llvm_dir = os.getenv("LLVM_DIR")
        local include_dir_list = {}
        table.insert(include_dir_list, "-I" .. vulkan_sdk .. "/Include")
        table.insert(include_dir_list, "-I" .. target:pkg("glfw"):installdir() .. "/include")
        table.insert(include_dir_list, "-I" .. target:pkg("glm"):installdir())
        table.insert(include_dir_list, "-I" .. target:pkg("volk"):installdir())
        table.insert(include_dir_list, "-I" .. target:pkg("spirv-cross"):installdir())
        table.insert(include_dir_list, "-I" .. target:pkg("stb"):installdir())
        table.insert(include_dir_list, "-I" .. target:pkg("assimp"):installdir() .. "/include")
        table.insert(include_dir_list, "-I" .. target:pkg("imgui"):installdir())
        table.insert(include_dir_list, "-I" .. llvm_dir .. "/include")
        table.insert(include_dir_list, "-I" .. llvm_dir .. "/lib/clang/19/include")
        table.insert(include_dir_list, "-I" .. os.projectdir() .. "/src/meow_runtime")
        
        local src_path = path.join("-S" .. os.projectdir(), "src/meow_runtime");
        local output_path = path.join("-O" .. os.projectdir(), "src/meow_runtime/generated");
        
        local args = include_dir_list
        table.insert(args, src_path)
        table.insert(args, output_path)

        os.execv(target:targetfile(), args)
    end)
end)
```

这样就可以构建成功了

但是这样做每次构建都会生成 要生成的代码文件

这样每次都会触发 runtime 的重新编译

所以代码生成器怎么做增量编译

在每一次编译时，目标 A 遍历目标 B 所有的头文件，生成代码。并且 A 生成的代码是 B 的一部分

因此每一次编译时，目标 A 都会更新生成文件的时间戳，触发 B 的重新编译

我们可以让 A 的生成命令的是否执行依赖于 B 的头文件是否更新，这样，当 B 只改源文件的时候，A 不会重新生成文件

所以 A 是不是应该自己有一个历史记录的文件，首先它可以把第一次生成的信息存为二进制，生成开始的时候，读取之前保存的二进制，就知道了之前生成了什么

在 B 改了头文件之后，去查看这些发生改变的头文件，看看要反射的类型在自己的保存历史中有没有，要是没有，就生成文件，要是有，那么对比反射信息是不是一样的，如果不一样才生成

## 访问变量

```lua
set_project("TestApp")

local test_app_dir = "$(projectdir)/src"
local b = "www"

target("test_app", function()
    set_kind("binary")
    add_files("src/**.cpp")
    add_includedirs("src")
    after_build(function (target)
        print("------------------------")
        print("$(test_app_dir)")
        print(test_app_dir)
        print(b)
        print("------------------------")
    end)
end)

```

输出

```
------------------------

E:\repositories\Playground\test_xmake/src
www
------------------------
```

原来访问变量直接写就好了，不需要 `$()`

## defines

我拿简单的 case 测试 define 没问题

```cpp
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtx/euler_angles.hpp>

int main()
{
    glm::quat rotation(1.0, 1.0, 1.0, 1.0);
    glm::vec3 euler = glm::eulerAngles(rotation);
    return 0;
}
```

```lua
set_project("TestApp")

add_requires("glm")

target("test_app", function()
    set_kind("binary")
    add_files("src/**.cpp")
    add_includedirs("src")
    add_packages("glm")
    add_defines("GLM_ENABLE_EXPERIMENTAL", {public = true})
end)

```

保留我的大部分代码也没问题

```lua
set_project("TestApp")

add_requires("vulkansdk")
-- add_requires("llvm") llvm isn't supported well now, so hard code dependency on env
add_requires("glm", {configs = {small = true}})
add_requires("glm", "glfw", "volk", "spirv-cross", "stb", "assimp")
add_requires("imgui docking", {configs = {glfw = true, vulkan = true}})

target("test_app", function()
    set_kind("static")
    add_files("src/**.cpp")
    add_includedirs("src")
    add_packages("glm", "glfw", "vulkansdk", "volk", "spirv-cross", "stb", "assimp", "imgui", {public = true})

    add_defines("ENGINE_ROOT_DIR=\"" .. os.projectdir() .. "\"", {public = true})
    
    add_defines("NOMINMAX", {public = true}) -- for std::numeric_limits<double>::min() and max()

    add_defines("GLM_ENABLE_EXPERIMENTAL", {public = true})   -- for GLM: GLM_GTX_component_wise
    add_defines("GLFW_INCLUDE_VULKAN", {public = true})
    add_defines("GLFW_EXPOSE_NATIVE_WIN32", {public = true}) -- TODO: Config by platform
    add_defines("VK_USE_PLATFORM_WIN32_KHR", {public = true}) -- TODO: Config by platform
    if is_mode("EditorDebug", "GameDebug") then
        add_defines("VKB_DEBUG", "VKB_VALIDATION_LAYERS", {public = true})
    end
    add_defines("VK_NO_PROTOTYPES", {public = true})
    add_defines("IMGUI_DEFINE_MATH_OPERATORS", {public = true})
end)

```

这就很难顶了

然后去看 compile_command.json 也没问题

## cmake 

之前就看过这个

[https://stackoverflow.com/questions/20638963/cmake-behaviour-custom-configuration-types-with-visual-studio-need-multiple-cma](https://stackoverflow.com/questions/20638963/cmake-behaviour-custom-configuration-types-with-visual-studio-need-multiple-cma)

于是我想自己把 `CMAKE_CONFIGURATION_TYPES` 都删了，结果似乎不行

```cmake
cmake_minimum_required(VERSION 3.24)
# Set Project Name
project (s4)

# Edit available Configrations to make them available in IDE that support multiple-configuration (for example Visual Studio)
# has to be between "project" and "enable_language" to work as intended!
set(CMAKE_CONFIGURATION_TYPES Debugverbose CACHE STRING "Append user-defined configuration to list of configurations to make it usable in Visual Studio" FORCE)
# Set Source Language
enable_language (CXX)

add_executable(TestMain ./src/main.cpp)
```

这么做会导致 cmake 错误，说是找不到 debug 配置（明明我根本不需要）

```
E:\software\Microsoft Visual Studio\2022\Community\MSBuild\Microsoft\VC\v170\Microsoft.CppBuil
d.targets(452,5): error MSB8013: 此项目不包含配置和平台组合 Debug|x64。 [E:\repositories\Playground\test_cus
tom_configuration\build-debug\ZERO_CHECK.vcxproj]
```

应该是 vs 那边的要求

但是打开 vs 工程之后对我的配置来构建还是可以的

然后这个回答讲述了多重配置生成器和 makefile 配置生成器的区别

[https://stackoverflow.com/questions/31546278/where-to-set-cmake-configuration-types-in-a-project-with-subprojects](https://stackoverflow.com/questions/31546278/where-to-set-cmake-configuration-types-in-a-project-with-subprojects)

虽然我觉得 vs 也尊重我的 `CMAKE_BUILD_TYPE`

他指的应该是 cmakelists 处理过程中 `CMAKE_BUILD_TYPE` 没有意义？

但是他的原始回答就可以

```cmake
cmake_minimum_required(VERSION 3.24)
# Set Project Name
project (s4)

# Edit available Configrations to make them available in IDE that support multiple-configuration (for example Visual Studio)
# has to be between "project" and "enable_language" to work as intended!
if(CMAKE_CONFIGURATION_TYPES)
   list(APPEND CMAKE_CONFIGURATION_TYPES Debugverbose)
   set(CMAKE_CONFIGURATION_TYPES Debugverbose CACHE STRING "Append user-defined configuration to list of configurations to make it usable in Visual Studio" FORCE)
endif()

# Set Source Language
enable_language (CXX)

add_executable(TestMain ./src/main.cpp)
```

虽然还是有一点报错

```
-- Selecting Windows SDK version 10.0.26100.0 to target Windows 10.0.22631.
-- The C compiler identification is MSVC 19.38.33141.0
-- The CXX compiler identification is MSVC 19.38.33141.0
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
-- Check for working C compiler: E:/software/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.38.33130/bin/Hostx64/x64/cl.exe - skipped
-- Detecting C compile features
-- Detecting C compile features - done
-- Detecting CXX compiler ABI info
-- Detecting CXX compiler ABI info - done
-- Check for working CXX compiler: E:/software/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.38.33130/bin/Hostx64/x64/cl.exe - skipped
-- Detecting CXX compile features
-- Detecting CXX compile features - done
-- Configuring done (3.1s)
CMake Error: Error required internal CMake variable not set, cmake may not be built correctly.
Missing variable is:
CMAKE_EXE_LINKER_FLAGS_DEBUGVERBOSE
-- Generating done (0.0s)
CMake Warning:
  Manually-specified variables were not used by the project:

    CMAKE_BUILD_TYPE


CMake Generate step failed.  Build files cannot be regenerated correctly.
适用于 .NET Framework MSBuild 版本 17.11.9+a69bbaaf5

  1>Checking Build System
  Building Custom Rule E:/repositories/Playground/test_custom_configuration/CMakeLists.txt
  main.cpp
  TestMain.vcxproj -> E:\repositories\Playground\test_custom_configuration\build-debug\Debug\T
  estMain.exe
  Building Custom Rule E:/repositories/Playground/test_custom_configuration/CMakeLists.txt
```

## cmake 仅仅更改一个文件就导致所有项目重新构建

cmake 仅仅更改一个文件就导致所有项目重新构建，我猜是因为我写了

```cmake
cmake_minimum_required(VERSION 3.24)

# should ahead of project

set(CMAKE_CXX_FLAGS_EDITORDEBUG
    "/Zi /Ob0 /Od /RTC1 /DMEOW_EDITOR /DMEOW_DEBUG"
    CACHE STRING "")
set(CMAKE_CXX_FLAGS_GAMEDEBUG
    "/Zi /Ob0 /Od /RTC1 /DMEOW_DEBUG"
    CACHE STRING "")
set(CMAKE_CXX_FLAGS_EDITORRELEASE
    "/O2 /Ob2 /DNDEBUG /DMEOW_EDITOR"
    CACHE STRING "")
set(CMAKE_CXX_FLAGS_GAMERELEASE
    "/O2 /Ob2 /DNDEBUG"
    CACHE STRING "")

set(CMAKE_EXE_LINKER_FLAGS_EDITORDEBUG
    "/debug /INCREMENTAL"
    CACHE STRING "")
set(CMAKE_EXE_LINKER_FLAGS_GAMEDEBUG
    "/debug /INCREMENTAL"
    CACHE STRING "")
set(CMAKE_EXE_LINKER_FLAGS_EDITORRELEASE
    "/INCREMENTAL:NO"
    CACHE STRING "")
set(CMAKE_EXE_LINKER_FLAGS_GAMERELEASE
    "/INCREMENTAL:NO"
    CACHE STRING "")

project(MeowEngine LANGUAGES NONE)
```

的问题，但是我不敢肯定

于是发现确实是设置 cache 的问题

每次 config 都设置 cache 就导致 cache 被刷新，就导致全量编译

现在加了一个条件判断就好了