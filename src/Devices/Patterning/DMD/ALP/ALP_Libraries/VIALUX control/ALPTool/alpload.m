function alpapi = alpload(tagname)
% function alpapi = alpload(tagname)
% creates (loads) specific ALP api
%
% function alpapi = alpload(tagname)
%
%   tagname is the tag name previously assigned to a registered DLL via alptoolinstall
%
% File information:
%   version 1.0 (feb 2014)
%   (c) Martin Vogel
%   email: matlab@martin-vogel.info
%
% Revision history:
%   1.0 (feb 2014) initial release version
%

if nargin < 1 || isempty(tagname)

    [selection, ok, salplib] = alplib('select');
    if (ok == 0) || (selection == 0) || isempty(salplib)
        alpapi = [];
        return;
    end

else

    salplib = alplib('get', tagname);
    if isempty(salplib)
        alpapi = [];
        return;
    end

end

apiclass = str2func(salplib.classname);

if salplib.pseudoDLL
    alpapi = apiclass(salplib.tag, true);
else
    try
        alpapi = apiclass(salplib.tag, false);
    catch
        uiwait(msgbox(sprintf('Can not load %s, fallback to pseudoDLL mode.', salplib.tag), ...
            'Error loading DLL', 'modal'));
        alpapi = apiclass(salplib.tag, true);
    end
end

end
