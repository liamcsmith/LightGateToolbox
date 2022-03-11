
MyPath1 = 'Path to lg1 scope file';
MyPath2 = 'Path to lg2 scope file';

% Seed LightGate objects using above file paths
LightGate1 = LightGate('FilePath',MyPath1);
LightGate2 = LightGate('FilePath',MyPath2);

% Fit LightGate signals
LightGate1 = LightGate1.FitLightGate;
LightGate2 = LightGate2.FitLightGate;

% Pull out the results of the FitLightGate method.
LG1Time = LightGate1.TrigTime;
LG2Time = LightGate2.TrigTime;
% LG1Time/LG2Time are a 2-Element arrays with trigger time and the 
% asscoiated error (both in seconds). The error is the 95% Confidence
% interval width (2 Standard Deviations) of the predicted trigger time.

Distance    = nan(2,1);
Distance(1) = 12e-3;  % Light Gate Separation Value [m]
Distance(2) = 100e-6; % Light Gate Separation Error [m]

% Transit Time
Time     = [abs(LG1Time(1)-LG1Time(2)) sqrt(LG1Time(2)^2 + LG2Time(2)^2)];

% Velocity and Velocity Error
Velocity = Distance(1) / Time(1);
VelocityError = Velocity * sqrt((Distance(2)/Distance(1))^2+(Time(2)/Time(1))^2);
