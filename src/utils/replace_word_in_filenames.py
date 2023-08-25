import os


def replace_word_in_filenames(directory, old_word, new_word):
    for root, dirs, files in os.walk(directory):
        for filename in files:
            if old_word in filename:
                old_filepath = os.path.join(root, filename)
                new_filename = filename.replace(old_word, new_word)
                new_filepath = os.path.join(root, new_filename)
                os.rename(old_filepath, new_filepath)
                print(f'Renamed "{old_filepath}" to "{new_filepath}"')


# Usage example
directory = "C:\\Users\\Cohen Lab\\Documents\\GitHub\\luminos\\src"  # Replace with the target directory path
old_word = "Confocal"
new_word = "Scanning"
replace_word_in_filenames(directory, old_word, new_word)
