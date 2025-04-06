# 构造函数

## 默认的移动构造的使用场合

```cpp
#include <array>
#include <iostream>
#include <vector>

class A
{
public:
    A(std::nullptr_t) {}
    A()
    {
        x = new int[3];
        for (int i = 0; i < 3; i++)
        {
            x[i] = 0;
        }
    }
    virtual ~A()
    {
        delete[] x;
        x = nullptr;
    }
    A(const A& a)            = delete;
    A& operator=(const A& a) = delete;
    A(A&& a)                 = default;
    A& operator=(A&& a)      = default;

    int* x = nullptr;
};

class B : public A
{
public:
    B(std::nullptr_t)
        : A(nullptr)
    {}
    B()
    {
        y = new int[3];
        for (int i = 0; i < 3; i++)
        {
            y[i] = 0;
        }
    }
    ~B()
    {
        delete[] y;
        y = nullptr;
    }
    B(const B& a)            = delete;
    B& operator=(const B& a) = delete;
    B(B&& a)                 = default;
    B& operator=(B&& a)      = default;

    int* y = nullptr;
};

int main()
{
    A a = nullptr;
    a = A();

    B b = nullptr;
    b = B();

    std::cout << (a.x == nullptr) << std::endl;
    std::cout << (b.x == nullptr) << std::endl;
    return 0;
}
```

这样写是错的，因为默认的移动对于值，是直接拷贝的，所以这里的指针会被拷贝，然后在旧的对象的销毁的时候，指针被释放内存，新的对象还存着这个指针，那么新的对象里面的这个指针就变成了野指针

但是默认的移动会移动那些具有移动语义的成员

```cpp
#include <array>
#include <iostream>
#include <vector>

class A
{
public:
    A(std::nullptr_t) {}
    A()
    {
        x = new int[3];
        for (int i = 0; i < 3; i++)
        {
            x[i] = 0;
        }
    }
    virtual ~A()
    {
        delete[] x;
        x = nullptr;
    }
    A(const A& a)            = delete;
    A& operator=(const A& a) = delete;
    A(A&& a)
    {
        if (this != &a)
        {
            swap(*this, a);
        }
    }
    A& operator=(A&& a)
    {
        if (this != &a)
        {
            swap(*this, a);
        }
        return *this;
    }

    friend void swap(A& a, A& b);
    int* x = nullptr;
};

void swap(A& a, A& b)
{
    std::swap(a.x, b.x);
}

class B
{
public:
    B(std::nullptr_t)
    {}
    B()
    {
        y = new int[3];
        for (int i = 0; i < 3; i++)
        {
            y[i] = 0;
        }

        a = A();
    }
    ~B()
    {
        delete[] y;
        y = nullptr;
    }
    B(const B& a)            = delete;
    B& operator=(const B& a) = delete;
    B(B&& a)                 = default;
    B& operator=(B&& a)      = default;

    int* y = nullptr;
    A a = nullptr;
};

int main()
{
    B b = nullptr;
    b = B();

    std::cout << (b.a.x == nullptr) << std::endl;
    return 0;
}
```

## 在 swap 中继承移动语义，而不是在移动构造中

因为我们一开始就选择了通过 swap 来完成所有的移动

```cpp
void swap(A& lhs, A& rhs)
{
    std::swap(lhs.x, rhs.x);
}

void swap(B& lhs, B& rhs)
{
    using std::swap;
    swap(static_cast<A&>(lhs), static_cast<A&>(rhs));
    std::swap(lhs.x, rhs.x);
}
```

所以当两个类有继承关系的时候，我们期望 swap 会包含这个继承关系

如果派生类的 swap 只关心派生类自己的行为，那么我们可以写

```cpp
B(B&& rhs) noexcept
    : A(std::move(rhs))
{
    swap(*this, rhs);
}

B& operator=(B&& rhs) noexcept
{
    if (this != &rhs)
    {
        A::operator=(std::move(rhs));

        swap(*this, rhs);
    }
    return *this;
}
```

但是这不是我期望的，这样使得外部对这个派生类的对象调用 swap 时，获得的结果与直接相反

外部对一个对象 swap，会发现这个对象并不是所有成员都 swap 了。也就是说这个 swap 仅仅是配合他自己的类型的移动构造/移动赋值的写法才有意义，其他地方都没有意义

如果 swap 里面继承了移动语义，就会符合直觉。那么这个移动构造/移动赋值的写法就会导致重复调用父类的移动语义，产生错误

and 如果想避免这个错误的话，那就让 swap 完成所有，并且提供一个不做任何事情的构造函数给移动构造，使得

```cpp
B(B&& rhs) noexcept
    : A(nullptr)
{
    swap(*this, rhs);
}

B& operator=(B&& rhs) noexcept
{
    if (this != &rhs)
    {
        swap(*this, rhs);
    }
    return *this;
}
```