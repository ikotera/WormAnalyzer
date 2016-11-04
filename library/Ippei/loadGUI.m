function handles = loadGUI(varargin)
% Load .fig file created by GUIDE. Returns handles of the main UI components. 

pathFig = varargin{1};
if nargin > 1
    handles = varargin{2};
end

% Load the figure from .fig file
ht = hgload(pathFig);

% Get handles of all the components in the figure
fa = findall(ht);
sizeFa = numel(fa);

for sf = 1:sizeFa
    % Get Tag and Type properties for the UI components
    tag = get(fa(sf), 'Tag');
    type = get(fa(sf), 'Type');
    
    % Put the relevant UI component handles in 'handles' structure
    if ~isempty(tag) && (...
            strcmp(type, 'figure') ||...
            strcmp(type, 'uipanel') ||...
            strcmp(type, 'uicontrol') ||...
            strcmp(type, 'uibuttongroup') ||...
            strcmp(type, 'axes'))
        
        handles.(tag) = fa(sf);
    end
end

end