## UI 开发

### creator 句柄

需要一个方法，获得任意类型的各个字段的地址

用在 UI 上，使得外部用户可以通过 UI 控制字段的值

参考 Piccolo，一开始我的想法是

```cpp
#pragma once

#include <string>
#include <unordered_map>

class UICreator
{
public:
    void Register(std::string, void*);

private:
    std::unordered_map<std::string, void*> m_editor_ui_creator;
};
```

但是之后发现确实不能直接传指针

因为对于不同的实例，字段的指针是不一样的

而我的 creator 要处理不同的实例

所以我应该存一个获取 void* 的函数

于是确实就像 Piccolo 那样，要做一个 `std::unordered_map<std::string, std::function<void(std::string, void*)>> m_editor_ui_creator;`

因为处理数据的时候需要知道数据的名字，所以加一个字符串参数

### creator 需要知道的信息

一般的树形写法是，创建一个树节点，返回这个树节点是否被打开的状态

如果这个树节点被打开了，那么在这个 if 里面再创建子节点，如此递归下去

如果是 hard code 的话，那么我们直接写 if 块就好了

但是现在需要可以处理不定数量的控件

所以我们需要把每个步骤都拆开，使得他们可以自由组合

举个例子就是说，我们要把 if 拆成 begin 和 end

其中的执行体也是单独拆出来，比如显示 int 或者显示 string

这个时候就需要知道当前的树节点是否是打开的

但是问题是，因为现在我们拆开了，所以各个执行部分之间都是互相独立的，不知道互相的状态

所以需要做一个全局的变量

首先是需要把树节点的是否打开的状态做成栈

一开始我觉得只需要栈就好了，但是不知道为什么 Piccolo 把树节点的状态做成数组，然后为了方便栈一样的索引，还做了一个全局的深度

我感觉只要保持栈的结构，那么深度似乎是没有必要的

后面看到这个

```cpp
    std::string EditorUI::getLeafUINodeParentLabel()
    {
        std::string parent_label;
        int         array_size = g_editor_node_state_array.size();
        for (int index = 0; index < array_size; index++)
        {
            parent_label += g_editor_node_state_array[index].first + "::";
        }
        return parent_label;
    }
```

他这里就明确需要了数组的结构

为了获取父级的名字？为什么要这么做呢

看了一个使用案例

```cpp
        m_editor_ui_creator["float"] = [this](const std::string& name, void* value_ptr) -> void {
            if (g_node_depth == -1)
            {
                std::string label = "##" + name;
                ImGui::Text("%s", name.c_str());
                ImGui::SameLine();
                ImGui::InputFloat(label.c_str(), static_cast<float*>(value_ptr));
            }
            else
            {
                if (g_editor_node_state_array[g_node_depth].second)
                {
                    std::string full_label = "##" + getLeafUINodeParentLabel() + name;
                    ImGui::Text("%s", (name + ":").c_str());
                    ImGui::InputFloat(full_label.c_str(), static_cast<float*>(value_ptr));
                }
            }
        };
```

在深度不为 -1 的时候要把父级的名字拼接上来

好怪我觉得，这样不会造出一个很长的字符串吗

后面才知道这个 `##` 的用法是，后面跟着的字符串是 ID 

他这里的 `full_label.c_str()` 不是用来显示的，单纯是用来标记的 label

之前的 `ImGui::Text` 才是用来显示的

我决定试试不用这个 label 因为不用 ## 的时候，imgui 会自己生成唯一 ID

### 外部存储的状态

于是我在想做如下功能的时候犯难了

```cpp
// Add a variable to track the current display mode
bool displayAsEuler = true; // true for Euler angles, false for Quaternion

m_editor_ui_creator["glm::quat"] = [&](const std::string& name, void* value_ptr) {
    if (!m_tree_node_open_states.top())
        return;

    glm::quat& rotation = *static_cast<glm::quat*>(value_ptr);

    // Toggle button to switch between Euler and Quaternion modes
    if (ImGui::Button(displayAsEuler ? "Switch to Quaternion" : "Switch to Euler")) {
        displayAsEuler = !displayAsEuler;
    }

    if (displayAsEuler) {
        // Convert quaternion to Euler angles (degrees)
        glm::vec3 euler = glm::eulerAngles(rotation);
        glm::vec3 degrees_val;

        degrees_val.x = glm::degrees(euler.x); // pitch
        degrees_val.y = glm::degrees(euler.y); // roll
        degrees_val.z = glm::degrees(euler.z); // yaw

        DrawVecControl(name, degrees_val);
        
        // Update quaternion from Euler angles
        rotation = glm::quat(glm::radians(degrees_val));
    } else {
        // Use ImGui::DragFloat4 for Quaternion representation
        glm::vec4 quat_values = glm::vec4(rotation.x, rotation.y, rotation.z, rotation.w);

        if (ImGui::DragFloat4(name.c_str(), &quat_values.x, 0.01f)) {
            rotation = glm::quat(quat_values);
        }
    }
};

```

如果每一个值都要对应这样一个有状态的按钮的话，那么肯定是需要把这些 bool 存到一个什么东西里面

那么为了每一帧都能持久保存这些 bool，需要存在数组

每一个 button 需要和 array 的 bool 元素建立关系

用 tree 的访问索引什么的肯定不行，因为 gameobject 的访问顺序可能会变化

或者用 gameobject 的 id 加上组件顺序作为 hash 也不是不行

然后就是怎么回收垃圾，在当前帧里就可以知道哪些 bool 没有遍历到，因此随时可以回收垃圾

但是这样也太麻烦了，我觉得还是要精简

那么还是不搞这种切换的东西了

std::string 的显示也涉及到字符串内存，算了，不提供 InputText 了 

### gameobject 获取的 component 的类型

直接用 `typeid(TComponent).name()` 获取的类名会包含 class 等类型名，以及命名空间等

于是做了一个去除这些东西的函数

```cpp
    std::string RemoveClassAndNamespace(const std::string& full_type_name)
    {
        // Split the string by spaces
        std::stringstream        ss(full_type_name);
        std::string              item;
        std::vector<std::string> tokens;

        while (ss >> item)
        {
            tokens.push_back(item);
        }

        // Get the last substring (after the last space)
        std::string& last_token = tokens.back();

        // Find the position of the last "::" in the last substring
        size_t last_colon_pos = last_token.rfind("::");

        // If "::" is found, return the part after it; otherwise, return the whole last substring
        return (last_colon_pos != std::string::npos) ? last_token.substr(last_colon_pos + 2) : last_token;
    }
```

看着这个函数这个大……我感觉确实还是 Piccolo 那个宏定义比较好

### 添加需要传入的信息

做 UI 的时候发现我还需要在 FieldAccessor 中添加类型名

因为 UI 的 creator 是以类型名作为 key 的

现在的仅仅是记录了变量名，而没有记类型名
