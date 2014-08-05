function [results funcnames] = resultreader(filename)
% This function will read the results from an external file.

if ~exist(filename, 'file')
    error('Unable to find file. Check path and/or filename is valid.');
end

f = fopen(filename, 'r');

fline = fgetl(f);

funcnames = {};
results = cell(2, 0);

% Read this file line by line
while ischar(fline)
    % Clean up this line by removing any (excessive) spacing.
    fline = strtrim(fline);
    
    % Only use lines where there is an equals
    if isempty(strfind(fline, '='))
        % No equals
        fline = fgetl(f);
        continue
    elseif length(strfind(fline, '=')) > 1
        % Multiple equals in one line
        fline = fgetl(f);
        continue
    end
    
    % if here, there is only one equals
    func = fline(1:(strfind(fline, '=') - 1));
    result = fline((strfind(fline, '=') + 1):end);
    
    % Make the result numeric
    result = str2double(result);
    
    % Next, parse the func expression:
    if isempty(strfind(func, '(')) || isempty(strfind(func, ')'))
        % This function does not have brackets so isn't a function of something.
        fline = fgetl(f);
        continue
    end
    
    % If here, we have brackets too
    funcname = strtrim(func(1:(strfind(func, '(') - 1)));
    funcof = strtrim(func((strfind(func, '(') + 1):(strfind(func, ')') - 1)));
    
    % Now tidy up the initial part of the expression:
    % Check for potential timestamp:
    if ~isempty(strfind(funcname, ':'))
        % There is a timestamp. Remove it.
        funcname = strtrim(funcname((strfind(funcname, ':') + 1):end));
    end

    % Now there should only be the node number to process:
    for n = 1:length(funcname)
        % Keep going unless there's a character that's not a number
        if funcname(n) < '0' || funcname(n) > '9'
            break;
        end
    end

    % Extract the function name
    funcname = strtrim(funcname(n:end));

    % Locate to see if this has previously occurred before
    bool = strcmp(funcname, funcnames);
    idx = find(bool);

    if ~any(bool)
        % Not encountered before. Append
        funcnames = {funcnames{:}, funcname};
        idx = length(funcnames);
        results{1, idx} = [];
        for n = 2:(2 + length(strfind(funcof, ',')))
            results{n, idx} = [];
        end
    end

    % Append result
    if isempty(strfind(funcof, ','))
        % Single argument
        results{2, idx} = [results{2, idx}, str2double(funcof)];
    else
        % Multiple arguments
        commaList = strfind(funcof, ',');
        remain = funcof;
        for n = 1:(length(strfind(funcof, ',')) + 1)
            [token, remain] = strtok(remain, [', ' 10 13]);
            results{n + 1, idx} = [results{n + 1, idx} str2double(token)];
        end
    end
    results{1, idx} = [results{1, idx}, result];
    
    % Finally, read a line
    fline = fgetl(f);
end

% For every function name:
for n = 1:size(results, 2)
    figure;
    
    % Check to see if function name is the same as a built-in function or one that's
    % available in MATLAB's path.
    if exist(funcnames{n}) == 2 || exist(funcnames{n}) == 5
        % Recognised the function name. Try getting some data out of it.
        try
            if size(results, 1) == 2
                truth = feval(funcnames{n}, results{2, n});
                plot(results{2, n}, results{1, n}, results{2, n}, truth);
            else
                % Got to determine which of the rows is valid
                for validRows = 1:(size(results, 1) - 1)
                    if isempty(results{validRows + 1, n})
                        break;
                    end
                end
                
                % Now out of these rows, determine which varies:
                varRowsCounts = zeros(1, validRows);
                for m = 2:(validRows + 1)
                    varRowsCounts(m - 1) = length(unique(results{m, n}));
                end
                [~, idx] = max(varRowsCounts);
                
                truth = feval(funcnames{n}, results{2:(validRows + 1), n});
                plot(results{idx + 1, n}, results{1, n}, results{idx + 1, n}, truth)
            end
            
            disp([funcnames{n} ' MSE: ' num2str(mean((results{1, n} - truth).^2))])
        catch
            % Didn't work. resort to plotting the file output.
            plot(results{2, n}, results{1, n});
        end
    else
        % Not recognised. Plot the file output only.
        plot(results{2, n}, results{1, n});
    end
    title(funcnames{n});
end