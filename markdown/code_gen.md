# 代码生成

## 代码生成器 Debug

### clang_parseTranslationUnit debug

于是发现之前我为什么添加了第三方库的 include 路径就会失败呢

是因为我传入的 args 的数量我一直没有改，也就是说我传入三个参数，但是给的数字是 2，那就报错了

现在就改好了

### TryAddComponent debug

`TryAddComponent` 里面的输出竟然是这样子的

```cpp
        template<typename TComponent>
        std::weak_ptr<TComponent> TryAddComponent(std::shared_ptr<TComponent> component_ptr)
        {
#ifdef MEOW_DEBUG
            if (!component_ptr)
            {
                RUNTIME_ERROR("shared ptr is invalid!");
                return std::shared_ptr<TComponent>(nullptr);
            }
#endif

            const std::string component_type_name = RemoveClassAndNamespace(typeid(TComponent).name());

            // Check if a component of the same type already exists
            for (const auto& refl_component : m_refl_components)
            {
                if (refl_component.type_name == component_type_name)
                {
                    RUNTIME_ERROR("Component already exists: {}", component_type_name);
                    return std::shared_ptr<TComponent>(nullptr);
                }
            }

            // Add the component to the container
            m_refl_components.emplace_back(component_type_name, component_ptr);

            RUNTIME_INFO("{} is added!", component_type_name.c_str());
```

输出

```
[14:05:22] RUNTIME: N4Meow20Transform3DComponentE is added!
[14:05:22] RUNTIME: N4Meow17Camera3DComponentE is added!
[14:05:22] RUNTIME: N4Meow20Transform3DComponentE is added!
[14:05:22] RUNTIME: N4Meow14ModelComponentE is added!
```

太奇怪了……

于是打算输出完整的

```cpp
            RUNTIME_INFO("typeid(TComponent).name() = {}", typeid(TComponent).name());
            RUNTIME_INFO("{} is added!", component_type_name.c_str());
```

输出

```
[14:10:58] RUNTIME: typeid(TComponent).name() = N4Meow20Transform3DComponentE
[14:10:58] RUNTIME: N4Meow20Transform3DComponentE is added!
[14:10:58] RUNTIME: typeid(TComponent).name() = N4Meow17Camera3DComponentE
[14:10:58] RUNTIME: N4Meow17Camera3DComponentE is added!
[14:10:58] RUNTIME: typeid(TComponent).name() = N4Meow20Transform3DComponentE
[14:10:58] RUNTIME: N4Meow20Transform3DComponentE is added!
[14:10:59] RUNTIME: typeid(TComponent).name() = N4Meow14ModelComponentE
[14:10:59] RUNTIME: N4Meow14ModelComponentE is added!
```

佛了，看来这个 `typeid(TComponent).name()` 的输出是依赖于编译器的，我不能依靠他来实现

## 代码生成器 Debug

我改 Log 之后不知道为什么代码生成器总是有问题

用 vscode gdb 调试的话，会直接退出

```
(gdb) run
Starting program: E:\repositories\MeowEngine\build-debug\src\code_generator\CodeGenerator.exe
[New Thread 784.0x7310]
[New Thread 784.0x8278]
[New Thread 784.0x5a58]
[Thread 784.0x4690 exited with code 3221225781]
[Thread 784.0x8278 exited with code 3221225781]
[Thread 784.0x7310 exited with code 3221225781]
During startup program exited with code 0xc0000135.
```

搜了一下，是找不到 dll 的问题

感觉各个人出现的问题都不尽相同

所以感觉这种工具确实，还是 visual studio 好用啊……我知错了

于是改回 cl

```bat
@echo off

cls

REM Configure a debug build
cmake -S . -B build-release/ -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=cl -DCMAKE_CXX_COMPILER=cl -DMSVC_TOOLSET_VERSION=143

cd build-release

REM Actually build the binaries
ninja -j8 -d explain

cd ..

pause
```

结果出错

```
-- The CXX compiler identification is MSVC 19.41.34120.0
-- Detecting CXX compiler ABI info
-- Detecting CXX compiler ABI info - failed
-- Check for working CXX compiler: E:/software/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.41.34120/bin/Hostx64/x64/cl.exe
-- Check for working CXX compiler: E:/software/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.41.34120/bin/Hostx64/x64/cl.exe - broken
CMake Error at E:/software/CMake/share/cmake-3.29/Modules/CMakeTestCXXCompiler.cmake:60 (message):
  The C++ compiler

    "E:/software/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.41.34120/bin/Hostx64/x64/cl.exe"

  is not able to compile a simple test program.

  It fails with the following output:

    Change Dir: 'E:/repositories/MeowEngine/build-release/CMakeFiles/CMakeScratch/TryCompile-21ofsb'

    Run Build Command(s): E:/software/mingw64/bin/ninja.exe -v cmTC_ccb99
    [1/2] "E:\software\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.41.34120\bin\Hostx64\x64\cl.exe"  /nologo /TP   -MDd /showIncludes /FoCMakeFiles\cmTC_ccb99.dir\testCXXCompiler.cxx.obj /FdCMakeFiles\cmTC_ccb99.dir\ /FS -c E:\repositories\MeowEngine\build-release\CMakeFiles\CMakeScratch\TryCompile-21ofsb\testCXXCompiler.cxx
    [2/2] C:\Windows\system32\cmd.exe /C "cd . && E:\software\CMake\bin\cmake.exe -E vs_link_exe --intdir=CMakeFiles\cmTC_ccb99.dir --rc=rc --mt=CMAKE_MT-NOTFOUND --manifests  -- E:\software\mingw64\bin\ld.exe /nologo CMakeFiles\cmTC_ccb99.dir\testCXXCompiler.cxx.obj  /out:cmTC_ccb99.exe /implib:cmTC_ccb99.lib /pdb:cmTC_ccb99.pdb /version:0.0 /debug /INCREMENTAL /subsystem:console  kernel32.lib user32.lib gdi32.lib winspool.lib shell32.lib ole32.lib oleaut32.lib uuid.lib comdlg32.lib advapi32.lib && cd ."
    FAILED: cmTC_ccb99.exe
    C:\Windows\system32\cmd.exe /C "cd . && E:\software\CMake\bin\cmake.exe -E vs_link_exe --intdir=CMakeFiles\cmTC_ccb99.dir --rc=rc --mt=CMAKE_MT-NOTFOUND --manifests  -- E:\software\mingw64\bin\ld.exe /nologo CMakeFiles\cmTC_ccb99.dir\testCXXCompiler.cxx.obj  /out:cmTC_ccb99.exe /implib:cmTC_ccb99.lib /pdb:cmTC_ccb99.pdb /version:0.0 /debug /INCREMENTAL /subsystem:console  kernel32.lib user32.lib gdi32.lib winspool.lib shell32.lib ole32.lib oleaut32.lib uuid.lib comdlg32.lib advapi32.lib && cd ."
    RC Pass 1: command "rc /fo CMakeFiles\cmTC_ccb99.dir/manifest.res CMakeFiles\cmTC_ccb99.dir/manifest.rc" failed (exit code 0) with the following output:
    no such file or directory
    ninja: build stopped: subcommand failed.
```

看了 [https://stackoverflow.com/questions/57348542/cmake-will-not-be-able-to-correctly-generate-this-project-call-stack-most-rece](https://stackoverflow.com/questions/57348542/cmake-will-not-be-able-to-correctly-generate-this-project-call-stack-most-rece)

于是用了 prompt 那个窗口

还是出现问题

```
-- The CXX compiler identification is MSVC 19.41.34120.0
-- Detecting CXX compiler ABI info
-- Detecting CXX compiler ABI info - failed
-- Check for working CXX compiler: E:/software/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.41.34120/bin/Hostx86/x86/cl.exe
-- Check for working CXX compiler: E:/software/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.41.34120/bin/Hostx86/x86/cl.exe - broken
CMake Error at E:/software/CMake/share/cmake-3.29/Modules/CMakeTestCXXCompiler.cmake:60 (message):
  The C++ compiler

    "E:/software/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.41.34120/bin/Hostx86/x86/cl.exe"

  is not able to compile a simple test program.

  It fails with the following output:

    Change Dir: 'E:/repositories/MeowEngine/build-release/CMakeFiles/CMakeScratch/TryCompile-ziu4gn'

    Run Build Command(s): E:/software/mingw64/bin/ninja.exe -v cmTC_f56cb
    [1/2] "E:\software\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.41.34120\bin\Hostx86\x86\cl.exe"  /nologo /TP   -MDd /showIncludes /FoCMakeFiles\cmTC_f56cb.dir\testCXXCompiler.cxx.obj /FdCMakeFiles\cmTC_f56cb.dir\ /FS -c E:\repositories\MeowEngine\build-release\CMakeFiles\CMakeScratch\TryCompile-ziu4gn\testCXXCompiler.cxx
    [2/2] C:\Windows\system32\cmd.exe /C "cd . && E:\software\CMake\bin\cmake.exe -E vs_link_exe --intdir=CMakeFiles\cmTC_f56cb.dir --rc=rc --mt=C:\PROGRA~2\WI3CF2~1\10\bin\100226~1.0\x86\mt.exe --manifests  -- E:\software\mingw64\bin\ld.exe /nologo CMakeFiles\cmTC_f56cb.dir\testCXXCompiler.cxx.obj  /out:cmTC_f56cb.exe /implib:cmTC_f56cb.lib /pdb:cmTC_f56cb.pdb /version:0.0 /debug /INCREMENTAL /subsystem:console  kernel32.lib user32.lib gdi32.lib winspool.lib shell32.lib ole32.lib oleaut32.lib uuid.lib comdlg32.lib advapi32.lib && cd ."
    FAILED: cmTC_f56cb.exe
    C:\Windows\system32\cmd.exe /C "cd . && E:\software\CMake\bin\cmake.exe -E vs_link_exe --intdir=CMakeFiles\cmTC_f56cb.dir --rc=rc --mt=C:\PROGRA~2\WI3CF2~1\10\bin\100226~1.0\x86\mt.exe --manifests  -- E:\software\mingw64\bin\ld.exe /nologo CMakeFiles\cmTC_f56cb.dir\testCXXCompiler.cxx.obj  /out:cmTC_f56cb.exe /implib:cmTC_f56cb.lib /pdb:cmTC_f56cb.pdb /version:0.0 /debug /INCREMENTAL /subsystem:console  kernel32.lib user32.lib gdi32.lib winspool.lib shell32.lib ole32.lib oleaut32.lib uuid.lib comdlg32.lib advapi32.lib && cd ."
    LINK Pass 1: command "E:\software\mingw64\bin\ld.exe /nologo CMakeFiles\cmTC_f56cb.dir\testCXXCompiler.cxx.obj /out:cmTC_f56cb.exe /implib:cmTC_f56cb.lib /pdb:cmTC_f56cb.pdb /version:0.0 /debug /INCREMENTAL /subsystem:console kernel32.lib user32.lib gdi32.lib winspool.lib shell32.lib ole32.lib oleaut32.lib uuid.lib comdlg32.lib advapi32.lib /MANIFEST /MANIFESTFILE:CMakeFiles\cmTC_f56cb.dir/intermediate.manifest CMakeFiles\cmTC_f56cb.dir/manifest.res" failed (exit code 1) with the following output:
    E:\software\mingw64\bin\ld.exe: cannot find /nologo: No such file or directory
    E:\software\mingw64\bin\ld.exe: cannot find /out:cmTC_f56cb.exe: No such file or directory
    E:\software\mingw64\bin\ld.exe: cannot find /implib:cmTC_f56cb.lib: No such file or directory
    E:\software\mingw64\bin\ld.exe: cannot find /pdb:cmTC_f56cb.pdb: No such file or directory
    E:\software\mingw64\bin\ld.exe: cannot find /version:0.0: No such file or directory
    E:\software\mingw64\bin\ld.exe: cannot find /debug: No such file or directory
    E:\software\mingw64\bin\ld.exe: cannot find /INCREMENTAL: No such file or directory
    E:\software\mingw64\bin\ld.exe: cannot find /subsystem:console: No such file or directory
    E:\software\mingw64\bin\ld.exe: cannot find kernel32.lib: No such file or directory
    E:\software\mingw64\bin\ld.exe: cannot find user32.lib: No such file or directory
    E:\software\mingw64\bin\ld.exe: cannot find gdi32.lib: No such file or directory
    E:\software\mingw64\bin\ld.exe: cannot find winspool.lib: No such file or directory
    E:\software\mingw64\bin\ld.exe: cannot find shell32.lib: No such file or directory
    E:\software\mingw64\bin\ld.exe: cannot find ole32.lib: No such file or directory
    E:\software\mingw64\bin\ld.exe: cannot find oleaut32.lib: No such file or directory
    E:\software\mingw64\bin\ld.exe: cannot find uuid.lib: No such file or directory
    E:\software\mingw64\bin\ld.exe: cannot find comdlg32.lib: No such file or directory
    E:\software\mingw64\bin\ld.exe: cannot find advapi32.lib: No such file or directory
    E:\software\mingw64\bin\ld.exe: cannot find /MANIFEST: No such file or directory
    E:\software\mingw64\bin\ld.exe: cannot find /MANIFESTFILE:CMakeFiles\cmTC_f56cb.dir/intermediate.manifest: Invalid argument
    CMakeFiles\cmTC_f56cb.dir/manifest.res: file not recognized: file format not recognized
    ninja: build stopped: subcommand failed.





  CMake will not be able to correctly generate this project.
Call Stack (most recent call first):
  CMakeLists.txt:2 (project)


-- Configuring incomplete, errors occurred!
ninja: error: loading 'build.ninja': The system cannot find the file specified.
```

于是还是放弃了 ninja 和 msbuild 合作

然后就是 clang 再试了一下，虽然可以构建，但是启动程序就报错

我也不想知道为什么了……放弃 debug

还是 gcc 吧

然后不知道为什么，之前的代码生成器一启动就退出，但是现在我构建出来的就不会有这个问题

可能是因为我改了环境变量？我把 Visual Studio 的环境变量改成正确的了