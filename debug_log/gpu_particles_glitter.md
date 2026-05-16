在 RenderDoc 看到的相邻两帧的 GPUParticleData2D storage buffer

![Alt text](../assets/GPUParticleData2D_storage_buffer_0.png)

![Alt text](../assets/GPUParticleData2D_storage_buffer_1.png)

这个分布是完全不一样的

所以两帧显示的内容也会不一样

然后看绑定的 descriptor set

发现问题应该是因为绑定的 in 和 out 的 buffer 居然是相同的

![Alt text](../assets/GPUParticleData2D_descriptor_set_0.png)

![Alt text](../assets/GPUParticleData2D_descriptor_set_1.png)