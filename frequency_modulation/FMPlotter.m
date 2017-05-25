fileID = fopen('fm.log', 'r') 
sizeA = [2 Inf] ;
formatA = '%d %f' ;
A = fscanf(fileID, formatA, sizeA) ;
%A = A' ;
fclose(fileID) ;
figure
plot(A(1,:), A(2,:), 'b') ;
hold on ;
pause(2) ;