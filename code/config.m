function C = config()
%CONFIG Central experiment configuration.
%
% All experiment parameters are kept here so the clean benchmark and all
% later robustness experiments use one reproducible source of truth.

%% Reproducibility
C.seed = 42;
C.rngAlgorithm = "twister";
C.targetFs = 16000;
C.cache.version = "v2.1-repro";

%% Current experiment switches
C.run.datasetInspection = true;
C.run.cleanBenchmark = true;

%% Future experiment switches
C.run.noise = false;
C.run.reverb = false;
C.run.channel = false;
C.run.representationShift = false;

%% MFCC settings
C.mfcc.numCoeffs = 13;
C.mfcc.frameMs = 25;
C.mfcc.hopMs = 10;
C.mfcc.summaryStatistics = ["mean","std","median","q25","q75"];

%% YAMNet settings
% The model is loaded as a frozen pretrained feature extractor.
C.yamnet.modelName = "yamnet";
C.yamnet.embeddingLayer = "global_average_pooling2d";
C.yamnet.embeddingDimension = 1024;
C.yamnet.autoDownload = true;
C.yamnet.downloadURL = "https://ssd.mathworks.com/supportfiles/audio/yamnet.zip";

%% Downstream classifier
% The same simple classifier is used for MFCC and YAMNet where practical.
C.svm.kernel = "linear";
C.svm.boxConstraint = 1;
C.svm.coding = "onevsone";

%% Future robustness settings
C.noise.snrDb = [20 10 0];

% Exact physical values are intentionally left as future experiment
% settings. The labels provide the planned controlled severity structure.
C.reverb.levels = ["mild","moderate","strong"];
C.channel.levels = ["mild","moderate","strong"];

% Future robustness experiments must always follow:
% clean training folds -> perturbed held-out test fold.
C.robustness.trainOnCleanOnly = true;
C.robustness.samePerturbedWaveformForAllRepresentations = true;
end
