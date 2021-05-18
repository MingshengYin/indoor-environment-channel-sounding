classdef ChanSounder < matlab.System
   % chanSounder are used to measure the channel response between a TX and
   % RX. It includes the codebook, TX and RX antenna array platform, and a
   % SIMO MP channel objects. Also it has function to gerenate signal x
   % using in SIMOMP channel
   
   properties 
       fc = 28e9   % carrier in Hz
       lambda = physconst('lightspeed')/28e9     % wavelength
       nTxArr = 3   % number of Tx arrays
       fsamp = 4*120e3*1024; % sample rate in Hz
       nfft = 1024; % number of samples per frame = FFT window
       nframe = 1; % number of frames
       Ptx = 23; % transmit power in dBm
       EkT = physconst('Boltzman')*290;	% noise energy in 290K
       noiseFig = 6;     % noise figure dBm 

       nRxAnt   % size of the RX array
       nTxXY    % size of a TX array
       rxVel    % Rx velocity     
       rxArr    % RX array platform
       txArrSet % TX array platform
       cb       % codebooks for multi-array Tx
       cbW      % W(j,ell,k) = codebook ell
       SIMOMPChan   % SIMO multi-path channel object
   end
   
   methods
        function obj = ChanSounder(varargin)
            % Constructor
            % Set key-value pair arguments
            if nargin >= 1
                obj.set(varargin{:});
            end
        end        

        function createArrPlatform(obj)
            % Create Tx arrays platform obj.txArrSet and Rx array platform
            % obj.rxArr
            % creat antenna element
            ant = design(patchMicrostrip, obj.fc);
            ant.set('Tilt', 90, 'TiltAxis', [0,1,0]);
            ant.Tilt = 90;
            ant.TiltAxis = [0 1 0];
            elemInterp = channelSounder.InterpPatternAntenna(ant, obj.fc);
            % create Rx array platform
            arrrx = phased.ULA('NumElements', obj.nRxAnt, ...
               'ElementSpacing', obj.lambda/2, 'ArrayAxis','x');
            obj.rxArr = channelSounder.ArrayPlatform('fc', obj.fc,...
                'arr', arrrx, 'elem', elemInterp);
            obj.rxArr.set('vel', obj.rxVel);
            % create Tx arrays platform
            [azArr, elArr] = obj.txArrOrient(); %generates the orientation
            arrBase  = phased.URA(obj.nTxXY,obj.lambda/2,...
                'ArrayNormal','x');
            obj.txArrSet = cell(obj.nTxArr,1);
            for iArr = 1:obj.nTxArr
                % Create the array
                arri = channelSounder.ArrayPlatform('arr', arrBase, ...
                    'elem', elemInterp, 'fc', obj.fc);
                % Align it to the desired direction
                arri.alignAxes(azArr(iArr), elArr(iArr));
                % Save the array in a list
                obj.txArrSet{iArr} = arri;
            end
        end
        
        function x = genTxSignal(obj)
            % Generate a channel sounding signal
            
            Etx = 10^(0.05*obj.Ptx)/obj.fsamp/1000; % Watt
            % Create TX signal in frequency domain
            x0Fd = (randn(obj.nfft, 1) + 1i*randn(obj.nfft, 1));
            % Convert to time domain and scale
            x0 = ifft(x0Fd);
            x0 =  x0 * sqrt(Etx / mean(abs(x0).^2));

            % Repeat x0 nframe times to create 
            % a vector x of length nframe*nfft x 1
            x = repmat(x0, obj.nframe, 1);
        end
        
        function genCodebook(obj)
            % Generate the codebooks for multi-array
            nant = prod(obj.nTxXY);  % num of antenna elements in a array
            ncode = 10*nant;       % number of codewords
            obj.cb = channelSounder.Codebook('arrSet', obj.txArrSet,...
                'ncode', ncode);
            obj.cb.genCodebook();
            obj.cbW = obj.cb.W;
        end
        
        function initChan(obj, dly0, dop, gainLin, utx, urx, aoaAz, aoaEl)
            % Initial the SIMO multi-path channel
            
            obj.SIMOMPChan = channelSounder.SIMOMPChan(...
                'fsamp', obj.fsamp, 'dly', dly0, 'dop', dop, ...
                'gainLin', gainLin, 'utx', utx,...
                'urx', urx,'rxArr', obj.rxArr, 'aoaAz', aoaAz,...
                'aoaEl', aoaEl);
        end
        
        function [az, el] = txArrOrient(obj)
            % Randomly generates the orientation for 3 Tx arrays.
            % Return:
            %   az [1,3] azimuth angles
            %   el [1,3] elevation angles

            % random orientation for the first array
            azRand = 360*rand(1)-180;
            elRand = 180*rand(1)-90;
            % Second and third array's orientations have a relation with 
            % 1st array
            az2 = (azRand/azRand)*(180-abs(azRand));
            el2 = -elRand;
            if elRand>0
                az3 = az2;
            else
                az3 = azRand;
            end
            arr3dir = rand(1)-0.5;
            if arr3dir>0
                el3 = 90 - abs(elRand);
            else
                el3 = -(90 - abs(elRand));
            end
            if obj.nTxArr == 3
%                 az = [azRand, az2, az3];
%                 el = [elRand, el2, el3];
                az = [120, 0, -120];
                el = [0, 0, 0];
                disp(az)
            else
                msg = 'Must re-design txArrOrient()';
                error(msg);  
            end
        end
        
    end
end