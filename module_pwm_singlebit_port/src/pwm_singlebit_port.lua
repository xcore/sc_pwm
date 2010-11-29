-------------------------------------------------------------------------------
-- Descriptive metadata
-------------------------------------------------------------------------------

componentName = "pwm_singlebit_port"
componentFullName = "PWM Single-bit Port"
alternativeNames = { "Pulse Width Modulation 1 Bit Port" }
componentDescription = "Pulse Width Modulation using 1-bit ports."
componentVersion = "1v0"

-------------------------------------------------------------------------------
-- Source generation functions
-------------------------------------------------------------------------------
 
function getIncludes()
    return "#include \"pwm_singlebit_port.h\""
end

function getGlobals()
    code = "out buffered port:32 pwm_singlebit_ports_" .. component.id .. "[]  = {"
    for i = 0, (component.params.numPorts - 1) do
        code = code .. component.port[i]
        if i ~= (component.params.numPorts - 1) then
            code = code .. ", "
        end
    end
    code = code .. "};\n"
    code = code .. "clock pwm_singlebit_ports_clk_" .. component.id .. " = " .. component.clockblock[0] .. ";"
    return code
end

function getChannels()
    return "chan pwm_singlebit_port_chan_" .. component.id .. ";"
end

function getLocals()
    return ""
end

function getCalls()
    return "pwmSingleBitPort(" ..
           "pwm_singlebit_port_chan_" .. component.id .. 
           ", pwm_singlebit_ports_clk_" .. component.id ..
           ", pwm_singlebit_ports_" .. component.id ..
           ", " .. component.params.numPorts .. 
           ", " .. component.params.resolution .. 
           ", " .. component.params.timestep .. ");" 
end

-------------------------------------------------------------------------------
-- Documentation functions
-------------------------------------------------------------------------------

function getPortName(i)    
    return "PWMSB[" .. i .. "]"
end

function getPortDescription(i)    
    return "Pwm Ouput Port " .. i
end

function getPortDirection(i)    
    return "out"
end

function getDatasheetSummary()
    return "Singlebit Port Pulse Width Modulation Component"
end

function getDatasheetDescription()
    return "This is the documentation for the PWM singlebit port component"
end


-------------------------------------------------------------------------------
-- Parameter descriptions.
-------------------------------------------------------------------------------

configPoints =
{
  numPorts =
  {
    short   = "Number of ports",
    long    = "Number of PWM signals on 1 bit ports",
    help    = "The PWM_SINGLE_BIT component is configured with an array of ports, thus can produce multiple sychronised pwm signals on multiple 1-bit ports. The number of ports is passed as a run-time parameter to the PWM_SINGLE_BIT server function.",
    units   = "",
    sortKey = 1,
    paramType = "int",
    max     = 256,
    min     = 1,
    default = 1
  },
  resolution =
  {
    short   = "Resolution",
    long    = "Resolution (multiple of 32)",
    help    = "The resolution of each of the components is configurable. For example, setting the resolution to 1024 will provide 1024 (10-bit) distinct levels. This is passed as a run-time parameter to the relevent server function.",
    units   = "",
    sortKey = 2,
    paramType = "int",
    max     = 256,
    min     = 1,
    default = 32
  },
  timestep =
  {
    short   = "Timestep",
    long    = "Timestep",
    help    = "The time-step width of each of the components is configurable. For example, setting the timestep parameter to 0 will provide a 10 ns minimum time-step. This is passed as a run-time parameter to the relevent server function.",
    units   = "",
    sortKey = 3,
    paramType = "int",
    max     = 256,
    min     = 1,
    default = 10
  }
}

configSets =
{
  typical     = { numPorts = 1, resolution = 1, timestep = 10 },
}

-------------------------------------------------------------------------------
-- Resource usage definitons
-------------------------------------------------------------------------------

function getStaticMemory()
  return buildResults.typical.memoryStatic
end

function getDynamicMemory()
  return buildResults.typical.memoryStack
end

function getNumberOfChanendArguments()
  return 1
end

function getNumberOfTimers()
  return buildResults.typical.numTimers
end

function getNumberOfThreads()
  return buildResults.typical.numThreads
end

function getNumberOfClockBlocks()
  return 1
end

function getNumberOfLocks()
  return 0
end

function getNumberOf1BitPorts()
  return component.params.numPorts
end

function getNumberOf4BitPorts()
  return 0
end

function getNumberOf8BitPorts()
  return 0
end

function getNumberOf16BitPorts()
  return 0
end

function getNumberOf32BitPorts()
  return 0
end

function hardcodedPorts()
  return {}
end

function requiedPhys()
  return {}
end
