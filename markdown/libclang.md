# libclang

## libclang 的问题

现在我为了 libclang 能够识别到我的第三方库的类型，特意在 cmake 里面加上了 Generator 对第三方库的依赖，然后提取依赖成字符串

```CMakeLists
add_executable(${CODE_GENERATOR_NAME} ${CODE_GENERATOR_HEADER_FILES} ${CODE_GENERATOR_SOURCE_FILES})

target_include_directories(${CODE_GENERATOR_NAME} PUBLIC ${SRC_ROOT_DIR}/runtime)
target_include_directories(${CODE_GENERATOR_NAME}
                           PUBLIC ${3RD_PARTY_ROOT_DIR}/spdlog/include)
target_include_directories(${CODE_GENERATOR_NAME} PUBLIC ${3RD_PARTY_ROOT_DIR}/rocket)
target_include_directories(${CODE_GENERATOR_NAME} PUBLIC ${3RD_PARTY_ROOT_DIR}/glm)
target_include_directories(${CODE_GENERATOR_NAME}
                           PUBLIC ${3RD_PARTY_ROOT_DIR}/glfw/include)
target_include_directories(${CODE_GENERATOR_NAME} PUBLIC ${3RD_PARTY_ROOT_DIR}/volk)
if(Vulkan_FOUND)
  # for vulkan hpp
  target_include_directories(${CODE_GENERATOR_NAME} PUBLIC ${Vulkan_INCLUDE_DIRS})
endif()
target_include_directories(${CODE_GENERATOR_NAME} PUBLIC ${3RD_PARTY_ROOT_DIR}/glslang)
target_include_directories(${CODE_GENERATOR_NAME}
                           PUBLIC ${3RD_PARTY_ROOT_DIR}/SPIRV-Cross)
target_include_directories(${CODE_GENERATOR_NAME} PUBLIC ${3RD_PARTY_ROOT_DIR}/stb)
target_include_directories(${CODE_GENERATOR_NAME}
                           PUBLIC ${3RD_PARTY_ROOT_DIR}/assimp/include)
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
```

然后调用的时候就传入包括路径

```CMakeLists
add_custom_command(
    OUTPUT ${SRC_ROOT_DIR}/runtime/generated/register_all.cpp
    COMMAND ${CODE_GENERATOR_NAME} ${INCLUDE_PATH_COLLECTION} "-S${SRC_ROOT_DIR}/runtime" "-O${SRC_ROOT_DIR}/runtime/generated"
    DEPENDS ${CODE_GENERATOR_NAME} always_rebuild
    COMMENT "Generating register_all.cpp"
)
```

程序内部也会接受这个路径

```cpp
int main(int argc, char* argv[])
{
    std::string include_path = "";
    std::string src_root     = "";
    std::string output_root  = "";

    for (int i = 1; i < argc; ++i)
    {
        std::string arg(argv[i]);
        if (arg.substr(0, 2) == "-S" && arg.size() > 2)
        {
            if (src_root.size() > 0)
            {
                std::cerr << "More than one -S<src_root>!" << std::endl;
                return 1;
            }
            src_root = arg.substr(2);
        }
        else if (arg.substr(0, 2) == "-O" && arg.size() > 2)
        {
            if (output_root.size() > 0)
            {
                std::cerr << "More than one -O<output_root>!" << std::endl;
                return 1;
            }
            output_root = arg.substr(2);
        }
        else if (arg.substr(0, 2) == "-I" && arg.size() > 2)
        {
            if (include_path.size() > 0)
                include_path += " ";
            include_path += arg;
        }
    }
```

输出的 `include_path` 我也看了，没问题

解析的时候就有问题

```cpp
    void Parser::ParseFile(const fs::path& path, const std::string& include_path)
    {
        // traverse AST to find class

        CXIndex           index   = clang_createIndex(0, 0);
        const char*       args[2] = {"-xc++", include_path.c_str()}; // view .h as c++ file
        CXTranslationUnit unit =
            clang_parseTranslationUnit(index, path.string().c_str(), args, 2, nullptr, 0, CXTranslationUnit_None);
        if (unit == nullptr)
        {
            std::cerr << "Unable to parse translation unit. Quitting." << std::endl;
            exit(-1);
        }
```

传入之后，始终就是不行

```
.\src\runtime\function\components\transform\transform_3d_component.hpp:10:13: warning: unknown attribute 'reflectable_class' ignored [-Wunknown-attributes]
   10 |     class [[reflectable_class()]] Transform3DComponent : public Component
      |             ^~~~~~~~~~~~~~~~~
   10 |     class [[reflectable_class()]] Transform3DComponent : public Component
   10 |     class [[reflectable_class()]] Transform3DComponent : public Component
   10 |     class [[reflectable_class()]] Transform3DComponent : public Component
      |             ^~~~~~~~~~~~~~~~~
.\src\runtime\function\components\transform\transform_3d_component.hpp:13:11: warning: unknown attribute 'reflectable_field' ignored [-Wunknown-attributes]
   13 |         [[reflectable_field()]]
      |           ^~~~~~~~~~~~~~~~~
.\src\runtime\function\components\transform\transform_3d_component.hpp:16:11: warning: unknown attribute 'reflectable_field' ignored [-Wunknown-attributes]
   16 |         [[reflectable_field()]]
      |           ^~~~~~~~~~~~~~~~~
.\src\runtime\function\components\transform\transform_3d_component.hpp:19:11: warning: unknown attribute 'reflectable_field' ignored [-Wunknown-attributes]
   19 |         [[reflectable_field()]]
```

但是仅仅 hard code 传入本仓库的路径就可以

```cpp
        CXIndex     index   = clang_createIndex(0, 0);
        const char* args[2] = {
            "-xc++",
            "-IE:/repositories/MeowEngine/src/runtime"}; // view .h as c++
```

那这就是第三方库的锅

为了 clang_getCursorType 能够识别到第三方库的类型

需要在 clang_parseTranslationUnit 传入第三方库的 include 路径

但是传入第三方库的路径之后，解析每个文件的 AST 膨胀了不说，还会导致奇怪的错误

使得我原来正常的代码都解析不出来了

果然，还是自己写文本解析器，才是正道啊

问了大佬，大佬说可以看诊断信息

于是做了

```cpp
    void print_diagnostics(CXTranslationUnit TU)
    {
        unsigned numDiagnostics = clang_getNumDiagnostics(TU);
        for (unsigned i = 0; i < numDiagnostics; ++i)
        {
            CXDiagnostic diag    = clang_getDiagnostic(TU, i);
            CXString     diagStr = clang_formatDiagnostic(diag, clang_defaultDiagnosticDisplayOptions());
            printf("Diagnostic %u: %s\n", i, clang_getCString(diagStr));
            clang_disposeString(diagStr);
            clang_disposeDiagnostic(diag);
        }
    }
```

```cpp
    void Parser::ParseFile(const fs::path& path, const std::string& include_path)
    {
        // traverse AST to find class

        CXIndex     index   = clang_createIndex(0, 0);
        const char* args[2] = {"-xc++", "-IE:/repositories/MeowEngine/src/runtime"}; // view .h as c++
                                                                                     // file
        CXTranslationUnit unit =
            clang_parseTranslationUnit(index, path.string().c_str(), args, 2, nullptr, 0, CXTranslationUnit_None);
        if (unit == nullptr)
        {
            std::cerr << "Unable to parse translation unit. Quitting." << std::endl;
            exit(-1);
        }

        print_diagnostics(unit);
        
```

结果是会输出很多 std 找不到的错误

就很神奇

而且可能是输出太多错了？反正是我的代码生成器程序加了 `print_diagnostics` 之后

## libclang 反射失败

```cpp
    void Parser::ParseFile(const fs::path& path, const std::vector<std::string>& include_paths)
    {
        // traverse AST to find class

        CXIndex index = clang_createIndex(0, 0);

        std::vector<const char*> all_args(2 + include_paths.size());
        all_args[0] = "-xc++";
        all_args[1] = "-std=c++20";
        all_args[2] = "-LE:\\software\\mingw64\\lib\\libstdc++.a";
        for (int i = 0; i < include_paths.size(); i++)
        {
            all_args[i + 3] = include_paths[i].c_str();
        }
        CXTranslationUnit unit = clang_parseTranslationUnit(
            index, path.string().c_str(), all_args.data(), all_args.size(), nullptr, 0, CXTranslationUnit_None);
        if (unit == nullptr)
        {
            std::cerr << "Unable to parse translation unit. Quitting." << std::endl;
            exit(-1);
        }
```

解析不了 `std::vector`

```cpp
all_args[2] = "-IE:\\software\\mingw64\\lib";
```

也解析不了 `std::vector`

如果是用

```cpp
all_args[2] = "-IE:\\software\\mingw64\\include\\c++\\15.0.0";
```

连 `std::string` 都解析不了了

去看了 piccolo 别人是明确可以反射出来的

animation_clip.reflection.gen.h

```cpp
        static const char* getFieldName_convert(){ return "convert";}
        static const char* getFieldTypeName_convert(){ return "std::vector<std::string>";}
        static void set_convert(void* instance, void* field_value){ static_cast<AnimNodeMap*>(instance)->convert = *static_cast<std::vector<std::string>*>(field_value);}
        static void* get_convert(void* instance){ return static_cast<void*>(&(static_cast<AnimNodeMap*>(instance)->convert));}
        static bool isArray_convert(){ return true; }
```

于是再用了简单的类

```cpp
#pragma once

#include "core/reflect/macros.h"

#include <string>
#include <vector>

class [[reflectable_class()]] TestRefl
{
public:
    [[reflectable_field()]]
    std::string test_str;

    [[reflectable_field()]]
    std::vector<std::string> m_image_paths;
};
```

这个时候就可以反射成功了

所以果然还是第三方库的问题

