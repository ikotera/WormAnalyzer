function outputLaserFixedPeriod(obj, mv, duration)

outputAnalogLaser(obj, mv);
tc1 = tic;
                    while toc(tc1) < (duration) / 1000
                        java.lang.Thread.sleep(2);
                    end

outputAnalogLaser(obj, 0);

end