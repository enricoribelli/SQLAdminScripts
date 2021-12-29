exec master..xp_fixeddrives
select str(sum(convert(dec(17,2),size)) / 128,10,2)  + 'MB'
from dbo.sysfiles