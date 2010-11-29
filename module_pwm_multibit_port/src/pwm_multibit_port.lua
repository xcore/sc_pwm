-------------------------------------------------------------------------------
-- Descriptive metadata
-------------------------------------------------------------------------------

componentName = "pwm_multibit_port"
componentFullName = "PWM Mul-bit Port"
alternativeNames = { "Pulse Width Modulation 1 Bit Port" }
componentDescription = "Pulse Width Modulation using 1-bit ports."
componentVersion = "1v0"

-------------------------------------------------------------------------------
-- Source generation functions
-------------------------------------------------------------------------------
 
function getIncludes()
    return "#include \"pwm_multibit_port.h\""
end

function getGlobals()
    code = "out buffered port:32 pwm_multibit_port_" .. component.id .. " = " .. component.port[0] .. ";\n"
    code = code .. "clock pwm_multibit_port_clk_" .. component.id .. " = " .. component.clockblock[0] .. ";"
    return code
end

function getChannels()
    return "chan pwm_multibit_port_chan_" .. component.id .. ";"
end

function getLocals()
    return ""
end

function getCalls()
    return "pwmMultiBitPort(" ..
           "pwm_multibit_port_chan_" .. component.id .. 
           ", pwm_multibit_port_clk_" .. component.id ..
           ", pwm_multibit_port_" .. component.id ..
           ", " .. component.params.portWidth .. 
           ", " .. component.params.resolution .. 
           ", " .. component.params.timestep .. ");" 
end

-------------------------------------------------------------------------------
-- Documentation functions
-------------------------------------------------------------------------------

function getPortName(i)    
    if i == 0 then
        return "PWMMB"
    end
end

function getPortDescription(i)    
    if i == 0 then
        return "Pwm Ouput Port"
    end
end

function getPortDirection(i)    
    if i == 0 then
        return "out"
    end
end

function getDatasheetSummary()
    return "Multi-bit Port Pulse Width Modulation Component"
end

function getDatasheetDescription()
    return "This is the documentation for the PWM multibit port component"
end



-------------------------------------------------------------------------------
-- Parameter descriptions.
-------------------------------------------------------------------------------

configPoints =
{
  portWidth =
  {
    short   = "Port width",
    long    = "Number of PWM signals on a multi-bit port",
    help    = "The PWM_MULTI_BIT component is configured with a 4, 8 or 16-bit port, and will produce multiple sychronised pwm signals on each pin of the given port. The port width is passed as a run-time parameter to the PWM_MULTI_BIT server function.",
    units   = "",
    sortKey = 1,
    paramType = "int",
    max     = 256,
    min     = 1,
    default = 8
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
    default = 8
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
    default = 16
  }
}

configSets =
{
  typical     = { portWidth = 4, resolution = 1, timestep = 10 },
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
  return 0
end

function getNumberOf4BitPorts()
  if component.params.portWidth == 4 then
    return 1
  else
    return 0
  end
end

function getNumberOf8BitPorts()
  if component.params.portWidth == 8 then
    return 1
  else
    return 0
  end
end

function getNumberOf16BitPorts()
  if component.params.portWidth == 16 then
    return 1
  else
    return 0
  end
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
