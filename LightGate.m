classdef LightGate
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        RawData
        Delay
        FittedCurve
        TrigTime
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
            
            if isfile(inputargs.FilePath)
                obj.RawData = ScopeTrace('FilePath',inputargs.FilePath);
            end
            obj.Delay = inputargs.Delay;
        end
        
        function obj = FitLightGate(obj,Box,plotflag)
            arguments
                obj
                Box = 'Undefined'
                plotflag = false
            end
            
            Signal = rescale(obj.Voltage);
            tmp = rescale(movmean(Signal,20));
            Crossover = median(find(tmp>0.475 & tmp<0.525));
            
            
            if ischar(Box)
                plot(tmp);
                title('Drag rectangle over transition region')
                Box = getrect();
                close all
%                 disp('Box:')
%                 fprintf('%.0f\n',round(Box(1)))
%                 fprintf('%.f\n',Box(2))
%                 fprintf('%.0f\n',round(Box(3)))
%                 fprintf('%.f\n',Box(4))
                plotflag = true;
            end
            
            PreSignalLevel  = median(Signal(1:round(Box(1))));
            PostSignalLevel = median(Signal(round(Box(1)+Box(3)):end));
            Amplitude = range([PreSignalLevel,PostSignalLevel])/2;
            %fitting erfc function to reduced space
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
            Time = obj.RawData.Time - obj.Delay;
        end
        function Voltage = get.Voltage(obj)
            Voltage = obj.RawData.Voltage;
        end
    end
end