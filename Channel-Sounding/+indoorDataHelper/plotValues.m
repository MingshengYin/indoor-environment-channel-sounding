function plotValues(values, roomIndex, XtxTrue)
    % Plot values in map.
    arguments
       values (:,1) % the values e.g. measured angle, SNR
       roomIndex (:,2) % map information
       XtxTrue (1,2) double = [-100 -100]; % Tx in coordiates (Xtx,Ytx)
    end
    %%%
    % creat map
    mapSize = 160;
    imgMap = NaN(mapSize,mapSize);
    nLink = length(roomIndex);
    figure;
    for i = 1:nLink
        imgMap(roomIndex(i,1), roomIndex(i,2)) = values(i); % room region
    end
    imagesc([1 mapSize],[1 mapSize],imgMap);
    axis on;
    hold on;
    xlabel('X');
    ylabel('Y');
    if nargin == 3 % plot Tx if input
        % pos2ind
        Ind = indoorDataHelper.pos2ind(XtxTrue);
        plot(Ind(2), Ind(1), 'go', 'LineWidth',2);
    end
    colorbar;
    hold off;
end