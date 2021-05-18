% chanSim processes the channel sounding to different indoor evironments 
% and then output the measured angle and power for each map and each TX.
% Input data includes two parts:
%       1. roomIndex.mat -- stores TXs location (row-colunms) in the room
%       2. Tx_X_data.mat -- stores the ray tracing paths for each link
% Output file:
%       Tx_X_csResult.csv -- stores in folder chanSouderResult
%           one row => one link's channel sounding results
%           csv header (columns) includes:
%               1. roomIndex_1 - the row number of RX
%               2. roomIndex_2 - the column number of RX
%               3. coordiates_1 - the X coordinate of RX
%               4. coordiates_2 - the Y coordinate of RX
%               5. recordSnr - SNR
%               6. recordPow - measured received power dBm
%               7. recordAoaAz - measured AZ AoA
%               8. recordAzErr - abs(measured AZ AoA  - truth AZ AoA)


% for now, I only place one project in the folder and only run 3 TXs.
% each TX takes 20 mins.

if ~exist('chanSounderResult', 'dir')
    % create folder for channel sounding results
    mkdir('chanSounderResult');  
end

dataDir = dir('rayTracingData');    % ray tracing data folder struct
dataDir([1,2]) = [];    % delete '.' and '..'
nPj = length(dataDir);  % number of projects
nTX = 10;   % ten TX location for each map
for iPj = 1: nPj    % print the projects
    fprintf('%s; ', dataDir(iPj).name);
end

% Set TX and RX array platform size
nRxAnt = 8;     % four Ants ULA RX
nTxXY = [4 4];  % 4x4 Ants URA TX
rxVel = [0 0 0];    % RX velocity = 0 m/s
nTxArr = 3;   % number of Tx arrays

% Loop projects
for iPj = 1 : nPj
    fprintf('\nStart project %s: ', dataDir(iPj).name);
    % load the roomIndex for the map
    filePath = strcat(dataDir(iPj).folder,'\',dataDir(iPj).name,'\',...
        dataDir(iPj).name,'_roomIndex.mat');
    load(filePath);
    roomIndex = double(roomIndex) + 1;  % Matlab starts from 1
    coordiates = indoorDataHelper.ind2pos(roomIndex); % coordiates for RX
    nLink = length(roomIndex);  % number of in room links
    
    % create ChanSounder object
    CS = channelSounder.ChanSounder('nRxAnt', nRxAnt, 'nTxXY', nTxXY,...
        'rxVel', rxVel, 'nTxArr', nTxArr);
    % set up array platform
    CS.createArrPlatform();
    
    % create folder for this project channel sounder results
    if ~exist(strcat('chanSounderResult\',dataDir(iPj).name), 'dir')
        % create folder for channel sounding results
        mkdir(strcat('chanSounderResult\',dataDir(iPj).name));
    end
    % loop for each TX
%     for iTX = 1: nTX
    for iTX = 3: 3      
        fprintf('Tx_%d; ', iTX);
        % load ray tracing data for one Tx
        filename = strcat(dataDir(iPj).folder,'\',dataDir(iPj).name,'\',...
        dataDir(iPj).name,'_Tx_',int2str(iTX),'_data.mat');
        load(filename);
        % process Remcom WI data
        dataHelper = indoorDataHelper.DataHelper('aoaAz', aoaAz, ...
            'aoaEl', 90-aoaEl, 'aodAz', aodAz, 'aodEl', 90-aodEl,...
            'rxPow', gain, 'dly', dly);
        
        % generate a codebook
        CS.genCodebook();
        
        % initial record arrays
        recordSnr = NaN(nLink,1);   % measured SNR for each link
        recordAoaAz = NaN(nLink,1);     % measured AoA Az for each link
        recordPow = NaN(nLink,1);   % measured received power
        recordAzErr = NaN(nLink,1);     % angle error
        recordBfGain = NaN(nLink,1);
        recordDly = NaN(nLink,1);
        
        % loop links
        for iLink = 1:nLink
            % get number of path
            nPath = dataHelper.numPath(iLink);
            if nPath > 0
                % the link has at least 1 path, do channel sounder and
                % measure the angle and power
                % paths' info and the strongest path's info
                [pl, aodAz0, aodEl0, aoaAz0, aoaEl0, dly0,...
                plStgst, aodAzStgst, aodElStgst, aoaAzStgst, ...
                aoaElStgst, dlyStgst] = dataHelper.pathsInfo(iLink, nPath);
                % get best codeword from trongest path's angles
                [bfGainMax, bfGainArr, indCode, indArr] = ...
                    CS.cb.getBfGain2(aodAzStgst,aodElStgst);
                codeword = CS.cbW(:,indCode(indArr),indArr);
                % BF gains on all paths by the stronges path's codeword
                % get the array response = sv + element gain on the best 
                % array(indArr)
                [Utx,elemGain] = CS.cb.arrSet{indArr}.step(...
                    aodAz0, aodEl0, true);
                Z = (Utx.') .* 10.^(0.05*elemGain');
                % get BF gain on each codeword 
                rho = abs(Z(:,:)*codeword).^2;
                txBFGain = 10*log10(rho); %  dBi
                
                % align receiver ULA
                CS.rxArr.alignAxes(aoaAzStgst, aoaElStgst);
                % get the directivity of the paths on the receiver antenna.
                [Urx, rxDirGain] = CS.rxArr.step(aoaAz0,aoaEl0,true);
                % calculate gain
                gainLin = 10.^(0.05*(rxDirGain + txBFGain' - pl));
                % set the doppler
                dop = CS.rxArr.doppler(aoaAz0,aoaEl0);
                
                % generate trasimit signal
                x = CS.genTxSignal(); % (nfft*nframe, 1)
                % configure the channel
                utx = codeword'*Utx; % conbine transmission signals
                % initial a SIMO multi-path channel
                CS.initChan(dly0, dop, gainLin, utx, Urx, aoaAz0, aoaEl0);
                % implement the channel
                y = CS.SIMOMPChan.step(x); % (nfft*nframe, 4)
%                 yvar = sum(mean(abs(y).^2))/CS.nRxAnt; % / 4 ants
                % SNR
                noiseVar = CS.EkT*10^(0.1*CS.noiseFig); % in linear scale
%                 recordSnr(iLink) = 10*log10(yvar/noiseVar);
                recordSnr(iLink) = 10*log10(mean(max(abs(y)))^2/noiseVar);
                % add thermal noise
                ynoisy = y + (randn(length(y),CS.nRxAnt) + ...
                    1i*randn(length(y),CS.nRxAnt))*sqrt(noiseVar/2);
                % measure receive power
%                 recordPow(iLink) = 20*log10(max(abs(ynoisy),'all').^2); % dBm
                recordPow(iLink) = pow2db(sum(db2pow(-pl))); % dBm
%                 disp(recordSnr(iLink));
                
                % measure the AoA Az
                z = sum(conj(x).'*ynoisy, 1); % Match filter along x
                nPtsAz = 901; % accuracy of az prediction

                if aoaAz0(1) <= 0 
                    az = linspace(-180,0,nPtsAz);
                else 
                    az = linspace(0,180,nPtsAz); 
                end
                [U, ~] = CS.rxArr.step(az, zeros(1,nPtsAz), true);
                rho = abs(sum(conj(U).*z.', 1)).^2; % (1, npts)
                [~, idx] = max(rho); 
                recordAoaAz(iLink) = az(idx);
                recordAzErr(iLink) = abs(az(idx)-aoaAz0(1));
                
                recordBfGain(iLink) = txBFGain(1);
            %else
                % the link is outage (0 path)
            end
        end
        
        % store measurements in csv file
        T = table(roomIndex, coordiates, recordPow,recordSnr, recordAoaAz,...
            recordAzErr, recordBfGain);
        resultFilename = strcat('chanSounderResult\',dataDir(iPj).name,...
            '\', dataDir(iPj).name, '_Tx_',int2str(iTX),'_csResult.csv');
        writetable(T, resultFilename);
        resultFilename = strcat(dataDir(iPj).name, '_Tx_',int2str(iTX),'_csResult.mat');
        save(resultFilename);
    end
end