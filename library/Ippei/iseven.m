function bool = iseven(number)

bool = ~logical( rem(number, 2) );

end