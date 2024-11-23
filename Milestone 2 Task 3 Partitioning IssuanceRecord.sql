-- Step 1: Create the Filegroups
-- Use a loop to create the filegroups dynamically for IssuanceRecord
DECLARE @i INT = 1;
WHILE @i <= 5 
BEGIN
    DECLARE @filegroup NVARCHAR(50) = 'IssuanceRecordFG' + CAST(@i AS NVARCHAR);
    
    -- Create the filegroup
    EXEC ('ALTER DATABASE [s3962053] ADD FILEGROUP ' + @filegroup);
    
    SET @i = @i + 1;
END;

-- Step 2: Add Files to the Filegroups for IssuanceRecord
DECLARE @i INT = 1;
WHILE @i <= 5 
BEGIN
    DECLARE @filegroup NVARCHAR(50) = 'IssuanceRecordFG' + CAST(@i AS NVARCHAR);
    DECLARE @filename NVARCHAR(100) = 'D:\RDSDBDATA\DATA\' + @filegroup + '.ndf';

    -- Add file to the corresponding filegroup
    EXEC ('ALTER DATABASE [s3962053]
           ADD FILE (
               NAME = N''' + @filegroup + '_File'', 
               FILENAME = N''' + @filename + ''', 
               SIZE = 5MB, 
               FILEGROWTH = 10MB
           ) TO FILEGROUP ' + @filegroup);

    SET @i = @i + 1;
END;

-- Step 3: Create a Partition Function for ElectionEventID
CREATE PARTITION FUNCTION IssuanceRecordPartitionFunction (INT)
AS RANGE RIGHT FOR VALUES (20190518, 20220521, 20250517, 20280516);  

-- Step 4: Create a Partition Scheme for IssuanceRecord
CREATE PARTITION SCHEME IssuanceRecordPartitionScheme
AS PARTITION IssuanceRecordPartitionFunction
TO (IssuanceRecordFG1, IssuanceRecordFG2, IssuanceRecordFG3, IssuanceRecordFG4, IssuanceRecordFG5);  

-- Step 5: Create the IssuanceRecord table with both VoterID and DivisionName
CREATE TABLE IssuanceRecord_Partitioned
(
    VoterID INT,                                      -- Voter identifier
    ElectionEventID INT,                              -- Election event identifier
    DivisionName NVARCHAR(100) NOT NULL,              -- Division name (from VoterRegistry)
    IssueDate DATE,                                   -- Date when the ballot was issued
    Timestamp DATETIME,                               -- Exact time when the ballot was issued
    PollingStation VARCHAR(100),                      -- Name of the polling station
    PRIMARY KEY (VoterID, ElectionEventID),           -- Composite primary key
    FOREIGN KEY (VoterID, DivisionName) REFERENCES VoterRegistry_Partitioned(VoterID, DivisionName),  -- Foreign key
    FOREIGN KEY (ElectionEventID) REFERENCES ElectionEvent(ElectionEventID)
)
ON IssuanceRecordPartitionScheme (ElectionEventID);   -- Partitioned on ElectionEventID



