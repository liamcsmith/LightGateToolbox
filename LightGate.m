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
    %   Installation:     You will need to alter the private property
    %                     ScopeTracePath (Line 41) to satisy dependency.
    %
    %   Dependencies:
    %       ScopeTrace:   This is contained within the ImportScope repo, if
    %                     you do not have this function (ScopeTrace()
    %                     specifically) you should first get it. Then you
    %                     should change the private property ScopeTracePath
    %                     to a folder path that will include the ScopeTrace 
    %                     function (most likely the Import Scope repo folder 
    %                     path).
    properties
        RawData
        Delay
        FittedCurve
        TrigTime
        Box
    end
    properties (Dependent)
        Voltage
        Time
    end
    properties (Access=private)
        ScopeTracePath = '~/Documents/GitHub/ImportScope' % CHANGE ME TO INCLUDE ScopeTrace IN THE PATH
    end

    methods
        function obj = LightGate(inputargs)
            arguments
                inputargs.FilePath  = 'Undefined'
                inputargs.Delay     = 0
            end
            if ~exist('ScopeTrace','file')
                addpath(obj.ScopeTracePath);
            end

            if isfile(inputargs.FilePath)
                obj.RawData = ScopeTrace('FilePath',inputargs.FilePath);
            else
                obj.RawData = ScopeTrace();
            end

            obj.Delay = inputargs.Delay;

        end
        function obj = FitLightGate(obj,inputargs)
            arguments
                obj
                inputargs.Box = 'Undefined'
                inputargs.PlotFlag = false
            end
            obj.Box = inputargs.Box;
            if ~exist('ScopeTrace','file')
                addpath(obj.ScopeTracePath);
            end
            
            Signal = rescale(obj.Voltage);
            
            tmp         = rescale(movmean(Signal,20));
            Crossover   = median(find(tmp>0.475 & tmp<0.525));
            
            if ischar(obj.Box)
                plot(tmp);
                title('Drag rectangle over transition region')
                obj.Box = getrect();
                close all
                inputargs.PlotFlag = true;
            end

            PreSignalLevel  = median(Signal(1:round(obj.Box(1))));
            PostSignalLevel = median(Signal(round(obj.Box(1)+obj.Box(3)):end));
            Amplitude       = range([PreSignalLevel,PostSignalLevel])/2;
            
            [xData, yData] = prepareCurveData([],Signal);
            
            opts             = fitoptions('Method','NonlinearLeastSquares');
            opts.Display     = 'Off';
            opts.MaxFunEvals = 100000;
            opts.MaxIter     = 100000;
            opts.TolFun      = 1e-07;
            opts.TolX        = 1e-07;
            opts.Lower       = [0.75*Amplitude  0               obj.Box(1)              PostSignalLevel-0.2];
            opts.StartPoint  = [Amplitude       4/obj.Box(3)    Crossover               PostSignalLevel];
            opts.Upper       = [1.25*Amplitude  Inf             (obj.Box(1)+obj.Box(3)) PostSignalLevel+0.2 ];
            
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
            
            if inputargs.PlotFlag
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
            if ~exist('ScopeTrace','file')
                addpath(obj.ScopeTracePath);
            end
            Time = obj.RawData.Time - obj.Delay;
        end
        function Voltage = get.Voltage(obj)
            if ~exist('ScopeTrace','file')
                addpath(obj.ScopeTracePath);
            end
            Voltage = obj.RawData.Voltage;
        end
        function [Fig,Ax,Line] = PlotLightGate(obj,Fig,Ax)
            arguments
                obj
                Fig = figure()
                Ax  = axes(Fig)
            end
            hold(Ax,"on")
            Line = cell(2,1);
            Line{1} = plot(Ax,obj.Time,rescale(obj.Voltage),'LineWidth',0.5);
            if isa(obj.FittedCurve,class(cfit))
                Line{2} = plot(Ax,obj.Time,obj.FittedCurve(1:numel(obj.Time)),'LineWidth',2);
            end
        end
    end
end