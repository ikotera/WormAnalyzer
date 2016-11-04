function handles = progressBar(flgGUI, handles, method, message, iteration, total)

if flgGUI
    switch method
        case 'instantiate'
            % Create status bar
            handles.statusBar = statusbar(handles.fig, '');
            set(handles.statusBar.CornerGrip, 'visible',0);
            handles.statusBar.getComponent(0).setFont(...
                java.awt.Font('Consolas', java.awt.Font.PLAIN, 11));
            handles.statusBar.getComponent(0).setVerticalTextPosition(1); % Center=0,Down=1,Top=3
            handles.progressBar = handles.statusBar.ProgressBar;
            handles.progressBar.setStringPainted(true);
            jD = java.awt.Dimension(200, 14);
            handles.progressBar.setPreferredSize(jD);
            handles.progressBar.setSize(jD);
            handles.progressBar.setMaximum(100);
            handles.progressBar.setMinimum(0);
            handles.progressBar.setValue(0);
            handles.movingBar = javax.swing.JProgressBar;
            handles.statusBar.add(handles.movingBar, 'East');
            handles.movingBar.setIndeterminate(true);
            handles.movingBar.setVisible(false);
            try % R2014a and earlier
                jframe = handles.jFig.fHG1Client.getWindow;
            catch % R2014b and later
                jframe = handles.jFig.fHG2Client.getWindow;
            end
            jframe.setResizable(true);
        case 'initiate'
            handles.progressBar.setVisible(true);
            handles.movingBar.setVisible(true);
            handles.statusBar.setText(message);
            handles.progressBar.setValue(0);
            handles.progressBar.setString([num2str(0, '%3.0f'), '%']);
        case 'iterate'
            if exist('message', 'var') && ~isempty(message)
                handles.statusBar.setText(message);
            end
            fraction = iteration / total * 100;
            handles.progressBar.setValue(fraction);
            handles.progressBar.setString([num2str(fraction, '%3.0f'), '%']);
            handles.progressBar.repaint();
        case 'terminate'
            pause(0.5);
            handles.progressBar.setVisible(false);
            handles.movingBar.setVisible(false);
            handles.statusBar.setText(message);
    end
end

if exist('message', 'var') && ~isempty(message)
    prt(message);
end

end