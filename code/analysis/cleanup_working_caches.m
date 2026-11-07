function cleanup_working_caches()
%CLEANUP_WORKING_CACHES Remove large perturbation caches after a successful run.
C=config(); P=project_paths();
if C.storage.keepPerturbedFeatureCachesAfterSuccess, return; end
D=dir(fullfile(P.cacheDir,"perturbed_*.mat"));
for k=1:numel(D)
    delete(fullfile(D(k).folder,D(k).name));
end
if isfolder(P.workRobustnessDir)
    files=dir(fullfile(P.workRobustnessDir,"*"));
    for k=1:numel(files)
        if ~files(k).isdir, delete(fullfile(files(k).folder,files(k).name)); end
    end
end
fprintf("Large perturbation working caches removed after successful audit.\n");
end
