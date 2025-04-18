## 视锥体 debug

```cpp
    // Calculates frustum planes in world space
    void Frustum::updatePlanes(const glm::vec3 cameraPos,
                               const glm::quat rotation,
                               float           fovy,
                               float           AR,
                               float           near,
                               float           far)
    {
        float tanHalfFOVy = tan((fovy / 2.0f) * (M_PI / 180.0f));
        float near_height = near * tanHalfFOVy; // Half of the frustum near plane height
        float near_width  = near_height * AR;

        glm::vec3 right   = rotation * glm::vec3(1.0f, 0.0f, 0.0f);
        glm::vec3 forward = rotation * glm::vec3(0.0f, 0.0f, 1.0f);
        glm::vec3 up      = glm::vec3(0.0f, 1.0f, 0.0f);

        // Gets worlds space position of the center points of the near and far planes
        // The forward vector Z points towards the viewer so you need to negate it and scale it
        // by the distance (near or far) to the plane to get the center positions
        glm::vec3 nearCenter = cameraPos + forward * near;
        glm::vec3 farCenter  = cameraPos + forward * far;

        glm::vec3 point;
        glm::vec3 normal;

        // We build the planes using a normal and a point (in this case the center)
        // Z is negative here because we want the normal vectors we choose to point towards
        // the inside of the view frustum that way we can cehck in or out with a simple
        // Dot product
        pl[NEARP].setNormalAndPoint(forward, nearCenter);

        std::cout << "updatePlanes" << std::endl << std::endl;
        std::cout << std::format("forward = ({}, {}, {})", forward.x, forward.y, forward.z) << std::endl;
        std::cout << std::format("center = ({}, {}, {})", nearCenter.x, nearCenter.y, nearCenter.z) << std::endl;

        // Far plane
        pl[FARP].setNormalAndPoint(-forward, farCenter);

        std::cout << std::format("forward = ({}, {}, {})", -forward.x, -forward.y, -forward.z) << std::endl;
        std::cout << std::format("center = ({}, {}, {})", farCenter.x, farCenter.y, farCenter.z) << std::endl;

        // Again, want to get the plane from a normal and point
        // You scale the up vector by the near plane height and added to the nearcenter to
        // optain a point on the edge of both near and top plane.
        // Subtracting the cameraposition from this point generates a vector that goes along the
        // surface of the plane, if you take the cross product with the direction vector equal
        // to the shared edge of the planes you get the normal
        point  = nearCenter + up * near_height;
        normal = glm::normalize(point - cameraPos);
        normal = glm::cross(normal, right);
        pl[TOP].setNormalAndPoint(normal, point);

        std::cout << std::format("forward = ({}, {}, {})", normal.x, normal.y, normal.z) << std::endl;
        std::cout << std::format("center = ({}, {}, {})", point.x, point.y, point.z) << std::endl;

        // Bottom plane
        point  = nearCenter - up * near_height;
        normal = glm::normalize(point - cameraPos);
        normal = glm::cross(right, normal);
        pl[BOTTOM].setNormalAndPoint(normal, point);

        std::cout << std::format("forward = ({}, {}, {})", normal.x, normal.y, normal.z) << std::endl;
        std::cout << std::format("center = ({}, {}, {})", point.x, point.y, point.z) << std::endl;

        // Left plane
        point  = nearCenter - right * near_width;
        normal = glm::normalize(point - cameraPos);
        normal = glm::cross(normal, up);
        pl[LEFT].setNormalAndPoint(normal, point);

        std::cout << std::format("forward = ({}, {}, {})", normal.x, normal.y, normal.z) << std::endl;
        std::cout << std::format("center = ({}, {}, {})", point.x, point.y, point.z) << std::endl;

        // Right plane
        point  = nearCenter + right * near_width;
        normal = glm::normalize(point - cameraPos);
        normal = glm::cross(up, normal);
        pl[RIGHT].setNormalAndPoint(normal, point);

        std::cout << std::format("forward = ({}, {}, {})", normal.x, normal.y, normal.z) << std::endl;
        std::cout << std::format("center = ({}, {}, {})", point.x, point.y, point.z) << std::endl;
    }
```

输出

```
updatePlanes

forward = (0, 0, 1)
center = (0, 0, -9.9)
forward = (-0, -0, -1)
center = (0, 0, 990)
forward = (0, 0.9999765, -0.006853813)
center = (0, 0.0006854, -9.9)
forward = (0, -0.9999765, -0.006853813)
center = (0, -0.0006854, -9.9)
forward = (-0.9999472, 0, -0.010280418)
center = (-0.0010281, 0, -9.9)
forward = (0.9999472, 0, -0.010280418)
center = (0.0010281, 0, -9.9)
```

相机位置在 (0,0,-10)，旋转为 0

于是发现 near 和 far 都是相近的，但是 top 那些似乎不对

给出一个更全面的信息

```cpp
    // Calculates frustum planes in world space
    void Frustum::updatePlanes(const glm::vec3 cameraPos,
                               const glm::quat rotation,
                               float           fovy,
                               float           AR,
                               float           near,
                               float           far)
    {
        float tanHalfFOVy = tan((fovy / 2.0f) * (M_PI / 180.0f));
        float near_height = near * tanHalfFOVy; // Half of the frustum near plane height
        float near_width  = near_height * AR;

        std::cout << "updatePlanes" << std::endl << std::endl;

        glm::vec3 right   = rotation * glm::vec3(1.0f, 0.0f, 0.0f);
        glm::vec3 forward = rotation * glm::vec3(0.0f, 0.0f, 1.0f);
        glm::vec3 up      = glm::vec3(0.0f, 1.0f, 0.0f);

        std::cout << std::format("tanHalfFOVy = {}", tanHalfFOVy) << std::endl;
        std::cout << std::format("near_height = {}", near_height) << std::endl;
        std::cout << std::format("near_width = {}", near_width) << std::endl;

        std::cout << std::format("right = ({}, {}, {})", right.x, right.y, right.z) << std::endl;
        std::cout << std::format("forward = ({}, {}, {})", forward.x, forward.y, forward.z) << std::endl;
        std::cout << std::format("up = ({}, {}, {})", up.x, up.y, up.z) << std::endl;

        // Gets worlds space position of the center points of the near and far planes
        // The forward vector Z points towards the viewer so you need to negate it and scale it
        // by the distance (near or far) to the plane to get the center positions
        glm::vec3 nearCenter = cameraPos + forward * near;
        glm::vec3 farCenter  = cameraPos + forward * far;

        glm::vec3 point;
        glm::vec3 normal;

        // We build the planes using a normal and a point (in this case the center)
        // Z is negative here because we want the normal vectors we choose to point towards
        // the inside of the view frustum that way we can cehck in or out with a simple
        // Dot product
        pl[NEARP].setNormalAndPoint(forward, nearCenter);

        std::cout << "NEARP" << std::endl;
        std::cout << std::format("normal = ({}, {}, {})", forward.x, forward.y, forward.z) << std::endl;
        std::cout << std::format("center = ({}, {}, {})", nearCenter.x, nearCenter.y, nearCenter.z) << std::endl;

        // Far plane
        pl[FARP].setNormalAndPoint(-forward, farCenter);

        std::cout << "FARP" << std::endl;
        std::cout << std::format("normal = ({}, {}, {})", -forward.x, -forward.y, -forward.z) << std::endl;
        std::cout << std::format("center = ({}, {}, {})", farCenter.x, farCenter.y, farCenter.z) << std::endl;

        // Again, want to get the plane from a normal and point
        // You scale the up vector by the near plane height and added to the nearcenter to
        // optain a point on the edge of both near and top plane.
        // Subtracting the cameraposition from this point generates a vector that goes along the
        // surface of the plane, if you take the cross product with the direction vector equal
        // to the shared edge of the planes you get the normal
        point  = nearCenter + up * near_height;
        normal = glm::normalize(point - cameraPos);
        normal = glm::cross(normal, right);
        pl[TOP].setNormalAndPoint(normal, point);

        std::cout << "TOP" << std::endl;
        std::cout << std::format("glm::normalize(point - cameraPos) = ({}, {}, {})",
                                 glm::normalize(point - cameraPos).x,
                                 glm::normalize(point - cameraPos).y,
                                 glm::normalize(point - cameraPos).z)
                  << std::endl;
        std::cout << std::format("normal = ({}, {}, {})", normal.x, normal.y, normal.z) << std::endl;
        std::cout << std::format("center = ({}, {}, {})", point.x, point.y, point.z) << std::endl;

        // Bottom plane
        point  = nearCenter - up * near_height;
        normal = glm::normalize(point - cameraPos);
        normal = glm::cross(right, normal);
        pl[BOTTOM].setNormalAndPoint(normal, point);

        std::cout << "BOTTOM" << std::endl;
        std::cout << std::format("glm::normalize(point - cameraPos) = ({}, {}, {})",
                                 glm::normalize(point - cameraPos).x,
                                 glm::normalize(point - cameraPos).y,
                                 glm::normalize(point - cameraPos).z)
                  << std::endl;
        std::cout << std::format("normal = ({}, {}, {})", normal.x, normal.y, normal.z) << std::endl;
        std::cout << std::format("center = ({}, {}, {})", point.x, point.y, point.z) << std::endl;

        // Left plane
        point  = nearCenter - right * near_width;
        normal = glm::normalize(point - cameraPos);
        normal = glm::cross(normal, up);
        pl[LEFT].setNormalAndPoint(normal, point);

        std::cout << "LEFT" << std::endl;
        std::cout << std::format("glm::normalize(point - cameraPos) = ({}, {}, {})",
                                 glm::normalize(point - cameraPos).x,
                                 glm::normalize(point - cameraPos).y,
                                 glm::normalize(point - cameraPos).z)
                  << std::endl;
        std::cout << std::format("normal = ({}, {}, {})", normal.x, normal.y, normal.z) << std::endl;
        std::cout << std::format("center = ({}, {}, {})", point.x, point.y, point.z) << std::endl;

        // Right plane
        point  = nearCenter + right * near_width;
        normal = glm::normalize(point - cameraPos);
        normal = glm::cross(up, normal);
        pl[RIGHT].setNormalAndPoint(normal, point);

        std::cout << "RIGHT" << std::endl;
        std::cout << std::format("glm::normalize(point - cameraPos) = ({}, {}, {})",
                                 glm::normalize(point - cameraPos).x,
                                 glm::normalize(point - cameraPos).y,
                                 glm::normalize(point - cameraPos).z)
                  << std::endl;
        std::cout << std::format("normal = ({}, {}, {})", normal.x, normal.y, normal.z) << std::endl;
        std::cout << std::format("center = ({}, {}, {})", point.x, point.y, point.z) << std::endl;
    }
```

输出

```
updatePlanes

tanHalfFOVy = 0.0068539996
near_height = 0.0006854
near_width = 0.0010281
right = (1, 0, 0)
forward = (0, 0, 1)
up = (0, 1, 0)
NEARP
normal = (0, 0, 1)
center = (0, 0, -9.9)
FARP
normal = (-0, -0, -1)
center = (0, 0, 990)
TOP
glm::normalize(point - cameraPos) = (0, 0.006853813, 0.9999765)
normal = (0, 0.9999765, -0.006853813)
center = (0, 0.0006854, -9.9)
BOTTOM
glm::normalize(point - cameraPos) = (0, -0.006853813, 0.9999765)
normal = (0, -0.9999765, -0.006853813)
center = (0, -0.0006854, -9.9)
LEFT
glm::normalize(point - cameraPos) = (-0.010280418, 0, 0.9999472)
normal = (-0.9999472, 0, -0.010280418)
center = (-0.0010281, 0, -9.9)
RIGHT
glm::normalize(point - cameraPos) = (0.010280418, 0, 0.9999472)
normal = (0.9999472, 0, -0.010280418)
center = (0.0010281, 0, -9.9)
```

于是发现之后的所有都反了

改过来之后

```cpp
    // Calculates frustum planes in world space
    void Frustum::updatePlanes(const glm::vec3 cameraPos,
                               const glm::quat rotation,
                               float           fovy,
                               float           AR,
                               float           near,
                               float           far)
    {
        float tanHalfFOVy = tan((fovy / 2.0f) * (M_PI / 180.0f));
        float near_height = near * tanHalfFOVy; // Half of the frustum near plane height
        float near_width  = near_height * AR;

        std::cout << "updatePlanes" << std::endl << std::endl;

        glm::vec3 right   = rotation * glm::vec3(1.0f, 0.0f, 0.0f);
        glm::vec3 forward = rotation * glm::vec3(0.0f, 0.0f, 1.0f);
        glm::vec3 up      = glm::vec3(0.0f, 1.0f, 0.0f);

        std::cout << std::format("tanHalfFOVy = {}", tanHalfFOVy) << std::endl;
        std::cout << std::format("near_height = {}", near_height) << std::endl;
        std::cout << std::format("near_width = {}", near_width) << std::endl;

        std::cout << std::format("right = ({}, {}, {})", right.x, right.y, right.z) << std::endl;
        std::cout << std::format("forward = ({}, {}, {})", forward.x, forward.y, forward.z) << std::endl;
        std::cout << std::format("up = ({}, {}, {})", up.x, up.y, up.z) << std::endl;

        // Gets worlds space position of the center points of the near and far planes
        // The forward vector Z points towards the viewer so you need to negate it and scale it
        // by the distance (near or far) to the plane to get the center positions
        glm::vec3 nearCenter = cameraPos + forward * near;
        glm::vec3 farCenter  = cameraPos + forward * far;

        glm::vec3 point;
        glm::vec3 normal;

        // We build the planes using a normal and a point (in this case the center)
        // Z is negative here because we want the normal vectors we choose to point towards
        // the inside of the view frustum that way we can cehck in or out with a simple
        // Dot product
        pl[NEARP].setNormalAndPoint(forward, nearCenter);

        std::cout << "NEARP" << std::endl;
        std::cout << std::format("normal = ({}, {}, {})", forward.x, forward.y, forward.z) << std::endl;
        std::cout << std::format("center = ({}, {}, {})", nearCenter.x, nearCenter.y, nearCenter.z) << std::endl;

        // Far plane
        pl[FARP].setNormalAndPoint(-forward, farCenter);

        std::cout << "FARP" << std::endl;
        std::cout << std::format("normal = ({}, {}, {})", -forward.x, -forward.y, -forward.z) << std::endl;
        std::cout << std::format("center = ({}, {}, {})", farCenter.x, farCenter.y, farCenter.z) << std::endl;

        // Again, want to get the plane from a normal and point
        // You scale the up vector by the near plane height and added to the nearcenter to
        // optain a point on the edge of both near and top plane.
        // Subtracting the cameraposition from this point generates a vector that goes along the
        // surface of the plane, if you take the cross product with the direction vector equal
        // to the shared edge of the planes you get the normal
        point  = nearCenter + up * near_height;
        normal = glm::normalize(point - cameraPos);
        normal = glm::cross(right, normal);
        pl[TOP].setNormalAndPoint(normal, point);

        std::cout << "TOP" << std::endl;
        std::cout << std::format("glm::normalize(point - cameraPos) = ({}, {}, {})",
                                 glm::normalize(point - cameraPos).x,
                                 glm::normalize(point - cameraPos).y,
                                 glm::normalize(point - cameraPos).z)
                  << std::endl;
        std::cout << std::format("normal = ({}, {}, {})", normal.x, normal.y, normal.z) << std::endl;
        std::cout << std::format("center = ({}, {}, {})", point.x, point.y, point.z) << std::endl;

        // Bottom plane
        point  = nearCenter - up * near_height;
        normal = glm::normalize(point - cameraPos);
        normal = glm::cross(normal, right);
        pl[BOTTOM].setNormalAndPoint(normal, point);

        std::cout << "BOTTOM" << std::endl;
        std::cout << std::format("glm::normalize(point - cameraPos) = ({}, {}, {})",
                                 glm::normalize(point - cameraPos).x,
                                 glm::normalize(point - cameraPos).y,
                                 glm::normalize(point - cameraPos).z)
                  << std::endl;
        std::cout << std::format("normal = ({}, {}, {})", normal.x, normal.y, normal.z) << std::endl;
        std::cout << std::format("center = ({}, {}, {})", point.x, point.y, point.z) << std::endl;

        // Left plane
        point  = nearCenter - right * near_width;
        normal = glm::normalize(point - cameraPos);
        normal = glm::cross(up, normal);
        pl[LEFT].setNormalAndPoint(normal, point);

        std::cout << "LEFT" << std::endl;
        std::cout << std::format("glm::normalize(point - cameraPos) = ({}, {}, {})",
                                 glm::normalize(point - cameraPos).x,
                                 glm::normalize(point - cameraPos).y,
                                 glm::normalize(point - cameraPos).z)
                  << std::endl;
        std::cout << std::format("normal = ({}, {}, {})", normal.x, normal.y, normal.z) << std::endl;
        std::cout << std::format("center = ({}, {}, {})", point.x, point.y, point.z) << std::endl;

        // Right plane
        point  = nearCenter + right * near_width;
        normal = glm::normalize(point - cameraPos);
        normal = glm::cross(normal, up);
        pl[RIGHT].setNormalAndPoint(normal, point);

        std::cout << "RIGHT" << std::endl;
        std::cout << std::format("glm::normalize(point - cameraPos) = ({}, {}, {})",
                                 glm::normalize(point - cameraPos).x,
                                 glm::normalize(point - cameraPos).y,
                                 glm::normalize(point - cameraPos).z)
                  << std::endl;
        std::cout << std::format("normal = ({}, {}, {})", normal.x, normal.y, normal.z) << std::endl;
        std::cout << std::format("center = ({}, {}, {})", point.x, point.y, point.z) << std::endl;
    }
```

输出

```
updatePlanes

tanHalfFOVy = 0.0068539996
near_height = 0.0068539996
near_width = 0.010280999
right = (1, 0, 0)
forward = (0, 0, 1)
up = (0, 1, 0)
NEARP
normal = (0, 0, 1)
center = (0, 0, -9)
FARP
normal = (-0, -0, -1)
center = (0, 0, 90)
TOP
glm::normalize(point - cameraPos) = (0, 0.0068538385, 0.9999765)
normal = (0, -0.9999765, 0.0068538385)
center = (0, 0.0068539996, -9)
BOTTOM
glm::normalize(point - cameraPos) = (0, -0.0068538385, 0.9999765)
normal = (-0, 0.9999765, 0.0068538385)
center = (0, -0.0068539996, -9)
LEFT
glm::normalize(point - cameraPos) = (-0.010280456, 0, 0.9999472)
normal = (0.9999472, -0, 0.010280456)
center = (-0.010280999, 0, -9)
RIGHT
glm::normalize(point - cameraPos) = (0.010280456, 0, 0.9999472)
normal = (-0.9999472, 0, 0.010280456)
center = (0.010280999, 0, -9)
```

摄像机位于 (0, 0, -10)，近平面 1 远平面 100

这下我觉得是对了

但是为什么我感觉这个视锥体还是太窄了……

之后发现是我 fovy 传入的是弧度，但是代码里面认为是角度

于是改了，就好了
