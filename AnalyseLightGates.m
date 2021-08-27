MyPath1 = 'Path to lg1 .trc file';
MyPath2 = 'Path to lg1 .trc file';


LightGate1 = LightGate('FilePath',MyPath1).FitLightGate;
LightGate2 = LightGate('FilePath',MyPath2).FitLightGate;

LG1Time = LightGate1.TrigTime;
LG2Time = LightGate2.TrigTime;
% 2 Element Array with time and error (in seconds) for each light gate [Trig Time, 95% Error].

Distance = [12e-3,100e-6];
Time     = [abs(LG1Time(1)-LG1Time(2)) sqrt(LG1Time(2)^2 + LG2Time(2)^2)];

Velocity = Distance / Time;
VelocityError = Velocity * sqrt((Distance(2)/Distance(1))^2+(Time(2)/Time(1))^2);
