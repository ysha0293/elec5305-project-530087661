function prune_legacy_result_files()
%PRUNE_LEGACY_RESULT_FILES Remove old non-report outputs after audit success.
% Never runs before the integrity audit. Core report tables/figures are kept.
P=project_paths();

% Old per-condition clip-level and redundant confusion outputs.
patterns={ ...
    fullfile(P.robustnessDir,"**","*_heldout_predictions.csv"), ...
    fullfile(P.robustnessDir,"**","*_aggregate_confusion.csv"), ...
    fullfile(P.robustnessDir,"**","*_aggregate_confusion.png"), ...
    fullfile(P.robustnessDir,"**","perturbation_manifest.csv"), ...
    fullfile(P.representationDir,"*_distances.csv"), ...
    fullfile(P.representationDir,"all_clip_distances.csv"), ...
    fullfile(P.tableDir,"*_fold??_confusion.csv"), ...
    fullfile(P.figureDir,"*_fold??_confusion.png")};
for p=1:numel(patterns)
    D=dir(patterns{p});
    for k=1:numel(D), if ~D(k).isdir, delete(fullfile(D(k).folder,D(k).name)); end, end
end

% Redundant clean figures from older verbose versions.
oldFigures=["mfcc_accuracy_by_fold.png","mfcc_macro_f1_by_fold.png","mfcc_per_class_recall.png", ...
    "mfcc_per_class_f1.png","yamnet_accuracy_by_fold.png","yamnet_macro_f1_by_fold.png", ...
    "yamnet_per_class_recall.png","yamnet_per_class_f1.png","dataset_fold_distribution.png", ...
    "dataset_sample_rate_distribution.png","dataset_duration_distribution.png","dataset_channel_distribution.png"];
for f=oldFigures
    path=fullfile(P.figureDir,f); if isfile(path), delete(path); end
end

% Old per-class diagnostic figures (final report keeps selected signal examples only).
classes=["air_conditioner","car_horn","children_playing","dog_bark","drilling", ...
    "engine_idling","gun_shot","jackhammer","siren","street_music"];
suffixes=["waveform","spectrum","spectrogram","mfcc"];
for c=classes
    for s=suffixes
        path=fullfile(P.figureDir,c+"_"+s+".png"); if isfile(path), delete(path); end
    end
end

% Old bulky/diagnostic tables not required for final report.
oldTables=["dataset_file_statistics.csv","dataset_sample_rate_counts.csv","dataset_channel_counts.csv", ...
    "mfcc_heldout_predictions.csv","yamnet_heldout_predictions.csv"];
for f=oldTables
    path=fullfile(P.tableDir,f); if isfile(path), delete(path); end
end

% Old MAT artifacts in results; working MAT files belong under work/.
oldRoot=["clean_results.mat","final_analysis.mat"];
for f=oldRoot
    path=fullfile(P.resultsRoot,f); if isfile(path), delete(path); end
end
oldRepro=["experiment_manifest.mat","integrity_audit.mat"];
for f=oldRepro
    path=fullfile(P.reproDir,f); if isfile(path), delete(path); end
end

legacyCache=fullfile(P.resultsRoot,"cache");
if isfolder(legacyCache)
    try, rmdir(legacyCache,"s"); catch, end
end
fprintf("Legacy non-report result files pruned. results/ now contains compact report outputs.\n");
end
