function seed = make_condition_seed(baseSeed,clipIndex,conditionIndex)
%MAKE_CONDITION_SEED Deterministic sample-specific seed for perturbations.
%
% Using a different but deterministic seed for every clip and condition
% avoids reusing the same Gaussian-noise sequence while preserving exact
% rerun reproducibility.

if nargin<3
    conditionIndex = 0;
end

seed = double(baseSeed) + double(clipIndex) + 100000*double(conditionIndex);
end
