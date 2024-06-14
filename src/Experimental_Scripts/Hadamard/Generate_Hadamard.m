function result = Generate_Hadamard(app, varargin)

% Initialize result to indicate failure in case the try block doesn't complete
result = 0;

try
    % Assuming xx.getDevice('DMD') is correct and returns a device object
    dmd = app.getDevice('DMD');
    nlocations_and_offset = [63, 14]; % [n offset]
    
    % Generate a matrix of size [1024, 768]. Randomization is always the same.
    % Assuming hadamard_patterns_scramble_nopermutation is a function that
    % exists and returns the patterns you need
    hadamard_patterns = alp_btd_to_logical(hadamard_patterns_scramble_nopermutation(nlocations_and_offset));
    
    % Send patterns to DMD
    % Assuming dmd(1,1).pattern_stack is the correct way to assign patterns
    % and Write_Stack is a function that correctly handles the dmd object
    dmd(1,1).pattern_stack = hadamard_patterns;
    Write_Stack(dmd(1,1));
    
    % If everything above succeeded, set result to 1
    result = 1;
catch
    % If there's an error, result remains 0 (initialized at the start)
    % You can optionally add error handling here, e.g., display an error message
    % disp('An error occurred.');
end

end