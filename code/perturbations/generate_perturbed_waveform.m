function [xClean,xPert,severity,info] = generate_perturbed_waveform(meta,rowIndex,family,severityIndex,P)
%GENERATE_PERTURBED_WAVEFORM Recreate exactly one formal perturbation.
% Used by diagnostic figures to ensure they match the feature-cache logic.

C=config(); family=lower(string(family));
[x,fs]=audioread(meta.filePath(rowIndex));
xClean=preprocess_audio(x,fs,C.targetFs);
seed=make_condition_seed(C.seed,rowIndex,1000*severityIndex + family_seed_offset_local(family));
info=struct(); info.seed=seed;

switch family
    case "noise"
        severity=string(C.noise.snrDb(severityIndex))+"dB";
        noiseFiles=list_environmental_noise_files(P);
        fileIndex=1+mod(round(seed)-1,numel(noiseFiles));
        [xPert,nInfo]=add_environmental_noise_snr(xClean,C.targetFs,noiseFiles(fileIndex),C.noise.snrDb(severityIndex),seed);
        info.noise=nInfo;
    case "reverb"
        severity=C.reverb.labels(severityIndex);
        rirSeed=make_condition_seed(C.seed,0,2000+severityIndex);
        rir=build_synthetic_rir(C.targetFs,C.reverb.rt60Seconds(severityIndex), ...
            C.reverb.rirDurationSeconds,C.reverb.directToReverbDb(severityIndex),rirSeed);
        xPert=apply_reverb(xClean,rir);
        info.rt60Seconds=C.reverb.rt60Seconds(severityIndex);
    case "channel"
        severity=C.channel.labels(severityIndex);
        xPert=apply_channel_filter(xClean,C.targetFs,C.channel.lowHz(severityIndex), ...
            C.channel.highHz(severityIndex),C.channel.filterOrder);
        info.lowHz=C.channel.lowHz(severityIndex); info.highHz=C.channel.highHz(severityIndex);
    otherwise
        error("Unknown perturbation family: %s",family);
end
end

function offset=family_seed_offset_local(family)
switch family
    case "noise", offset=10000;
    case "reverb", offset=20000;
    case "channel", offset=30000;
    otherwise, offset=40000;
end
end
