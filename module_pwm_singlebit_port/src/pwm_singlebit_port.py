import sys
import java

def process(numPorts, timeStep):
    try: 
        xta.addExclusion("updateDutyCycle");
        routeIds = xta.analyzeEndpoints("handlePwm", "handlePwm");

        required = 10.0 * 32.0 if timeStep == 0 else (timeStep * 10.0 * 2.0) * 32.0
        for routeId in routeIds:
            xta.setRequired(routeId, required, "ns");
     
        for routeId in routeIds:
            xta.setLoop(routeId, "handlePwmLoop", numPorts);

        for routeId in routeIds:
            worstCaseTime = xta.getWorstCase(routeId, "ns")
            status = "PASS" if worstCaseTime <= required else "FAILED"
            print "%s: %s: worst case time: %.2f ns, required time: %.2f ns" % \
                (status, xta.getRouteDescription(routeId), worstCaseTime, required)

    except java.lang.Exception, e:
        print e.getMessage()

if len(sys.argv) != 3:
    print "Error in arguments:"
    print "Usage: xta source pwm.py <num ports> <timestep>"
else:
    numPorts = int(sys.argv[1])
    timeStep = int(sys.argv[2])
    process(numPorts, timeStep)

