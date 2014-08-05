# Result Reader for DAMSON

This MATLAB function parses output from the DAMSON C compiler and plots the results. If a function name is recognised within MATLAB, the function is called and evaluated alongside the output from DAMSON. This assists in verifying the correct implementation of functions, knowing the limitations of implemented functions and test the accuracy compared with true floating point.

## Usage
The function requires a single input string corresponding with the path of the log file. The function returns two variables: the results and the recognised function names. Entries within the log file need to be of the form:

```
NodeID  functionName(input_value)=output_value
```

or, with timestamps enabled, the form:

```
TimeStamp:  NodeID  functionName(input_value)=output_value
```

Spacing in the `println` statement is ignored. Lines within the log file that do not conform with this standard are skipped.

To generate a log file in Linux, run:

```bash
damson script_name.d > script_results.log
```

The result reader can handle functions with multiple inputs and these input arguments are stored as additional rows in the results cell array.

This function also automatically plots the output of the discovered functions. For functions with multiple arguments, the argument which has the most unique values is used as the plot's x axis.