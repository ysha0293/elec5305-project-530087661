function meta = load_urbansound8k_metadata(P)
%LOAD_URBANSOUND8K_METADATA Load official metadata and audio paths.

opts = detectImportOptions(P.metadataFile,"VariableNamingRule","preserve");
meta = readtable(P.metadataFile,opts);

required = ["slice_file_name","fold","classID","class"];
missing = required(~ismember(required,string(meta.Properties.VariableNames)));

assert(isempty(missing), ...
    "Missing metadata columns: %s",strjoin(missing,", "));

n = height(meta);
filePath = strings(n,1);

for i = 1:n
    filePath(i) = fullfile( ...
        P.audioRoot, ...
        "fold"+string(meta.fold(i)), ...
        string(meta.slice_file_name(i)));
end

meta.filePath = filePath;

assert(all(isfile(meta.filePath)), ...
    "Some audio files referenced by the metadata are missing.");

meta.label = categorical(string(meta.class));
end
