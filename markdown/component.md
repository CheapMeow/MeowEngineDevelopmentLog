## 从 ECS 转成组件组合

突然感觉用 ECS 来做普通的功能可能是，杀鸡用牛刀

于是还是转成正常的开发了

于是各个地方都要改

主要的原因还是要分析性能，但是对 ECS 这个复杂的东西不太好分析性能，我感觉基础成本太大

## 存储 component

我在想用共享指针来存储 component

我一开始用的是 shared_ptr

但是我在想，怎么从基类的 component 获得到派生类

测试了一下发现，`shared_ptr` 转到基类或者派生类，引用计数都是共享的

```cpp
#include <iostream>
#include <memory>

class Base
{
public:
    virtual ~Base() { std::cout << "Base Destructor" << std::endl; }
};

class Derived : public Base
{
public:
    ~Derived() { std::cout << "Derived Destructor" << std::endl; }
};

void demonstrateSharedOwnership()
{
    // 创建一个 shared_ptr<Derived>
    std::shared_ptr<Derived> derivedPtr = std::make_shared<Derived>();

    // 将 shared_ptr<Derived> 转换为 shared_ptr<Base>
    std::shared_ptr<Base> basePtr = derivedPtr;

    // 输出引用计数
    std::cout << "Reference count after conversion: " << derivedPtr.use_count() << std::endl;

    {
        // 在一个新的作用域中创建一个 shared_ptr<Derived>
        std::shared_ptr<Derived> anotherDerivedPtr = std::dynamic_pointer_cast<Derived>(basePtr);

        // 输出引用计数
        std::cout << "Reference count after dynamic_pointer_cast: " << derivedPtr.use_count() << std::endl;
    }

    // 输出引用计数，anotherDerivedPtr 已经超出作用域被销毁
    std::cout << "Reference count after anotherDerivedPtr goes out of scope: " << derivedPtr.use_count() << std::endl;
}

int main()
{
    demonstrateSharedOwnership();
    return 0;
}
```

但是我后面在想，为什么用 shared 呢，每个对象拥有的 component 应该是 unique 的，所以考虑 unique_ptr

unique_ptr 也类似，转类型的时候，不会析构对象

```cpp
#include <iostream>
#include <memory>

class Base {
public:
    virtual ~Base() {
        std::cout << "Base Destructor" << std::endl;
    }
};

class Derived : public Base {
public:
    ~Derived() {
        std::cout << "Derived Destructor" << std::endl;
    }
};

int main() {
    // 创建一个 unique_ptr<Derived>
    std::unique_ptr<Derived> derivedPtr = std::make_unique<Derived>();

    // 将 unique_ptr<Derived> 转换为 unique_ptr<Base>
    std::unique_ptr<Base> basePtr = std::move(derivedPtr);

    if (!derivedPtr) {
        std::cout << "derivedPtr is now null after move." << std::endl;
    }
    if (basePtr) {
        std::cout << "basePtr now owns the object." << std::endl;
    }

    return 0;
}
```

但是 unique_ptr 不能提供 weak_ptr，只有 shared_ptr 提供

我需要一个“既能独占所有权，但是又能有弱引用”的场景

本来我以为我需要用 unique_ptr 实现这个“独占所有权”，实际上只有一个地方有 shared_ptr 也是一样的效果

倒不如说，unique_ptr 分不出 weak 更显出他是 unique

weak 的所有权也是 shared 的含义的一部分

所以现在的 gameobject 仍然是 shared 地来存储 component 的