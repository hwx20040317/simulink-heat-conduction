function setup_shc(openLibrary)
%SETUP_SHC Add this project to the current MATLAB session.
%   setup_shc opens the library; setup_shc(false) only configures the path.
%   SPDX-License-Identifier: MIT
if nargin == 0, openLibrary = true; end
validateattributes(openLibrary, {'logical'}, {'scalar'});
root = fileparts(mfilename('fullpath'));
folders = {'library', 'src', 'examples', 'tests'};
addpath(root);
for k = 1:numel(folders)
    addpath(fullfile(root, folders{k}));
end
libraryFile = fullfile(root, 'library', 'SHCLib.slx');
if bdIsLoaded('SHCLib')
    assert(strcmpi(get_param('SHCLib', 'FileName'), libraryFile), ...
        'SHC:LibraryNameConflict', 'Another SHCLib is already loaded.');
elseif ~isfile(libraryFile)
    build_shc_library;
end
if openLibrary
    open_system(libraryFile);
    sl_refresh_customizations;
end
end
