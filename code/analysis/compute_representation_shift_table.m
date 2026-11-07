function T = compute_representation_shift_table(Xclean,Xperturbed,meta,representationName,perturbationName,severity,metric,P)
%COMPUTE_REPRESENTATION_SHIFT_TABLE Clip-level clean-to-perturbed distance.
%
% Returned in memory for condition/class aggregation. By default the full
% 8732-row table is NOT written to results because it is an intermediate
% analysis product, not a report deliverable.

if nargin<8 || isempty(P), P=project_paths(); end
C=config();

assert(isequal(size(Xclean),size(Xperturbed)), ...
    "Clean and perturbed representation matrices must have identical size.");
assert(size(Xclean,1)==height(meta), ...
    "Representation rows must align with metadata rows.");

n=size(Xclean,1);
Distance=zeros(n,1);
for i=1:n
    Distance(i)=representation_distance(Xclean(i,:),Xperturbed(i,:),metric);
end

T=table(string(meta.slice_file_name),meta.fold,string(meta.class), ...
    repmat(string(representationName),n,1),repmat(string(perturbationName),n,1), ...
    repmat(string(severity),n,1),Distance, ...
    'VariableNames',{'ClipID','Fold','Class','Representation','Perturbation','Severity','Distance'});

if C.storage.keepClipLevelDistanceFiles
    repTag=regexprep(lower(string(representationName)),"[^a-z0-9]+","_");
    pertTag=regexprep(lower(string(perturbationName)),"[^a-z0-9]+","_");
    sevTag=regexprep(lower(string(severity)),"[^a-z0-9]+","_");
    writetable(T,fullfile(P.workRobustnessDir,repTag+"_"+pertTag+"_"+sevTag+"_distances.csv"));
end
end
