# 火焰图

## 火焰图开发

看了 [https://github.com/bwrsandman/imgui-flame-graph](https://github.com/bwrsandman/imgui-flame-graph)

他这个还是挺限制的

他是 hard code 了事件枚举，然后在每一帧更新这些事件的起点时间，终点时间，相减得到这些事件的耗时

然后在画图函数里面，根据这个枚举，来手动计算 rect 的高度位置

然后还根据起点和终点的时刻来判断这个矩形占了哪里到哪里

怎么说呢……看上去挺酷，但是一细想就很受限

但是他 FetchContent 的一套构建下来还是挺舒服的

于是看 [https://github.com/RudjiGames/rprof](https://github.com/RudjiGames/rprof)

核心是

```cpp
ImDrawList* draw_list = ImGui::GetWindowDrawList();
for (uint32_t i=0; i<_data->m_numScopes; ++i)
{
    ProfilerScope& cs = _data->m_scopes[i];
    if (!cs.m_name)
        continue;

    // handle wrap around
    int64_t sX = int64_t(cs.m_start	- _data->m_startTime);
    if (sX < 0) sX = -sX;
    int64_t eX = int64_t(cs.m_end - _data->m_startTime);
    if (eX < 0) eX = -eX;

    float startXpct = float(sX) / float(totalTime);
    float endXpct	= float(eX) / float(totalTime);

    float startX	= paz.w2s(startXpct, frameStartX, frameEndX);
    float endX		= paz.w2s(endXpct  , frameStartX, frameEndX);

    ImVec2 tl = ImVec2(startX,	frameStartY + cs.m_level * (barHeight + 1.0f));
    ImVec2 br = ImVec2(endX,	frameStartY + cs.m_level * (barHeight + 1.0f) + barHeight);
    
    bottom = rprofMax(bottom, br.y);

    int level = cs.m_level;
    if (cs.m_level >= s_maxLevelColors)
        level = s_maxLevelColors - 1;

    ImU32 drawColor = s_levelColors[level];

    draw_list->PushClipRect(tl, br, true);
    draw_list->AddRectFilled(tl, br, drawColor);
    tl.x += 3;
    draw_list->AddText(tl, IM_COL32(0, 0, 0, 255), cs.m_name);
    draw_list->PopClipRect();
}
```

### pch

为了能够大部分函数都加上 Profile 所以我希望把 Profile 装到 pch 里

结果后面想到把 global context 装到 pch 里的时候出了一堆错

于是发现确实是用错了，pch 只能用在哪些没有依赖要求的头文件

如果是那些有依赖要求的，很容易就循环依赖了

当然，你可以把所有的 include pch 都放在 cpp 但是那些使用模板的就没有办法了

所以还是老老实实只装基础的东西吧