function Ind = pos2ind(X)
    % return the index (No.row, No.col) of a position X (x,y)
    arguments
       X (:,2) % point (x,y) coordinate
       % Return Ind  "roomIndex" (Row, Col)
    end
    mapStep = 0.15;
    mapOff = 0.05;
    Ind2 = (X(:,1)-mapOff)/mapStep + 1;
    Ind1 = (mapOff-X(:,2))/mapStep;
    Ind = [Ind1 Ind2];
end