# frames in flight

## Material 的变量声明

本来是想

```cpp
using UniformBufferMap = std::unordered_map<std::string, std::unique_ptr<UniformBuffer>>;
```

然后搞个 vector<UniformBufferMap>

结果发现 resize 调用会导致模板报错

自己测试了一下

```cpp
#include <iostream>
#include <memory>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

int main()
{
    // Ok
    std::vector<std::unique_ptr<int>> test1;
    test1.resize(2);
    std::cout << "std::is_copy_constructible_v<std::unique_ptr<int>> : " << std::is_copy_constructible_v<std::unique_ptr<int>> << "\n";
    std::cout << "std::is_copy_assignable_v<std::unique_ptr<int>> : " << std::is_copy_assignable_v<std::unique_ptr<int>> << "\n";
    std::cout << "std::is_move_constructible_v<std::unique_ptr<int>> : " << std::is_move_constructible_v<std::unique_ptr<int>> << "\n";
    std::cout << "std::is_move_assignable_v<std::unique_ptr<int>> : " << std::is_move_assignable_v<std::unique_ptr<int>> << "\n";
    
    // Ok
    std::vector<std::vector<std::unique_ptr<int>>> test2;
    test2.reserve(2);
    std::cout << "\n";
    std::cout << "std::is_copy_constructible_v<std::vector<std::unique_ptr<int>>> : " << std::is_copy_constructible_v<std::vector<std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_copy_assignable_v<std::vector<std::unique_ptr<int>>> : " << std::is_copy_assignable_v<std::vector<std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_move_constructible_v<std::vector<std::unique_ptr<int>>> : " << std::is_move_constructible_v<std::vector<std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_move_assignable_v<std::vector<std::unique_ptr<int>>> : " << std::is_move_assignable_v<std::vector<std::unique_ptr<int>>> << "\n";
    
    // Ok
    std::vector<std::pair<std::string, std::unique_ptr<int>>> test3;
    test3.resize(2);
    std::cout << "\n";
    std::cout << "std::is_copy_constructible_v<std::pair<std::string, std::unique_ptr<int>>> : " << std::is_copy_constructible_v<std::pair<std::string, std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_copy_assignable_v<std::pair<std::string, std::unique_ptr<int>>> : " << std::is_copy_assignable_v<std::pair<std::string, std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_move_constructible_v<std::pair<std::string, std::unique_ptr<int>>> : " << std::is_move_constructible_v<std::pair<std::string, std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_move_assignable_v<std::pair<std::string, std::unique_ptr<int>>> : " << std::is_move_assignable_v<std::pair<std::string, std::unique_ptr<int>>> << "\n";
    
    // Ok
    std::vector<std::pair<const std::string, std::unique_ptr<int>>> test4;
    test4.resize(2);
    std::cout << "\n";
    std::cout << "std::is_copy_constructible_v<std::pair<const std::string, std::unique_ptr<int>>> : " << std::is_copy_constructible_v<std::pair<const std::string, std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_copy_assignable_v<std::pair<const std::string, std::unique_ptr<int>>> : " << std::is_copy_assignable_v<std::pair<const std::string, std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_move_constructible_v<std::pair<const std::string, std::unique_ptr<int>>> : " << std::is_move_constructible_v<std::pair<const std::string, std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_move_assignable_v<std::pair<const std::string, std::unique_ptr<int>>> : " << std::is_move_assignable_v<std::pair<const std::string, std::unique_ptr<int>>> << "\n";
    
    // Error
    // Error C2280 : “std::pair<const std::string,std::unique_ptr<int,std::default_delete<int>>>::
    // pair(const std::pair<const std::string,std::unique_ptr<int,std::default_delete<int>>> &)”: is deleted
    //std::vector<std::unordered_map<std::string, std::unique_ptr<int>>> test5;
    //test5.resize(2);
    std::cout << "\n";
    std::cout << "std::is_copy_constructible_v<std::unordered_map<std::string, std::unique_ptr<int>>> : " << std::is_copy_constructible_v<std::unordered_map<std::string, std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_copy_assignable_v<std::unordered_map<std::string, std::unique_ptr<int>>> : " << std::is_copy_assignable_v<std::unordered_map<std::string, std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_move_constructible_v<std::unordered_map<std::string, std::unique_ptr<int>>> : " << std::is_move_constructible_v<std::unordered_map<std::string, std::unique_ptr<int>>> << "\n";
    std::cout << "std::is_move_assignable_v<std::unordered_map<std::string, std::unique_ptr<int>>> : " << std::is_move_assignable_v<std::unordered_map<std::string, std::unique_ptr<int>>> << "\n";
    
    return 0;
}
```

最后输出的 copyable movable 那些都是 1，居然还会模板报错？

问了大佬，说是

因为 vector::resize 要求元素类型 CopyInsertable

msvc 的 unordered_map 实现在 V 不能复制的时候不满足 CopyInsertable

并且标准允许这种实现

所以 vector 就不能 resize

这个是看 spec 看的，但是我……还不知道怎么看