function [XmfccPert,XyamPert,perturbationTable] = build_perturbed_condition_cache(meta,family,severityIndex,P)
%BUILD_PERTURBED_CONDITION_CACHE Generate one controlled condition once.
%
% raw -> common preprocessing ONCE -> perturb ONCE -> SAME waveform ->
% MFCC and frozen YAMNet. Large matrices are working caches under work/.

C=config(); family=lower(string(family)); clipID=string(meta.slice_file_name);

switch family
    case "noise"
        severity=string(C.noise.snrDb(severityIndex))+"dB";
        parameterValue=C.noise.snrDb(severityIndex); parameterName="SNRdB";
        noiseFiles=list_environmental_noise_files(P); rir=[];
    case "reverb"
        severity=C.reverb.labels(severityIndex);
        parameterValue=C.reverb.rt60Seconds(severityIndex); parameterName="RT60Seconds";
        noiseFiles=strings(0,1);
        rirSeed=make_condition_seed(C.seed,0,2000+severityIndex);
        rir=build_synthetic_rir(C.targetFs,C.reverb.rt60Seconds(severityIndex), ...
            C.reverb.rirDurationSeconds,C.reverb.directToReverbDb(severityIndex),rirSeed);
    case "channel"
        severity=C.channel.labels(severityIndex);
        parameterValue=C.channel.highHz(severityIndex); parameterName="HighCutHz";
        noiseFiles=strings(0,1); rir=[];
    otherwise
        error("Unknown perturbation family: %s",family);
end

signature=perturbation_signature(family,severityIndex,P);
familyTag=regexprep(family,"[^a-z0-9]+","_");
severityTag=regexprep(lower(severity),"[^a-z0-9]+","_");
cacheFile=fullfile(P.cacheDir,"perturbed_"+familyTag+"_"+severityTag+".mat");

if isfile(cacheFile)
    S=load(cacheFile);
    if all(isfield(S,{"XmfccPert","XyamPert","perturbationTable","cacheInfo"})) && ...
            string(S.cacheInfo.version)==C.cache.robustnessVersion && ...
            string(S.cacheInfo.signature)==signature && isequal(string(S.cacheInfo.clipID),clipID)
        XmfccPert=S.XmfccPert; XyamPert=S.XyamPert; perturbationTable=S.perturbationTable;
        fprintf("Loaded working perturbed cache: %s / %s\n",family,severity);
        return;
    end
end

fprintf("\nGenerating condition: %s / %s\n",upper(family),severity);
[net,~,~]=load_yamnet_model(); n=height(meta);
probeM=extract_mfcc_features(zeros(C.targetFs,1),C.targetFs,true);
XmfccPert=zeros(n,numel(probeM),'single');
XyamPert=zeros(n,2*C.yamnet.embeddingDimension,'single');
Seed=zeros(n,1); AuxiliaryFile=strings(n,1); AuxiliaryStart=zeros(n,1);
TargetValue=repmat(double(parameterValue),n,1); AchievedValue=nan(n,1);

for i=1:n
    [x,fs]=audioread(meta.filePath(i));
    xClean=preprocess_audio(x,fs,C.targetFs);
    seed=make_condition_seed(C.seed,i,1000*severityIndex+family_seed_offset(family)); Seed(i)=seed;

    switch family
        case "noise"
            fileIndex=1+mod(round(seed)-1,numel(noiseFiles)); noiseFile=noiseFiles(fileIndex);
            [xp,info]=add_environmental_noise_snr(xClean,C.targetFs,noiseFile,parameterValue,seed);
            AuxiliaryFile(i)=noiseFile; AuxiliaryStart(i)=info.startIndex; AchievedValue(i)=info.achievedSNRdB;
        case "reverb"
            xp=apply_reverb(xClean,rir); AuxiliaryFile(i)="synthetic_fixed_RIR";
            AchievedValue(i)=parameterValue;
        case "channel"
            lowHz=C.channel.lowHz(severityIndex); highHz=C.channel.highHz(severityIndex);
            xp=apply_channel_filter(xClean,C.targetFs,lowHz,highHz,C.channel.filterOrder);
            AuxiliaryFile(i)=sprintf("bandpass_%d_%d_Hz",round(lowHz),round(highHz)); AchievedValue(i)=highHz;
    end

    % CRITICAL FAIRNESS CONTROL: exact same xp feeds both representations.
    XmfccPert(i,:)=single(extract_mfcc_features(xp,C.targetFs,true));
    XyamPert(i,:)=single(extract_yamnet_features(xp,C.targetFs,net,true));
    if mod(i,100)==0 || i==n, fprintf("%s %s: %d/%d\n",upper(family),severity,i,n); end
end

perturbationTable=table(clipID,meta.fold,string(meta.class),repmat(family,n,1), ...
    repmat(severity,n,1),Seed,repmat(string(parameterName),n,1),TargetValue,AchievedValue, ...
    AuxiliaryFile,AuxiliaryStart,'VariableNames',{'ClipID','Fold','Class','Perturbation','Severity','Seed', ...
    'ParameterName','TargetValue','AchievedValue','AuxiliaryFile','AuxiliaryStart'});

cacheInfo=struct('version',C.cache.robustnessVersion,'family',family,'severity',severity, ...
    'clipID',clipID,'parameterName',parameterName,'parameterValue',parameterValue, ...
    'generatedWithSameWaveform',true,'signature',signature);
save(cacheFile,"XmfccPert","XyamPert","perturbationTable","cacheInfo","-v7.3");
end

function offset=family_seed_offset(family)
switch family
    case "noise", offset=10000;
    case "reverb", offset=20000;
    case "channel", offset=30000;
    otherwise, offset=40000;
end
end
