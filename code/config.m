function C = config()
%CONFIG Single source of truth for the complete ELEC5305 experiment.
%
% HARD EXPERIMENTAL RULES (do not relax)
%   * UrbanSound8K official folds are never replaced by a random split.
%   * The downstream SVM is trained on CLEAN training folds only.
%   * Perturbations are applied ONLY to the held-out test recordings.
%   * MFCC and YAMNet consume the exact same perturbed waveform.
%   * All perturbation severities are fixed before evaluation.

%% Reproducibility
C.seed = 42;
C.rngAlgorithm = "twister";
C.targetFs = 16000;
C.cache.version = "v2.1-repro";
C.cache.robustnessVersion = "v3.0-final-robustness";

%% Stages
C.run.datasetInspection = true;
C.run.cleanBenchmark = true;
C.run.noise = true;
C.run.reverb = true;
C.run.channel = true;
C.run.finalAnalysis = true;

%% Storage policy
% Large feature matrices are working data, not report results.
% They live under project/work/ and are excluded from Git.
C.storage.keepPerturbedFeatureCachesAfterSuccess = false;
C.storage.keepCleanFeatureCaches = true;
C.storage.keepClipLevelPredictionFiles = false;
C.storage.keepClipLevelDistanceFiles = false;
C.storage.saveExtendedDatasetInspection = false;
C.storage.savePerFoldConfusionMatrices = false;
C.storage.savePerMethodRedundantPlots = false;

%% MFCC representation
C.mfcc.numCoeffs = 13;
C.mfcc.frameMs = 25;
C.mfcc.hopMs = 10;
C.mfcc.summaryStatistics = ["mean","std","median","q25","q75"];

%% Frozen YAMNet representation
C.yamnet.modelName = "yamnet";
C.yamnet.embeddingLayer = "global_average_pooling2d";
C.yamnet.embeddingDimension = 1024;
C.yamnet.autoDownload = true;
C.yamnet.downloadURL = "https://ssd.mathworks.com/supportfiles/audio/yamnet.zip";

%% Common downstream classifier
C.svm.kernel = "linear";
C.svm.boxConstraint = 1;
C.svm.coding = "onevsone";

%% Robustness protocol (must stay true)
C.robustness.trainOnCleanOnly = true;
C.robustness.samePerturbedWaveformForAllRepresentations = true;
C.robustness.useOfficialFoldsOnly = true;

%% Background-noise experiment
% Formal setting: unrelated EXTERNAL environmental-noise WAV files.
% Current project uses DEMAND OOFFICE 16 kHz ch01 as the fixed source.
C.noise.mode = "external";
C.noise.snrDb = [20 10 0];
C.noise.allowedExtensions = [".wav",".flac",".mp3",".m4a"];

%% Reverberation experiment
% Controlled deterministic synthetic RIRs with documented RT60 values.
C.reverb.labels = ["mild","moderate","strong"];
C.reverb.rt60Seconds = [0.20 0.50 0.80];
C.reverb.rirDurationSeconds = 1.00;
C.reverb.directToReverbDb = [12 8 4];

%% Channel / frequency-response experiment
% Increasingly restricted passbands at 16 kHz sampling rate.
C.channel.labels = ["mild","moderate","strong"];
C.channel.lowHz = [100 200 300];
C.channel.highHz = [7000 5000 3400];
C.channel.filterOrder = 8;

%% Representation-shift metrics
% Interpret distances WITHIN each representation only because scales differ.
C.shift.mfccMetric = "euclidean";
C.shift.yamnetMetric = "cosine";
end
