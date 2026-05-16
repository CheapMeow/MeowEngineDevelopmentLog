# Dt

## 键位映射出错

不知道为什么，之前都没出错的键位映射，现在就出现了映射不上的问题

具体就是，我按下键盘的时候，用我的 GetAction 方法没有办法获取到值

在 glfw 的回调里面 debug

src\runtime\function\window\window.cpp

```cpp
    void CallbackKey(GLFWwindow* glfwWindow, int32_t key, int32_t scancode, int32_t action, int32_t mods)
    {
        std::cout << key << std::endl;

        auto window = static_cast<Window*>(glfwGetWindowUserPointer(glfwWindow));
        window->m_on_key_signal(
            static_cast<KeyCode>(key), static_cast<InputAction>(action), static_cast<uint8_t>(mods));
    }
```

这里是有正确的反应的

于是在 input 类里面 debug

他是应该被 glfw 回调调用的

src\runtime\function\input\buttons\keyboard_input_button.cpp

```cpp
    KeyboardInputButton::KeyboardInputButton(KeyCode key)
        : m_key(key)
    {
        g_runtime_global_context.window_system->GetCurrentFocusWindow()->OnKey().connect(
            [this](KeyCode key, InputAction action, uint8_t mods) {
                std::cout << static_cast<int16_t>(key) << std::endl;

                if (m_key == key)
                {
                    m_on_button(action, mods);
                }
            });
    }
```


这里也有正确的反应

那么再查看开放给外部的接口

src\runtime\function\window\window.cpp

```cpp
    InputAction Window::GetKeyAction(KeyCode key) const
    {
        auto state = glfwGetKey(m_glfw_window, static_cast<int32_t>(key));
        if (key == KeyCode::A)
            std::cout << state << std::endl;
        return static_cast<InputAction>(state);
    }
```

也是正确的……

那就没道理了，那为什么我的摄像机不走了呢

于是在 Camera 里面 debug

```cpp
    void Camera3DComponent::TickFreeCamera(float dt)
    {
        if (std::shared_ptr<Transform3DComponent> transform_component = m_transform.lock())
        {
            if (g_runtime_global_context.input_system->GetButton("RightMouse")->GetAction() == InputAction::Press)
            {
                float dx = g_runtime_global_context.input_system->GetAxis("MouseX")->GetAmount();
                float dy = g_runtime_global_context.input_system->GetAxis("MouseY")->GetAmount();

                glm::vec3 temp_right = transform_component->rotation * glm::vec3(1.0f, 0.0f, 0.0f);

                // TODO: config camera rotate velocity
                glm::quat dyaw   = Math::QuaternionFromAngleAxis(-dx * dt * 100.0f, glm::vec3(0.0f, 1.0f, 0.0f));
                glm::quat dpitch = Math::QuaternionFromAngleAxis(-dy * dt * 100.0f, temp_right);

                transform_component->rotation = dyaw * dpitch * transform_component->rotation;
            }

            glm::vec3 right   = transform_component->rotation * glm::vec3(1.0f, 0.0f, 0.0f);
            glm::vec3 forward = transform_component->rotation * glm::vec3(0.0f, 0.0f, 1.0f);
            glm::vec3 up      = glm::vec3(0.0f, 1.0f, 0.0f);

            glm::vec3 movement = glm::vec3(0.0f);

            if (g_runtime_global_context.input_system->GetButton("Left")->GetAction() == InputAction::Press)
            {
                movement += -right;
            }
            if (g_runtime_global_context.input_system->GetButton("Right")->GetAction() == InputAction::Press)
            {
                movement += right;
            }
            if (g_runtime_global_context.input_system->GetButton("Forward")->GetAction() == InputAction::Press)
            {
                std::cout << "Hello" << std::endl;
                movement += forward;
            }
```

仍然是正确的输出……

好吧，最后发现是 dt 的问题，他一直是 0

```cpp
    float last_time = 0.0;
    while (MeowEditor::Get().IsRunning())
    {
        float curr_time = Time::GetTime();
        float dt        = curr_time - last_time;

        MEOW_INFO("curr_time = {}", curr_time);
        MEOW_INFO("last_time = {}", last_time);
        MEOW_INFO("dt = {}", dt);

        last_time = curr_time;

        MeowEditor::Get().Tick(dt);
    }
```

输出一直是 0

我不知道 glfw 的 gettime 为什么返回 0，明明 glfw 都没报错，glfw 的按键绑定都是 ok 的

于是自己写

```cpp
    class LIBRARY_API Time
    {
    public:
        Time(const Time&) = delete;
        Time(Time&&)      = delete;

        static Time& Get()
        {
            static Time instance;
            return instance;
        }

        float GetDeltaTime()
        {
            auto end_timepoint = std::chrono::steady_clock::now();
            auto elapsed_time =
                std::chrono::time_point_cast<std::chrono::microseconds>(end_timepoint).time_since_epoch() -
                std::chrono::time_point_cast<std::chrono::microseconds>(m_last_timepoint).time_since_epoch();
            m_last_timepoint = end_timepoint;

            return (double)elapsed_time.count() / 1000000.0;
        }

    private:
        Time() { m_last_timepoint = std::chrono::steady_clock::now(); }

        std::chrono::time_point<std::chrono::steady_clock> m_last_timepoint;
    };
```

但是这写的有问题

输出

```
[MeowEngine][2024-09-07 03:10:39] dt = -0.0011969996
[MeowEngine][2024-09-07 03:10:39] curr_time = 0.008333
[MeowEngine][2024-09-07 03:10:39] curr_time = 0.006947
[MeowEngine][2024-09-07 03:10:39] dt = 0.0013860003
[MeowEngine][2024-09-07 03:10:39] curr_time = 0.006663
[MeowEngine][2024-09-07 03:10:39] curr_time = 0.008333
[MeowEngine][2024-09-07 03:10:39] dt = -0.0016700001
[MeowEngine][2024-09-07 03:10:39] curr_time = 0.008147
[MeowEngine][2024-09-07 03:10:39] curr_time = 0.006663
[MeowEngine][2024-09-07 03:10:39] dt = 0.0014840001
[MeowEngine][2024-09-07 03:10:39] curr_time = 0.006957
[MeowEngine][2024-09-07 03:10:39] curr_time = 0.008147
[MeowEngine][2024-09-07 03:10:39] dt = -0.0011900002
[MeowEngine][2024-09-07 03:10:39] curr_time = 0.009373
[MeowEngine][2024-09-07 03:10:39] curr_time = 0.006957
[MeowEngine][2024-09-07 03:10:39] dt = 0.0024159998
[MeowEngine][2024-09-07 03:10:39] curr_time = 0.007164
[MeowEngine][2024-09-07 03:10:39] curr_time = 0.009373
[MeowEngine][2024-09-07 03:10:39] dt = -0.0022089998
[MeowEngine][2024-09-07 03:10:39] curr_time = 0.008866
[MeowEngine][2024-09-07 03:10:39] curr_time = 0.007164
[MeowEngine][2024-09-07 03:10:39] dt = 0.0017019999
[MeowEngine][2024-09-07 03:10:39] curr_time = 0.007197
[MeowEngine][2024-09-07 03:10:39] curr_time = 0.008866
[MeowEngine][2024-09-07 03:10:39] dt = -0.0016689999
[MeowEngine][2024-09-07 03:10:39] curr_time = 0.00929
[MeowEngine][2024-09-07 03:10:39] curr_time = 0.007197
[MeowEngine][2024-09-07 03:10:39] dt = 0.0020930003
```

问题是我一帧之内反复调用这个 GetDeltaTime

于是改了 update 的时机

但是输出 dt 还是不行

```
dt = 0
dt = 0
dt = 1e-06
dt = 1e-06
dt = 0
dt = 1e-06
dt = 1e-06
dt = 1e-06
dt = 0
dt = 1e-06
dt = 1e-06
```

但是很奇怪啊，我另外一个地方用到了 deltatime 来更新灯光的位置，实际做出来灯光也是正常运动的，为什么传递 dt 就会有问题呢

之后多次编译，原来是因为我分成两个构建了，一个是 editor 一个是 runtime 我的灯光在 runtime 里面，然后我修改传入的 dt 的逻辑是在 editor 里面

所以似乎出现了一些不匹配的情况……

好吧，那么我自己用 chrono 实现的 time 是没有问题的

那么为什么 glfwgettime 会返回 0……

fine，不打算纠结这个问题了