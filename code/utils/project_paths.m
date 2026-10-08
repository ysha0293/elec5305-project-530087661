function P = project_paths()
%PROJECT_PATHS Portable project-relative paths.
%
% Required structure:
%
% project/
%   code/
%   UrbanSound8K/
%       audio/
%       metadata/UrbanSound8K.csv
%
% Generated folders:
%   models/              local pretrained model files (not for Git)
%   results/
%       tables/
%       figures/
%       cache/
%       reproducibility/
%       robustness/
%       representation/
%
% No absolute /Users/... or Windows drive path is stored in the code.

thisFile = mfilename("fullpath");
utilsDir = fileparts(thisFile);
codeDir = fileparts(utilsDir);
projectRoot = fileparts(codeDir);

P.projectRoot = projectRoot;
P.codeDir = codeDir;

P.datasetRoot = fullfile(projectRoot,"UrbanSound8K");
P.audioRoot = fullfile(P.datasetRoot,"audio");
P.metadataFile = fullfile(P.datasetRoot,"metadata","UrbanSound8K.csv");

P.modelsDir = fullfile(projectRoot,"models");
P.yamnetDir = fullfile(P.modelsDir,"yamnet");

P.resultsRoot = fullfile(projectRoot,"results");
P.tableDir = fullfile(P.resultsRoot,"tables");
P.figureDir = fullfile(P.resultsRoot,"figures");
P.cacheDir = fullfile(P.resultsRoot,"cache");
P.reproDir = fullfile(P.resultsRoot,"reproducibility");
P.robustnessDir = fullfile(P.resultsRoot,"robustness");
P.representationDir = fullfile(P.resultsRoot,"representation");

requiredDirs = { ...
    P.modelsDir, ...
    P.resultsRoot,P.tableDir,P.figureDir,P.cacheDir, ...
    P.reproDir,P.robustnessDir,P.representationDir};

for i = 1:numel(requiredDirs)
    if ~isfolder(requiredDirs{i})
        mkdir(requiredDirs{i});
    end
end

assert(isfolder(P.datasetRoot), ...
    "UrbanSound8K folder not found: %s",P.datasetRoot);
assert(isfolder(P.audioRoot), ...
    "UrbanSound8K audio folder not found: %s",P.audioRoot);
assert(isfile(P.metadataFile), ...
    "UrbanSound8K.csv not found: %s",P.metadataFile);
end
