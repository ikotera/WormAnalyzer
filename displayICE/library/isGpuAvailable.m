function OK = isGpuAvailable
 try
     d = gpuDevice;
     OK = d.SupportsDouble;
 catch
     OK = false;
 end