function [fitresult, gof] = createFit(x, y, show)
%CREATEFIT(X,Y)
%  Model the relationship between x and y using a power function.
%  If show == true, plot the data and fit.

[xData, yData] = prepareCurveData( x, y );
% Set up fittype and options.
ft = fittype( 'power2' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.StartPoint = [0 0 0]
% opts.StartPoint = [0.00444907476924962 0.379792900228052 -0.00131725834264842];
opts.Upper = [0 Inf Inf];

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );

% Plot fit with data.
if show:
    figure( 'Name', 'fitPowerFun' );
    h = plot( fitresult, xData, yData );
    legend( h, 'y vs. x', 'fitPowerFun', 'Location', 'NorthEast', 'Interpreter', 'none' );
    Label axes
    xlabel( 'x', 'Interpreter', 'none' );
    ylabel( 'y', 'Interpreter', 'none' );
    grid on
end
