#import pandas as pd 
#from sql_metadata import Parser
import os 

def list_files(dir):
    files = []
    for pathroot, _, files in os.walk(dir):
        for file in files:
            if '.sql' in file: 
                files.append(file)

    return files


if __name__ == '__main__': 
    print("Starting Application")
    FILE_DIR = os.getcwd()

    files_list = list_files(FILE_DIR)

    print(FILE_DIR)
    print(files_list)