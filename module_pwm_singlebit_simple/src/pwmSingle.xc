#define MAXONEBITPORTS 16

void pwmSingle(chanend c, port pwmPorts[], int N) {
    unsigned int value, shiftValue;
    unsigned int time[MAXONEBITPORTS];
    unsigned int firstTime;

    pwmPorts[0] :> void @ firstTime;
    c <: firstTime;
    c :> value;
    c :> firstTime;

    shiftValue = value;
    for(int i = 0; i < N; i++) {
        pwmPorts[i] @ firstTime <: shiftValue;
        shiftValue >>= 1;
    }

//#pragma unsafe arrays
    while(1) {
        master {
            c <: 0;
            for(int i = 0; i < N; i++) {
                c :> time[i];
            }
            c :> firstTime;
        }
        value = ~value;
        shiftValue = value;
        for(int i = 0; i < N; i++) {
            pwmPorts[i] @ time[i] <: shiftValue;
            shiftValue >>= 1;
        }
    }
}
