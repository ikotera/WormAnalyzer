function sizeWin = getSizeWindows

% Get Windows' Taskbar dimension
sizeWin.bounds = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment().getMaximumWindowBounds();
sizeWin.screen = java.awt.Toolkit.getDefaultToolkit().getScreenSize();

end