;
function wincos4,len
    x=findgen(len)* !pi * 2. / len
    return,((cos(x)-1.)*.5) ^2
end
