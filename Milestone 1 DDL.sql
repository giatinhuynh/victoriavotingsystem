    -- Drop tables if they exist
    DROP TABLE IF EXISTS PreferenceTallyPerRoundPerCandidate;
    DROP TABLE IF EXISTS PrefCountRecord;
    DROP TABLE IF EXISTS IssuanceRecord;
    DROP TABLE IF EXISTS BallotPreferences;
    DROP TABLE IF EXISTS Ballot;
    DROP TABLE IF EXISTS VoterRegistry;
    DROP TABLE IF EXISTS Contests;
    DROP TABLE IF EXISTS Candidate;
    DROP TABLE IF EXISTS ElectionEvent;
    DROP TABLE IF EXISTS ElectoralDivisionHistory;
    DROP TABLE IF EXISTS ElectoralDivision;
    DROP TABLE IF EXISTS PoliticalParty;
    DROP TABLE IF EXISTS ElectionMaster;

    -- Create tables in the correct order

    -- ElectionMaster Table
    CREATE TABLE ElectionMaster (
        ElectionSerialNo INT PRIMARY KEY,
        ElectionDate DATE NOT NULL,
        Type VARCHAR(50) NOT NULL,
        TotalNumDivisions INT NOT NULL,
        TotalRegVoters INT,
        LastDateToVoterRegister DATE NOT NULL,
        LastDateCandidateNominate DATE NOT NULL,
        LastDateToDeclareResult DATE NOT NULL
    );

    -- ElectoralDivision Table
    CREATE TABLE ElectoralDivision (
        DivisionName VARCHAR(100) PRIMARY KEY,
        TotalRegVoters INT NOT NULL,
        CurrMember VARCHAR(100)
    );

    -- ElectoralDivisionHistory Table
    CREATE TABLE ElectoralDivisionHistory (
        DivisionName VARCHAR(100),
        ElectionSerialNo INT,
        HistoricRegVoters INT,
        PRIMARY KEY (DivisionName, ElectionSerialNo),
        FOREIGN KEY (DivisionName) REFERENCES ElectoralDivision(DivisionName),
        FOREIGN KEY (ElectionSerialNo) REFERENCES ElectionMaster(ElectionSerialNo)
    );

    -- PoliticalParty Table
    CREATE TABLE PoliticalParty (
        PartyCode VARCHAR(10) PRIMARY KEY,
        PartyName VARCHAR(100) NOT NULL,
        PartyLogo VARBINARY(MAX),
        PostalAddress VARCHAR(200),
        PartySecretary VARCHAR(100),
        ContactPersonName VARCHAR(100),
        ContactPersonPhone VARCHAR(20),
        ContactPersonMobile VARCHAR(20),
        ContactPersonEmail VARCHAR(100)
    );

    -- Candidate Table
    CREATE TABLE Candidate (
        CandidateID INT PRIMARY KEY,
        Name VARCHAR(100) NOT NULL,
        ContactAddress VARCHAR(200),
        ContactPhone VARCHAR(20),
        ContactMobile VARCHAR(20),
        ContactEmail VARCHAR(100),
        PartyCode VARCHAR(10),
        FOREIGN KEY (PartyCode) REFERENCES PoliticalParty(PartyCode)
    );

    -- ElectionEvent Table
    CREATE TABLE ElectionEvent (
        ElectionEventID INT,
        TotalVoters INT,
        VotesCast INT,
        VotesReject INT,
        VotesValid INT,
        ElectionSerialNo INT,
        DivisionName VARCHAR(100),
        TwoCandidatePrefWinnerCandidateID INT,
        WinnerTally INT,
        TwoCandidatePrefLoserCandidateID INT,
        LoserTally INT,
        PRIMARY KEY (ElectionEventID),
        FOREIGN KEY (ElectionSerialNo) REFERENCES ElectionMaster(ElectionSerialNo),
        FOREIGN KEY (DivisionName) REFERENCES ElectoralDivision(DivisionName)
    );

    -- Contests Table
    CREATE TABLE Contests (
        ElectionEventID INT,
        CandidateID INT,
        PRIMARY KEY (ElectionEventID, CandidateID),
        FOREIGN KEY (ElectionEventID) REFERENCES ElectionEvent(ElectionEventID),
        FOREIGN KEY (CandidateID) REFERENCES Candidate(CandidateID)
    );

    -- VoterRegistry Table
    CREATE TABLE VoterRegistry (
        VoterID INT PRIMARY KEY,
        FirstName VARCHAR(100) NOT NULL,
        MiddleNames VARCHAR(100),
        LastName VARCHAR(100) NOT NULL,
        Address VARCHAR(200),
        DoB DATE NOT NULL NOT NULL,
        Gender CHAR(1) NOT NULL,
        ResidentialAddress VARCHAR(200) NOT NULL,
        PostalAddress VARCHAR(200),
        ContactPhone VARCHAR(20),
        ContactMobile VARCHAR(20),
        ContactEmail VARCHAR(100),
        DivisionName VARCHAR(100),
        FOREIGN KEY (DivisionName) REFERENCES ElectoralDivision(DivisionName),
        UNIQUE (FirstName, LastName, DoB, ResidentialAddress)
    );

    -- Ballot Table
    CREATE TABLE Ballot (
        BallotID INT PRIMARY KEY,
        ElectionEventID INT,
        FOREIGN KEY (ElectionEventID) REFERENCES ElectionEvent(ElectionEventID)
    );

    -- BallotPreferences Table
    CREATE TABLE BallotPreferences (
        BallotID INT,
        CandidateID INT,
        Preference INT NOT NULL,
        PRIMARY KEY (BallotID, CandidateID),
        FOREIGN KEY (BallotID) REFERENCES Ballot(BallotID),
        FOREIGN KEY (CandidateID) REFERENCES Candidate(CandidateID)
    );

    -- IssuanceRecord Table
    CREATE TABLE IssuanceRecord (
        VoterID INT,
        ElectionEventID INT,
        IssueDate DATE NOT NULL,
        Timestamp DATETIME NOT NULL,
        PollingStation VARCHAR(100) NOT NULL,
        PRIMARY KEY (VoterID, ElectionEventID),
        FOREIGN KEY (VoterID) REFERENCES VoterRegistry(VoterID),
        FOREIGN KEY (ElectionEventID) REFERENCES ElectionEvent(ElectionEventID)
    );

    -- PrefCountRecord Table
    CREATE TABLE PrefCountRecord (
        ElectionEventID INT,
        RoundNo INT,
        EliminatedCandidateID INT NOT NULL,
        CountStatus VARCHAR(50) NOT NULL,
        PreferenceAggregate INT NOT NULL,
        PRIMARY KEY (ElectionEventID, RoundNo), 
        FOREIGN KEY (ElectionEventID) REFERENCES ElectionEvent(ElectionEventID),
        FOREIGN KEY (EliminatedCandidateID) REFERENCES Candidate(CandidateID)
    );

    -- PreferenceTallyPerRoundPerCandidate Table
    CREATE TABLE PreferenceTallyPerRoundPerCandidate (
        ElectionEventID INT,
        RoundNo INT,
        CandidateID INT,
        PreferenceTally INT NOT NULL,
        PRIMARY KEY (ElectionEventID, RoundNo, CandidateID),
        FOREIGN KEY (ElectionEventID, RoundNo) REFERENCES PrefCountRecord(ElectionEventID, RoundNo),
        FOREIGN KEY (CandidateID) REFERENCES Candidate(CandidateID)
    );
