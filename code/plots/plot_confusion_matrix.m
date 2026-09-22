function plot_confusion_matrix(C,classOrder,plotTitle,outFile)
%PLOT_CONFUSION_MATRIX Save a row-normalized confusion-matrix heatmap.

rowSum=sum(C,2);
rowSum(rowSum==0)=1;
Cn=C./rowSum;

fig=figure('Visible','off');
imagesc(Cn);
axis image;
colorbar;
clim([0 1]);

xticks(1:numel(classOrder));
yticks(1:numel(classOrder));
xticklabels(classOrder);
yticklabels(classOrder);
xtickangle(35);

xlabel("Predicted class");
ylabel("True class");
title(plotTitle);

exportgraphics(fig,outFile,"Resolution",200);
close(fig);
end
