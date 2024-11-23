-- Step 1: Create the Filegroups
-- Use a loop to create the filegroups and files dynamically
DECLARE @i INT = 1;
WHILE @i <= 146
BEGIN
    DECLARE @filegroup NVARCHAR(50) = 'VoterRegistryFG' + CAST(@i AS NVARCHAR);
    
    -- Create the filegroup
    EXEC ('ALTER DATABASE [s3962053] ADD FILEGROUP ' + @filegroup);
    
    SET @i = @i + 1;
END;

-- Step 2: Add Files to the Filegroups
-- Use a loop to add corresponding files to the filegroups
DECLARE @i INT = 1;
WHILE @i <= 146
BEGIN
    DECLARE @filegroup NVARCHAR(50) = 'VoterRegistryFG' + CAST(@i AS NVARCHAR);
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

-- Step 3: Create a Partition Function to define the range for the partitions
CREATE PARTITION FUNCTION VoterRegistryDivisionPartitionFunction (NVARCHAR(100))
AS RANGE RIGHT FOR VALUES 
(
    'Adelaide', 'Aston', 'Ballarat', 'Banks', 'Barker', 'Barton', 'Bass', 'Bean', 
    'Bendigo', 'Berowra', 'Blair', 'Blaxland', 'Bonner', 'Boothby', 'Bowman', 'Braddon', 
    'Bradfield', 'Brand', 'Brisbane', 'Bruce', 'Calare', 'Calwell', 'Canning', 'Capricornia', 
    'Casey', 'Chifley', 'Chisholm', 'Clark', 'Cook', 'Cooper', 'Corangamite', 'Corio', 'Cowper', 
    'Cunningham', 'Curtin', 'Dawson', 'Deakin', 'Dickson', 'Dobell', 'Dunkley', 'Durack', 'Eden-Monaro',
    'Fadden', 'Fairfax', 'Farrer', 'Fenner', 'Fisher', 'Flinders', 'Flynn', 'Forde', 'Forrest', 
    'Fowler', 'Franklin', 'Fraser', 'Fremantle', 'Gellibrand', 'Gilmore', 'Gippsland', 'Goldstein', 
    'Gorton', 'Grayndler', 'Grey', 'Griffith', 'Groome', 'Hasluck', 'Herbert', 'Higgins', 'Hindmarsh',
    'Hinkler', 'Holt', 'Hotham', 'Hunter', 'Hughes', 'Hume', 'Indi', 'Isaacs', 'Jagajaga', 'Kennedy', 
    'Kingsford Smith', 'Kingston', 'Lalor', 'Leichhardt', 'Lilley', 'Lingiari', 'Lonsdale', 'Lyne', 
    'Lyons', 'Macarthur', 'Mackellar', 'Macnamara', 'Makin', 'Mallee', 'Maranoa', 'Maribyrnong', 
    'Mayo', 'McEwen', 'McMahon', 'McPherson', 'Melbourne', 'Monash', 'Moore', 'Moreton', 'New England', 
    'Newcastle', 'Nicholls', 'North Sydney', 'O''Connor', 'Oxley', 'Page', 'Parkes', 'Parramatta', 
    'Paterson', 'Pearce', 'Perth', 'Petrie', 'Rankin', 'Reid', 'Richmond', 'Riverina', 'Robertson', 
    'Ryan', 'Scullin', 'Shortland', 'Spence', 'Stirling', 'Sturt', 'Swan', 'Sydney', 'Tangney', 
    'Teller', 'Throsby', 'Wakefield', 'Wannon', 'Warringah', 'Watson', 'Wentworth', 'Werriwa', 'Wide Bay', 
    'Wills', 'Wright'
);

-- Step 4: Create a Partition Scheme to map partitions to filegroups
CREATE PARTITION SCHEME VoterRegistryDivisionPartitionScheme
AS PARTITION VoterRegistryDivisionPartitionFunction
TO 
(
    VoterRegistryFG1, VoterRegistryFG2, VoterRegistryFG3, VoterRegistryFG4, VoterRegistryFG5, 
    VoterRegistryFG6, VoterRegistryFG7, VoterRegistryFG8, VoterRegistryFG9, VoterRegistryFG10,
    VoterRegistryFG11, VoterRegistryFG12, VoterRegistryFG13, VoterRegistryFG14, VoterRegistryFG15,
    VoterRegistryFG16, VoterRegistryFG17, VoterRegistryFG18, VoterRegistryFG19, VoterRegistryFG20,
    VoterRegistryFG21, VoterRegistryFG22, VoterRegistryFG23, VoterRegistryFG24, VoterRegistryFG25,
    VoterRegistryFG26, VoterRegistryFG27, VoterRegistryFG28, VoterRegistryFG29, VoterRegistryFG30,
    VoterRegistryFG31, VoterRegistryFG32, VoterRegistryFG33, VoterRegistryFG34, VoterRegistryFG35,
    VoterRegistryFG36, VoterRegistryFG37, VoterRegistryFG38, VoterRegistryFG39, VoterRegistryFG40,
    VoterRegistryFG41, VoterRegistryFG42, VoterRegistryFG43, VoterRegistryFG44, VoterRegistryFG45,
    VoterRegistryFG46, VoterRegistryFG47, VoterRegistryFG48, VoterRegistryFG49, VoterRegistryFG50,
    VoterRegistryFG51, VoterRegistryFG52, VoterRegistryFG53, VoterRegistryFG54, VoterRegistryFG55,
    VoterRegistryFG56, VoterRegistryFG57, VoterRegistryFG58, VoterRegistryFG59, VoterRegistryFG60,
    VoterRegistryFG61, VoterRegistryFG62, VoterRegistryFG63, VoterRegistryFG64, VoterRegistryFG65,
    VoterRegistryFG66, VoterRegistryFG67, VoterRegistryFG68, VoterRegistryFG69, VoterRegistryFG70,
    VoterRegistryFG71, VoterRegistryFG72, VoterRegistryFG73, VoterRegistryFG74, VoterRegistryFG75,
    VoterRegistryFG76, VoterRegistryFG77, VoterRegistryFG78, VoterRegistryFG79, VoterRegistryFG80,
    VoterRegistryFG81, VoterRegistryFG82, VoterRegistryFG83, VoterRegistryFG84, VoterRegistryFG85,
    VoterRegistryFG86, VoterRegistryFG87, VoterRegistryFG88, VoterRegistryFG89, VoterRegistryFG90,
    VoterRegistryFG91, VoterRegistryFG92, VoterRegistryFG93, VoterRegistryFG94, VoterRegistryFG95,
    VoterRegistryFG96, VoterRegistryFG97, VoterRegistryFG98, VoterRegistryFG99, VoterRegistryFG100,
    VoterRegistryFG101, VoterRegistryFG102, VoterRegistryFG103, VoterRegistryFG104, VoterRegistryFG105,
    VoterRegistryFG106, VoterRegistryFG107, VoterRegistryFG108, VoterRegistryFG109, VoterRegistryFG110,
    VoterRegistryFG111, VoterRegistryFG112, VoterRegistryFG113, VoterRegistryFG114, VoterRegistryFG115,
    VoterRegistryFG116, VoterRegistryFG117, VoterRegistryFG118, VoterRegistryFG119, VoterRegistryFG120,
    VoterRegistryFG121, VoterRegistryFG122, VoterRegistryFG123, VoterRegistryFG124, VoterRegistryFG125,
    VoterRegistryFG126, VoterRegistryFG127, VoterRegistryFG128, VoterRegistryFG129, VoterRegistryFG130,
    VoterRegistryFG131, VoterRegistryFG132, VoterRegistryFG133, VoterRegistryFG134, VoterRegistryFG135,
    VoterRegistryFG136, VoterRegistryFG137, VoterRegistryFG138, VoterRegistryFG139, VoterRegistryFG140,
    VoterRegistryFG141, VoterRegistryFG142, VoterRegistryFG143, VoterRegistryFG144, VoterRegistryFG145,
    VoterRegistryFG146
);

-- Step 5: Create the VoterRegistry table on the partition scheme
CREATE TABLE VoterRegistry_Partitioned
(
    VoterID INT,                                     -- Primary key for the voter
    FirstName NVARCHAR(100) NOT NULL,                -- Voter's first name
    MiddleNames NVARCHAR(100),                       -- Voter's middle name
    LastName NVARCHAR(100) NOT NULL,                 -- Voter's last name
    Address NVARCHAR(200),                           -- Full address of the voter
    DoB DATE NOT NULL,                               -- Date of birth
    Gender CHAR(1) NOT NULL,                         -- Gender of the voter
    ResidentialAddress NVARCHAR(255) NOT NULL,       -- Residential address
    PostalAddress NVARCHAR(255),                     -- Postal address
    ContactPhone NVARCHAR(15),                       -- Contact phone number
    ContactMobile NVARCHAR(15),                      -- Mobile phone number
    ContactEmail NVARCHAR(100),                      -- Contact email address
    DivisionName NVARCHAR(100) NOT NULL,             -- Electoral division name (used for partitioning)
    
    -- Primary Key with DivisionName included
    PRIMARY KEY (VoterID, DivisionName),
    
    -- Foreign Key Constraint on DivisionName
    FOREIGN KEY (DivisionName) REFERENCES ElectoralDivision(DivisionName),
    
    -- Unique constraint with DivisionName included
    UNIQUE (FirstName, LastName, DoB, ResidentialAddress, DivisionName)
)
ON VoterRegistryDivisionPartitionScheme (DivisionName);
