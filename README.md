# LightGate
## Summary
An object to store and analyse light gate data whilst minimising the memory requriements and still maintaining a high degree of both accuracy and precision.

## Dependencies
**ScopeTrace** This can be found in one of my other repos.

## Installation
In order to install this correctly you will need to do the following:
1) Ensure you have a copy of ScopeTrace
2) Change the private property (in LightGate) that is called ScopeTracePath (see line 43 of LightGate) to a folder path that will include the ScopeTrace function (most likely the Import Scope repo folder path).

## InputArgs
All given as Name-Value and all optional[^1].

| Name          | DataType      | Default      	| Description								|
| ------------- | ------------- | -------------	| -------------			                          		|
| 'FilePath'    | string        | 'Undefined'   | The path to an oscilloscope file that corresponds to a light gate.	|
| 'Delay'    	| numeric 	| 0.0		| The amount of cable delay this trace was subjected to (in seconds).  
[^1]: If no arguments are passed the default delay will be used and ScopeTrace will be used to launch a file dialogue box to select a scope file.

## Methods
### FitLightGate
This method actually fits the light gate trace, it will ask you to draw a rectangle around the region where the light gate falls. It will return FittedCurve, TrigTime, & Box properties. You can specify Box in future analyses to use reuse the previously made box.

# AnalyseLightGate
## Summary
This is a little example script showing how you could interact with LightGate to produce a value for impact velocity given two light gate traces. Its really only scratching the surface but theres no harm in including it.

# LightGateLegacy
## Summary
The precursor to LightGate, this is an object to store and analyse light gate data, however the analysis method is not nearly as robust, seamless or fast!

## Dependencies
**ScopeTrace** This can be found in one of my other repos.

## Installation
In order to install this correctly you will need to do the following:
1) Ensure you have a copy of ScopeTrace
2) Change the private property (in LightGate) that is called ScopeTracePath (see line 41 of LightGateLegacy) to a folder path that will include the ScopeTrace function (most likely the Import Scope repo folder path).

## Input Args
All given as Name-Value, all optional[^1]
| Name          | DataType      | Default      	| Description								|
| ------------- | ------------- | -------------	| -------------			                          		|
| 'FilePath'    | string        | 'Undefined'   | The path to an oscilloscope file that corresponds to a light gate.	|
| 'Delay'    	| numeric 	| 0.0		| The amount of cable delay this trace was subjected to (in seconds).  

## Methods
### FitLightGate
This method actually fits the light gate trace, it will ask you to draw a rectangle around the region where the light gate falls. It will return FittedCurve, TrigTime, & Box properties. You can specify Box in future analyses to use reuse the previously made box.
