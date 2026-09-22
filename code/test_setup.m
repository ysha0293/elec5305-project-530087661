%% TEST_SETUP
% Run this before main.m to verify paths, dataset, and MATLAB support.

clear;
clc;

codeDir = fileparts(mfilename("fullpath"));
addpath(genpath(codeDir));

P = project_paths();
meta = load_urbansound8k_metadata(P);

fprintf("\n=== Project Setup Check ===\n");
fprintf("Project root   : %s\n",P.projectRoot);
fprintf("Dataset root   : %s\n",P.datasetRoot);
fprintf("Metadata rows  : %d\n",height(meta));
fprintf("Classes        : %d\n",numel(unique(meta.classID)));
fprintf("Official folds : %d\n",numel(unique(meta.fold)));

assert(height(meta)==8732, ...
    "Expected 8732 UrbanSound8K metadata rows.");
assert(numel(unique(meta.classID))==10, ...
    "Expected 10 UrbanSound8K classes.");
assert(numel(unique(meta.fold))==10, ...
    "Expected 10 official folds.");

fprintf("\nRequired functions:\n");
fprintf("mfcc                    : %d\n",exist("mfcc","file")==2);
fprintf("resample                : %d\n",exist("resample","file")==2);
fprintf("fitcecoc                : %d\n",exist("fitcecoc","file")==2);
fprintf("audioPretrainedNetwork : %d\n",exist("audioPretrainedNetwork","file")==2);
fprintf("yamnetPreprocess        : %d\n",exist("yamnetPreprocess","file")==2);

assert(exist("mfcc","file")==2, ...
    "mfcc is unavailable. Check Audio Toolbox.");
assert(exist("fitcecoc","file")==2, ...
    "fitcecoc is unavailable. Check Statistics and Machine Learning Toolbox.");
assert(exist("audioPretrainedNetwork","file")==2, ...
    "audioPretrainedNetwork is unavailable.");
assert(exist("yamnetPreprocess","file")==2, ...
    "yamnetPreprocess is unavailable.");

fprintf("\nAttempting to load YAMNet...\n");
try
    [net,classes] = audioPretrainedNetwork("yamnet"); %#ok<ASGLU>
    fprintf("YAMNet loaded successfully (%d AudioSet classes).\n",numel(classes));
catch ME
    fprintf(2,"YAMNet could not be loaded:\n%s\n",ME.message);
    fprintf(2,"Install/download the YAMNet support model before running main.m.\n");
    rethrow(ME);
end

fprintf("\nSetup check passed.\n");
