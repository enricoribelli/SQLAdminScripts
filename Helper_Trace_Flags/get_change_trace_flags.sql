SELECT @@VERSION;


-- TEMP_DB
-- TF1118	= Full Extents Only
-- This means that each newly allocated object in every database on the instance gets its own private 64KB of data. 
-- Tempdb is usually the place where most objects are created, so it makes the most difference there.
-- TF1117	= Grow All Files in a FileGroup Equally

--TF3226	= Suppress all successful backups in SQL server error log

--TF2371	= Changes the fixed auto update statistics threshold to dynamic auto update statistics threshold.

--TF3023	= Enables CHECKSUM option as default for BACKUP command

DBCC TRACESTATUS (3226,1118,1117,2371,3226);  

DBCC TRACEON (1118,-1);  






