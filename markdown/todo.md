# TODO

是否可以在 subpass 间隔中，把一个 attachment 做 layout 转换

并且这个 attachment 不作为之后的 subpass 的 attachment，所以无法使用 `AttachmentReference` 在 `SubpassDescription` 中指定 subpass 对 attachment 的转换

比如现在的问题就是，我希望深度图被渲染了之后，直接转为 shader read 的格式，作为下一个 subpass 的 sampler

应该是可以 vkCmdPipelineBarrier