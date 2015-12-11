%DATABRAID   Class for representing braids created from data.
%   A DATABRAID object holds a braid created from data.  Unlike the BRAID
%   class, a DATABRAID remembers the times at which particles crossed.
%
%   In addition to the data members of the BRAID class, the class DATABRAID
%   has the following data member (property):
%
%    'tcross'   vector of interpolated crossing times
%
%   A DATABRAID has access to most of the methods of BRAID, though some of
%   them work a bit differently.  See in particular DATABRAID.EQ,
%   DATABRAID.COMPACT, and DATABRAID.MTIMES.  MPOWER and MINV are undefined.
%
%   METHODS('DATABRAID') shows a list of methods.
%
%   See also DATABRAID.DATABRAID (constructor).

% <LICENSE
%   Braidlab: a Matlab package for analyzing data using braids
%
%   http://github.com/jeanluct/braidlab
%
%   Copyright (C) 2013-2015  Jean-Luc Thiffeault <jeanluc@math.wisc.edu>
%                            Marko Budisic         <marko@math.wisc.edu>
%
%   This file is part of Braidlab.
%
%   Braidlab is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   Braidlab is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with Braidlab.  If not, see <http://www.gnu.org/licenses/>.
% LICENSE>

classdef databraid < braidlab.braid
  properties
    tcross            % vector of interpolated crossing times
  end

  methods

    function br = databraid(varargin)
    %DATABRAID   Construct a databraid object.
    %   B = DATABRAID(XY) constucts a databraid from a trajectory dataset XY.
    %   The data format is XY(1:NSTEPS,1:2,1:N), where NSTEPS is the number
    %   of time steps and N is the number of particles.
    %
    %   DATABRAID(XY,T) specifies the times of the datapoints.  T defaults
    %   to 1:NSTEPS if omitted or if empty.
    %
    %   DATABRAID(XY,T,PROJANG) or DATABRAID(XY, [], PROJANG) uses a projection
    %   line with angle PROJANG (in radians) from the X axis to determine
    %   crossings.  The default is to project onto the X axis (PROJANG = 0).
    %
    %   DATABRAID(BB,T) creates a databraid from a braid BB and crossing
    %   times T.  T defaults to [1:length(BB)].
    %
    %   DATABRAID(W,T) creates a databraid from a list of generators W and
    %   crossing times T.  T defaults to [1:length(BB)].
    %
    %   This is a method for the DATABRAID class.
    %   See also DATABRAID, BRAID, BRAID.BRAID.

    %% Parse for positional inputs
      parser = inputParser;
      parser.addRequired('First'); % generic input
      parser.addOptional('t',[], @isnumeric);
      parser.addOptional('proj',0, @isscalar);
      parser.addParameter('CheckClosure',false, @islogical);

      try
        parser.parse(varargin{:});
        params = parser.Results;
        if isempty(params.proj)
          params.proj = 0;
        end
      catch me
        m = MException( 'BRAIDLAB:databraid:databraid:badarg', ...
                        'Invalid arguments');
        throw(m.addCause(me)); % attach validator exception
      end

      %% Input is a databraid already
      if isa(params.First,'braidlab.databraid')
        br = params.First;
        return
      end

      %% Input is a braid, we just need to add tcross to it
      if isa(params.First,'braidlab.braid')
        br.word = params.First.word;
        br.n = params.First.n;
        if ~isempty(params.t) % use input
          br.tcross = params.t(:)';
        else % use default
          br.tcross = 1:length(br.word);
        end
        check_tcross(br);
        return
      end

      %% Input is a list of generators
      if isvector(params.First) || isempty(params.First)
        % create a braid first
        b = braidlab.braid( params.First );

        % use databraid generator with braid input to create the databraid
        br = braidlab.databraid(b, params.t);
        return
      end

      %% Input has only a single trajectory
      if ismatrix(params.First) || ( iscell(params.First) && ...
                                     numel(params.First) == 1 )
        % single trajectory always yields a trivial braid
        warning('BRAIDLAB:databraid:databraid:onetraj',...
                ['Single trajectory input (XY is a 2d matrix or'...
                 'a single-element cell array).']);
        br = braidlab.databraid([]);
        return;

      end

      %% Input is a data set and will be passed onto colorbraiding
      is3d = @(x)isnumeric(x) && (numel(size(x)) == 3);
      if isempty(params.t)
        assert( is3d(params.First),...
                'BRAIDLAB:databraid:databraid:badarg',...
                ['Default time vector can be generated only for'...
                 'data in 3d array form'] );
        params.t = 1:size(params.First,1);
      end

      [b,tcross] = braidlab.braid.colorbraiding(...
          params.First,...
          params.t,...
          params.proj,...
          params.CheckClosure);

      % invoke braid-timevector constructor
      br = braidlab.databraid( b, tcross );
    end

    function b = braid(db)
    %BRAID   Convert a DATABRAID to a BRAID.
    %   C = BRAID(B) converts the databraid B to a regular braid object C
    %   by dropping the crossing times.
    %
    %   This is a method for the DATABRAID class.
    %   See also BRAID.BRAID.
      b = braidlab.braid(db.word,db.n);
    end

    function ee = eq(b1,b2)
    %EQ   Test databraids for equality.
    %   EQ(B1,B2) or B1==B2 returns TRUE if the two databraids B1 and B2 are
    %   equal.  Equality of databraids, unlike equality of braids, is
    %   defined lexicographically.  The list of crossing times must also be
    %   identical.
    %
    %   To check if the braids themselves are equal, convert to BRAID
    %   objects before testing: EQ(BRAID(B1),BRAID(B2)).
    %
    %   This is a method for the DATABRAID class.
    %   See also BRAID.EQ, BRAID.LEXEQ.
      if length(b1.tcross) ~= length(b2.tcross)
        ee = false;
        return
      end
      ee = all(b1.tcross == b2.tcross);
      if ee
        % If there are simultaneous times, for which the generators have to
        % commute, sort the generators according to absolute value.  See
        % issue #97.
        w1 = sort_sim_tcross(b1);
        w2 = sort_sim_tcross(b2);
        ee = all(w1.word == w2.word);
      end
    end

    function ee = ne(b1,b2)
    %NE   Test databraids for inequality.
    %   NE(B1,B2) or B1~=B2 returns ~EQ(B1,B2).
    %
    %   This is a method for the BRAID class.
    %   See also DATABRAID.EQ.
      ee = ~(b1 == b2);
    end

    function b12 = mtimes(b1,b2)
    %MTIMES   Multiply two databraids together or act on a loop by a databraid.
    %   C = B1*B2, return the product of the two databraids B1 and B2.  This
    %   is only well-defined if the crossing times of B1 are all earlier
    %   than those of B2.
    %
    %   L2 = B*L, where B is a databraid and L is a loop object, returns a
    %   new loop L2 given by the action of B on L.
    %
    %   This is a method for the DATABRAID class.
    %   See also BRAID.MTIMES, DATABRAID, LOOP.
      if isa(b2,'braidlab.databraid')
        if b1.tcross(end) > b2.tcross(1)
          error('BRAIDLAB:databraid:mtimes:notchrono',...
                'First braid must have earlier times than second.')
        end
        b12 = braidlab.databraid(...
            braidlab.braid([b1.word b2.word],max(b1.n,b2.n)),...
            [b1.tcross b2.tcross]);
      elseif isa(b2,'braidlab.loop')
        % Action of databraid on a loop.
        b12 = mtimes@braidlab.braid(b1,b2);
      end
    end

    function bs = subbraid(b,s)
      ; %#ok<NOSEM>
      % Do not put comments above the first line of code, so the help
      % message from braid.subbraid is displayed.

      % Use the optional return argument ii for braid.subbraid, which gives
      % a list of the generators that were kept.
      [bb,ii] = subbraid@braidlab.braid(b,s);
      bs = braidlab.databraid(bb,b.tcross(ii));
    end

  end % methods block


  methods (Access = protected)

    function displayScalarObject(b)
      fprintf('braid: '), disp(braid(b));
      fprintf('tcross: '), disp(b.tcross);
    end

  end % methods block


  % Some operations are not appropriate for databraids, since they break
  % chronology.  Hide these, though they can still be called and will
  % return an error message.
  methods (Hidden)
    function mpower(~,~)
      error('BRAIDLAB:databraid:mpower:undefined',...
            'This operation is not defined for databraids.')
    end

    function inv(~)
      error('BRAIDLAB:databraid:inv:undefined',...
            'This operation is not defined for databraids.')
    end

    function complexity(varargin)
      error('BRAIDLAB:databraid:complexity:undefined',...
            ['This operation is not defined for databraids.  ' ...
             'Use databraid.ftbe instead.'])
    end

    function conjtest(~,~)
      error('BRAIDLAB:databraid:conjtest:undefined',...
            'This operation is not defined for databraids.')
    end

    function cycle(varargin)
      error('BRAIDLAB:databraid:cycle:undefined',...
            'This operation is not defined for databraids.')
    end

    function entropy(varargin)
      error('BRAIDLAB:databraid:entropy:undefined',...
            ['This operation is not defined for databraids.  ' ...
             'Use databraid.ftbe instead.'])
    end
  end % methods block

end % databraid classdef
