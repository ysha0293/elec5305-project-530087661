%% ELEC5305 Final Project - Main Entry
% MFCCs versus Pretrained Audio Embeddings:
% Robustness of Environmental Sound Classification
%
% CURRENTLY IMPLEMENTED:
%   1) UrbanSound8K dataset inspection
%   2) MFCC + linear SVM using official 10-fold CV
%   3) Frozen YAMNet embeddings + linear SVM using official 10-fold CV
%   4) Preliminary tables and figures for the current project milestone
%   5) Reproducibility manifest and deterministic random seed
%
% FUTURE EXTENSIONS:
%   6) Background-noise robustness
%   7) Reverberation robustness
%   8) Channel-filter robustness
%   9) Representation-shift and correlation analysis

clear;
clc;
close all;

codeDir = fileparts(mfilename("fullpath"));
addpath(genpath(codeDir));

C = config();
P = project_paths();

% One deterministic global seed for any algorithm that consults MATLAB's
% global random-number generator. Perturbation functions use their own
% deterministic per-clip streams and therefore do not disturb this state.
rng(C.seed,C.rngAlgorithm);

write_reproducibility_manifest();

fprintf("\n=============================================\n");
fprintf("ELEC5305 Environmental Sound Project\n");
fprintf("Project root : %s\n", P.projectRoot);
fprintf("Dataset root : %s\n", P.datasetRoot);
fprintf("Results root : %s\n", P.resultsRoot);
fprintf("Seed         : %d (%s)\n", C.seed, C.rngAlgorithm);
fprintf("=============================================\n\n");

%% 1. Dataset inspection
if C.run.datasetInspection
    inspect_dataset();
end

%% 2. Clean official 10-fold benchmark
if C.run.cleanBenchmark
    cleanResults = run_clean_benchmark();
    save(fullfile(P.resultsRoot,"clean_results.mat"),"cleanResults","C","-v7.3");
end

%% Future experiments
% The future runners should preserve the teacher-recommended protocol:
%
%   CLEAN training folds -> PERTURBED held-out test fold
%
% and the same perturbed waveform must be used to extract both MFCC and
% YAMNet representations.
%
% if C.run.noise
%     noiseResults = run_noise_experiments();
% end
%
% if C.run.reverb
%     reverbResults = run_reverb_experiments();
% end
%
% if C.run.channel
%     channelResults = run_channel_experiments();
% end
%
% if C.run.representationShift
%     shiftResults = run_representation_shift_analysis();
% end

fprintf("\nAll currently enabled stages are complete.\n");
fprintf("Tables         : %s\n",P.tableDir);
fprintf("Figures        : %s\n",P.figureDir);
fprintf("Reproducibility: %s\n",P.reproDir);
