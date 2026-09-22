%% ELEC5305 Final Project - Main Entry
% MFCCs versus Pretrained Audio Embeddings:
% Robustness of Environmental Sound Classification
%
% CURRENTLY IMPLEMENTED:
%   1) UrbanSound8K dataset inspection
%   2) MFCC + linear SVM using official 10-fold CV
%   3) Frozen YAMNet embeddings + linear SVM using official 10-fold CV
%   4) Preliminary tables and figures for the current project milestone
%
% FUTURE EXTENSIONS:
%   5) Background-noise robustness
%   6) Reverberation robustness
%   7) Channel-filter robustness
%   8) Representation-shift and correlation analysis

clear;
clc;
close all;

codeDir = fileparts(mfilename("fullpath"));
addpath(genpath(codeDir));

C = config();
P = project_paths();

fprintf("\n=============================================\n");
fprintf("ELEC5305 Environmental Sound Project\n");
fprintf("Project root : %s\n", P.projectRoot);
fprintf("Dataset root : %s\n", P.datasetRoot);
fprintf("Results root : %s\n", P.resultsRoot);
fprintf("=============================================\n\n");

%% 1. Dataset inspection
if C.run.datasetInspection
    inspect_dataset();
end

%% 2. Clean official 10-fold benchmark
if C.run.cleanBenchmark
    cleanResults = run_clean_benchmark();
    save(fullfile(P.resultsRoot,"clean_results.mat"),"cleanResults","-v7.3");
end

%% Future experiments
% These modules can be connected here later without changing the clean
% benchmark implementation.
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
fprintf("Tables : %s\n",P.tableDir);
fprintf("Figures: %s\n",P.figureDir);
