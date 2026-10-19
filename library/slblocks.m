function blkStruct = slblocks
%SLBLOCKS Register the library in the Simulink Library Browser.
% SPDX-License-Identifier: MIT
browser.Library = 'SHCLib';
browser.Name = 'Heat Conduction';
browser.IsFlat = 0;
blkStruct.Browser = browser;
end
