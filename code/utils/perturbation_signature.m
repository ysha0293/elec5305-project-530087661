function sig = perturbation_signature(family,severityIndex,P)
%PERTURBATION_SIGNATURE Exact condition identity for cache invalidation.
C=config(); family=lower(string(family));
parts=["version="+C.cache.robustnessVersion,"family="+family,"index="+string(severityIndex)];

switch family
    case "noise"
        parts(end+1)="snr="+string(C.noise.snrDb(severityIndex));
        files=list_environmental_noise_files(P);
        for i=1:numel(files)
            [~,name,ext]=fileparts(files(i));
            parts(end+1)=string(name)+string(ext)+":"+file_sha256(files(i)); %#ok<AGROW>
        end
    case "reverb"
        parts(end+1)="rt60="+string(C.reverb.rt60Seconds(severityIndex));
        parts(end+1)="duration="+string(C.reverb.rirDurationSeconds);
        parts(end+1)="drr="+string(C.reverb.directToReverbDb(severityIndex));
    case "channel"
        parts(end+1)="low="+string(C.channel.lowHz(severityIndex));
        parts(end+1)="high="+string(C.channel.highHz(severityIndex));
        parts(end+1)="order="+string(C.channel.filterOrder);
    otherwise
        error("Unknown perturbation family: %s",family);
end
sig=strjoin(parts,"|");
end
