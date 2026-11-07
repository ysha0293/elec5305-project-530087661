%% ELEC5305 Final Project - Compact Reproducible Pipeline
% MFCCs versus Pretrained Audio Embeddings:
% Robustness of Environmental Sound Classification
%
% results/ = compact report-ready outputs only
% work/    = large intermediate/reusable caches 

clear; clc; close all;
codeDir=fileparts(mfilename("fullpath")); addpath(genpath(codeDir));
C=config(); P=project_paths(); rng(C.seed,C.rngAlgorithm);

fprintf("\n=============================================\n");
fprintf("ELEC5305 COMPLETE ROBUSTNESS PIPELINE\n");
fprintf("Project root : %s\n",P.projectRoot);
fprintf("Dataset root : %s\n",P.datasetRoot);
fprintf("Seed         : %d (%s)\n",C.seed,C.rngAlgorithm);
fprintf("=============================================\n\n");

migrate_legacy_working_files();
write_reproducibility_manifest();
if C.run.datasetInspection, inspect_dataset(); end

%% Clean benchmark
% New compact location is work/clean_results.mat. For backward compatibility,
% an existing results/clean_results.mat from the previous version is accepted.
cleanFile=P.cleanWorkFile;
legacyCleanFile=fullfile(P.resultsRoot,"clean_results.mat");
requiredCleanTables=["mfcc_summary.csv","yamnet_summary.csv","mfcc_per_class_metrics.csv","yamnet_per_class_metrics.csv"];
cleanReady=isfile(cleanFile) || isfile(legacyCleanFile);
for k=1:numel(requiredCleanTables), cleanReady=cleanReady && isfile(fullfile(P.tableDir,requiredCleanTables(k))); end

if C.run.cleanBenchmark && ~cleanReady
    cleanResults=run_clean_benchmark();
    save(cleanFile,"cleanResults","C","-v7.3");
elseif cleanReady
    if ~isfile(cleanFile) && isfile(legacyCleanFile)
        S=load(legacyCleanFile,"cleanResults","C");
        save(cleanFile,"-struct","S","-v7.3");
    end
    fprintf("Clean benchmark already exists; reusing completed official 10-fold results.\n");
else
    error("Clean benchmark results are missing. Enable C.run.cleanBenchmark in config.m.");
end

%% Formal robustness experiments
noiseResults=[]; reverbResults=[]; channelResults=[];
if C.run.noise, noiseResults=run_noise_experiments(); end
if C.run.reverb, reverbResults=run_reverb_experiments(); end
if C.run.channel, channelResults=run_channel_experiments(); end

%% Final analysis + audit + safe cleanup
if C.run.finalAnalysis
    assert(~isempty(noiseResults) && ~isempty(reverbResults) && ~isempty(channelResults), ...
        "Final analysis requires all three robustness families in the same run.");
    finalAnalysis=run_final_analysis(noiseResults,reverbResults,channelResults); 
    integrityReport=audit_experiment_integrity(noiseResults,reverbResults,channelResults); 
    cleanup_working_caches();
    prune_legacy_result_files();
end

write_reproducibility_manifest();

fprintf("\n=============================================\n");
fprintf("COMPLETE. Compact report outputs:\n");
fprintf("Tables        : %s\n",P.tableDir);
fprintf("Figures       : %s\n",P.figureDir);
fprintf("Robustness    : %s\n",P.robustnessDir);
fprintf("Representation: %s\n",P.representationDir);
fprintf("Audit/manifest: %s\n",P.reproDir);
fprintf("Working cache : %s (not for submission)\n",P.workDir);
fprintf("=============================================\n");
