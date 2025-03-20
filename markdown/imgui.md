# ImGui

## 停靠在 dockspace

希望有一些窗口可以停靠在 dockspace 也可以自由地拉出来变成 viewport

于是发现所有的 imgui 绘制都在 dockspace 之后就好了

## Alpha 禁用

```cpp
    void ImGuiPass::RefreshOffscreenRenderTarget(VkSampler     offscreen_image_sampler,
                                                 VkImageView   offscreen_image_view,
                                                 VkImageLayout offscreen_image_layout)
    {
        m_offscreen_image_desc =
            ImGui_ImplVulkan_AddTexture(offscreen_image_sampler, offscreen_image_view, offscreen_image_layout);
    }
```

对于这里会导致一个问题，当传入的图像有不为 1 的透明度的时候，imgui 会和背景混合，使得呈现出来的图像变黑

对于 vulkan 怎么禁用 imgui 的混合？

参考这个

[How to disable alpha in ImGui::Image?](https://github.com/ocornut/imgui/issues/4730)

这个是调整窗口的透明度的

[ImGuiStyleVar_Alpha is unused](https://github.com/ocornut/imgui/issues/1198)

```cpp
ImGui::PushStyleVar(ImGuiStyleVar_Alpha, 1.0f);
ImGui::PopStyleVar();
```