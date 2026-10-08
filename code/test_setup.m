%% TEST_SETUP
% Run this before main.m to verify paths, dataset, MATLAB support and YAMNet.
% If YAMNet is absent, the helper automatically downloads the official
% pretrained model once into project/models/yamnet.

clear;
clc;

codeDir = fileparts(mfilename("fullpath"));
addpath(genpath(codeDir));

C = config();
P = project_paths();
meta = load_urbansound8k_metadata(P);

fprintf("\n=== Project Setup Check ===\n");
fprintf("Project root   : %s\n",P.projectRoot);
fprintf("Dataset root   : %s\n",P.datasetRoot);
fprintf("Metadata rows  : %d\n",height(meta));
fprintf("Classes        : %d\n",numel(unique(meta.classID)));
fprintf("Official folds : %d\n",numel(unique(meta.fold)));
fprintf("Seed           : %d (%s)\n",C.seed,C.rngAlgorithm);

assert(height(meta)==8732, ...
    "Expected 8732 UrbanSound8K metadata rows.");
assert(numel(unique(meta.classID))==10, ...
    "Expected 10 UrbanSound8K classes.");
assert(numel(unique(meta.fold))==10, ...
    "Expected 10 official folds.");
assert(numel(unique(string(meta.slice_file_name)))==height(meta), ...
    "Expected UrbanSound8K slice_file_name values to be unique.");

fprintf("\nRequired functions:\n");
fprintf("mfcc                    : %d\n",exist("mfcc","file")==2);
fprintf("resample                : %d\n",exist("resample","file")==2);
fprintf("fitcecoc                : %d\n",exist("fitcecoc","file")==2);
fprintf("audioPretrainedNetwork : %d\n",exist("audioPretrainedNetwork","file")==2);
fprintf("yamnetPreprocess        : %d\n",exist("yamnetPreprocess","file")==2);

assert(exist("mfcc","file")==2, ...
    "mfcc is unavailable. Check Audio Toolbox.");
assert(exist("resample","file")==2, ...
    "resample is unavailable. Check Signal Processing Toolbox.");
assert(exist("fitcecoc","file")==2, ...
    "fitcecoc is unavailable. Check Statistics and Machine Learning Toolbox.");
assert(exist("audioPretrainedNetwork","file")==2, ...
    "audioPretrainedNetwork is unavailable. Check Audio Toolbox / Deep Learning Toolbox.");
assert(exist("yamnetPreprocess","file")==2, ...
    "yamnetPreprocess is unavailable. Check Audio Toolbox.");

fprintf("\nChecking pretrained YAMNet...\n");
[net,classes,info] = load_yamnet_model(); %#ok<ASGLU>
fprintf("YAMNet loaded successfully (%d AudioSet classes).\n",numel(classes));
fprintf("YAMNet source: %s\n",info.source);

write_reproducibility_manifest();

fprintf("\nSetup check passed.\n");
