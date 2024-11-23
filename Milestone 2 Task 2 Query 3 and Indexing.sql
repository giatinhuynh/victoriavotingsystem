-- Selects the first name, last name, and residential address of voters who did not vote in the 2022 and 2019 federal elections
SELECT 
    V.FirstName, 
    V.LastName, 
    V.ResidentialAddress
FROM VoterRegistry V
WHERE V.VoterID NOT IN (
    SELECT IR.VoterID 
    FROM IssuanceRecord IR
    WHERE IR.ElectionEventID IN (20220521, 20190518)
);

-- Creates an index on the VoterID and ElectionEventID columns in the IssuanceRecord table to improve the performance of the subquery
CREATE INDEX idx_issuancerecord_voter_election 
ON IssuanceRecord (VoterID, ElectionEventID);

-- Creates an index on the VoterID column in the VoterRegistry table to speed up the outer query when filtering based on VoterID
CREATE INDEX idx_issuancerecord_voter_election 
ON VoterRegistry (VoterID);

