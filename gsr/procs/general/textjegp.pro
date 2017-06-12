pro textjegp, body, subject=subject

if keyword_set(subject) then spawn, 'echo "' + body + '" | mail -s "' + subject + '" 5102994427@txt.att.net' else spawn, 'echo "' + body + '" | mail 5102994427@txt.att.net'

end