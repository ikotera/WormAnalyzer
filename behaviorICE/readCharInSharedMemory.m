function text = readCharInSharedMemory(SM, field)

int = SM.Data.(field);
lenText = find(int == 3);
text = char( int(1:lenText(1)-1) )';

end