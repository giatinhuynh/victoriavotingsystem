-- Select the electoral division name and the total number of voters in each division
SELECT
    E.DivisionName,
    COUNT(V.VoterID) AS TotalVoters
FROM
    ElectoralDivision E
JOIN
    VoterRegistry V ON E.DivisionName = V.DivisionName
GROUP BY
    E.DivisionName
ORDER BY
    TotalVoters DESC;

-- Create an index on the DivisionName column in the VoterRegistry table to improve lookup performance
CREATE INDEX idx_voterregistry_divisionname
ON VoterRegistry (DivisionName);

-- Create an index on the DivisionName column in the ElectoralDivision table to improve lookup performance
CREATE INDEX idx_electoraldivision_divisionname
ON ElectoralDivision (DivisionName);

