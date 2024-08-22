LANGUAGE = 'es'  # Change this to your desired language code


import os
import re
import requests
import shutil



# Replace with your TMDB API key
API_KEY = 'ADD YOUR API KEY HERE' 
BASE_URL = 'https://api.themoviedb.org/3'

def get_movie_details(movie_name, movie_id=None):
    search_url = f'{BASE_URL}/search/movie'
    search_params = {
        'api_key': API_KEY,
        'query': movie_name,
        'language': 'en-US'
    }
    
    if movie_id:
        search_url = f'{BASE_URL}/movie/{movie_id}'
        search_params = {'api_key': API_KEY, 'language': LANGUAGE}
    
    response = requests.get(search_url, params=search_params)
    data = response.json()
    
    if movie_id or data.get('results'):
        if movie_id:
            details = data
        else:
            movie_id = data['results'][0]['id']
            details_url = f'{BASE_URL}/movie/{movie_id}'
            details_params = {'api_key': API_KEY, 'language': LANGUAGE}
            details_response = requests.get(details_url, params=details_params)
            details = details_response.json()
        
        title = details.get('title', 'No title found')
        release_date = details.get('release_date', 'No date found')
        year = release_date.split('-')[0] if release_date else 'No year found'
        return title, year, movie_id
    return 'No movie found', None, None

def get_director_from_credits(movie_id):
    credits_url = f'{BASE_URL}/movie/{movie_id}/credits'
    credits_params = {'api_key': API_KEY}
    response = requests.get(credits_url, params=credits_params)
    credits_data = response.json()
    
    # Find the director from the credits
    for crew_member in credits_data.get('crew', []):
        if crew_member['job'] == 'Director':
            return crew_member['name']
    return 'Unknown Director'

def extract_director(nfo_file_path):
    director_pattern = re.compile(r'<movie>.*?<director>(.*?)</director>.*?</movie>', re.DOTALL)
    unique_id_pattern = re.compile(r'<uniqueid type="tmdb" default="true">(.*?)</uniqueid>', re.DOTALL)
    
    try:
        with open(nfo_file_path, 'r') as file:
            content = file.read()
        
        director_match = director_pattern.search(content)
        unique_id_match = unique_id_pattern.search(content)
        
        director_name = director_match.group(1).strip() if director_match else None
        unique_id = unique_id_match.group(1).strip() if unique_id_match else None
        
        return director_name, unique_id
    except FileNotFoundError:
        return None, None

def find_nfo_file(folder_path):
    for filename in os.listdir(folder_path):
        if filename.lower().endswith('.nfo'):
            return os.path.join(folder_path, filename)
    return None

def rename_folders():
    base_directory = os.getcwd()  # Get the current working directory

    for folder_name in os.listdir(base_directory):
        folder_path = os.path.join(base_directory, folder_name)
        
        if os.path.isdir(folder_path):
            nfo_file_path = find_nfo_file(folder_path)
            
            if nfo_file_path:
                # Extract director and unique ID
                director_name, unique_id = extract_director(nfo_file_path)
                
                if unique_id:
                    spanish_title, year, movie_id = get_movie_details(None, unique_id)
                    if movie_id:
                        director_name = get_director_from_credits(movie_id)
                else:
                    spanish_title, year, movie_id = get_movie_details(folder_name)
                    if movie_id:
                        director_name = get_director_from_credits(movie_id)
                
                if spanish_title != 'No movie found' and year:
                    if not director_name:
                        # Use placeholder if director is not found in .nfo file or TMDB
                        director_name = 'Unknown Director'
                    
                    new_folder_name = f"{spanish_title} ({year}) {director_name}"
                    new_folder_path = os.path.join(base_directory, new_folder_name)
                    
                    shutil.move(folder_path, new_folder_path)
                    print(f"Renamed folder to: {new_folder_path}")
                else:
                    print(f"Spanish title not found or movie details incomplete for '{folder_name}'")
            else:
                print(f"No .nfo file found in {folder_path}")

# Execute the function
rename_folders()
