%ifndef _COLON_INC_
%define _COLON_INC_

global _colon_1
%define _current_ref _colon_%+_current_colon
%assign _current_colon 1

%macro colon 2
_current_ref:
%2:
%assign _current_colon _current_colon + 1
dq _current_ref
db %1, 0
%endmacro

%define last_colon _current_ref:

%endif

