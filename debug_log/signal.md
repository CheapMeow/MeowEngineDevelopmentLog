# 信号类

## 信号类的开发

最容易对信号类想到的实现为

```cpp
#pragma once

#include <algorithm>
#include <functional>
#include <vector>

template<typename... Args>
class Signal
{
public:
    using SlotType = std::function<void(Args...)>;

    SlotType& connect(const SlotType& slot)
    {
        m_slots.push_back(slot);
        return *(m_slots.end() - 1);
    }

    bool disconnect(const SlotType& slot)
    {
        auto it = std::remove(m_slots.begin(), m_slots.end(), slot);
        if (it != m_slots.end())
        {
            m_slots.erase(it);
            return true;
        }
        return false;
    }

    void operator()(Args... args) const
    {
        for (const auto& slot : m_slots)
        {
            slot(args...);
        }
    }

private:
    std::vector<SlotType> m_slots;
};
```

这样有一个问题是 `disconnect` 时，`std::function` 本身并不是一个可以比较的对象

因为 `std::function` 可能是由全局/静态函数、成员函数、运算符构造而来，构造成 `std::function` 的时候会擦除它们的底层类型信息，所以 `std::function` 的比较运算符才被设置为删除

所以你肯定是需要一个东西来区分你存储的 lambda

所以你就需要一个 ID 了

这个 ID 直接用 size_t 就好了

那既然你都用 ID 了，那不如直接用 map 来存储 slot，就不用在 vector 中查找了

于是当你 connect 的时候会返回一个 ID，如果你 connect 了之后就不管他，只希望 signal 销毁的时候也带走他的 slot，那么你就不用存储这些 id

如果你外部代码希望之后还会销毁这个 slot，那么就需要存储这个 id