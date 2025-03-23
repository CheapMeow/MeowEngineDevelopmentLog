# PBR

反射率方程

$$
L_o(p,\omega_o) = \int\limits_{\Omega} f_r(p,\omega_i,\omega_o) L_i(p,\omega_i) n \cdot \omega_i  d\omega_i
$$

L 表示辐射率

$$
L=\frac{d^2\Phi}{ dA d\omega \cos\theta}
$$

![](https://learnopengl-cn.github.io/img/07/01/radiance.png)

learnOpenGL 已经讲得很清晰了

[https://learnopengl-cn.github.io/07 PBR/01 Theory/](https://learnopengl-cn.github.io/07%20PBR/01%20Theory/)

> 如果我们把立体角 ω 和面积 A 看作是无穷小的，那么我们就能用辐射率来表示单束光线穿过空间中的一个点的通量。这就使我们可以计算得出作用于单个（片段）点上的单束光线的辐射率，我们实际上把立体角 ω 转变为方向向量 ω 然后把面 A 转换为点 p。这样我们就能直接在我们的着色器中使用辐射率来计算单束光线对每个片段的作用了。

最重要的就是这里，**外推到无穷小，立体角 ω 就对应光线（方向向量），面积 A 就对应着色点**

那么其实从定义到实践就打通了