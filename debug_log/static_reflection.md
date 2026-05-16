# 静态反射

## 反射 debug

然后又发现了我的反射的问题

我的字段反射是

```cpp
        class FieldAccessor
        {
        public:
            FieldAccessor() = default;

            FieldAccessor(const FieldAccessor&)            = delete;
            FieldAccessor& operator=(const FieldAccessor&) = delete;
            FieldAccessor(FieldAccessor&&)                 = default;
            FieldAccessor& operator=(FieldAccessor&&)      = default;

            template<typename ClassType, typename FieldType>
            FieldAccessor(const std::string& name, const std::string& type_name, FieldType ClassType::*field_ptr)
                : m_name(name)
                , m_type_name(type_name)
            {
                m_ptr_getter = [field_ptr](std::any obj) -> void* {
                    return &(std::any_cast<ClassType*>(obj)->*field_ptr);
                };
                m_getter = [field_ptr](std::any obj) -> std::any { return std::any_cast<ClassType*>(obj)->*field_ptr; };
                m_setter = [field_ptr](std::any obj, std::any val) {
                    // Syntax: https://stackoverflow.com/a/670744/12003165
                    // `obj.*field`
                    auto* self       = std::any_cast<ClassType*>(obj);
                    self->*field_ptr = std::any_cast<FieldType>(val);
                };
            }

            const std::string& name() const { return m_name; }

            const std::string& type_name() const { return m_type_name; }

            template<typename ClassType>
            void* GetValuePtr(ClassType* ins_ptr) const
            {
                return m_ptr_getter(ins_ptr);
            }

            template<typename ClassType, typename FieldType>
            FieldType GetValue(ClassType* ins_ptr) const
            {
                return std::any_cast<FieldType>(m_getter(ins_ptr));
            }

            template<typename ClassType, typename FieldType>
            void SetValue(ClassType* ins_ptr, FieldType val)
```

结果在 `m_ptr_getter` 的 `std::any_cast<ClassType*>(obj)` 出了问题

之后才发现是因为我传入的是 `Component` 类型

```cpp
    void ImguiPass::CreateLeafNodeUI(const reflect::refl_shared_ptr<Component> comp_ptr)
    {
        if (!reflect::Registry::instance().HasType(comp_ptr.type_name))
            return;

        const reflect::TypeDescriptor& type_desc = reflect::Registry::instance().GetType(comp_ptr.type_name);
        const std::vector<reflect::FieldAccessor>& field_accessors = type_desc.GetFields();

        for (const reflect::FieldAccessor& field_accessor : field_accessors)
        {
            if (m_editor_ui_creator.find(field_accessor.type_name()) != m_editor_ui_creator.end())
            {
                m_editor_ui_creator[field_accessor.type_name()](field_accessor.name(),
                                                                field_accessor.GetValuePtr(comp_ptr.shared_ptr.get()));
            }
        }
    }
```

这个和 `FieldAccessor` 里面记录的 `ClassType` 是不一样的

所以果然，这里并不是使用 any 的场合

为了能够接受基类指针，并且能够转成子类指针，以便使用注册的时候传进来的子类成员指针

看了一下 Piccolo 是怎么做的

```cpp
static void set_convert(void* instance, void* field_value){ static_cast<AnimNodeMap*>(instance)->convert = *static_cast<std::vector<std::string>*>(field_value);}
static void* get_convert(void* instance){ return static_cast<void*>(&(static_cast<AnimNodeMap*>(instance)->convert));}
```

所以看上去，lambda 里面需要有一个 static cast

所以传进来的肯定是 void* 了

于是想改成

```cpp
        class FieldAccessor
        {
        public:
            FieldAccessor() = default;

            FieldAccessor(const FieldAccessor&)            = delete;
            FieldAccessor& operator=(const FieldAccessor&) = delete;
            FieldAccessor(FieldAccessor&&)                 = default;
            FieldAccessor& operator=(FieldAccessor&&)      = default;

            template<typename ClassType, typename FieldType>
            FieldAccessor(const std::string& name, const std::string& type_name, FieldType ClassType::*field_ptr)
                : m_name(name)
                , m_type_name(type_name)
            {
                m_ptr_getter = [field_ptr](void* obj) -> void* { return &(static_cast<ClassType*>(obj)->*field_ptr); };
                m_getter     = [field_ptr](void* obj) -> FieldType { return static_cast<ClassType*>(obj)->*field_ptr; };
                m_setter     = [field_ptr](void* obj, FieldType val) {
                    // Syntax: https://stackoverflow.com/a/670744/12003165
                    // `obj.*field`
                    auto* self       = static_cast<ClassType*>(obj);
                    self->*field_ptr = val;
                };
            }

            const std::string& name() const { return m_name; }

            const std::string& type_name() const { return m_type_name; }

            void* GetValuePtr(void* ins_ptr) const { return m_ptr_getter(ins_ptr); }

            template<typename FieldType>
            FieldType GetValue(void* ins_ptr) const
            {
                return std::any_cast<FieldType>(m_getter(ins_ptr));
            }

            template<typename FieldType>
            void SetValue(void* ins_ptr, FieldType val)
            {
                m_setter(ins_ptr, val);
            }
            
        private:
            std::string                          m_name;
            std::string                          m_type_name;
            std::function<void*(void*)>          m_ptr_getter {nullptr};
            std::function<std::any(void*)>       m_getter {nullptr};
            std::function<void(void*, std::any)> m_setter {nullptr};
        };
```

希望是输入是 void* 输出是注册时记录的字段类型

结果发现也不行

因为 `m_ptr_getter` `m_getter` `m_getter` 的声明应该拿不到模板类的，也不能用 any

所以还是只能像 Piccolo 那样，传出来的值也应该是 void* 一个地址来表示

## 静态反射

之前我的想法是

```cpp
namespace reflect
{
    class FieldAccessor
    {
    public:
        FieldAccessor() = default;

        const std::string& name() const { return m_name; }

        const std::string& type_name() const { return m_type_name; }

        const bool is_array() const { return m_is_array; }

        virtual void* get(void* ins_ptr, std::size_t idx = 0) const { return nullptr; };

        virtual void set(void* ins_ptr, void* val, std::size_t idx = 0) const {};

    protected:
        std::string m_name;
        std::string m_type_name;
        bool        m_is_array = false;
    };

    class FieldAccessorNonArray : public FieldAccessor
    {
    public:
        FieldAccessorNonArray() = default;

        template<typename ClassType, typename FieldType>
        FieldAccessorNonArray(const std::string& name,
                                const std::string& type_name,
                                FieldType ClassType::*field_ptr)
        {
            m_name      = name;
            m_type_name = type_name;
            m_is_array  = false;

            m_getter = [field_ptr](void* obj) -> void* {
                ClassType* self = static_cast<ClassType*>(obj);
                return &(self->*field_ptr);
            };

            m_setter = [field_ptr](void* obj, void* val) {
                ClassType* self  = static_cast<ClassType*>(obj);
                self->*field_ptr = *static_cast<FieldType*>(val);
            };
        }

        void* get(void* ins_ptr, std::size_t idx = 0) const override { return m_getter(ins_ptr); }

        void set(void* ins_ptr, void* val, std::size_t idx = 0) const override { m_setter(ins_ptr, val); }

    private:
        std::function<void*(void*)>       m_getter {nullptr};
        std::function<void(void*, void*)> m_setter {nullptr};
    };

    class FieldAccessorArray : public FieldAccessor
    {
    public:
        FieldAccessorArray() = default;

        template<typename ClassType, typename FieldType>
        FieldAccessorArray(const std::string& name, const std::string& type_name, FieldType ClassType::*field_ptr)
        {
            m_name      = name;
            m_type_name = type_name;
            m_is_array  = true;

            m_getter = [field_ptr](void* obj, std::size_t idx) -> void* {
                ClassType* self = static_cast<ClassType*>(obj);
                return &((self->*field_ptr)[idx]);
            };

            m_setter = [field_ptr](void* obj, void* val, std::size_t idx) {
                ClassType* self         = static_cast<ClassType*>(obj);
                (self->*field_ptr)[idx] = *static_cast<FieldType*>(val);
            };
        }

        void* get(void* ins_ptr, std::size_t idx = 0) const override { return m_getter(ins_ptr, idx); }

        void set(void* ins_ptr, void* val, std::size_t idx = 0) const override { m_setter(ins_ptr, val, idx); }

    private:
        std::function<void*(void*, std::size_t)>       m_getter {nullptr};
        std::function<void(void*, void*, std::size_t)> m_setter {nullptr};
    };
```

我始终是想 field 和 array 是融合在一起的

但是结果发现难度确实是有的，而且如果要用基类把他们统一的话，有些 array 特定的函数就要开放给基类，比如说定义在基类里面

比如 get_array_size 这种函数，你要是定义在基类里面的话，那么他的实现对于那些不是 array 的 field 就会很奇怪……
 
如果是你希望 get_array_size 定义在子类，需要用的时候就 cast 到子类

那么还不如直接定义两个类是分开的呢

改成

```cpp
class FieldAccessor
{
public:
    FieldAccessor() = default;

    template<typename ClassType, typename FieldType>
    FieldAccessor(const std::string& name, const std::string& type_name, FieldType ClassType::*field_ptr)
    {
        m_name      = name;
        m_type_name = type_name;

        m_getter = [field_ptr](void* obj) -> void* {
            ClassType* self = static_cast<ClassType*>(obj);
            return &(self->*field_ptr);
        };

        m_setter = [field_ptr](void* obj, void* val) {
            ClassType* self  = static_cast<ClassType*>(obj);
            self->*field_ptr = *static_cast<FieldType*>(val);
        };
    }

    const std::string& name() const { return m_name; }

    const std::string& type_name() const { return m_type_name; }

    void* get(void* ins_ptr) const { return m_getter(ins_ptr); }

    void set(void* ins_ptr, void* val) const { m_setter(ins_ptr, val); }

private:
    std::string m_name;
    std::string m_type_name;

    std::function<void*(void*)>       m_getter {nullptr};
    std::function<void(void*, void*)> m_setter {nullptr};
};

class ArrayAccessor
{
public:
    ArrayAccessor() = default;

    template<typename ClassType, typename FieldType>
    ArrayAccessor(const std::string& name,
                    const std::string& type_name,
                    const std::string& inner_type_name,
                    FieldType ClassType::*field_ptr)
    {
        m_name            = name;
        m_type_name       = type_name;
        m_inner_type_name = inner_type_name;

        m_getter = [field_ptr](void* obj, std::size_t idx) -> void* {
            ClassType* self = static_cast<ClassType*>(obj);
            return &((self->*field_ptr)[idx]);
        };

        m_setter = [field_ptr](void* obj, void* val, std::size_t idx) {
            ClassType* self         = static_cast<ClassType*>(obj);
            (self->*field_ptr)[idx] = *static_cast<FieldType*>(val);
        };

        m_array_size_getter = [field_ptr](void* obj) -> std::size_t {
            ClassType* self = static_cast<ClassType*>(obj);
            return self->size();
        };
    }

    const std::string& name() const { return m_name; }

    const std::string& type_name() const { return m_type_name; }

    const std::string& inner_type_name() const { return m_inner_type_name; }

    void* get(void* ins_ptr, std::size_t idx = 0) const { return m_getter(ins_ptr, idx); }

    void set(void* ins_ptr, void* val, std::size_t idx = 0) const { m_setter(ins_ptr, val, idx); }

private:
    std::string m_name;
    std::string m_type_name;
    std::string m_inner_type_name;

    std::function<void*(void*, std::size_t)>       m_getter {nullptr};
    std::function<void(void*, void*, std::size_t)> m_setter {nullptr};
    std::function<std::size_t(void*)>              m_array_size_getter {nullptr};
};
```

但是我之前只是担心这样会导致我的仓库会被修改

```cpp
class TypeDescriptor
{
public:
    TypeDescriptor() {}

    TypeDescriptor(const std::string& name)
        : m_name(name)
    {}

    TypeDescriptor(const TypeDescriptor&)            = delete;
    TypeDescriptor& operator=(const TypeDescriptor&) = delete;
    TypeDescriptor(TypeDescriptor&&)                 = default;
    TypeDescriptor& operator=(TypeDescriptor&&)      = default;

    const std::string& name() const { return m_name; }

    const std::vector<FieldAccessor>& GetFields() const { return m_fields; }

    const std::vector<MethodAccessor>& GetMethods() const { return m_methods; }

    void AddField(FieldAccessor&& field) { m_fields.emplace_back(std::move(field)); }

    void AddMethod(MethodAccessor&& method) { m_methods.emplace_back(std::move(method)); }

private:
    std::string                 m_name;
    std::vector<FieldAccessor>  m_fields;
    std::vector<MethodAccessor> m_methods;
};
```

现在是需要加入一个 array 存储

```cpp
class TypeDescriptor
{
public:
    TypeDescriptor() {}

    TypeDescriptor(const std::string& name)
        : m_name(name)
    {}

    TypeDescriptor(const TypeDescriptor&)            = delete;
    TypeDescriptor& operator=(const TypeDescriptor&) = delete;
    TypeDescriptor(TypeDescriptor&&)                 = default;
    TypeDescriptor& operator=(TypeDescriptor&&)      = default;

    const std::string& name() const { return m_name; }

    const std::vector<FieldAccessor>& GetFields() const { return m_fields; }

    const std::vector<MethodAccessor>& GetMethods() const { return m_methods; }

    void AddField(FieldAccessor&& field) { m_fields.emplace_back(std::move(field)); }

    void AddArray(ArrayAccessor&& array) { m_arrays.emplace_back(std::move(array)); }

    void AddMethod(MethodAccessor&& method) { m_methods.emplace_back(std::move(method)); }

private:
    std::string                 m_name;
    std::vector<FieldAccessor>  m_fields;
    std::vector<ArrayAccessor>  m_arrays;
    std::vector<MethodAccessor> m_methods;
};
```

builder 也需要改，原来的 builder 是

```cpp
template<typename FieldType>
TypeDescriptorBuilder&
AddFieldNonArray(const std::string& name, const std::string& type_name, FieldType ClassType::*field_ptr)
{
    m_type_descriptor.AddField(std::move(FieldAccessorNonArray(name, type_name, field_ptr)));
    return *this;
}

template<typename FieldType>
TypeDescriptorBuilder&
AddFieldArray(const std::string& name, const std::string& type_name, FieldType ClassType::*field_ptr)
{
    m_type_descriptor.AddField(std::move(FieldAccessorArray(name, type_name, field_ptr)));
    return *this;
}
```

改成

```cpp
template<typename FieldType>
TypeDescriptorBuilder&
AddField(const std::string& name, const std::string& type_name, FieldType ClassType::*field_ptr)
{
    m_type_descriptor.AddField({name, type_name, field_ptr});
    return *this;
}

template<typename ArrayType>
TypeDescriptorBuilder& AddFieldArray(const std::string& name,
                                        const std::string& type_name,
                                        const std::string& inner_type_name,
                                        ArrayType ClassType::*array_ptr)
{
    m_type_descriptor.AddArray({name, type_name, inner_type_name, array_ptr});
    return *this;
}
```

原来的生成代码

```cpp
bool                     is_first           = true;
static const std::string add_field_nonarray = ".AddFieldNonArray(\"";
static const std::string add_field_array    = ".AddFieldArray(\"";

for (const auto& class_result : class_results)
{
    // seperate each part
    if (!is_first)
        output_source_file << std::endl;

    is_first = false;

    output_source_file << "\t\t" << "reflect::AddClass<" << class_result.class_name << ">(\""
                        << class_result.class_name << "\")";

    for (const auto& field_result : class_result.field_results)
    {
        output_source_file << "\n\t\t\t" << (field_result.is_array ? add_field_array : add_field_nonarray)
                            << field_result.field_name << "\", \"" << field_result.field_type_name << "\", &"
                            << class_result.class_name << "::" << field_result.field_name << ")";
    }
```

然后这个 ArrayAccessor 我居然还是写错了

主要是因为 fieldtype 他不能当作 array 来用

于是改成

```cpp
class ArrayAccessor
{
public:
    ArrayAccessor() = default;

    template<typename ClassType, template<typename> class ArrayType, typename InnerType>
    ArrayAccessor(const std::string&   name,
                    const std::string&   type_name,
                    const std::string&   inner_type_name,
                    ArrayType<InnerType> ClassType::*array_ptr)
    {
        m_name            = name;
        m_type_name       = type_name;
        m_inner_type_name = inner_type_name;

        m_getter = [array_ptr](void* obj, std::size_t idx) -> void* {
            ClassType*           self = static_cast<ClassType*>(obj);
            ArrayType<InnerType> arr  = static_cast<ArrayType<InnerType>>(self->*array_ptr);
            return &(arr[idx]);
        };

        m_setter = [array_ptr](void* obj, void* val, std::size_t idx) {
            ClassType*           self = static_cast<ClassType*>(obj);
            ArrayType<InnerType> arr  = static_cast<ArrayType<InnerType>>(self->*array_ptr);
            arr[idx]                  = *static_cast<InnerType*>(val);
        };

        m_array_size_getter = [array_ptr](void* obj) -> std::size_t {
            ClassType*           self = static_cast<ClassType*>(obj);
            ArrayType<InnerType> arr  = static_cast<ArrayType<InnerType>>(self->*array_ptr);
            return arr.size();
        };
    }
```