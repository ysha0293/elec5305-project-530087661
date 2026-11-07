function inspect_dataset()
%INSPECT_DATASET Compact UrbanSound8K validation and report-ready summary.
%
% Default mode saves only dataset evidence useful in the report. Extended
% per-class waveform/spectrum/spectrogram/MFCC diagnostics can be enabled in
% config.m but are not required for the final robustness report.

P=project_paths(); C=config(); meta=load_urbansound8k_metadata(P);
fprintf("\n=== UrbanSound8K Dataset Inspection ===\n");
fprintf("Files   : %d\n",height(meta));
fprintf("Classes : %d\n",numel(unique(meta.classID)));
fprintf("Folds   : %d\n",numel(unique(meta.fold)));

classNames=unique(string(meta.class),"stable"); classCount=zeros(numel(classNames),1);
for i=1:numel(classNames), classCount(i)=nnz(string(meta.class)==classNames(i)); end
classTable=table(classNames,classCount,'VariableNames',{'Class','Count'});
writetable(classTable,fullfile(P.tableDir,"dataset_class_counts.csv"));
fig=figure('Visible','off'); bar(categorical(classNames),classCount); ylabel("Number of clips");
title("UrbanSound8K Class Distribution"); grid on; xtickangle(35);
exportgraphics(fig,fullfile(P.figureDir,"dataset_class_distribution.png"),"Resolution",200); close(fig);

foldNumber=(1:10)'; foldCount=arrayfun(@(f) nnz(meta.fold==f),foldNumber);
writetable(table(foldNumber,foldCount,'VariableNames',{'Fold','Count'}),fullfile(P.tableDir,"dataset_fold_counts.csv"));

n=height(meta); sampleRate=zeros(n,1); duration=zeros(n,1); channels=zeros(n,1);
for i=1:n
    info=audioinfo(meta.filePath(i)); sampleRate(i)=info.SampleRate; duration(i)=info.Duration; channels(i)=info.NumChannels;
    if mod(i,1000)==0 || i==n, fprintf("audioinfo: %d/%d\n",i,n); end
end

datasetSummary=table(height(meta),numel(unique(meta.classID)),numel(unique(meta.fold)), ...
    min(duration),max(duration),mean(duration),median(duration),nnz(channels==1),nnz(channels>1), ...
    'VariableNames',{'NumFiles','NumClasses','NumFolds','MinDuration_s','MaxDuration_s', ...
    'MeanDuration_s','MedianDuration_s','MonoFiles','MultiChannelFiles'});
writetable(datasetSummary,fullfile(P.tableDir,"dataset_summary.csv")); disp(datasetSummary);

if C.storage.saveExtendedDatasetInspection
    fileStats=table(string(meta.slice_file_name),meta.fold,string(meta.class),sampleRate,duration,channels, ...
        'VariableNames',{'File','Fold','Class','SampleRate_Hz','Duration_s','Channels'});
    writetable(fileStats,fullfile(P.workRobustnessDir,"dataset_file_statistics.csv"));
    % Optional diagnostics only; not part of compact report output.
end
fprintf("Dataset inspection complete.\n");
end
