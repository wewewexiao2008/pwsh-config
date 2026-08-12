local wezterm = require 'wezterm'

---@alias WeztermGPUBackend 'Vulkan'|'Metal'|'Gl'|'Dx12'
---@alias WeztermGPUDeviceType 'DiscreteGpu'|'IntegratedGpu'|'Cpu'|'Other'

local GpuAdapters = {}
GpuAdapters.__index = GpuAdapters

GpuAdapters.AVAILABLE_BACKENDS = {
  windows = { 'Dx12', 'Vulkan', 'Gl' },
  linux = { 'Vulkan', 'Gl' },
  mac = { 'Metal' },
}

local function host_os()
  local triple = wezterm.target_triple
  if triple:find 'windows' then
    return 'windows'
  end
  if triple:find 'apple' or triple:find 'darwin' then
    return 'mac'
  end
  return 'linux'
end

function GpuAdapters:init()
  local os_name = host_os()
  local initial = {
    __backends = self.AVAILABLE_BACKENDS[os_name],
    __preferred_backend = self.AVAILABLE_BACKENDS[os_name][1],
    DiscreteGpu = nil,
    IntegratedGpu = nil,
    Cpu = nil,
    Other = nil,
  }

  local gpus = {}
  if wezterm.gui then
    gpus = wezterm.gui.enumerate_gpus() or {}
  end

  for _, adapter in ipairs(gpus) do
    if not initial[adapter.device_type] then
      initial[adapter.device_type] = {}
    end
    initial[adapter.device_type][adapter.backend] = adapter
  end

  return setmetatable(initial, self)
end

--- Discrete > Integrated > Other(Gl) > Cpu; preferred backend first for the OS.
function GpuAdapters:pick_best()
  local adapters_options = self.DiscreteGpu
  local preferred_backend = self.__preferred_backend

  if not adapters_options then
    adapters_options = self.IntegratedGpu
  end

  if not adapters_options then
    adapters_options = self.Other
    preferred_backend = 'Gl'
  end

  if not adapters_options then
    adapters_options = self.Cpu
  end

  if not adapters_options then
    wezterm.log_warn 'No GPU adapters found. Using default adapter.'
    return nil
  end

  local adapter_choice = adapters_options[preferred_backend]
  if not adapter_choice then
    wezterm.log_warn 'Preferred GPU backend not available. Using default adapter.'
    return nil
  end

  return adapter_choice
end

return GpuAdapters:init()
