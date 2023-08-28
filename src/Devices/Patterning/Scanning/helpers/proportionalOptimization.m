function [done, nextOutputWaveform, optimizationData] = proportionalOptimization(linearScanner, iterationNumber, sampleRateHz, desiredWaveform, outputWaveform, feedbackWaveform, optimizationData)

if iterationNumber == 1
    optimizationData = struct();

    delay = findDelay(feedbackWaveform, desiredWaveform);
    if isempty(delay)
        delay = 0; % no correlation found. probably because waveform is constant
    end

    optimizationData.delay = delay;
    nextOutputWaveform = circshift(outputWaveform, -optimizationData.delay);
else
    err = feedbackWaveform - desiredWaveform;
    err_shift = circshift(err, -optimizationData.delay);

    K = 0.5;
    nextOutputWaveform = outputWaveform - K * err_shift;
end

done = iterationNumber >= 5;
end


%--------------------------------------------------------------------------%
% proportionalOptimization.m                                               %
% Copyright © 2020 Vidrio Technologies, LLC                                %
%                                                                          %
% ScanImage is licensed under the Apache License, Version 2.0              %
% (the "License"); you may not use any files contained within the          %
% ScanImage release  except in compliance with the License.                %
% You may obtain a copy of the License at                                  %
% http://www.apache.org/licenses/LICENSE-2.0                               %
%                                                                          %
% Unless required by applicable law or agreed to in writing, software      %
% distributed under the License is distributed on an "AS IS" BASIS,        %
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. %
% See the License for the specific language governing permissions and      %
% limitations under the License.                                           %
%--------------------------------------------------------------------------%
