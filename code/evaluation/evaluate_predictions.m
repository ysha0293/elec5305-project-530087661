function M = evaluate_predictions(yTrue,yPred,classOrder)
%EVALUATE_PREDICTIONS Accuracy, macro-F1, class metrics and confusion matrix.

yTrue=categorical(string(yTrue),classOrder,classOrder);
yPred=categorical(string(yPred),classOrder,classOrder);

C=confusionmat( ...
    yTrue,yPred, ...
    "Order",categorical(classOrder,classOrder));

TP=diag(C);
FP=sum(C,1)'-TP;
FN=sum(C,2)-TP;

precision=TP./max(TP+FP,1);
recall=TP./max(TP+FN,1);
f1=2.*precision.*recall./max(precision+recall,eps);

M.accuracy=sum(TP)/max(sum(C(:)),1);
M.macroF1=mean(f1);
M.precision=precision;
M.recall=recall;
M.f1=f1;
M.confusion=C;
end
