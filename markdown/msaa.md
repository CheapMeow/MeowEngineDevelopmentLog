# MSAA

当渲染出来的颜色要作为 RT 传给别的 Shader 当作 Texture 的话，那么就 Resolve 到这个 RT

否则就 resolve 到 swapchain image

原理和我之前做 editor 都是一样的

为了 ImGui 用，所以，在有 Editor 的时候，颜色都是渲染到 RT，ImGui 再渲染到 SwapChain，在没有 Editor 的时候就渲染到 Swapchain

VulkanDemos 里面的 framebuffer 多了个 depth stencil 没有用到，而 Vulkan-Samples 考虑到要对比硬件 resolve 和单独的 Pass resolve，于是 framebuffer 也混杂了两种情况要用到的 attachments

实际上，最简单的情况应该是，msaa color, resolve color, msaa depth，没了