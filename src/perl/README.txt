New layout of options and installation:

$HOME/.filedirector:
	anidb.sql3db
	config
	install

$HOME/.filedirector/install:
	anidbClient.jar
	lib

$HOME/.filedirector/install/lib: (copied from here ./lib)
	anidbClient.jar
	AniDBRequest.pm
	CacheDB.pm
	CacheFacade.pm
	SQLColumnJoin.pm
	SQLite.pm
	TableCache.pm
	VerifyFile.pm

Contents of config file (config above):
--userid xxxxxx
--password yyyyyy
--install-directory /home/dminer/.filedirector/install
