function files = list_environmental_noise_files(P)
%LIST_ENVIRONMENTAL_NOISE_FILES Return the formal external noise bank.
C = config();
files = strings(0,1);
for ext = C.noise.allowedExtensions
    D = dir(fullfile(P.noiseDir,"*"+ext));
    for k = 1:numel(D)
        files(end+1,1) = string(fullfile(D(k).folder,D(k).name)); %#ok<AGROW>
    end
end
files = sort(unique(files));

if C.noise.mode == "external" && isempty(files)
    error(["No external environmental-noise recordings were found in:\n  %s\n" + ...
        "For the formal experiment, add one or more unrelated environmental-noise audio files there. " + ...
        "The code intentionally does not substitute UrbanSound8K clips, because that would confound the evaluation dataset with the perturbation source."],P.noiseDir);
end
end
