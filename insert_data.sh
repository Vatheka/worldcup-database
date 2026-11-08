#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

# Read the CSV and prepare the team and game records
TEAM_VALUES=""
GAME_VALUES=""

while IFS="," read -r YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
do
  # Skip the header and any empty lines
  if [[ $YEAR == "year" || -z $YEAR ]]
  then
    continue
  fi

  # Collect the team names
  TEAM_VALUES+="${TEAM_VALUES:+,}('$WINNER'),('$OPPONENT')"

  # Collect each game and its results
  GAME_VALUES+="${GAME_VALUES:+,}($YEAR,'$ROUND','$WINNER','$OPPONENT',$WINNER_GOALS,$OPPONENT_GOALS)"

done < games.csv

# Insert all the records in one database call
$PSQL "
BEGIN;

TRUNCATE TABLE games, teams RESTART IDENTITY;

INSERT INTO teams(name)
SELECT DISTINCT name
FROM (VALUES $TEAM_VALUES) AS t(name);

INSERT INTO games(
  year, round, winner_id, opponent_id,
  winner_goals, opponent_goals
)
SELECT
  g.year, g.round, w.team_id, o.team_id,
  g.winner_goals, g.opponent_goals
FROM (
  VALUES $GAME_VALUES
) AS g(year, round, winner, opponent, winner_goals, opponent_goals)
JOIN teams AS w ON w.name = g.winner
JOIN teams AS o ON o.name = g.opponent;

COMMIT;
"
