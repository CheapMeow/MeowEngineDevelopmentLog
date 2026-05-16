# input scheme

## input scheme

原来的 input scheme 的策略是

一个 input scheme 对应一套映射方案

切换 input scheme 的同时也交换 window 绑定好的信号

```cpp
    void InputSystem::SetScheme(InputScheme* scheme)
    {
        if (!scheme)
            scheme = m_null_scheme.get();
        // We want to preserve signals from the current scheme to the new one.
        scheme->MoveSignals(m_current_scheme);
        m_current_scheme = scheme;
    }
```

```cpp
    void InputScheme::MoveSignals(InputScheme* other)
    {
        if (!other)
            return;
        // Move all axis and button top level signals from the other scheme.
        for (auto& [axis_name, axis] : other->m_axes)
        {
            if (auto it = m_axes.find(axis_name); it != m_axes.end())
                std::swap(it->second->OnAxis(), axis->OnAxis());
            else
                MEOW_WARN("InputAxis was not found in input scheme: \"{}\"", axis_name);
        }
        for (auto& [button_name, button] : other->m_buttons)
        {
            if (auto it = m_buttons.find(button_name); it != m_buttons.end())
                std::swap(it->second->OnButton(), button->OnButton());
            else
                MEOW_WARN("InputButton was not found in input scheme: \"{}\"", button_name);
        }
    }
```

但是这个是固定绑定到 current window

