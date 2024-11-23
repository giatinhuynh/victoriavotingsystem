-- Create or Alter the previouslyVoted function to check if a voter has voted in a specific election event and division
CREATE OR ALTER FUNCTION previouslyVoted
(
    @ElectionEventID INT,          -- Input: Election event identifier (unique for each election)
    @VoterID INT,                  -- Input: Voter identifier (unique for each voter)
    @DivisionName NVARCHAR(100)    -- Input: Electoral division name (specifies the voter's division)
)
RETURNS BIT                         -- Output: Returns a boolean value (1 = True, 0 = False) to indicate if the voter has voted
AS
BEGIN
    DECLARE @HasVoted BIT;          -- Declare a variable to store the result (1 if voted, 0 if not

    -- Check if there is a record in the IssuanceRecord table for the given voter, election, and division
    IF EXISTS (
        SELECT 1                    -- Check if at least one record exists (no need for full details)
        FROM IssuanceRecord IR       -- From the IssuanceRecord table (stores issued ballot records)
        JOIN VoterRegistry VR ON IR.VoterID = VR.VoterID  -- Join VoterRegistry to get voter details
        WHERE IR.ElectionEventID = @ElectionEventID       -- Filter by the election event
          AND IR.VoterID = @VoterID                       -- Filter by the voter ID (use IR.VoterID instead of VR.VoterID)
          AND VR.DivisionName = @DivisionName             -- Filter by the division name
    )
    BEGIN
        SET @HasVoted = 1;           -- Set @HasVoted to 1 (True), meaning the voter has voted
    END
    ELSE
    BEGIN
        SET @HasVoted = 0;           -- Set @HasVoted to 0 (False), meaning the voter has not voted
    END

    RETURN @HasVoted;                -- Return the result (1 if voted, 0 if not voted)
END;


-- Example usage of the previouslyVoted function
-- This query checks if the voter with VoterID 1 has voted in the 2013 election (ElectionEventID 20130907) in the 'Canning' division
SELECT dbo.previouslyVoted(20220521, 2, 'Canning') AS HasVoted;