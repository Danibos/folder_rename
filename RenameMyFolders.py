import os
from tmdbv3api import TMDb, Search, Movie
import re

# Initialize TMDb and search objects with your API key
api_key = 'ADD YOUR API KEY HERE'
tmdb = TMDb()
tmdb.api_key = api_key
tmdb.language = 'es'  # Set the language to Spanish
search = Search()
movie = Movie()

def get_movie_info(title, year=None):
    try:
        # Debugging log
        print(f"Searching TMDB for: {title} ({year if year else 'N/A'})")

        # Perform the search using TMDB API with the title as a positional argument
        results = search.movies(title)
        
        if results:
            # Filter results by year if provided, else take the first result
            for movie in results:
                if year and movie.release_date and movie.release_date.startswith(str(year)):
                    return movie
            return results[0] if results else None
        else:
            print(f"No results found for: {title} ({year})")
    except Exception as e:
        print(f"Error retrieving movie info: {e}")
    return None

def get_director_name(movie_id):
    try:
        credits = movie.credits(movie_id)
        for crew_member in credits['crew']:
            if crew_member['job'] == 'Director':
                return crew_member['name']
    except Exception as e:
        print(f"Error retrieving director info: {e}")
    return None

def rename_file_with_tmdb_info(folder_path, file_name, movie_info):
    file_extension = file_name.split('.')[-1]
    new_file_name = f"{movie_info.original_title} ({movie_info.release_date[:4]}).{file_extension}"
    old_file_path = os.path.join(folder_path, file_name)
    new_file_path = os.path.join(folder_path, new_file_name)

    if not os.path.exists(new_file_path):
        os.rename(old_file_path, new_file_path)
        print(f"Renamed file to: {new_file_name}")

def rename_folder_with_tmdb_info(folder_path, file_name):
    title, year = parse_title_year(file_name)
    if year is None:
        # Try to get the year from TMDB if it's missing
        print(f"No year found in file name, fetching from TMDB for: {file_name}")
    movie_info = get_movie_info(title, year)

    if movie_info:
        # Get the director's name
        director_name = get_director_name(movie_info.id)
        if director_name:
            print(f"Director: {director_name}")

        # Rename the folder to the movie title, year, and director's name in Spanish
        new_folder_name = f"{movie_info.title} ({movie_info.release_date[:4]}) {director_name}"
        new_folder_path = os.path.join(os.path.dirname(folder_path), new_folder_name)

        if not os.path.exists(new_folder_path):
            os.rename(folder_path, new_folder_path)
            print(f"Renamed folder to: {new_folder_name}")

        # Rename the movie file inside the folder if needed
        rename_file_with_tmdb_info(new_folder_path, file_name, movie_info)
    else:
        print(f"Could not find movie info for: {title} ({year})")

def parse_title_year(file_name):
    """
    Extracts the title and year from a filename like 'Movie Title (Year).extension'.
    Handles missing year case.
    """
    pattern = re.compile(r"(.*) \((\d{4})\)")
    match = pattern.match(file_name)
    if match:
        title = match.group(1).strip()
        year = match.group(2).strip()
        return title, year
    else:
        # If the file name doesn't contain the year, return just the title and None for the year
        title = os.path.splitext(file_name)[0].strip()  # Remove the extension
        return title, None

def process_folder(folder_path):
    for file_name in os.listdir(folder_path):
        # Ignore metadata or hidden files like ._*
        if file_name.startswith("._"):
            continue
        if file_name.lower().endswith(('.avi', '.mkv', '.mp4')):  # Add other video formats as needed
            rename_folder_with_tmdb_info(folder_path, file_name)
            break  # Exit loop after processing the first video file

def create_folder_for_movie(base_directory, file_name):
    title, year = parse_title_year(file_name)
    if year is None:
        print(f"No year found in file name, fetching from TMDB for: {file_name}")
    movie_info = get_movie_info(title, year)

    if movie_info:
        director_name = get_director_name(movie_info.id)
        if director_name:
            print(f"Director: {director_name}")

        new_folder_name = f"{movie_info.title} ({movie_info.release_date[:4]}) {director_name}"
        new_folder_path = os.path.join(base_directory, new_folder_name)

        if not os.path.exists(new_folder_path):
            os.makedirs(new_folder_path)
            print(f"Created folder: {new_folder_name}")

        old_file_path = os.path.join(base_directory, file_name)
        new_file_path = os.path.join(new_folder_path, f"{movie_info.original_title} ({movie_info.release_date[:4]}).{file_name.split('.')[-1]}")

        if not os.path.exists(new_file_path):
            os.rename(old_file_path, new_file_path)
            print(f"Moved file to: {new_file_path}")
    else:
        print(f"Could not find movie info for: {title} ({year})")

def rename_folders(base_directory):
    for item_name in os.listdir(base_directory):
        item_path = os.path.join(base_directory, item_name)
        if os.path.isdir(item_path):
            process_folder(item_path)
        elif item_name.lower().endswith(('.avi', '.mkv', '.mp4')):
            create_folder_for_movie(base_directory, item_name)

if __name__ == "__main__":
    base_directory = os.getcwd()  # Use the current working directory
    print(f"Base directory: {base_directory}")
    rename_folders(base_directory)
