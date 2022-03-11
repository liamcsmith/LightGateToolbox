classdef LightGate
    % An object to store and analyse light gate data
    %   Input Args (All given as name-value):
    %       'FilePath' - String  - The path to an oscilloscope file that
    %                              corresponds to a light gate.
    %       'Delay'    - Numeric - The amount of cable delay this trace was
    %                              subjected to, this is to be given in the
    %                              same units as the trace itself (It will
    %                              delay the time axis by that value).
    %   Methods:
    %       FitLightGate: This method actually fits the light gate trace,
    %                     it will ask you to draw a rectangle around the
    %                     region where the light gate falls. It will return
    %                     FittedCurve, TrigTime, & Box properties. You can
    %                     specify Box in future analyses to use reuse the 
    %                     previously made box.
    %
    %
    %   Dependencies:
    %       ScopeTrace: This is contained within the ImportScope repo, if
    %                   you have installed both LightGateToolbox & 
    %                   ImportScope repos in the same folder then the 
    %                   default value property ScopeTracePath
    %                   ('../ImportScope') should satisfy this dependency,
    %                   if you have not you should edit this to provide a
    %                   correct path to the ImportScope function.

    
    properties
        RawData
        ScopeTracePath = '../ImportScope'
        Delay
        FittedCurve
        TrigTime
        Box
    end
    properties (Dependent)
        Voltage
        Time
    end
    
    methods
        function obj = LightGate(inputargs)
            arguments
                inputargs.FilePath  = 'Undefined'
                inputargs.Delay     = 0
            end
            addpath(obj.ScopeTracePath)
            if isfile(inputargs.FilePath)
                obj.RawData = ScopeTrace('FilePath',inputargs.FilePath);
            end
            obj.Delay = inputargs.Delay;
            path(obj.ScopeTracePath)
        end
        function obj = FitLightGate(obj,Box,plotflag)
            arguments
                obj
                Box = 'Undefined'
                plotflag = false
            end
            
            Signal = rescale(obj.Voltage);
            
            tmp         = rescale(movmean(Signal,20));
            Crossover   = median(find(tmp>0.475 & tmp<0.525));
            
            if ischar(Box)
                plot(tmp);
                title('Drag rectangle over transition region')
                Box = getrect();
                close all
                plotflag = true;
            end

            obj.Box = Box;

            PreSignalLevel  = median(Signal(1:round(Box(1))));
            PostSignalLevel = median(Signal(round(Box(1)+Box(3)):end));
            Amplitude       = range([PreSignalLevel,PostSignalLevel])/2;
            
            [xData, yData] = prepareCurveData([],Signal);
            
            opts             = fitoptions('Method','NonlinearLeastSquares');
            opts.Display     = 'Off';
            opts.MaxFunEvals = 100000;
            opts.MaxIter     = 100000;
            opts.TolFun      = 1e-07;
            opts.TolX        = 1e-07;
            opts.Lower       = [0.75*Amplitude  0           Box(1)           PostSignalLevel-0.2];
            opts.StartPoint  = [Amplitude       4/Box(3)    Crossover        PostSignalLevel];
            opts.Upper       = [1.25*Amplitude  Inf         (Box(1)+Box(3))  PostSignalLevel+0.2 ];
            
            [obj.FittedCurve, ~] = fit(xData,...
                                       yData,...
                                       fittype('a*erfc(b*(x-c))+d',...
                                               'independent',...
                                               'x',...
                                               'dependent',...
                                               'y'),...
                                       opts );

            TriggerIdx = coeffvalues(obj.FittedCurve);
            TriggerIdx = TriggerIdx(3);
            obj.TrigTime = interp1(1:numel(obj.Time),obj.Time,TriggerIdx);

            ErrorVal = confint(obj.FittedCurve);
            ErrorVal = range(ErrorVal(:,3))*(obj.RawData.Time(2)-obj.RawData.Time(1));
            obj.TrigTime(2) = ErrorVal/2;
            
            if plotflag
                plot(Signal)
                hold on
                plot(obj.FittedCurve)
                hold off
                disp('Press any key to continue')
                pause
                close all
            end
        end
        function Time = get.Time(obj)
            addpath(obj.ScopeTracePath)
            Time = obj.RawData.Time - obj.Delay;
            rmpath(obj.ScopeTracePath)
        end
        function Voltage = get.Voltage(obj)
            addpath(obj.ScopeTracePath)
            Voltage = obj.RawData.Voltage;
            rmpath(obj.ScopeTracePath)
        end
    end
end