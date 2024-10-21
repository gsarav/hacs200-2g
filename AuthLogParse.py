import re
from collections import defaultdict
from datetime import datetime
import openpyxl

login_regex = re.compile(r'(\w+ \d+ \d+:\d+:\d+) .+ Accepted .+ from (\d+\.\d+\.\d+\.\d+)')
logout_regex = re.compile(r'(\w+ \d+ \d+:\d+:\d+) .+ session closed for user')

def parse_timestamp(timestamp):
    return datetime.strptime(timestamp, "%b %d %H:%M:%S")

login_times = defaultdict(list)
login_counts = defaultdict(int)

def parse_auth_log(file_path):
    with open(file_path, 'r') as log_file:
        for line in log_file:
            # check for login
            login_match = login_regex.search(line)
            if login_match:
                timestamp, ip = login_match.groups()
                login_times[ip].append(parse_timestamp(timestamp))
                login_counts[ip] += 1
            # check for logout
            logout_match = logout_regex.search(line)
            if logout_match and len(login_times) > 0:
                timestamp = parse_timestamp(logout_match.group(1))
                # calculate time spent in container per ip 
                for ip, times in login_times.items():
                    if times and times[-1] < timestamp:
                        times[-1] = timestamp

def calculate_time_spent():
    time_spent = defaultdict(int)
    for ip, times in login_times.items():
        if len(times) % 2 == 0:  # matching logout
            for i in range(0, len(times), 2):
                time_spent[ip] += (times[i + 1] - times[i]).total_seconds()
    return time_spent

def write_to_excel(time_spent, login_counts, output_file):
    wb = openpyxl.Workbook()
    
    # time in container
    time_sheet = wb.active
    time_sheet.title = "Time Spent"
    time_sheet.append(["IP Address", "Time Spent (seconds)"])
    
    for ip, time in time_spent.items():
        time_sheet.append([ip, time])
    
    # login count
    count_sheet = wb.create_sheet(title="Login Counts")
    count_sheet.append(["IP Address", "Login Attempts"])
    
    for ip, count in login_counts.items():
        count_sheet.append([ip, count])
    
    wb.save(output_file)

def main():
    log_file = "/var/log/auth.log"  # PATH
    output_file = "auth_report.xlsx"
    
    parse_auth_log(log_file)
    time_spent = calculate_time_spent()
    write_to_excel(time_spent, login_counts, output_file)
    print(f"Data has been written to {output_file}")

if __name__ == "__main__":
    main()
