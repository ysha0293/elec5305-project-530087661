function inspect_dataset()
%INSPECT_DATASET Inspect UrbanSound8K before model training.
%
% Saves dataset statistics and representative waveform/spectrum/
% spectrogram/MFCC plots.

P = project_paths();
C = config();
meta = load_urbansound8k_metadata(P);

fprintf("\n=== UrbanSound8K Dataset Inspection ===\n");
fprintf("Files   : %d\n",height(meta));
fprintf("Classes : %d\n",numel(unique(meta.classID)));
fprintf("Folds   : %d\n",numel(unique(meta.fold)));

%% Class distribution
classNames = unique(string(meta.class),"stable");
classCount = zeros(numel(classNames),1);

for i=1:numel(classNames)
    classCount(i)=nnz(string(meta.class)==classNames(i));
end

classTable = table(classNames,classCount, ...
    'VariableNames',{'Class','Count'});
writetable(classTable,fullfile(P.tableDir,"dataset_class_counts.csv"));

fig=figure('Visible','off');
bar(categorical(classNames),classCount);
ylabel("Number of clips");
title("UrbanSound8K Class Distribution");
grid on;
xtickangle(35);
exportgraphics(fig,fullfile(P.figureDir, ...
    "dataset_class_distribution.png"),"Resolution",200);
close(fig);

%% Official fold distribution
foldNumber=(1:10)';
foldCount=zeros(10,1);

for f=1:10
    foldCount(f)=nnz(meta.fold==f);
end

foldTable=table(foldNumber,foldCount, ...
    'VariableNames',{'Fold','Count'});
writetable(foldTable,fullfile(P.tableDir,"dataset_fold_counts.csv"));

fig=figure('Visible','off');
bar(foldNumber,foldCount);
xlabel("Official fold");
ylabel("Number of clips");
title("UrbanSound8K Official Fold Distribution");
grid on;
exportgraphics(fig,fullfile(P.figureDir, ...
    "dataset_fold_distribution.png"),"Resolution",200);
close(fig);

%% Sample rate, duration, channels
n=height(meta);
sampleRate=zeros(n,1);
duration=zeros(n,1);
channels=zeros(n,1);

for i=1:n
    info=audioinfo(meta.filePath(i));
    sampleRate(i)=info.SampleRate;
    duration(i)=info.Duration;
    channels(i)=info.NumChannels;

    if mod(i,1000)==0 || i==n
        fprintf("audioinfo: %d/%d\n",i,n);
    end
end

fileStats=table( ...
    string(meta.slice_file_name), ...
    meta.fold, ...
    string(meta.class), ...
    sampleRate,duration,channels, ...
    'VariableNames',{'File','Fold','Class', ...
    'SampleRate_Hz','Duration_s','Channels'});
writetable(fileStats,fullfile(P.tableDir, ...
    "dataset_file_statistics.csv"));

datasetSummary=table( ...
    height(meta), ...
    numel(unique(meta.classID)), ...
    numel(unique(meta.fold)), ...
    min(duration),max(duration),mean(duration),median(duration), ...
    nnz(channels==1),nnz(channels>1), ...
    'VariableNames',{'NumFiles','NumClasses','NumFolds', ...
    'MinDuration_s','MaxDuration_s','MeanDuration_s','MedianDuration_s', ...
    'MonoFiles','MultiChannelFiles'});
writetable(datasetSummary,fullfile(P.tableDir,"dataset_summary.csv"));
disp(datasetSummary);

[uSR,~,idxSR]=unique(sampleRate);
srCounts=accumarray(idxSR,1);
srTable=table(uSR,srCounts, ...
    'VariableNames',{'SampleRate_Hz','Count'});
writetable(srTable,fullfile(P.tableDir,"dataset_sample_rate_counts.csv"));

fig=figure('Visible','off');
bar(categorical(string(uSR)),srCounts);
xlabel("Sample rate (Hz)");
ylabel("Number of clips");
title("Sample Rate Distribution");
grid on;
exportgraphics(fig,fullfile(P.figureDir, ...
    "dataset_sample_rate_distribution.png"),"Resolution",200);
close(fig);

fig=figure('Visible','off');
histogram(duration,20);
xlabel("Duration (s)");
ylabel("Number of clips");
title("Audio Duration Distribution");
grid on;
exportgraphics(fig,fullfile(P.figureDir, ...
    "dataset_duration_distribution.png"),"Resolution",200);
close(fig);

channelNames=["Mono";"Multi-channel"];
channelCounts=[nnz(channels==1);nnz(channels>1)];
channelTable=table(channelNames,channelCounts, ...
    'VariableNames',{'Type','Count'});
writetable(channelTable,fullfile(P.tableDir,"dataset_channel_counts.csv"));

fig=figure('Visible','off');
bar(categorical(channelNames),channelCounts);
ylabel("Number of clips");
title("Channel Configuration");
grid on;
exportgraphics(fig,fullfile(P.figureDir, ...
    "dataset_channel_distribution.png"),"Resolution",200);
close(fig);

%% Representative signal-processing examples: one clip from each class
for c=1:numel(classNames)

    idx=find(string(meta.class)==classNames(c),1,"first");

    [x,fs]=audioread(meta.filePath(idx));
    x=preprocess_audio(x,fs,C.targetFs);

    safeName=regexprep(classNames(c),'[^A-Za-z0-9]+','_');
    t=(0:numel(x)-1)'/C.targetFs;

    % Waveform
    fig=figure('Visible','off');
    plot(t,x);
    xlabel("Time (s)");
    ylabel("Amplitude");
    title(classNames(c)+" - Waveform");
    grid on;
    exportgraphics(fig,fullfile(P.figureDir, ...
        safeName+"_waveform.png"),"Resolution",200);
    close(fig);

    % Magnitude spectrum
    N=numel(x);
    X=abs(fft(x));
    nHalf=floor(N/2)+1;
    f=(0:nHalf-1)'*C.targetFs/N;

    fig=figure('Visible','off');
    plot(f,X(1:nHalf));
    xlim([0 C.targetFs/2]);
    xlabel("Frequency (Hz)");
    ylabel("Magnitude");
    title(classNames(c)+" - Magnitude Spectrum");
    grid on;
    exportgraphics(fig,fullfile(P.figureDir, ...
        safeName+"_spectrum.png"),"Resolution",200);
    close(fig);

    % Spectrogram
    fig=figure('Visible','off');
    spectrogram(x,hann(512,"periodic"),256,512,C.targetFs,"yaxis");
    title(classNames(c)+" - Spectrogram");
    exportgraphics(fig,fullfile(P.figureDir, ...
        safeName+"_spectrogram.png"),"Resolution",200);
    close(fig);

    % MFCC map
    winLength=round(C.mfcc.frameMs/1000*C.targetFs);
    hopLength=round(C.mfcc.hopMs/1000*C.targetFs);
    overlapLength=winLength-hopLength;

    M=mfcc(x,C.targetFs, ...
        "Window",hann(winLength,"periodic"), ...
        "OverlapLength",overlapLength, ...
        "NumCoeffs",C.mfcc.numCoeffs);

    fig=figure('Visible','off');
    imagesc(M');
    axis xy;
    xlabel("Frame");
    ylabel("MFCC coefficient");
    title(classNames(c)+" - MFCC");
    colorbar;
    exportgraphics(fig,fullfile(P.figureDir, ...
        safeName+"_mfcc.png"),"Resolution",200);
    close(fig);
end

fprintf("Dataset inspection complete.\n");
end
