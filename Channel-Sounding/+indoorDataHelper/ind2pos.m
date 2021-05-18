function X = ind2pos(Ind)
    % Convert a room index to coordiate location X(x,y)
    arguments
       Ind (:,2) % "roomIndex" (Row, Col)
       % Return X (:,2) point (x,y) coordinate
    end
    mapStep = 0.15;
    mapOff = 0.05;
    Ind = double(Ind);
    X1 = (Ind(:,2)-1)*mapStep + mapOff;
    X2 = -Ind(:,1)*mapStep + mapOff;
    X = [X1 X2];
end