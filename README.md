# LangKit
The idea here is to make a toolkit that will be helpful for people making (domain specific) languages in julia. 
A user of this package will be required to give a string macro which takes code from whatever langauge the user has 
implemented and turns it into julia code which is then parsed by julia. LangKit will then create a repl mode where end users 
and just type code from the implemented language and have it be parsed into julia code automatically. 
