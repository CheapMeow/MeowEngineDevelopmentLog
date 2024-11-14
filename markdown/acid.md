# Acid 引擎

试试构建 Acid 引擎

下载 OpenAL SDK 配置 `OPENALDIR` 环境变量

然后是找不到 python

于是传入了 msvc 的

```bat
 -D@echo off

cls

REM Configure a debug build
cmake -S . -B build-debug/ -G "Visual Studio 17 2022" -A x64 -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Debug -DPYTHON_EXECUTABLE="e:\software\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\VC\SecurityIssueAnalysis\python\python.exe"
cmake --build build-debug/ --parallel 8

pause
```

然后是 OpenAL 又有问题

```
-- Could NOT find OpenALSoft (missing: OPENALSOFT_LIBRARY OPENALSOFT_INCLUDE_DIR) 
CMake Error at Sources/CMakeLists.txt:31 (add_library):
  add_library cannot create imported target "OpenAL::OpenAL" because another
  target with the same name already exists.
```

是 openal target 重复

于是那个部分改成

```cmake
# OpenAL must be installed on the system, env "OPENALDIR" must be set
find_package(OpenALSoft)
find_package(OpenAL)
if(OPENALSOFT_FOUND)
	#if(OPENALSOFT_FOUND AND NOT TARGET OpenAL::OpenAL)
		add_library(OpenAL::OpenAL UNKNOWN IMPORTED)
		set_target_properties(OpenAL::OpenAL PROPERTIES
				IMPORTED_LOCATION "${OPENALSOFT_LIBRARY}"
				INTERFACE_INCLUDE_DIRECTORIES "${OPENALSOFT_INCLUDE_DIR}"
				)
	#endif()
elseif(OPENAL_FOUND)
	if(NOT TARGET OpenAL::OpenAL)
		add_library(OpenAL::OpenAL UNKNOWN IMPORTED)
	endif()
	set_target_properties(OpenAL::OpenAL PROPERTIES
	IMPORTED_LOCATION "${OPENAL_LIBRARY}"
	INTERFACE_INCLUDE_DIRECTORIES "${OPENAL_INCLUDE_DIR}"
	)
else()
	message(FATAL_ERROR "Could not find OpenAL or OpenAL-Soft")
endif()

```

就可以编译了

但是很多可执行文件都会报错

于是还是放弃了

直接看看他的源码

## descriptor

根据 pipeline 来创建的 descriptor

```cpp
DescriptorsHandler::DescriptorsHandler(const Pipeline &pipeline) :
	shader(pipeline.GetShader()),
	pushDescriptors(pipeline.IsPushDescriptors()),
	descriptorSet(std::make_unique<DescriptorSet>(pipeline)),
	changed(true) {
}
```

然后添加 descriptor 的时候就是根据 material 的 pipeline 来创建

更新数据的时候看上去是要先把数据堆在一个 `map` 里面

```cpp
void DescriptorsHandler::Push(const std::string &descriptorName, UniformHandler &uniformHandler, const std::optional<OffsetSize> &offsetSize) {
	if (shader) {
		uniformHandler.Update(shader->GetUniformBlock(descriptorName));
		Push(descriptorName, uniformHandler.GetUniformBuffer(), offsetSize);
	}
}

void DescriptorsHandler::Push(const std::string &descriptorName, StorageHandler &storageHandler, const std::optional<OffsetSize> &offsetSize) {
	if (shader) {
		storageHandler.Update(shader->GetUniformBlock(descriptorName));
		Push(descriptorName, storageHandler.GetStorageBuffer(), offsetSize);
	}
}

void DescriptorsHandler::Push(const std::string &descriptorName, PushHandler &pushHandler, const std::optional<OffsetSize> &offsetSize) {
	if (shader) {
		pushHandler.Update(shader->GetUniformBlock(descriptorName));
	}
}
```

底层就是这个 `map`

```cpp
	template<typename T>
	void Push(const std::string &descriptorName, const T &descriptor, const std::optional<OffsetSize> &offsetSize = std::nullopt) {
		if (!shader)
			return;

		// Finds the local value given to the descriptor name.
		auto it = descriptors.find(descriptorName);

		if (it != descriptors.end()) {
			// If the descriptor and size have not changed then the write is not modified.
			if (it->second.descriptor == to_address(descriptor) && it->second.offsetSize == offsetSize) {
				return;
			}

			descriptors.erase(it);
		}

		// Only non-null descriptors can be mapped.
		if (!to_address(descriptor)) {
			return;
		}

		// When adding the descriptor find the location in the shader.
		auto location = shader->GetDescriptorLocation(descriptorName);

		if (!location) {
#ifdef ACID_DEBUG
			if (shader->ReportedNotFound(descriptorName, true)) {
				Log::Error("Could not find descriptor in shader ", shader->GetName(), " of name ", std::quoted(descriptorName), '\n');
			}
#endif

			return;
		}

		auto descriptorType = shader->GetDescriptorType(*location);

		if (!descriptorType) {
#ifdef ACID_DEBUG
			if (shader->ReportedNotFound(descriptorName, true)) {
				Log::Error("Could not find descriptor in shader ", shader->GetName(), " of name ", std::quoted(descriptorName), " at location ", *location, '\n');
			}
#endif
			return;
		}

		// Adds the new descriptor value.
		auto writeDescriptor = to_address(descriptor)->GetWriteDescriptor(*location, *descriptorType, offsetSize);
		descriptors.emplace(descriptorName, DescriptorValue{to_address(descriptor), std::move(writeDescriptor), offsetSize, *location});
		changed = true;
	}
```

如果已经有值了，那么就删掉旧值 `descriptors.erase(it);`

更新新值就这个 `descriptors.emplace`

然后 descriptor 的 value 还做了封装 `DescriptorValue`

实际更新的时候

```cpp
bool DescriptorsHandler::Update(const Pipeline &pipeline) {
	if (shader != pipeline.GetShader()) {
		shader = pipeline.GetShader();
		pushDescriptors = pipeline.IsPushDescriptors();
		descriptors.clear();
		writeDescriptorSets.clear();

		if (!pushDescriptors) {
			descriptorSet = std::make_unique<DescriptorSet>(pipeline);
		}

		changed = false;
		return false;
	}

	if (changed) {
		writeDescriptorSets.clear();
		writeDescriptorSets.reserve(descriptors.size());

		for (const auto &[descriptorName, descriptor] : descriptors) {
			auto writeDescriptorSet = descriptor.writeDescriptor.GetWriteDescriptorSet();
			writeDescriptorSet.dstSet = VK_NULL_HANDLE;

			if (!pushDescriptors)
				writeDescriptorSet.dstSet = descriptorSet->GetDescriptorSet();

			writeDescriptorSets.emplace_back(writeDescriptorSet);
		}

		if (!pushDescriptors)
			descriptorSet->Update(writeDescriptorSets);

		changed = false;
	}

	return true;
}
```

是否是 push 的这个选项我还不太懂

然后这个 `descriptors` 变量就是之前 push 过的

看看他的接口是怎么使用的

```cpp
void DeferredSubrender::Render(const CommandBuffer &commandBuffer) {
	auto camera = Scenes::Get()->GetScene()->GetCamera();

	// TODO probably use a cubemap image directly instead of scene components.
	std::shared_ptr<ImageCube> skybox = nullptr;
	auto meshes = Scenes::Get()->GetScene()->QueryComponents<Mesh>();
	for (const auto &mesh : meshes) {
		if (auto materialSkybox = dynamic_cast<const SkyboxMaterial *>(mesh->GetMaterial())) {
			skybox = materialSkybox->GetImage();
			break;
		}
	}

	if (this->skybox != skybox) {
		this->skybox = skybox;
		irradiance = Resources::Get()->GetThreadPool().Enqueue(ComputeIrradiance, skybox, 64);
		prefiltered = Resources::Get()->GetThreadPool().Enqueue(ComputePrefiltered, skybox, 512);
	}

	// Updates uniforms.
	std::vector<DeferredLight> deferredLights(MAX_LIGHTS);
	uint32_t lightCount = 0;

	auto sceneLights = Scenes::Get()->GetScene()->QueryComponents<Light>();

	for (const auto &light : sceneLights) {
		//auto position = *light->GetPosition();
		//float radius = light->GetRadius();

		//if (radius >= 0.0f && !camera.GetViewFrustum()->SphereInFrustum(position, radius))
		//{
		//	continue;
		//}

		DeferredLight deferredLight = {};
		deferredLight.colour = light->GetColour();

		if (auto transform = light->GetEntity()->GetComponent<Transform>())
			deferredLight.position = transform->GetPosition();

		deferredLight.radius = light->GetRadius();
		deferredLights[lightCount] = deferredLight;
		lightCount++;

		if (lightCount >= MAX_LIGHTS)
			break;
	}

	// Updates uniforms.
	uniformScene.Push("view", camera->GetViewMatrix());
	if (auto shadows = Scenes::Get()->GetScene()->GetSystem<Shadows>())
		uniformScene.Push("shadowSpace", shadows->GetShadowBox().GetToShadowMapSpaceMatrix());
	uniformScene.Push("cameraPosition", camera->GetPosition());
	uniformScene.Push("lightsCount", lightCount);
	uniformScene.Push("fogColour", fog.GetColour());
	uniformScene.Push("fogDensity", fog.GetDensity());
	uniformScene.Push("fogGradient", fog.GetGradient());

	// Updates storage buffers.
	storageLights.Push(deferredLights.data(), sizeof(DeferredLight) * MAX_LIGHTS);

	// Updates descriptors.
	descriptorSet.Push("UniformScene", uniformScene);
	descriptorSet.Push("BufferLights", storageLights);
	descriptorSet.Push("samplerShadows", Graphics::Get()->GetAttachment("shadows"));
	descriptorSet.Push("samplerPosition", Graphics::Get()->GetAttachment("position"));
	descriptorSet.Push("samplerDiffuse", Graphics::Get()->GetAttachment("diffuse"));
	descriptorSet.Push("samplerNormal", Graphics::Get()->GetAttachment("normal"));
	descriptorSet.Push("samplerMaterial", Graphics::Get()->GetAttachment("material"));
	descriptorSet.Push("samplerBRDF", *brdf);
	descriptorSet.Push("samplerIrradiance", *irradiance);
	descriptorSet.Push("samplerPrefiltered", *prefiltered);

	if (!descriptorSet.Update(pipeline))
		return;

	// Draws the object.
	pipeline.BindPipeline(commandBuffer);

	descriptorSet.BindDescriptor(commandBuffer, pipeline);
	vkCmdDraw(commandBuffer, 3, 1, 0, 0);
}
```

那么这个就看上去很正常

但是还是没有按照频率来更新啊