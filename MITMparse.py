import pandas as pd
import re

def parse_mitm_log(log_file):
    commands = []

    command_pattern = re.compile(r'line from reader:\s*(.*)')  

    with open(log_file, 'r') as file:
        for line in file:
            match = command_pattern.search(line)
            if match:
                commands.append(match.group(1).strip())

    return commands

def save_to_excel(commands, output_file):
    df = pd.DataFrame(commands, columns=['Commands'])
    df.to_excel(output_file, index=False)

def main():
    log_file = 'mitm_log.txt'  
    output_file = 'commands.xlsx' 

    commands = parse_mitm_log(log_file)
    save_to_excel(commands, output_file)

if __name__ == "__main__":
    main()
