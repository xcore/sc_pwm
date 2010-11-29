import sys
import java

def process(portWidth, timeStep):
    try: 
        xta.addExclusion("updateDutyCycle")
        routeIds = xta.analyzeEndpoints("handlePwm", "handlePwm")

        for routeId in routeIds:
            xta.setLoop(routeId, "nextDutyCycleLoop", portWidth)
            xta.setLoop(routeId, "calculatePortValueLoop", portWidth)

        clockTicksPerPeriod = 32.0 / portWidth
        required = 10.0 * clockTicksPerPeriod if timeStep == 0 else (timeStep * 10.0 * 2.0) * clockTicksPerPeriod
        for routeId in routeIds:
            xta.setRequired(routeId, required, "ns")
     
        for routeId in routeIds:
            errors = xta.getErrors(routeId)
            if len(errors) == 0:  
                worstCaseTime = xta.getWorstCase(routeId, "ns")
                status = "PASS" if worstCaseTime <= required else "FAILED"
                print "%s: %s: worst case time: %.2f ns, required time: %.2f ns" % \
                    (status, xta.getRouteDescription(routeId), worstCaseTime, required)
            else:
                print "Errors detected in route id: %d" % routeId
                for error in errors:
                    print "Error: %s" % error

    except java.lang.Exception, e:
        print e.getMessage()

if len(sys.argv) != 3:
    print "Error in arguments:"
    print "Usage: xta source pwm.py <num ports> <timestep>"
else:
    portWidth = int(sys.argv[1])
    timeStep = int(sys.argv[2])
    process(portWidth, timeStep)

