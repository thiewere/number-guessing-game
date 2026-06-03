#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
RANDOM_NUMBER=$(( RANDOM % 1000 + 1 ))
NUMBER_OF_GUESSES=0

echo "Enter your username:"
read USERNAME

GUESSING_NUMBER() {
    echo -e "\nGuess the secret number between 1 and 1000:"

    while true
    do
        read GUESS_NUMBER
            
        # if user input not an integer
        if [[ ! $GUESS_NUMBER =~ ^[0-9]+$ ]]
        then
            echo "That is not an integer, guess again:"
        else
            (( NUMBER_OF_GUESSES++ ))

            # check user input
            if [[ $GUESS_NUMBER -eq $RANDOM_NUMBER ]]
            then
                echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $RANDOM_NUMBER. Nice job!"

                # get the user_id
                USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")

                INSERT_GAME=$($PSQL "INSERT INTO games(user_id, number_of_guesses) VALUES($USER_ID, $NUMBER_OF_GUESSES)")
                break
            elif [[ $GUESS_NUMBER -lt $RANDOM_NUMBER ]]
            then
                echo "It's higher than that, guess again:"
            else
                echo "It's lower than that, guess again:"
            fi
        fi
    done
}

GET_USERNAME=$($PSQL "SELECT username FROM users WHERE username='$USERNAME'")

# if username doesn't exist
if [[ -z $GET_USERNAME ]]
then
    # insert username in db
    INSERT_USER=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")

    if [[ $INSERT_USER == "INSERT 0 1" ]]
    then
        echo "Welcome, $USERNAME! It looks like this is your first time here."
        GUESSING_NUMBER 
    fi
else
    USER_GAMES=$($PSQL "SELECT user_id, COUNT(*), MIN(number_of_guesses) FROM users INNER JOIN games USING(user_id) WHERE username='$USERNAME' GROUP BY(user_id)")
    
    echo $USER_GAMES | while IFS="|" read USER_ID GAMES_PLAYED BEST_GAME
    do
        echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
    done
    GUESSING_NUMBER
fi
