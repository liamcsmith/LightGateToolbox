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
    %                     ScopeTracePath (Line 43) to satisy dependency.
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
        FittedCurve = []
    end
    properties (Dependent)
        Voltage
        Time
        TrigTime
        LightGateCache
    end
    properties (Access=private)
        OuterBox        = []
        InnerBox        = []
        ScopeTracePath  = '~/Documents/GitHub/ImportScope' % CHANGE ME TO INCLUDE ScopeTrace IN THE PATH
    end

    methods
        function obj = LightGate(inputargs)
            arguments
                inputargs.FilePath  = 'Undefined'
                inputargs.Delay     = 0
                inputargs.LoadCache = true
            end
            obj.CheckDependency
            obj.Delay = inputargs.Delay;
            
            % Load Oscilloscope File
            if isfile(inputargs.FilePath)
                obj.RawData = ScopeTrace('FilePath',inputargs.FilePath);
            else
                obj.RawData = ScopeTrace();
            end
            
            % If Desired & Present Load the Cache & Fit and do not
            % overwrite
            if inputargs.LoadCache && isfile(obj.LightGateCache)
                Cache           = load(obj.LightGateCache);
                obj.OuterBox    = Cache.OuterBox;
                obj.InnerBox    = Cache.InnerBox;
                obj.FittedCurve = Cache.FittedCurve;
                clearvars Cache
            end
        end
        function obj = FitLightGate(obj,inputargs)
            arguments
                obj
                inputargs.Boxes     {mustBeA(inputargs.Boxes,'cell')}        = {[],[]}
                inputargs.PlotFlag  {mustBeA(inputargs.PlotFlag,'logical')}  = false
                inputargs.SaveCache {mustBeA(inputargs.SaveCache,'logical')} = true
            end
            obj.CheckDependency

            obj.OuterBox = inputargs.Boxes{1};
            obj.InnerBox = inputargs.Boxes{2};
            
            Signal = rescale(movmean(obj.Voltage,50));
            Idx    = (1:numel(Signal))';

            % Outer Box Filter
            if isempty(obj.OuterBox)
                plot(Idx,Signal);
                title('Drag rectangle over larger transition region (well before to well after fall)')
                drawnow
                obj.OuterBox = round(getrect());
            end
            [Idx,Signal] = obj.BoxCrop(Idx,Signal,obj.OuterBox);
            
            % Inner Box Filter
            if isempty(obj.InnerBox)
                plot(Idx,Signal);
                title('Drag rectangle over smaller transition region (just the fall)')
                drawnow
                obj.InnerBox = round(getrect());
                close(gcf)
            end
            [Idx_Inner,Signal_Inner] = obj.BoxCrop(Idx,Signal,obj.InnerBox);
                    
            Crossover       = Idx_Inner(round(median(find(abs(Signal_Inner-0.5)<0.05))));
            
            FallStartIdx    = obj.InnerBox(1);
            FallEndIdx      = obj.InnerBox(1) + obj.InnerBox(3);
            
            Signal = obj.Voltage;
            [~,Signal]      = obj.BoxCrop(1:numel(Signal),Signal,obj.OuterBox);
            PreSignalLevel  = mean(Signal(Idx < FallStartIdx ));
            PostSignalLevel = mean(Signal(Idx > FallEndIdx   ));

            Amplitude       = range([PreSignalLevel,PostSignalLevel])/2;
            FallWidth       = range([FallStartIdx,FallEndIdx]);
            
            [xData, yData]  = prepareCurveData(Idx,Signal);
            
            opts                = fitoptions('Method','NonlinearLeastSquares');
            opts.Display        = 'Off';
            opts.MaxFunEvals    = 100000;
            opts.MaxIter        = 100000;
            opts.TolFun         = 1e-07;
            opts.TolX           = 1e-07;
            opts.Lower          = [0.75*Amplitude  0            FallStartIdx PostSignalLevel-0.2];
            opts.StartPoint     = [Amplitude       4/FallWidth  Crossover    PostSignalLevel];
            opts.Upper          = [1.25*Amplitude  Inf          FallEndIdx   PostSignalLevel+0.2 ];
            opts.DiffMaxChange  = 10;
            
            [obj.FittedCurve, ~] = fit(xData,yData,...
                                       fittype('a*erfc(b*(x-c))+d',...
                                               'independent','x',...
                                               'dependent','y'),opts);
            
            if inputargs.SaveCache
                if isfile(obj.LightGateCache)
                    delete(obj.LightGateCache)
                end
                Cache = struct('OuterBox'   ,obj.OuterBox, ...
                               'InnerBox'   ,obj.InnerBox, ...
                               'FittedCurve',obj.FittedCurve);
                save(obj.LightGateCache,'-struct','Cache');
            end
            
            if inputargs.PlotFlag
                Fig = figure();
                Ax  = axes(Fig);
                [Fig] = obj.PlotLightGate(Fig,Ax);
                title(Ax,'Press any button to close')
                pause
                close(Fig)
            end
            
        end
        function [Fig,Ax,Line] = PlotLightGate(obj,Fig,Ax)
            arguments
                obj
                Fig = figure()
                Ax  = axes(Fig)
            end
            hold(Ax,"on")
            Line = cell(3,1);
            [XIdx,Y] = obj.BoxCrop((1:numel(obj.Time))',obj.Voltage,obj.OuterBox);

            Line{1} = plot(Ax,obj.Time(XIdx),Y,'LineWidth',0.5);
            if isa(obj.FittedCurve,class(cfit))
                Line{2} = plot(Ax,obj.Time(XIdx),obj.FittedCurve(XIdx),'LineWidth',2);
                Line{3} = xline(Ax,obj.TrigTime(1),'LineWidth',2);
            end
        end
    end
    methods
        function Time           = get.Time(obj)
            if ~exist('ScopeTrace','file')
                addpath(obj.ScopeTracePath);
            end
            Time = obj.RawData.Time - obj.Delay;
        end
        function Voltage        = get.Voltage(obj)
            if ~exist('ScopeTrace','file')
                addpath(obj.ScopeTracePath);
            end
            Voltage = obj.RawData.Voltage;
        end
        function Filename       = get.LightGateCache(obj)
            Filename = '';
            if isa(obj.RawData,'ScopeTrace')
                if isfile(obj.RawData.FilePath)
                    Filename = split(obj.RawData.FilePath,'.');
                    Filename = [Filename{1},'_LightGateCache.mat'];
                end
            end
        end
        function TrigTime       = get.TrigTime(obj)
            TrigTime = [];
            if isa(obj.FittedCurve,class(cfit))
                TriggerIdx = coeffvalues(obj.FittedCurve);
                
                tmp         = obj.Time;
                TrigTime    = interp1(1:numel(tmp),tmp,TriggerIdx(3));
                
                ErrorVals    = confint(obj.FittedCurve);
                TrigTime(2) = 0.5*range(ErrorVals(:,3))*mean(diff(obj.RawData.Time));
            end
        end
        function CheckDependency(obj)
            if ~exist('ScopeTrace','file')
                addpath(obj.ScopeTracePath);
            end
        end
    end
    methods (Static)
        function [Time,Voltage] = BoxCrop(Time,Voltage,Box)
            
            MinIdx = Box(1);
            MaxIdx = Box(1) + Box(3);
            Idx = Time>MinIdx & Time<MaxIdx;
            

            Time    = Time(Idx);
            Voltage = rescale(Voltage(Idx));

        end
    end
end