function [done, nextOutputWaveform, optimizationData] = proportionalOptimizationwithFill(crit_index, delay, iterationNumber, desiredWaveform, outputWaveform, feedbackWaveform, optimizationData)

if iterationNumber == 1
    optimizationData = struct();

    delay = findDelay(feedbackWaveform, desiredWaveform);
    if isempty(delay)
        delay = 0;
    end
    optimizationData.delay = delay;
    nextOutputWaveform = circshift(outputWaveform, -optimizationData.delay);
else
    err = feedbackWaveform(crit_index) - desiredWaveform(crit_index);
    err_shift = circshift(err, -delay);

    K = 0.5;
    nextOutputWaveform(crit_index) = outputWaveform(crit_index) - K * err_shift(crit_index);

end

done = iterationNumber >= 5;
end
