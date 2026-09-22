function C = config()
%CONFIG Central experiment configuration.
%
% Future experiments should read their settings from this file so that all
% parameters remain reproducible and consistent.

C.seed = 42;
C.targetFs = 16000;

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

%% Downstream classifier
% Same simple classifier is used for MFCC and YAMNet where practical.
C.svm.kernel = "linear";
C.svm.boxConstraint = 1;

%% Future robustness settings
C.noise.snrDb = [20 10 0];

% These severity labels are placeholders for the later controlled
% reverberation/channel experiments. Exact physical parameters can be set
% when those experiments are implemented.
C.reverb.levels = ["mild","moderate","strong"];
C.channel.levels = ["mild","moderate","strong"];
end
