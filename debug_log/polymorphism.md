# 多态

## 多态的坑

问题代码出在

```cpp
    void InputSystem::Start()
    {
        // TODO: Support json to get default input scheme
        m_current_scheme->buttons["Left"] =
            std::move(KeyboardInputButton(g_runtime_global_context.window_system->GetCurrentFocusWindow(), KeyCode::A));
        m_current_scheme->buttons["Right"] =
            std::move(KeyboardInputButton(g_runtime_global_context.window_system->GetCurrentFocusWindow(), KeyCode::D));
        m_current_scheme->buttons["Forward"] =
            std::move(KeyboardInputButton(g_runtime_global_context.window_system->GetCurrentFocusWindow(), KeyCode::W));
        m_current_scheme->buttons["Backward"] =
            std::move(KeyboardInputButton(g_runtime_global_context.window_system->GetCurrentFocusWindow(), KeyCode::S));
        m_current_scheme->buttons["Up"] =
            std::move(KeyboardInputButton(g_runtime_global_context.window_system->GetCurrentFocusWindow(), KeyCode::E));
        m_current_scheme->buttons["Down"] =
            std::move(KeyboardInputButton(g_runtime_global_context.window_system->GetCurrentFocusWindow(), KeyCode::Q));

        m_current_scheme->buttons["LeftMouse"]  = std::move(MouseInputButton(
            g_runtime_global_context.window_system->GetCurrentFocusWindow(), MouseButtonCode::ButtonLeft));
        m_current_scheme->buttons["RightMouse"] = std::move(MouseInputButton(
            g_runtime_global_context.window_system->GetCurrentFocusWindow(), MouseButtonCode::ButtonRight));

        m_current_scheme->axes["MouseX"] =
            std::move(MouseInputAxis(g_runtime_global_context.window_system->GetCurrentFocusWindow(), 0));
        m_current_scheme->axes["MouseY"] =
            std::move(MouseInputAxis(g_runtime_global_context.window_system->GetCurrentFocusWindow(), 1));
    }
```

这里的 map 存的是基类

```cpp
    struct InputScheme : public NonCopyable
    {
        std::map<std::string, InputAxis>   axes;
        std::map<std::string, InputButton> buttons;
    };
```

但是却往里面传子类的实例

这样其实不会调用子类的构造函数的，所以直接出错了

所以这就是为什么要用指针……直接把子类对象赋给父类的值对象的话，只能调用父类的拷贝构造或者移动构造，这样完全没有办法应用
