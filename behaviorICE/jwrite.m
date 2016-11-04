function jwrite(bw, data)

% bw = System.IO.BinaryWriter(System.IO.File.Open(path, System.IO.FileMode.Create) );
byteStream = getByteStreamFromArray(data);
bw.Write(byteStream);


end