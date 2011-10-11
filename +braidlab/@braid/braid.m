%BRAID   Class for representing braids.
%   B = BRAID(W) creates a braid object B from a vector of generators W.
%   B = BRAID(W,N) specifies the number of strings N of the braid group,
%   which is otherwise guessed from the maximal elements of W.
%
%   The braid group generators are represented as a list of integers I
%   satisfying -N < I < N.  The usual group operations (multiplication,
%   inverse, powers) can be performed on braids.
%
%   B = BRAID(XY) constucts a braid from a trajectory dataset XY.
%   The data format is XY(1:NSTEPS,1:2,1:N), where NSTEPS is the number
%   of time steps and N is the number of particles.
%
%   BC = BRAID(B) copies the object B of type BRAID or CFBRAID to the BRAID
%   object BC.
%
%   METHODS(BRAID) shows a list of methods.
%
%   See also LOOP, CFBRAID.

% set/get methods
% better naming convention for vars

classdef braid
  properties
    n = 1            % number of strings
    word = int32([]) % braid word in Artin generators
  end

  methods

    function br = braid(b,nn)
      % Allow default empty braid: return identity with one string.
      if nargin == 0, return; end
      if isa(b,'braidlab.braid')
	br.n     = b.n;
	br.word  = b.word;
      elseif isa(b,'braidlab.cfbraid')
        D = braidlab.halftwist(b.n);
        br = D^b.delta * braidlab.braid(cell2mat(b.factors),b.n);
      elseif max(size(size(b))) == 3
	if nargin > 1
	  error
	end
	% The input is an array of data.
	br = color_braiding(b,1:size(b,1));
      else
	% Store word as row vector.
	if size(b,1) > size(b,2)
	  b = b.';
	end
	br.word = b;
	if nargin < 2
	  br.n = max(abs(b))+1;
	else
	  br.n = nn;
	end
      end
    end

    function obj = set.n(obj,value)
      if value < 1
	error('BRAIDLAB:braid:setn','Need at least one string.')
      end
      if ~isempty(obj.word)
        if value < max(abs(obj.word))+1
	  error('BRAIDLAB:braid:setn',...
		'Too few strings for generators.')
	end
      end
      obj.n = value;
    end

    % Make sure it's an int32, internally.
    function obj = set.word(obj,value)
      obj.word = int32(value);
      % Raise n if necessary, and convert to double (eventually make int32?).
      obj.n = double(max(obj.n,max(abs(obj.word))+1));
    end

    function ee = eq(b1,b2)
    %EQ   Test braids for equality.
    %   EQ(B1,B2) or B1==B2 returns TRUE if the two braids B1 and B2 are
    %   equal.  The algorithm uses Dynnikov coordinates (action on loops) to
    %   determine braid equalitty.
    %
    %   Reference: P. Dehornoy, "Efficient solutions to the braid isotopy
    %   problem," Discrete Applied Mathematics 156 (2008), 3091-3112.
    %
    %   This is a method for the BRAID class.
    %   See also BRAID, BRAID.LEXEQ, LOOP, LOOPCOORDS.
      ee = b1.n == b2.n;
      % Check if the loop coordinates are the same.
      % This can fail if the braids are too long, since the coordinates
      % overflow.  Check for that.
      if ee, ee = all(loopcoords(b1) == loopcoords(b2)); end
    end

    function ee = lexeq(b1,b2)
    %LEXEQ   Test braids for lexicographical equality.
    %   LEXEQ(B1,B2) return TRUE if the words representing B1 and B2 in
    %   terms of braid generators are equal, generator by generator.
    %
    %   This is a method for the BRAID class.
    %   See also BRAID, BRAID.EQ, LOOP, LOOPCOORDS.
      ee = b1.n == b2.n & length(b1) == length(b2);
      if ee, ee = all(b1.word == b2.word); end
    end

    function ee = ne(b1,b2)
    %NE   Test braids for inequality.
    %   NE(B1,B2) or B1~=B2 returns ~EQ(B1,B2).
    %
    %   This is a method for the BRAID class.
    %   See also BRAID, BRAID.EQ.
      ee = ~(b1 == b2);
    end

    %function ee = isempty(b)
    %  ee = isempty(b.word);
    %end

    function ee = isidentity(b)
    %ISIDENTITY   Returns true if braid is the identity braid.
    %
    %   This is a method for the BRAID class.
    %   See also BRAID, BRAID.EQ.
      ee = isempty(b.word);
    end

    % Conversion to a vector.
    %function c = double(obj)
    %  c = obj.word;
    %end
 
    function b12 = mtimes(b1,b2)
    %MTIMES   Multiply two braids together.
    %
    %   This is a method for the BRAID class.
    %   See also BRAID, BRAID.INV, BRAID.MTIMES.
      if isa(b2,'braidlab.braid')
	b12 = braidlab.braid([b1.word b2.word],max(b1.n,b2.n));
      else
	% Action of braid on a loop.
	%
	% Have to define this here, rather than in the loop class, since the
        % braid goes on the left, and Matlab determines which overloaded
        % function to call by looking at the first argument.
	if b1.n > b2.n
	  error('BRAIDLAB:braid:mtimes', ...
		'Generator values too lage for the loop.')
	end
	b12 = braidlab.loop(loopsigma(b1.word,b2.coords));
      end
    end

    function bm = mpower(b,m)
    %MPOWER   Raise a braid to some positive or negative power.
    %
    %   This is a method for the BRAID class.
    %   See also BRAID, BRAID.INV, BRAID.MPOWER.
      bm = braidlab.braid([],b.n);
      if m > 0
	bm.word = repmat(b.word,[1 m]);
      else
	bm.word = repmat(b.inv.word,[1 -m]);
      end
    end

    function bi = inv(b)
    %INV   Inverse of a braid.
    %
    %   This is a method for the BRAID class.
    %   See also BRAID, BRAID.MTIMES, BRAID.MPOWER.
      bi = braidlab.braid(-b.word(end:-1:1),b.n);
    end

    function str = char(b)
      if isempty(b.word)
	str = 'e';
      else
	str = num2str(b.word);
      end
      str = ['< ' str ' >'];
    end

    function disp(b)
       c = char(b);
       if iscell(c)
	 disp(['     ' c{:}])
       else
	 disp(c)
       end
    end

    function l = length(b)
    %LENGTH   Length of a braid.
    %   L = LENGTH(B) returns the number of generators in the current
    %   internal representation of a braid.  Calling COMPACT(B) can reduce
    %   this length, often dramatically when B is created from data.
    %
    %   This is a method for the BRAID class.
    %   See also BRAID, COMPACT.
      l = length(b.word);
    end

  end % methods block

  % Static methods defined in separate files.
  % Need to execute 'clear classes' to register changes here.
  methods (Static = true)
    [b,tc] = crosstimes(XY,t)
  end % static methods

end % braid classdef
