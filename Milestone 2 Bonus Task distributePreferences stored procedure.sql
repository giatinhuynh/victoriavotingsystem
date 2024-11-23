CREATE OR ALTER PROCEDURE distributePreferences
    @ElectionEventID INT,          -- Input: Election event identifier
    @DivisionName NVARCHAR(100)    -- Input: Electoral division name
AS
BEGIN
    -- Set NOCOUNT to ON to prevent messages from interfering with the result
    SET NOCOUNT ON;
    
    -- Set XACT_ABORT to ON to ensure that the transaction is rolled back if an error occurs
    SET XACT_ABORT ON;

    -- Declare variables to store vote counts, candidate IDs, round number, and preference aggregates
    DECLARE @TotalValidVotes INT;
    DECLARE @HalfValidVotes DECIMAL(18,2);         -- Majority threshold (50% + 1)
    DECLARE @WinnerCandidateID INT = NULL;         -- Stores the winner's candidate ID
    DECLARE @LoserCandidateID INT = NULL;          -- Stores the loser's candidate ID
    DECLARE @RoundNo INT = 0;                      -- Round number starts from 0 (initial state)
    DECLARE @EliminatedCandidateID INT = NULL;     -- Stores the ID of the eliminated candidate
    DECLARE @PreferenceAggregate INT;              -- Aggregate preference count for the round

    BEGIN TRY
        -- Start a transaction to ensure data consistency during vote redistribution
        BEGIN TRANSACTION;

        -- Verify that the specified ElectionEventID and DivisionName exist
        IF NOT EXISTS (
            SELECT 1
            FROM ElectionEvent
            WHERE ElectionEventID = @ElectionEventID
              AND DivisionName = @DivisionName
        )
        BEGIN
            -- Raise an error if ElectionEventID or DivisionName is invalid
            RAISERROR('Invalid ElectionEventID or Division Name.', 16, 1);
            RETURN;
        END;

        -- Step 1: Clear existing data related to this election event from previous rounds
        DELETE FROM PreferenceTallyPerRoundPerCandidate WHERE ElectionEventID = @ElectionEventID;
        DELETE FROM PrefCountRecord WHERE ElectionEventID = @ElectionEventID;

        -- Reset FinalVoteCount and IsWinner fields in the ElectionResults table
        UPDATE ElectionResults
        SET FinalVoteCount = NULL,
            IsWinner = 0
        WHERE ElectionEventID = @ElectionEventID;

        -- Step 2: Retrieve the total number of valid votes from the ElectionEvent table
        SELECT @TotalValidVotes = VotesValid
        FROM ElectionEvent
        WHERE ElectionEventID = @ElectionEventID;

        -- Step 3: If VotesValid is NULL, calculate it from the ElectionResults table
        IF @TotalValidVotes IS NULL
        BEGIN
            SELECT @TotalValidVotes = SUM(PrimaryVoteCount)
            FROM ElectionResults
            WHERE ElectionEventID = @ElectionEventID;
        END;

        -- Set the majority threshold (50% + 1) for determining a winner
        SET @HalfValidVotes = (@TotalValidVotes / 2.0) + 1;

        -- Step 4: Create temporary tables to track the current state of ballots and candidate tallies
        CREATE TABLE #BallotCurrentCandidate (
            BallotID INT PRIMARY KEY,              -- BallotID for tracking the current candidate's votes
            CurrentCandidateID INT                -- The candidate currently associated with each ballot
        );

        -- Table to store tally of votes for each candidate
        CREATE TABLE #CandidateTallies (
            CandidateID INT PRIMARY KEY,           -- CandidateID
            Tally INT                              -- Tally of votes for each candidate
        );

        -- Table to store the IDs of candidates still in the running
        CREATE TABLE #ContinuingCandidates (
            CandidateID INT PRIMARY KEY            -- CandidateID of remaining candidates
        );

        -- Step 5: Initialize candidate tallies from the ElectionResults table
        INSERT INTO #CandidateTallies (CandidateID, Tally)
        SELECT CandidateID, PrimaryVoteCount
        FROM ElectionResults
        WHERE ElectionEventID = @ElectionEventID;

        -- Step 6: Initialize ballots with their current candidate (start with first preference)
        INSERT INTO #BallotCurrentCandidate (BallotID, CurrentCandidateID)
        SELECT bp.BallotID, bp.CandidateID
        FROM BallotPreferences bp
        INNER JOIN Ballot b ON bp.BallotID = b.BallotID
        WHERE b.ElectionEventID = @ElectionEventID
          AND bp.Preference = 1;

        -- Step 7: Initialize continuing candidates (all candidates start as continuing)
        INSERT INTO #ContinuingCandidates (CandidateID)
        SELECT CandidateID FROM #CandidateTallies;

        -- Calculate the initial PreferenceAggregate (total number of votes in this round)
        SELECT @PreferenceAggregate = SUM(Tally)
        FROM #CandidateTallies;

        -- Insert the initial vote counts into PrefCountRecord for round 0
        INSERT INTO PrefCountRecord (ElectionEventID, RoundNo, EliminatedCandidateID, CountStatus, PreferenceAggregate)
        VALUES (@ElectionEventID, @RoundNo, NULL, 'Initial', @PreferenceAggregate);

        -- Insert the initial tally for each candidate into PreferenceTallyPerRoundPerCandidate for round 0
        INSERT INTO PreferenceTallyPerRoundPerCandidate (ElectionEventID, RoundNo, CandidateID, PreferenceTally)
        SELECT @ElectionEventID, @RoundNo, CandidateID, Tally
        FROM #CandidateTallies;

        -- Increment round number for the first elimination round
        SET @RoundNo = @RoundNo + 1;

        -- Main redistribution loop: Continue until a winner is found
        WHILE 1 = 1
        BEGIN
            -- Step 8: Check if only two candidates remain
            IF (SELECT COUNT(*) FROM #ContinuingCandidates) = 2
            BEGIN
                -- Assign Winner and Loser Candidate IDs based on tally
                SELECT TOP 1 @WinnerCandidateID = CandidateID
                FROM #CandidateTallies
                WHERE CandidateID IN (SELECT CandidateID FROM #ContinuingCandidates)
                ORDER BY Tally DESC;

                SELECT TOP 1 @LoserCandidateID = CandidateID
                FROM #CandidateTallies
                WHERE CandidateID IN (SELECT CandidateID FROM #ContinuingCandidates)
                AND CandidateID <> @WinnerCandidateID
                ORDER BY Tally ASC;

                -- Step 9: Update final vote counts in ElectionResults
                UPDATE er
                SET FinalVoteCount = ct.Tally,
                    IsWinner = CASE WHEN er.CandidateID = @WinnerCandidateID THEN 1 ELSE 0 END
                FROM ElectionResults er
                INNER JOIN #CandidateTallies ct ON er.CandidateID = ct.CandidateID
                WHERE er.ElectionEventID = @ElectionEventID;

                -- Update ElectionEvent table with winner and loser information
                UPDATE ElectionEvent
                SET TwoCandidatePrefWinnerCandidateID = @WinnerCandidateID,
                    TwoCandidatePrefLoserCandidateID = @LoserCandidateID,
                    WinnerTally = (SELECT Tally FROM #CandidateTallies WHERE CandidateID = @WinnerCandidateID),
                    LoserTally = (SELECT Tally FROM #CandidateTallies WHERE CandidateID = @LoserCandidateID)
                WHERE ElectionEventID = @ElectionEventID;

                -- Mark the round as completed in PrefCountRecord
                UPDATE PrefCountRecord
                SET CountStatus = 'Completed'
                WHERE ElectionEventID = @ElectionEventID
                  AND RoundNo = @RoundNo;

                -- Exit the loop since the process is complete
                BREAK;
            END;

            -- Step 10: Identify and eliminate the candidate with the fewest votes
            SELECT TOP 1 @EliminatedCandidateID = CandidateID
            FROM #CandidateTallies
            WHERE CandidateID IN (SELECT CandidateID FROM #ContinuingCandidates)
            ORDER BY Tally ASC, CandidateID ASC; -- Use CandidateID to break ties

            -- Remove the eliminated candidate from continuing candidates
            DELETE FROM #ContinuingCandidates WHERE CandidateID = @EliminatedCandidateID;

            -- Step 11: Redistribute votes from the eliminated candidate to remaining candidates
            ;WITH NextPreferences AS (
                SELECT
                    bc.BallotID,
                    MIN(bp.Preference) AS NextPreference
                FROM #BallotCurrentCandidate bc
                INNER JOIN BallotPreferences bp ON bc.BallotID = bp.BallotID
                WHERE bc.CurrentCandidateID = @EliminatedCandidateID
                  AND bp.Preference > (
                      SELECT MAX(bp2.Preference)
                      FROM BallotPreferences bp2
                      WHERE bp2.BallotID = bp.BallotID
                        AND bp2.CandidateID = @EliminatedCandidateID
                  )
                  AND bp.CandidateID IN (SELECT CandidateID FROM #ContinuingCandidates)
                GROUP BY bc.BallotID
            )
            UPDATE bc
            SET CurrentCandidateID = bp.CandidateID
            FROM #BallotCurrentCandidate bc
            INNER JOIN NextPreferences np ON bc.BallotID = np.BallotID
            INNER JOIN BallotPreferences bp ON bp.BallotID = bc.BallotID AND bp.Preference = np.NextPreference
            WHERE bc.CurrentCandidateID = @EliminatedCandidateID;

            -- Step 12: Remove exhausted ballots (those with no further preferences)
            DELETE bc
            FROM #BallotCurrentCandidate bc
            WHERE bc.CurrentCandidateID = @EliminatedCandidateID
              AND NOT EXISTS (
                  SELECT 1
                  FROM BallotPreferences bp
                  WHERE bp.BallotID = bc.BallotID
                    AND bp.Preference > (
                        SELECT MAX(bp2.Preference)
                        FROM BallotPreferences bp2
                        WHERE bp2.BallotID = bp.BallotID
                          AND bp2.CandidateID = @EliminatedCandidateID
                    )
                    AND bp.CandidateID IN (SELECT CandidateID FROM #ContinuingCandidates)
              );

            -- Step 13: Recalculate tallies for the remaining candidates
            -- First, reset all tallies to zero
            UPDATE #CandidateTallies
            SET Tally = 0;

            -- Update the tallies based on the current candidate assignments (after redistribution)
            UPDATE ct
            SET Tally = bcc.VoteCount
            FROM #CandidateTallies ct
            INNER JOIN (
                -- Calculate the new vote count for each continuing candidate
                SELECT CurrentCandidateID, COUNT(*) AS VoteCount
                FROM #BallotCurrentCandidate
                GROUP BY CurrentCandidateID
            ) bcc ON ct.CandidateID = bcc.CurrentCandidateID;

            -- Calculate the PreferenceAggregate for this round (total votes for remaining candidates)
            SELECT @PreferenceAggregate = SUM(Tally)
            FROM #CandidateTallies
            WHERE CandidateID IN (SELECT CandidateID FROM #ContinuingCandidates);

            -- Insert the updated tallies for the current round into PrefCountRecord
            INSERT INTO PrefCountRecord (ElectionEventID, RoundNo, EliminatedCandidateID, CountStatus, PreferenceAggregate)
            VALUES (@ElectionEventID, @RoundNo, @EliminatedCandidateID, 'Ongoing', @PreferenceAggregate);

            -- Insert the updated tallies into PreferenceTallyPerRoundPerCandidate for this round
            INSERT INTO PreferenceTallyPerRoundPerCandidate (ElectionEventID, RoundNo, CandidateID, PreferenceTally)
            SELECT @ElectionEventID, @RoundNo, CandidateID, Tally
            FROM #CandidateTallies;

            -- Update ElectionResults table with the current tallies for each candidate
            UPDATE er
            SET FinalVoteCount = ct.Tally
            FROM ElectionResults er
            INNER JOIN #CandidateTallies ct ON er.CandidateID = ct.CandidateID
            WHERE er.ElectionEventID = @ElectionEventID;

            -- Step 14: Increment the round number for the next iteration
            SET @RoundNo = @RoundNo + 1;
        END; -- End of the main WHILE loop for redistribution

        -- Commit the transaction if all rounds are processed successfully
        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        -- Rollback the transaction in case of any errors
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Capture and raise the error message
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH;

    -- Clean up temporary tables used for vote redistribution and tallying
    IF OBJECT_ID('tempdb..#CandidateTallies') IS NOT NULL
        DROP TABLE #CandidateTallies;
    IF OBJECT_ID('tempdb..#BallotCurrentCandidate') IS NOT NULL
        DROP TABLE #BallotCurrentCandidate;
    IF OBJECT_ID('tempdb..#ContinuingCandidates') IS NOT NULL
        DROP TABLE #ContinuingCandidates;

END; -- End of the distributePreferences stored procedure

-- Example execution: redistributes preferences for the 2022 election in the Adelaide division
EXEC distributePreferences 20220521, 'Adelaide';

-- Check the results in relevant tables after running the stored procedure
SELECT * FROM ElectionResults WHERE ElectionEventID = 20220521

SELECT * FROM ElectionEvent WHERE ElectionEventID = 20220521 AND DivisionName = 'Adelaide'

SELECT * FROM PrefCountRecord WHERE ElectionEventID = 20220521

SELECT * FROM PreferenceTallyPerRoundPerCandidate WHERE ElectionEventID= 20220521
