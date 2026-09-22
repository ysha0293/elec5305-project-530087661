function d = representation_distance(a,b,metric)
%REPRESENTATION_DISTANCE Distance between clean and perturbed features.
%
% "cosine"    -> intended for YAMNet embeddings
% "euclidean" -> intended for MFCC summary vectors

a=double(a(:));
b=double(b(:));

switch lower(metric)
    case "cosine"
        d=1-dot(a,b)/max(norm(a)*norm(b),eps);

    case "euclidean"
        d=norm(a-b,2);

    otherwise
        error("Unknown distance metric: %s",metric);
end
end
