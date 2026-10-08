function [net,classes,info] = load_yamnet_model()
%LOAD_YAMNET_MODEL Load YAMNet, downloading it once when necessary.
%
% Behaviour:
%   1) If YAMNet is already available on the MATLAB path, load it directly.
%   2) Otherwise, if a project-local copy exists in models/yamnet, add it
%      to the path and load it.
%   3) Otherwise, download the official MathWorks YAMNet archive, unzip it
%      into models/, add models/yamnet to the path, and load it.
%
% This keeps the project portable while avoiding repeated downloads.

C = config();
P = project_paths();

assert(exist("audioPretrainedNetwork","file")==2, ...
    "audioPretrainedNetwork is unavailable. Check Audio Toolbox / Deep Learning Toolbox.");
assert(exist("yamnetPreprocess","file")==2, ...
    "yamnetPreprocess is unavailable. Check Audio Toolbox.");

info = struct();
info.modelName = C.yamnet.modelName;
info.downloadURL = C.yamnet.downloadURL;
info.source = "";
info.localModelDir = P.yamnetDir;

% First try the current MATLAB path. This is the fastest path when the
% network is already installed.
try
    [net,classes] = audioPretrainedNetwork(C.yamnet.modelName);
    info.source = "existing MATLAB path";
    return;
catch firstError
    firstMessage = firstError.message;
end

% Then try a previously downloaded project-local copy.
if isfolder(P.yamnetDir)
    addpath(P.yamnetDir);
    try
        [net,classes] = audioPretrainedNetwork(C.yamnet.modelName);
        info.source = "project-local models/yamnet";
        return;
    catch
        % Continue to the controlled download step below.
    end
end

if ~C.yamnet.autoDownload
    error("YAMNet is not available and automatic download is disabled.\nOriginal error:\n%s", ...
        firstMessage);
end

fprintf("YAMNet was not found locally. Downloading the official pretrained model...\n");
fprintf("Source: %s\n",C.yamnet.downloadURL);

zipFile = fullfile(P.modelsDir,"yamnet.zip");
try
    websave(zipFile,C.yamnet.downloadURL);
catch ME
    error("Automatic YAMNet download failed. Check internet access.\n%s",ME.message);
end

try
    unzip(zipFile,P.modelsDir);
catch ME
    error("YAMNet archive could not be unzipped.\n%s",ME.message);
end

if isfile(zipFile)
    delete(zipFile);
end

assert(isfolder(P.yamnetDir), ...
    "Download completed, but models/yamnet was not created as expected.");

addpath(P.yamnetDir);

try
    [net,classes] = audioPretrainedNetwork(C.yamnet.modelName);
catch ME
    error("YAMNet was downloaded but still could not be loaded.\n%s",ME.message);
end

info.source = "downloaded to project-local models/yamnet";
fprintf("YAMNet downloaded and loaded successfully.\n");
end
