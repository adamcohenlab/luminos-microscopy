"""
Prints the default parameters for each waveform function in the Waveform_Functions folder.
To save the output to a file, run the script as

python3 add_defaults_to_wfms.py > defaults.txt

"""

import re
import os

def get_default_params(filename):
    """
    Reads a MATLAB .m file containing a function and returns a dictionary of default parameters for the specified function.

    Args:
    - filename (str): the name of the .m file.

    Returns:
    - default_params (dict): a dictionary containing the default parameters for the specified function.
    """
    default_params = {}

    # Define regex pattern to match default parameter assignments
    pattern = r'(\w+)\s*=\s*defcheck\((\w+),\s*([0-9.e+-]+)\);'

    filepath = os.path.join(os.path.dirname(__file__),
                            "Waveform_Functions", filename)

    # Read the file and search for the specified function
    with open(filepath, 'r') as f:
        content = f.read()
        # remove all spaces
        content = content.replace(" ", "")

        # Find default parameter assignments in the function body
        matches = re.findall(pattern, content)
        for match in matches:
            default_params[match[0]] = float(match[2])

    return default_params


def get_function_args(filename):
    """
    Reads a MATLAB .m file containing a function and returns a list of the function's arguments.

    Args:
    - filename (str): the name of the .m file.

    Returns:
    - function_args (list): a list of the function's arguments.
    """
    function_args = []

    # Define regex pattern to match function arguments
    pattern = r'function\s+\w+\s*=\s*\w+\((.+)\)'

    filepath = os.path.join(os.path.dirname(__file__),
                            "Waveform_Functions", filename)

    # Read the file and search for the specified function
    with open(filepath, 'r') as f:
        content = f.read()

        # Find the function's arguments
        match = re.search(pattern, content)
        if match:
            function_args = match.group(1).split(',')

    return function_args[1:]  # Remove the first argument (t)


def print_default_params(filename):
    """
    Prints thedefault parameters for the specified function.

    Args:
    - filename (str): the name of the .m file.
    """
    default_params = get_default_params(filename)
    function_args = get_function_args(filename)

    print("% [DEFAULTS] add default values and units below")
    for arg in function_args:
        if arg in default_params:
            # print but drop the 0s after the decimal point
            # e.g. 1.30 --> 1.3 and 1.0 --> 1
            print("% {}, {:g}".format(arg, default_params[arg]))
        else:
            print("% {}".format(arg))
    print("% [END]")

# write main function
if __name__ == "__main__":
    for filename in os.listdir(os.path.join(os.path.dirname(__file__), "Waveform_Functions")):
        if filename.endswith(".m"):
            print(filename)
            print_default_params(filename)
            print()