function migrate_legacy_working_files()
%MIGRATE_LEGACY_WORKING_FILES Reuse caches from the previous final version.
% Moves large cache files out of results/cache into work/cache without
% changing their contents or experimental meaning.
P=project_paths();
legacy=fullfile(P.resultsRoot,"cache");
if ~isfolder(legacy), return; end
D=dir(fullfile(legacy,"*.mat"));
for k=1:numel(D)
    src=fullfile(D(k).folder,D(k).name); dst=fullfile(P.cacheDir,D(k).name);
    if ~isfile(dst)
        try
            movefile(src,dst);
        catch
            copyfile(src,dst);
        end
    end
end
try
    if isempty(dir(fullfile(legacy,"*.*"))) || numel(dir(legacy))<=2, rmdir(legacy); end
catch
end
end
