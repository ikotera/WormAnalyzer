function [slide, ap, ppt] = activatePptSlide()

slideNumber = 'append';

% Connect to PowerPoint
ppt = actxserver('PowerPoint.Application');

% Open current presentation
if get(ppt.Presentations,'Count')==0
    ap = invoke(ppt.Presentations,'Add');
else
    ap = get(ppt,'ActivePresentation');
end

% Set slide object to be the active pane
wind = get(ppt,'ActiveWindow');
panes = get(wind,'Panes');
slide_pane = invoke(panes,'Item',2);
invoke(slide_pane,'Activate');

% Identify current slide
try
    currSlide = wind.Selection.SlideRange.SlideNumber;
catch %#ok<CTCH>
    % No slides
end

% Select the slide to which the figure will be exported
slide_count = int32(get(ap.Slides,'Count'));
if strcmpi(slideNumber,'append')
    slide = invoke(ap.Slides,'Add',slide_count+1,11);
    shapes = get(slide,'Shapes');
    invoke(slide,'Select');
    invoke(shapes.Range,'Delete');
else
    if strcmpi(slideNumber,'last')
        slideNum = slide_count;
    elseif strcmpi(slideNumber,'current');
        slideNum = get(wind.Selection.SlideRange,'SlideNumber');
    else
        slideNum = slideNumber;
    end
    slide = ap.Slides.Item(slideNum);
    invoke(slide,'Select');
end

end