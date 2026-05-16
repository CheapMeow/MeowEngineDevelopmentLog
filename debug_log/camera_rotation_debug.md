添加调试信息

```cpp
    std::pair<glm::vec3, glm::quat> Camera3DComponent::CalculateFreeCameraDeltas(float dt)
    {
        // Default zero deltas
        glm::vec3 movement_delta(0.0f);
        glm::quat rotation_delta(1.0f, 0.0f, 0.0f, 0.0f); // Identity quaternion

        if (!m_transform.lock())
        {
            return {movement_delta, rotation_delta};
        }

        // Handle mouse rotation
        if (g_runtime_context.input_system->GetButton("RightMouse")->GetAction() == InputAction::Press)
        {
            float dx = g_runtime_context.input_system->GetAxis("MouseX")->GetAmount();
            float dy = g_runtime_context.input_system->GetAxis("MouseY")->GetAmount();

            auto      transform_component = m_transform.lock();
            glm::vec3 temp_right          = transform_component->rotation * glm::vec3(1.0f, 0.0f, 0.0f);

            float yaw_angle   = -dx * dt * camera_rotate_velocity;
            float pitch_angle = -dy * dt * camera_rotate_velocity;

            glm::quat dyaw   = Math::QuaternionFromAngleAxis(yaw_angle, glm::vec3(0.0f, 1.0f, 0.0f));
            glm::quat dpitch = Math::QuaternionFromAngleAxis(pitch_angle, temp_right);

            rotation_delta = dyaw * dpitch;

            // --- CAMERA DEBUG LOGGING ---
            // One-time header explaining all field names and current parameter values
            static bool header_printed = false;
            if (!header_printed)
            {
                header_printed = true;
                float axis_x_scale = g_runtime_context.input_system->GetAxis("MouseX")->GetScale();
                float axis_x_offset = g_runtime_context.input_system->GetAxis("MouseX")->GetOffset();
                float axis_y_scale = g_runtime_context.input_system->GetAxis("MouseY")->GetScale();
                float axis_y_offset = g_runtime_context.input_system->GetAxis("MouseY")->GetOffset();

                MEOW_INFO("CAMDBG_HEADER | "
                          "dt=delta_time_sec | "
                          "dx_raw=mouse_pixel_delta_x | dy_raw=mouse_pixel_delta_y | "
                          "axis_x_scale/offset={:.3f}/{:.3f} | axis_y_scale/offset={:.3f}/{:.3f} | "
                          "rotate_vel=camera_rotate_velocity | "
                          "yaw_deg=angle_around_Y_world | pitch_deg=angle_around_cam_right | "
                          "cam_euler_before_deg=(yaw_before,pitch_before,roll_before) | "
                          "delta_euler_deg=(delta_yaw,delta_pitch,delta_roll) | "
                          "cam_rot_quat=quat_before(w,x,y,z) | delta_quat=quat_delta(w,x,y,z)",
                          axis_x_scale, axis_x_offset,
                          axis_y_scale, axis_y_offset);

                MEOW_INFO("CAMDBG_HOW_TO_READ | "
                          "dx_raw=direction check: move mouse RIGHT -> expect dx_raw>0. "
                          "move mouse DOWN -> expect dy_raw>0 (GLFW Y-down). "
                          "yaw_deg>0 means rotate counter-clockwise around world Y (camera looks LEFT). "
                          "pitch_deg>0 means rotate 'up' around camera right axis (camera looks UP).");
            }

            glm::vec3 cam_euler_before = glm::eulerAngles(transform_component->rotation);
            glm::vec3 delta_euler      = glm::eulerAngles(rotation_delta);

            MEOW_INFO(
                "CAMDBG | dt={:.6f} | dx_raw={:.3f} | dy_raw={:.3f} | rotate_vel={:.1f} | "
                "yaw_deg={:.3f} | pitch_deg={:.3f} | "
                "cam_euler_before_deg=({:.3f},{:.3f},{:.3f}) | delta_euler_deg=({:.3f},{:.3f},{:.3f}) | "
                "cam_rot_quat=({:.6f},{:.6f},{:.6f},{:.6f}) | delta_quat=({:.6f},{:.6f},{:.6f},{:.6f})",
                dt,
                dx,
                dy,
                camera_rotate_velocity,
                glm::degrees(yaw_angle),
                glm::degrees(pitch_angle),
                glm::degrees(cam_euler_before.x),
                glm::degrees(cam_euler_before.y),
                glm::degrees(cam_euler_before.z),
                glm::degrees(delta_euler.x),
                glm::degrees(delta_euler.y),
                glm::degrees(delta_euler.z),
                transform_component->rotation.w,
                transform_component->rotation.x,
                transform_component->rotation.y,
                transform_component->rotation.z,
                rotation_delta.w,
                rotation_delta.x,
                rotation_delta.y,
                rotation_delta.z);
            // --- END CAMERA DEBUG LOGGING ---
        }
```