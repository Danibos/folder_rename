Movie Folder Renamer

With the help of AI, I've created this script to rename my movie folders. 
The script can rename folders by replacing the original movie title with the title from a selected country, and it will also add the release year and the director’s name.

Features

Rename by Country: Automatically fetches and replaces the folder name with the movie title in the language of your choice.
Add Release Year: The script appends the release year of the movie to the folder name.
Include Director’s Name: It also appends the director's name at the end of the folder name.
Supports Multiple Languages: You can change the language of the movie title by modifying a single line in the script.

Requirements

Python 3: The script is compatible with Python 3.

TMDB API Key: You'll need an API key from TMDB to use the script.


Usage


Set up your environment:

Clone this repository to your local machine.

Install the required Python packages using pip install requests.


Edit the Script:

Open the script and add your TMDB API key.

(Optional) Change the language for the movie titles by modifying the LANGUAGE variable.

Run the Script:

Place the script in the directory containing your movie folders.

Run the script, and it will automatically rename the folders based on the movie information.

Example

Before: Saturday Night Fever (1977)

After: Fiebre del sábado noche (1977) John Badham

Notes

Ensure your movie folders contain .nfo files with metadata for accurate renaming.

If a director’s name isn’t found in the .nfo file, the script will attempt to retrieve it from TMDB.

License
This project is open-source and available under the MIT License
