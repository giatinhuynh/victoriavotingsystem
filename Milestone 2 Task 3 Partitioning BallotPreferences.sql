-- Step 1: Create the Filegroups
-- Use a loop to create the filegroups dynamically for BallotPreferences
DECLARE @i INT = 1;
WHILE @i <= 5  
BEGIN
    DECLARE @filegroup NVARCHAR(50) = 'BallotPreferencesFG' + CAST(@i AS NVARCHAR);
    
    -- Create the filegroup
    EXEC ('ALTER DATABASE s3962053 ADD FILEGROUP ' + @filegroup);
    
    SET @i = @i + 1;
END;

-- Step 2: Add Files to the Filegroups for BallotPreferences
-- Use a loop to add corresponding files to the filegroups
DECLARE @i INT = 1;
WHILE @i <= 5  
BEGIN
    DECLARE @filegroup NVARCHAR(50) = 'BallotPreferencesFG' + CAST(@i AS NVARCHAR);
    DECLARE @filename NVARCHAR(100) = 'D:\RDSDBDATA\DATA\' + @filegroup + '.ndf';

    -- Add file to the corresponding filegroup
    EXEC ('ALTER DATABASE s3962053
           ADD FILE (
               NAME = N''' + @filegroup + '_File'', 
               FILENAME = N''' + @filename + ''', 
               SIZE = 5MB, 
               FILEGROWTH = 10MB
           ) TO FILEGROUP ' + @filegroup);

    SET @i = @i + 1;
END;

-- Step 3: Create a Partition Function for ElectionEventID
CREATE PARTITION FUNCTION BallotPreferencesPartitionFunction (INT)
AS RANGE RIGHT FOR VALUES (20190518, 20220521, 20250517, 20280516);  

-- Step 4: Create a Partition Scheme for BallotPreferences
CREATE PARTITION SCHEME BallotPreferencesPartitionScheme
AS PARTITION BallotPreferencesPartitionFunction
TO (BallotPreferencesFG1, BallotPreferencesFG2, BallotPreferencesFG3, BallotPreferencesFG4, BallotPreferencesFG5);  

-- Step 5: Create the partitioned BallotPreferences table
CREATE TABLE BallotPreferences_Partitioned
(
    BallotID INT,                                      -- Ballot identifier
    CandidateID INT,                                   -- Candidate identifier
    ElectionEventID INT,                               -- Election Event identifier
    Preference INT,                                    -- Voter's preference ranking
    PRIMARY KEY (BallotID, CandidateID, ElectionEventID),  -- Composite primary key 
    FOREIGN KEY (BallotID) REFERENCES Ballot(BallotID),
    FOREIGN KEY (CandidateID) REFERENCES Candidate(CandidateID),
    FOREIGN KEY (ElectionEventID) REFERENCES ElectionEvent(ElectionEventID)
)
ON BallotPreferencesPartitionScheme (ElectionEventID);   -- Partitioned on ElectionEventID
