function plotPoints(points, isInd, roomIndex, XtxTrue)
    % Plot points in map.
    arguments
       points (:,2) % points need to plot
       isInd 
       % isInd: true, if input points is in "roomIndex", where (Row, Col)
       %        false, if input points is in coordiates, where (x, y)
       roomIndex (:,2) % map information
       XtxTrue (1,2) double = [-100 -100]; % Tx in coordiates (Xtx,Ytx)
    end
    %%%
    % creat map
    mapSize = 160;
    imgMap = NaN(mapSize,mapSize);
    npair = length(roomIndex);
    figure;
    for i = 1:npair
        imgMap(roomIndex(i,1), roomIndex(i,2)) = 10; % room region
    end
    imagesc([1 mapSize],[1 mapSize],imgMap);
    axis on;
    hold on;
    xlabel('X');
    ylabel('Y');
    if nargin == 4 % plot Tx if input
        % pos2ind
        Ind = indoorDataHelper.pos2ind(XtxTrue);
        plot(Ind(2), Ind(1), 'go', 'LineWidth',2);
    end
    if isInd % plot points
        plot(points(:,2), points(:,1), 'r+');
    else
        % pos2ind
        Ind = indoorDataHelper.pos2ind(points);
        plot(Ind(:,2), Ind(:,1), 'r+');
    end
    hold off;
end