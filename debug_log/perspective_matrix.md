# 透视矩阵

## 透视矩阵的问题

之前一直是，想要验证我对透视矩阵的推导，但是反映到渲染器都没有反应

原因是我有两个管线，forward 和 deferred

我有一个 bool 控制在这两个管线之间切换

然后我改透视矩阵的时候一直在 deferred 里面改，但是查看效果是查看的 forward 的效果

## 透视矩阵 debug

配置为

```cpp
glm::mat4 view = glm::mat4(1.0f);
view           = glm::mat4_cast(glm::conjugate(transfrom_comp_ptr->rotation)) * view;
view           = glm::translate(view, -transfrom_comp_ptr->position);

ubo_data.view             = view;
ubo_data.projection       = glm::perspectiveRH_NO(camera_comp_ptr->field_of_view,
                                            (float)window_size[0] / (float)window_size[1],
                                            camera_comp_ptr->near_plane,
                                            camera_comp_ptr->far_plane);
ubo_data.projection[1][1] = -1.0 * ubo_data.projection[1][1];
```

`vk::FrontFace::eCounterClockwise`

的时候，保持摄像机旋转角 0 0 0 不变，摄像机向后退，z 减小的时候，才能看到物体，向前进，z 变大的时候，看不到物体

改成

```cpp
glm::mat4 view = glm::mat4(1.0f);
view           = glm::mat4_cast(glm::conjugate(transfrom_comp_ptr->rotation)) * view;
view           = glm::translate(view, -transfrom_comp_ptr->position);

ubo_data.view             = view;
ubo_data.projection       = glm::perspectiveLH_NO(camera_comp_ptr->field_of_view,
                                            (float)window_size[0] / (float)window_size[1],
                                            camera_comp_ptr->near_plane,
                                            camera_comp_ptr->far_plane);
ubo_data.projection[1][1] = -1.0 * ubo_data.projection[1][1];
```

的时候，才是正常的

好吧，但是都应该用 ZO 但是似乎效果类似

然后试了一下我的 lookat

```cpp
glm::mat4 view = glm::mat4(1.0f);
view           = glm::mat4_cast(glm::conjugate(transfrom_comp_ptr->rotation)) * view;
view           = glm::translate(view, -transfrom_comp_ptr->position);

std::cout << "Custom lookAt" << std::endl;
std::cout << view[0][0] << ',' << view[0][1] << ',' << view[0][2] << ',' << view[0][3] << std::endl;
std::cout << view[1][0] << ',' << view[1][1] << ',' << view[1][2] << ',' << view[1][3] << std::endl;
std::cout << view[2][0] << ',' << view[2][1] << ',' << view[2][2] << ',' << view[2][3] << std::endl;
std::cout << view[3][0] << ',' << view[3][1] << ',' << view[3][2] << ',' << view[3][3] << std::endl;

view = glm::lookAt(transfrom_comp_ptr->position,
                    transfrom_comp_ptr->position + glm::vec3(0.0f, 0.0f, -10.0f),
                    glm::vec3(0.0f, 1.0f, 0.0f));

std::cout << "glm lookAt" << std::endl;
std::cout << view[0][0] << ',' << view[0][1] << ',' << view[0][2] << ',' << view[0][3] << std::endl;
std::cout << view[1][0] << ',' << view[1][1] << ',' << view[1][2] << ',' << view[1][3] << std::endl;
std::cout << view[2][0] << ',' << view[2][1] << ',' << view[2][2] << ',' << view[2][3] << std::endl;
std::cout << view[3][0] << ',' << view[3][1] << ',' << view[3][2] << ',' << view[3][3] << std::endl;
```

我还没看懂 glm 的 lookat

但是这么粗略的来看的话，我的 view 跟 glm 的 lookat 打印出来是一样的

那么我就完全不能理解为什么网上的人都说从 opengl 转换到 vulkan 需要 glm::perspective 加上 projection[1][1] *= -1

也就是 perspectiveRH_ZO 加上 projection[1][1] *= -1 而不是 perspectiveLH_ZO？

明明我自己是必须要 perspectiveLH_ZO 加上 projection[1][1] *= -1 才行的

好吧，之后看了 lookat，我之前是那个 s u f 与 eye 相乘看不懂

现在看懂了

然后我还发现我的 lookat 测试有问题

```cpp
glm::mat4 view = glm::mat4(1.0f);
view           = glm::mat4_cast(glm::conjugate(transfrom_comp_ptr->rotation)) * view;
view           = glm::translate(view, -transfrom_comp_ptr->position);

std::cout << "Custom lookAt" << std::endl;
std::cout << view[0][0] << ',' << view[0][1] << ',' << view[0][2] << ',' << view[0][3] << std::endl;
std::cout << view[1][0] << ',' << view[1][1] << ',' << view[1][2] << ',' << view[1][3] << std::endl;
std::cout << view[2][0] << ',' << view[2][1] << ',' << view[2][2] << ',' << view[2][3] << std::endl;
std::cout << view[3][0] << ',' << view[3][1] << ',' << view[3][2] << ',' << view[3][3] << std::endl;

view = glm::lookAt(transfrom_comp_ptr->position,
                    transfrom_comp_ptr->position + glm::vec3(0.0f, 0.0f, 10.0f),
                    glm::vec3(0.0f, 1.0f, 0.0f));

std::cout << "glm lookAt" << std::endl;
std::cout << view[0][0] << ',' << view[0][1] << ',' << view[0][2] << ',' << view[0][3] << std::endl;
std::cout << view[1][0] << ',' << view[1][1] << ',' << view[1][2] << ',' << view[1][3] << std::endl;
std::cout << view[2][0] << ',' << view[2][1] << ',' << view[2][2] << ',' << view[2][3] << std::endl;
std::cout << view[3][0] << ',' << view[3][1] << ',' << view[3][2] << ',' << view[3][3] << std::endl;
```

输出的不一样

于是仔细看我的 view……我的 view 似乎写错了……

于是改回

```cpp
glm::mat4 view = glm::mat4(1.0f);
view           = glm::translate(view, -transfrom_comp_ptr->position);
view           = glm::mat4_cast(glm::conjugate(transfrom_comp_ptr->rotation)) * view;
```

还是不一样

所以回头来看的话，从旋转矩阵和平移矩阵构建的 lookat，和直接调用 glm 的 lookat，要想相同，条件就是 lookat 要朝着 -z 看

```
Custom lookAt
1,0,0,0
0,1,0,0
0,0,1,0
0,0,25,1
glm lookAt
1,0,-0,0
-0,1,-0,0
0,0,1,0
-0,-0,25,1
```

如果是 +z

```
Custom lookAt
1,0,0,0
0,1,0,0
0,0,1,0
0,0,25,1
glm lookAt
-1,0,-0,0
0,1,-0,0
0,-0,-1,0
-0,-0,-25,1
```

这两种 glm lookAt 给出的结果都是有效的 view 矩阵

两种都有效，但是 `lookAtRH` 得到的 view 矩阵是右手系，`lookAtLH` 得到的 view 矩阵是左手系

于是去搜为什么要朝着 -z 看

于是搜到

[https://www.songho.ca/opengl/gl_projectionmatrix.html](https://www.songho.ca/opengl/gl_projectionmatrix.html)

我不止一次看到别人推荐这个网站，然后引用这句话

> Note that the eye coordinates are defined in the right-handed coordinate system, but NDC uses the left-handed coordinate system. That is, the camera at the origin is looking along -Z axis in eye space, but it is looking along +Z axis in NDC.

于是我再仔细看，灵光一闪

他的意思似乎是，因为 NDC 是左手系，view 空间（eye 空间）是右手系，所以 x 和 y 轴不变的话，就可以认为两者的 z 轴是反的。那么假设视锥体都在一个固定的 NDC 正 z 的地方，那么我在 NDC 中需要看向这个视锥体，所以我在 view 空间中才需要让我的摄像机看向 -z 方向而不是 +z

所以他这段话就解答了为什么摄像机 lookat 是看向摄像机的 -z 方向

然后再仔细看 glm 的 `lookAtRH` 里面，构建了一个 eye 空间中的 u s (-f) 坐标系，分别对应 x y z

这个 f 就是 eye 到 center 的方向，也就是所谓的摄像机看向的 +z 方向(好吧或者说是 front 方向)

`lookAtRH` 用 u s (-f) 坐标系 才能保证得到的结果是右手系，也就导致摄像机现在虽然是看向物体了，但是摄像机的 -front 方向指向物体

所以 `lookAtRH` 的内容就说明了，他构造出来的矩阵确实是保证了“摄像机看向 -z”

## view 矩阵

奇怪的是，只有看向当前的 -front 方向，才跟我自己做的 view 是相同的

```cpp
glm::mat4 view = glm::mat4(1.0f);
view           = glm::translate(view, -transfrom_comp_ptr->position);
view           = glm::mat4_cast(glm::conjugate(transfrom_comp_ptr->rotation)) * view;

std::cout << "Custom lookAt" << std::endl;
std::cout << view[0][0] << ',' << view[0][1] << ',' << view[0][2] << ',' << view[0][3] << std::endl;
std::cout << view[1][0] << ',' << view[1][1] << ',' << view[1][2] << ',' << view[1][3] << std::endl;
std::cout << view[2][0] << ',' << view[2][1] << ',' << view[2][2] << ',' << view[2][3] << std::endl;
std::cout << view[3][0] << ',' << view[3][1] << ',' << view[3][2] << ',' << view[3][3] << std::endl;

view = glm::lookAt(transfrom_comp_ptr->position,
                    transfrom_comp_ptr->position + glm::vec3(0.0f, 0.0f, -10.0f),
                    glm::vec3(0.0f, 1.0f, 0.0f));

std::cout << "glm lookAt" << std::endl;
std::cout << view[0][0] << ',' << view[0][1] << ',' << view[0][2] << ',' << view[0][3] << std::endl;
std::cout << view[1][0] << ',' << view[1][1] << ',' << view[1][2] << ',' << view[1][3] << std::endl;
std::cout << view[2][0] << ',' << view[2][1] << ',' << view[2][2] << ',' << view[2][3] << std::endl;
std::cout << view[3][0] << ',' << view[3][1] << ',' << view[3][2] << ',' << view[3][3] << std::endl;
```

OpenGL 中的构建 view 矩阵的堆栈（来自 [https://learnopengl.com/](https://learnopengl.com/)）

```cpp
glm::mat4 view = camera.GetViewMatrix();
```

```cpp
glm::mat4 GetViewMatrix()
{
    return glm::lookAt(Position, Position + Front, Up);
}
```

```cpp
void updateCameraVectors()
{
    // calculate the new Front vector
    glm::vec3 front;
    front.x = cos(glm::radians(Yaw)) * cos(glm::radians(Pitch));
    front.y = sin(glm::radians(Pitch));
    front.z = sin(glm::radians(Yaw)) * cos(glm::radians(Pitch));
    Front = glm::normalize(front);
    // also re-calculate the Right and Up vector
    Right = glm::normalize(glm::cross(Front, WorldUp));  // normalize the vectors, because their length gets closer to 0 the more you look up or down which results in slower movement.
    Up    = glm::normalize(glm::cross(Right, Front));
}
```

别人都是直接传入 front 向量

## 用于 Vulkan 的透视矩阵

视图矩阵是右手系，正交长方体的左平面的坐标为 l，右平面的坐标为 r，上平面的坐标为 t，下平面的坐标为 b，近平面的坐标为 -n，远平面的坐标为 -f。转换之后 NDC 坐标还是右手系。

n, f 为正

但是这里有一个地方可以额外说的，对比 OpenGL 的公式，Vulkan 是 z 轴和 y 轴都反转了，所以反而 Vulkan 转换到 NDC 时没有改变手性

写正交投影矩阵时注意两个轴都反转了，并且 [-n, -f] 映射到 [0, 1]

$$
M_{ortho}=\left(\begin{array}{cccc}
\frac{2}{r-l} & 0 & 0 & 0\\
0 & \frac{2}{b-t} & 0 & 0\\
0 & 0 & \frac{1}{n-f} & 0\\
0 & 0 & 0 & 1
\end{array}\right)\left(\begin{array}{cccc}
1 & 0 & 0 & -\frac{r+l}{2}\\
0 & 1 & 0 & -\frac{t+b}{2}\\
0 & 0 & 1 & n\\
0 & 0 & 0 & 1
\end{array}\right)
$$

沿用之前推 OpenGL 推出来的压缩矩阵

$$M_{persp2ortho} = \left(\begin{array}{cccc}
n & 0 & 0 & 0\\
0 & n & 0 & 0\\
0 & 0 & f+n & f\,n\\
0 & 0 & -1 & 0
\end{array}\right)$$

得到的结果与 `perspectiveLH_ZO` 完全不同

```matlab
syms zNear zFar width height fovy aspect;  

% world space is right hand
% zNear > 0, zFar > 0
n = zNear;  
f = zFar;  

tanHalfFovy = tan(fovy/2);  
height = 2 * n * tanHalfFovy;
width = aspect * height;  
  
r = width/2;  
l = -width/2;
t = height/2;  
b = -height/2;  
  
Mortho = [2/(r-l) 0 0 0; 0 2/(b-t) 0 0; 0 0 1/(n-f) 0; 0 0 0 1] * [1 0 0 -(r+l)/2; 0 1 0 -(t+b)/2; 0 0 1 n; 0 0 0 1];
Mortho = simplify(Mortho);
Mpersp2ortho = [n 0 0 0; 0 n 0 0; 0 0 (n+f) n*f; 0 0 -1 0];
Mproj = Mortho * Mpersp2ortho;
Mproj = simplify(Mproj)
```

$M_{proj} = \left(\begin{array}{cccc}
\frac{1}{\mathrm{aspect}\,\tan \left(\frac{\mathrm{fovy}}{2}\right)} & 0 & 0 & 0\\
0 & -\frac{1}{\tan \left(\frac{\mathrm{fovy}}{2}\right)} & 0 & 0\\
0 & 0 & -\frac{\mathrm{zFar}}{\mathrm{zFar}-\mathrm{zNear}} & -\frac{\mathrm{zFar}\,\mathrm{zNear}}{\mathrm{zFar}-\mathrm{zNear}}\\
0 & 0 & -1 & 0
\end{array}\right)$

于是我在想为什么……可能是我完全不需要反转轴

于是我试了一下， [b, t] 映射到 [-1, 1], [n, f] 映射到 [0, 1]

$$
M_{ortho}=\left(\begin{array}{cccc}
\frac{2}{r-l} & 0 & 0 & 0\\
0 & \frac{2}{t-b} & 0 & 0\\
0 & 0 & \frac{1}{f-n} & 0\\
0 & 0 & 0 & 1
\end{array}\right)\left(\begin{array}{cccc}
1 & 0 & 0 & -\frac{r+l}{2}\\
0 & 1 & 0 & -\frac{t+b}{2}\\
0 & 0 & 1 & -n\\
0 & 0 & 0 & 1
\end{array}\right)
$$

n, f 的近平面坐标的压缩矩阵

$$M_{persp2ortho} = \left(\begin{array}{cccc}
n & 0 & 0 & 0\\
0 & n & 0 & 0\\
0 & 0 & f+n & -f\,n\\
0 & 0 & 1 & 0
\end{array}\right)$$

```matlab
syms zNear zFar width height fovy aspect;  

% world space is right hand
% zNear > 0, zFar > 0
n = zNear;  
f = zFar;  

tanHalfFovy = tan(fovy/2);  
height = 2 * n * tanHalfFovy;
width = aspect * height;  
  
r = width/2;  
l = -width/2;
t = height/2;  
b = -height/2;  
  
Mortho = [2/(r-l) 0 0 0; 0 2/(t-b) 0 0; 0 0 1/(f-n) 0; 0 0 0 1] * [1 0 0 -(r+l)/2; 0 1 0 -(t+b)/2; 0 0 1 -n; 0 0 0 1];
Mortho = simplify(Mortho);
Mpersp2ortho = [n 0 0 0; 0 n 0 0; 0 0 n+f -n*f; 0 0 1 0];
Mproj = Mortho * Mpersp2ortho;
Mproj = simplify(Mproj)

```

算出来确实是跟 `perspectiveLH_ZO` 一样了

$M_{proj} = \left(\begin{array}{cccc}
\frac{1}{\mathrm{aspect}\,\tan \left(\frac{\mathrm{fovy}}{2}\right)} & 0 & 0 & 0\\
0 & \frac{1}{\tan \left(\frac{\mathrm{fovy}}{2}\right)} & 0 & 0\\
0 & 0 & \frac{\mathrm{zFar}}{\mathrm{zFar}-\mathrm{zNear}} & -\frac{\mathrm{zFar}\,\mathrm{zNear}}{\mathrm{zFar}-\mathrm{zNear}}\\
0 & 0 & 1 & 0
\end{array}\right)$

但是问题是这样没有用啊

虽然我推出来了另外一个公式，但是这会使我更混乱

于是我才回过头来看 lookAt，确认了摄像机就是看向 -z 的

不过再仔细想，可能是我的问题

现在的问题是，我似乎不应该用 `perspectiveLH_ZO`，但是之前的经验一直都告诉我要用 `perspectiveLH_ZO` 才可以

但是这是这是因为我之前的 view 矩阵是我自己写的，一个跟 lookat 之后摄像机指向 -z 不一样的

于是我现在

```cpp
glm::mat4 view = glm::lookAt(transfrom_comp_ptr->position,
                                transfrom_comp_ptr->position + glm::vec3(0.0f, 0.0f, 1.0f),
                                glm::vec3(0.0f, 1.0f, 0.0f));

ubo_data.view             = view;
ubo_data.projection       = glm::perspectiveRH_ZO(camera_comp_ptr->field_of_view,
                                            (float)window_size[0] / (float)window_size[1],
                                            camera_comp_ptr->near_plane,
                                            camera_comp_ptr->far_plane);
ubo_data.projection[1][1] = -1.0 * ubo_data.projection[1][1];
```

得到的 x 是相反的，其他完全正常，并且不需要反转 frontface

于是再看

```cpp
	template<typename T>
	GLM_FUNC_QUALIFIER mat<4, 4, T, defaultp> perspectiveRH_ZO(T fovy, T aspect, T zNear, T zFar)
	{
		assert(abs(aspect - std::numeric_limits<T>::epsilon()) > static_cast<T>(0));

		T const tanHalfFovy = tan(fovy / static_cast<T>(2));

		mat<4, 4, T, defaultp> Result(static_cast<T>(0));
		Result[0][0] = static_cast<T>(1) / (aspect * tanHalfFovy);
		Result[1][1] = static_cast<T>(1) / (tanHalfFovy);
		Result[2][2] = zFar / (zNear - zFar);
		Result[2][3] = - static_cast<T>(1);
		Result[3][2] = -(zFar * zNear) / (zFar - zNear);
		return Result;
	}
```

与我推出来的 vulkan 公式

$M_{proj} = \left(\begin{array}{cccc}
\frac{1}{\mathrm{aspect}\,\tan \left(\frac{\mathrm{fovy}}{2}\right)} & 0 & 0 & 0\\
0 & -\frac{1}{\tan \left(\frac{\mathrm{fovy}}{2}\right)} & 0 & 0\\
0 & 0 & -\frac{\mathrm{zFar}}{\mathrm{zFar}-\mathrm{zNear}} & -\frac{\mathrm{zFar}\,\mathrm{zNear}}{\mathrm{zFar}-\mathrm{zNear}}\\
0 & 0 & -1 & 0
\end{array}\right)$

嘿！还真的是仅仅差在 [1][1] 上面！

但是为什么我现在 x 会相反呢