classdef DataHelper < matlab.System
   % 
   
   properties
       WITxPow = 10     % Remcom WI TX power dBm
       nPathMax = 25    % a link at most has 25 paths
       
       aoaAz
       aoaEl
       aodAz
       aodEl
       rxPow
       dly
       roomIndex
       pathloss
   end
   
   methods
        function obj = DataHelper(varargin)
            % Constructor
            % Set key-value pair arguments
            if nargin >= 1
                obj.set(varargin{:});
            end
        end

        function nPath = numPath(obj, iLink)
            % check whether there are any paths in Link i
            % Return:
            %   nPath - number of paths, if no path, nPath = 0
            power0 = obj.rxPow(iLink,:);
            if ~isnan(power0(obj.nPathMax))
                % the link has 25 paths
                nPath = obj.nPathMax;
            else
                % compute number of paths
                nPath = find(isnan(power0), 1) - 1; 
            end
        end
        
        function [pl, aodAz0, aodEl0, aoaAz0, aoaEl0, dly0,...
                plStgst, aodAzStgst, aodElStgst, aoaAzStgst, ...
                aoaElStgst, dlyStgst] = pathsInfo(obj, iLink, nPath)
            % return all paths information for Link i
            % Return:
            %   pl - path loss for all paths
            %   aodAz0 - AZ AoD for all paths
            %   aodEl0 - EL AoD for all paths
            %   aoaAz0 - AZ AoA for all paths
            %   aoaEl0 - EL AoA for all paths
            %   dly0 - delay for all paths
            %   plStgst - path loss for the strongest path
            %   aodAzStgst - AZ AoD for the strongest path
            %   aodElStgst - EL AoD for the strongest paths
            %   aoaAzStgst - AZ AoA for the strongest paths
            %   aoaElStgst - EL AoA for the strongest paths
            %   dlyStgst - delay for the strongest paths
            
            pl = obj.WITxPow - obj.rxPow(iLink,1:nPath);
            aodAz0 = obj.aodAz(iLink,1:nPath);
            aodEl0 = obj.aodEl(iLink,1:nPath);
            aoaAz0 = obj.aoaAz(iLink,1:nPath);
            aoaEl0 = obj.aoaEl(iLink,1:nPath);
            dly0 = obj.dly(iLink,1:nPath);
            
            [plStgst, I] = min(pl);
            aodAzStgst = aodAz0(I);
            aodElStgst = aodEl0(I);
            aoaAzStgst = aoaAz0(I);
            aoaElStgst = aoaEl0(I);
            dlyStgst = dly0(I);
        end
        
    end
end