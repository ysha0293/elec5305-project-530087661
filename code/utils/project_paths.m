function P = project_paths()
%PROJECT_PATHS Portable project-relative paths.
%
% Final/report outputs are written only to project/results/.
% Large reusable/intermediate arrays are written to project/work/.

thisFile = mfilename("fullpath");
utilsDir = fileparts(thisFile);
codeDir = fileparts(utilsDir);
projectRoot = fileparts(codeDir);

P.projectRoot = projectRoot;
P.codeDir = codeDir;

candidate1 = fullfile(projectRoot,"UrbanSound8K");
candidate2 = fullfile(fileparts(projectRoot),"UrbanSound8K");
if isfolder(candidate1)
    P.datasetRoot = candidate1;
elseif isfolder(candidate2)
    P.datasetRoot = candidate2;
else
    error("UrbanSound8K dataset not found. Place UrbanSound8K either inside the project root or one directory above it.");
end

P.audioRoot = fullfile(P.datasetRoot,"audio");
P.metadataFile = fullfile(P.datasetRoot,"metadata","UrbanSound8K.csv");

P.assetsDir = fullfile(projectRoot,"assets");
P.noiseDir = fullfile(P.assetsDir,"noise");
P.noiseSourcesFile = fullfile(P.noiseDir,"SOURCES.csv");
P.modelsDir = fullfile(projectRoot,"models");
P.yamnetDir = fullfile(P.modelsDir,"yamnet");

% Small, report-facing outputs only.
P.resultsRoot = fullfile(projectRoot,"results");
P.tableDir = fullfile(P.resultsRoot,"tables");
P.figureDir = fullfile(P.resultsRoot,"figures");
P.reproDir = fullfile(P.resultsRoot,"reproducibility");
P.robustnessDir = fullfile(P.resultsRoot,"robustness");
P.representationDir = fullfile(P.resultsRoot,"representation");

% Large/intermediate data. Safe to exclude from Git and delete after success.
P.workDir = fullfile(projectRoot,"work");
P.cacheDir = fullfile(P.workDir,"cache");
P.workRobustnessDir = fullfile(P.workDir,"robustness_temp");
P.cleanWorkFile = fullfile(P.workDir,"clean_results.mat");

requiredDirs = {P.assetsDir,P.noiseDir,P.modelsDir,P.resultsRoot, ...
    P.tableDir,P.figureDir,P.reproDir,P.robustnessDir,P.representationDir, ...
    P.workDir,P.cacheDir,P.workRobustnessDir};
for i = 1:numel(requiredDirs)
    if ~isfolder(requiredDirs{i}), mkdir(requiredDirs{i}); end
end

assert(isfolder(P.audioRoot),"UrbanSound8K audio folder not found: %s",P.audioRoot);
assert(isfile(P.metadataFile),"UrbanSound8K.csv not found: %s",P.metadataFile);
end
