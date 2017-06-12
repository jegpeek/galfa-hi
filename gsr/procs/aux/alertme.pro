pro alertme, etitle, ebody, address, joshtxt=joshtxt

if keyword_set(joshtxt) then addy = '5102994427@txt.att.net' else addy = address

spawn, 'echo '+ ebody +' | mail -s ' +etitle +' '+ addy

end