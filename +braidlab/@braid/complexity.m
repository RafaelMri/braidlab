function [c,bE] = complexity(b, lengthtype)
%COMPLEXITY   Dynnikov-Wiest geometric complexity of a braid.
%   C = COMPLEXITY(B) returns the Dynnikov-Wiest complexity of a braid:
%
%     C(B) = log|B.E| - log|E|
%
%   where E is a canonical curve diagram, and |L| gives the number of
%   intersections of the curve diagram L with the real axis. 
%
%   C = COMPLEXITY(B, LENGTHTYPE) performs the same calculation,
%   but modifies how |L| is computed:
%   For LENGTHTYPE = 
%   0 : using intaxis (default, as originally by Dynnikov and Wiest)
%   1 : using minlength.
%
%   Note: Dynnikov and Wiest originally stated the complexity in
%   base-2 logarithm.
%
%   [C,BE] = COMPLEXITY(...)
%   Additionally returns loop b.E 
%
%   References:
%
%   I. A. Dynnikov and B. Wiest, "On the Complexity of Braids,"
%   Journal of the European Mathematical Society 9 (2007), 801-840.
%
%   This is a method for the BRAID class.
%   See also BRAID, BRAID.LOOPCOORDS, LOOP.MINLENGTH, LOOP.INTAXIS.

% <LICENSE
%   Braidlab: a Matlab package for analyzing data using braids
%
%   http://bitbucket.org/jeanluc/braidlab/
%
%   Copyright (C) 2013--2014  Jean-Luc Thiffeault <jeanluc@math.wisc.edu>
%                             Marko Budisic         <marko@math.wisc.edu>
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

% Canonical set of loops, with extra boundary puncture (n+1).
E = braidlab.loop(b.n,'bp');

if nargin < 2
  lengthtype = 0;
end

validateattributes(lengthtype, {'numeric'}, ...
                   {'integer', '>=',0, '<=',1}, ...
                   'braid/complexity','lengthtype',2);

bE = b*E;

switch lengthtype
  case 0
    % Subtract b.n-1 to remove extra crossings due to boundary (n+1)
    % puncture: (n-1) arcs going to it never cross the horizontal so
    % they should be accounted for.
    disp('intaxis')
    b.n-1
    c = log(intaxis(bE)-b.n+1) - log(intaxis(E)-b.n+1);
  case 1
    disp('minlength')
    b*E
    c = log( minlength(bE) ) - log( minlength(E) );
  otherwise
    error('BRAIDLAB:braid:complexity:unknownlength', ...
          'Specified length computation is not supported');
end

end


