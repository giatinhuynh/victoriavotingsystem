-- Selects the division name, candidate name, and political party name for the specified election event
SELECT
    E.DivisionName AS Electorate,
    C.Name AS CandidateName,
    P.PartyName AS PoliticalParty
FROM
    ElectionEvent EE
JOIN
    Contests CO ON EE.ElectionEventID = CO.ElectionEventID
JOIN
    Candidate C ON CO.CandidateID = C.CandidateID
JOIN
    PoliticalParty P ON C.PartyCode = P.PartyCode
JOIN
    ElectoralDivision E ON EE.DivisionName = E.DivisionName
WHERE
    EE.ElectionEventID = '20220521'
ORDER BY
    E.DivisionName,
    NEWID();

-- Creates an index on the ElectionEventID column of the Contests table to improve query performance when filtering or joining on ElectionEventID
CREATE INDEX idx_contests_electioneventid
ON Contests (ElectionEventID);

-- Creates an index on the DivisionName column of the ElectoralDivision table to improve query performance when filtering or joining on DivisionName
CREATE INDEX idx_electoraldivision_divisionname
ON ElectoralDivision (DivisionName);

-- Creates an index on the CandidateID column of the Contests table to improve performance when joining or filtering on CandidateID
CREATE INDEX idx_contests_candidateid
ON Contests (CandidateID);

-- Creates an index on the PartyCode column of the PoliticalParty table to speed up joins and lookups involving PartyCode
CREATE INDEX idx_politicalparty_partycode
ON PoliticalParty (PartyCode);



