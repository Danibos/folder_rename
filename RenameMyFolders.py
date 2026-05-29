import os
from tmdbv3api import TMDb, Search, Movie
import re
from concurrent.futures import ThreadPoolExecutor
import unicodedata
import platform
import xml.etree.ElementTree as ET

# Initialize TMDb and search objects with your API key
api_key = ''
tmdb = TMDb()
tmdb.api_key = api_key
tmdb.language = 'es'
search = Search()
movie = Movie()

def normalize_unicode(name):
    """Normalize unicode characters (fixes macOS name issues)."""
    return unicodedata.normalize('NFC', name)

def sanitize_filename(name):
    """Remove characters forbidden for filenames on most OS."""
    # First normalize unicode to avoid special characters from combining marks
    name = normalize_unicode(name)
    # Remove forbidden characters
    name = re.sub(r'[:?\"<>|\\/*]', '', name).strip()
    # Remove extra spaces
    name = re.sub(r'\s{2,}', ' ', name)
    return name

def is_hidden_or_system_file(name):
    """Check if file/folder is hidden or system file (macOS/Windows)."""
    return (name.startswith('.') or 
            name.startswith('._') or 
            name in ['@eaDir', 'Thumbs.db', 'desktop.ini', 'DS_Store'] or
            name == '.gitkeep')

def has_correct_format(folder_name):
    """Checks if folder_name matches 'Title (Year) Director' format."""
    return re.match(r".+ \(\d{4}\) .+", folder_name) is not None

def parse_title_year(file_name):
    """Extract title and year from filename. Returns (title, year:str) or (title, None) if year invalid/missing."""
    # First normalize the filename
    file_name = normalize_unicode(file_name)
    pattern = re.compile(r"(.*?)\s*\((\d{4})\)")
    match = pattern.search(file_name)
    if match:
        title = match.group(1).strip()
        year = match.group(2).strip()
        if year.isdigit() and len(year) == 4:
            return title, year
        else:
            return title, None
    else:
        title = os.path.splitext(file_name)[0].strip()
        return title, None

def get_movie_info(title, year=None):
    """Query TMDB for movie info using title and year (if valid). Defensive for errors and type issues."""
    try:
        print(f"Searching TMDB for: {title} ({year if year else 'N/A'})")
        clean_year = year if year and isinstance(year, str) and year.isdigit() and len(year) == 4 else None
        results = search.movies(title)
        if results:
            # If year is provided, try to find exact match
            if clean_year:
                for m in results:
                    release_year = ''
                    if hasattr(m, 'release_date') and m.release_date and len(m.release_date) >= 4:
                        release_year = m.release_date[:4]
                    if release_year == str(clean_year):
                        return m
            # Fallback to first result
            return results[0]
        else:
            print(f"No results found for: {title} ({year})")
    except Exception as e:
        print(f"Error retrieving movie info: {e}")
    return None

def get_director_name(movie_id):
    """Get director's name from TMDB crew results."""
    try:
        credits = movie.credits(movie_id)
        if credits and 'crew' in credits:
            for crew_member in credits['crew']:
                if crew_member['job'] == 'Director':
                    return crew_member['name']
    except Exception as e:
        print(f"Error retrieving director info: {e}")
    return None

def get_director_from_nfo(nfo_path):
    """Extract director name from .nfo file."""
    try:
        if not os.path.exists(nfo_path):
            return None
        
        tree = ET.parse(nfo_path)
        root = tree.getroot()
        
        # Try to find director in XML
        director_elem = root.find('director')
        if director_elem is not None and director_elem.text:
            return director_elem.text.strip()
        
        # Alternative: search in credits
        credits = root.find('credits')
        if credits is not None and credits.text:
            return credits.text.strip()
            
    except ET.ParseError:
        # NFO file might not be XML format, try text parsing
        try:
            with open(nfo_path, 'r', encoding='utf-8') as f:
                content = f.read()
                # Look for Director: pattern
                match = re.search(r'Director[:\s]+([^\n]+)', content, re.IGNORECASE)
                if match:
                    director = match.group(1).strip()
                    if director:
                        return director
        except Exception as e:
            print(f"Error parsing text NFO: {e}")
    except Exception as e:
        print(f"Error reading NFO file: {e}")
    
    return None

def remove_duplicates(folder_path, ext_list):
    """Remove duplicates, keeping the largest file (newest in case of tie)."""
    for ext in ext_list:
        files = [f for f in os.listdir(folder_path) 
                 if f.lower().endswith(ext) and not is_hidden_or_system_file(f)]
        if len(files) > 1:
            files_info = [(f, os.path.getsize(os.path.join(folder_path, f)), 
                          os.path.getmtime(os.path.join(folder_path, f))) for f in files]
            files_info.sort(key=lambda x: (-x[1], -x[2]))
            keep = files_info[0][0]
            for f, _, _ in files_info[1:]:
                print(f"Deleting duplicate: {f}")
                try:
                    os.remove(os.path.join(folder_path, f))
                except Exception as e:
                    print(f"Error deleting duplicate {f}: {e}")

def update_or_create_nfo(folder_path, movie_info):
    """
    Update or create .nfo file with TMDB movie info inside folder_path.
    If TMDB result is valid and release date exists, update NFO.
    """
    try:
        year = movie_info.release_date[:4] if (hasattr(movie_info, "release_date") and 
                                               movie_info.release_date) else ""
        nfo_filename = f"{sanitize_filename(movie_info.original_title)} ({year}).nfo"
        nfo_path = os.path.join(folder_path, nfo_filename)
        director = get_director_name(movie_info.id)
        
        genres = ''
        if hasattr(movie_info, 'genres') and isinstance(movie_info.genres, list):
            genres = ', '.join(str(g['name']) if isinstance(g, dict) and 'name' in g else str(g) 
                              for g in movie_info.genres)
        
        overview = getattr(movie_info, 'overview', '')
        
        info_lines = [
            f"Title: {movie_info.original_title}",
            f"Spanish Title: {movie_info.title}",
            f"Year: {year}",
            f"Director: {director if director else ''}",
            f"Genres: {genres}",
            f"Overview: {overview}",
        ]
        
        with open(nfo_path, 'w', encoding='utf-8') as f:
            for line in info_lines:
                f.write(line + '\n')
        print(f"Updated/created NFO file: {nfo_filename}")
    except Exception as e:
        print(f"Error writing NFO file: {e}")

def rename_files_in_folder(folder_path, movie_info):
    """Rename all video/subtitle/metadata files in folder with original title and year."""
    try:
        year = movie_info.release_date[:4] if (hasattr(movie_info, "release_date") and 
                                               movie_info.release_date) else ""
        original_title_clean = sanitize_filename(movie_info.original_title)
        exts = ['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.nfo', '.srt', '.ass', '.ssa', '.sub']
        remove_duplicates(folder_path, ['.nfo', '.srt', '.ass', '.ssa', '.sub'])
        
        for file_name in os.listdir(folder_path):
            # Skip hidden and system files
            if is_hidden_or_system_file(file_name):
                continue
            
            # Normalize filename
            file_name_normalized = normalize_unicode(file_name)
            file_lower = file_name_normalized.lower()
            
            for ext in exts:
                if file_lower.endswith(ext):
                    file_path = os.path.join(folder_path, file_name)
                    new_name = f"{original_title_clean} ({year}){ext}"
                    new_path = os.path.join(folder_path, new_name)
                    
                    if file_name != new_name and not os.path.exists(new_path):
                        try:
                            os.rename(file_path, new_path)
                            print(f"Renamed file {file_name} to {new_name}")
                        except Exception as e:
                            print(f"Error renaming {file_name} to {new_name}: {e}")
                    break
    except Exception as e:
        print(f"Error renaming files in folder: {e}")

def rename_folder_with_tmdb_info(folder_path):
    """Rename folder using Spanish Title (year) Director, rename files inside, clean up duplicates, update NFO."""
    try:
        current_folder = os.path.basename(folder_path)
        
        # Normalize folder name
        current_folder_normalized = normalize_unicode(current_folder)
        
        # Skip hidden or system folders
        if is_hidden_or_system_file(current_folder_normalized):
            print(f"Skipping hidden/system folder: {current_folder}")
            return
        
        print(f"\nDetected folder: {current_folder}")
        
        # Find reference file for extracting title/year
        ref_file = None
        for ext in ('.nfo', '.mp4', '.avi', '.mkv', '.mov', '.wmv', '.srt'):
            files = [f for f in os.listdir(folder_path) 
                     if f.lower().endswith(ext) and not is_hidden_or_system_file(f)]
            if files:
                ref_file = files[0]
                break
        
        if not ref_file:
            print(f"No valid reference file in {folder_path}, skipping.")
            return
        
        # First try to extract info from NFO file
        director_from_nfo = None
        nfo_files = [f for f in os.listdir(folder_path) 
                     if f.lower().endswith('.nfo') and not is_hidden_or_system_file(f)]
        if nfo_files:
            nfo_path = os.path.join(folder_path, nfo_files[0])
            director_from_nfo = get_director_from_nfo(nfo_path)
        
        title, year = parse_title_year(ref_file)
        movie_info = get_movie_info(title, year)
        director_clean = ""
        
        if movie_info:
            # Try to get director from TMDB, fallback to NFO
            director_name = get_director_name(movie_info.id) or director_from_nfo
            title_clean = sanitize_filename(movie_info.title) if (hasattr(movie_info, 'title') and 
                                                                   movie_info.title) else sanitize_filename(title)
            director_clean = sanitize_filename(director_name) if director_name else ""
            year_folder = movie_info.release_date[:4] if (hasattr(movie_info, "release_date") and 
                                                          movie_info.release_date) else (year if year else "")
        else:
            print(f"No TMDB info found for {title} ({year}), using fallback!")
            title_clean = sanitize_filename(title)
            year_folder = year if year else ""
            director_clean = sanitize_filename(director_from_nfo) if director_from_nfo else ""
        
        if not title_clean or not year_folder:
            print(f"Cannot rename folder: missing title or year even after fallback.")
            return
        
        new_folder_name = f"{title_clean} ({year_folder}) {director_clean}".strip()
        new_folder_name = re.sub(r'\s{2,}', ' ', new_folder_name)
        parent = os.path.dirname(folder_path)
        new_folder_path = os.path.join(parent, new_folder_name)
        
        if current_folder != new_folder_name and not os.path.exists(new_folder_path):
            print(f"Renaming folder: '{current_folder}' -> '{new_folder_name}'")
            try:
                os.rename(folder_path, new_folder_path)
                print(f"Successfully renamed folder to: {new_folder_name}")
                folder_path = new_folder_path
            except Exception as e:
                print(f"Error renaming folder: {e}")
                return
        else:
            if current_folder == new_folder_name:
                print(f"Folder already has correct name: {current_folder}")
            else:
                print(f"Folder already exists: {new_folder_name}")
        
        # Rename files, update nfo if TMDB info is valid
        if movie_info:
            rename_files_in_folder(folder_path, movie_info)
            update_or_create_nfo(folder_path, movie_info)
        else:
            print(f"Skipping file renaming and NFO update (no TMDB info)")
            
    except Exception as e:
        print(f"Unexpected error processing folder {folder_path}: {e}")

def rename_folders_parallel(base_directory, max_workers=None):
    """Process all folders using multiple threads for performance."""
    # Auto-detect optimal worker count (fewer on macOS to avoid issues)
    if max_workers is None:
        if platform.system() == 'Darwin':  # macOS
            max_workers = 4
        else:
            max_workers = 8
    
    try:
        folder_paths = [os.path.join(base_directory, item_name)
                       for item_name in os.listdir(base_directory)
                       if os.path.isdir(os.path.join(base_directory, item_name))
                       and not is_hidden_or_system_file(item_name)]
        
        print(f"Platform: {platform.system()}")
        print(f"Scanning base directory: {base_directory} with {max_workers} workers")
        print(f"Found {len(folder_paths)} valid folders to process")
        
        if not folder_paths:
            print("No valid folders found to process.")
            return
        
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            executor.map(rename_folder_with_tmdb_info, folder_paths)
        
        print("\nProcessing complete!")
    except Exception as e:
        print(f"Error in batch processing: {e}")

if __name__ == "__main__":
    base_directory = os.getcwd()
    print(f"Base directory: {base_directory}")
    rename_folders_parallel(base_directory)
