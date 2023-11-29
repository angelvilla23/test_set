#!/usr/bin/env python

"""

This Module Test Different protocols used in the TCP/IP
version 1.1 August 7th 2023

"""

# Import necessary modules and packages

import subprocess
import os
import argparse
import shutil
import datetime
import tempfile

# Define global constants and variables
url_list = ["google.com", "youtube.com", "facebook.com", "twitter.com", "instagram.com", "wikipedia.org", "whatsapp.com"]


# Define functions and classes


def get_time():
    # Get the current date and time
    current_datetime = datetime.datetime.now()

    # Format the date and time as a string with a specific format
    formatted_datetime = current_datetime.strftime("%Y-%m-%d_%H_%M_%S")

    return formatted_datetime

# Set the time that will be used as reference for the next funcions
current_t = get_time()
current_path = subprocess.check_output("pwd", shell=True, universal_newlines=True)
current_path = current_path.rstrip()  # removing the newline at the end
logfile = str(current_path) + "/Conn_test_" + current_t + ".log"


def add_time():
    # write output to a file
    with open(logfile, "a") as f:
        f.write("Starting Connectivity Check Test at time:\n")
        f.write(current_t)
        f.write("\n\r")


def remove_directory(directory):
    try:
        shutil.rmtree(directory)
        # print(f"Directory '{directory}' removed.")
    except FileNotFoundError:
        print(f"Directory '{directory}' does not exist.")
    except OSError as e:
        print(f"Error occurred while removing directory '{directory}': {e}")


def install_speedtest_cli():
    try:
        # Install speedtest-cli package using pip
        subprocess.check_call(['pip', 'install', 'speedtest-cli'])

        print("Speedtest CLI installed successfully.")

    except subprocess.CalledProcessError as e:
        print("Error occurred while installing Speedtest CLI:", e)

           
def install_dnsutils():
    # Check if the script is being run as root or with sudo privileges
    if not (subprocess.check_output("id -u", shell=True).decode().strip() == "0"):
        print("This script must be run as root or with sudo privileges.")
        print("Please run the script using 'sudo python connectivity_check.py --ins'")
        return

    # Install the necessary package
    package_managers = [
        ("apt-get", "update && apt-get install -y dnsutils"),
        ("yum", "install -y bind-utils"),
        ("pacman", "-Sy --noconfirm bind")
    ]

    for package_manager, command in package_managers:
        try:
            subprocess.check_call(f"command -v {package_manager} &> /dev/null", shell=True)
            if package_manager == "apt-get":
                subprocess.check_call("apt-get update && apt-get install -y dnsutils", shell=True)
            elif package_manager == "yum":
                subprocess.check_call("yum install -y bind-utils", shell=True)
            elif package_manager == "pacman":
                subprocess.check_call("pacman -Sy --noconfirm bind", shell=True)
            print("Dependency installation completed.")
            return
        except subprocess.CalledProcessError:
            pass

    print("Unable to determine package manager.")
    print("Please install dnsutils or bind manually.")


def install_dependencies():
    install_speedtest_cli()
    install_dnsutils()


def set_url():

    # get the URL to test
    import random
    random_url = random.randint(0, 6)
    url = url_list[random_url]
    print("The URL To test will be: " + url)
    return url


def result_check(pass_flag):
    if pass_flag == 1:
        print("Test PASS\n")
        with open(logfile, "a") as f:
            f.write("Test PASS\n\r")

    elif pass_flag == 0:
        print("Test FAIL")
        with open(logfile, "a") as f:
            f.write("Test FAIL\n\r")

    else: 
        print("My Dog ate the result...\n")
        with open(logfile, "a") as f:
            f.write("My Dog ate the result...\n\r")


def test_speed():
    print("Speedtest by Okla CLI will be execute wait a moment please...\n")
    pass_flag = 0 # reset flag to Fail
    with open(logfile, "a") as f:
                f.write("Speedtest by Okla CLI will be execute\n")

    try:
        # Run command and capture output
        output = subprocess.check_output("speedtest", shell=True)
        # Split the output into a list of lines
        lines = output.splitlines()
        for line in lines:
                # print(line)
                decoded_line = line.decode("utf-8")
                if "Download" in decoded_line : 
                    print(line)
                    pass_flag = 1 # 1 means Pass

                    #  write output to a file
                    with open(logfile, "a") as f:
                        f.write(line.decode())
                        f.write("\n\r")
                        
                if "Upload" in decoded_line : 
                    print(line)
                    with open(logfile, "a") as f:
                        f.write(line.decode())
                        f.write("\n\r")
                    

    except subprocess.CalledProcessError as e:
        print("Command failed with return code", e.returncode)
        print(e.output.decode())
        with open(logfile, "a") as f:
            f.write("\n\r")
            f.write("testing speedtest failed with error")

    result_check(pass_flag)



def get_dns_test():
    print("testing DNS to URL www.continental.com\n\r")
    pass_flag = 0 # reset flag to Fail
    with open(logfile, "a") as f:
                f.write("testing DNS to URL www.continental.com\n")

    try:
        # run command and capture output
        output = subprocess.check_output("nslookup www.continental.com", shell=True)
        lines = output.splitlines(keepends=True)
        # pass_flag = 0 # reset flag to Fail


        # Split the output into a list of lines
        lines = output.split(b'\n')
        print(lines[0].decode())

        for line in lines:
            # print(line)
            decoded_line = line.decode("utf-8")
            if "Address" in decoded_line : 
                print(line)
                pass_flag = 1 # 1 means Pass

                #  write output to a file
                with open(logfile, "a") as f:
                    f.write(line.decode())
                    f.write("\n")

    except subprocess.CalledProcessError as e:
        print("Command failed with return code", e.returncode)
        print(e.output.decode())
        with open(logfile, "a") as f:
            f.write("\n\r")
            f.write("testing URL in failed with error")
                      

    result_check(pass_flag)

"""
    # write output to a file
    with open(logfile, "a") as f:
        f.write("\n\r")
        f.write("Test for DNS started:\n\r")
        f.write("testing DNS to URL www.continental.com\n\r")
        f.write(lines[0].decode())
        f.write("\n\r")"""


def download_test():
    print("Download testing started wait a moment please...\n")
    with open(logfile, "a") as f:
                f.write("Download testing started\n")
    # Check if the directory already exists
    wget_dir = current_path + "/wget_test/"
    if not os.path.exists(wget_dir):
        # Create the new directory
        os.mkdir(wget_dir)
    # run command and capture output
    url_to_use = set_url()
    get_page = "wget -P " + wget_dir + " " + url_to_use
    pass_flag = 0 # reset flag to Fail


    try:
        output = subprocess.check_output(get_page, stderr=subprocess.STDOUT, shell=True)
        #  Split the output into a list of lines to use

        lines = output.splitlines(keepends=True)
        # print(len(lines))
        
        for line in lines:
            decoded_line = line.decode("utf-8")
            if "connected" in decoded_line :
                print(line)
                pass_flag = 1 # 1 means Pass

                #  write output to a file
                with open(logfile, "a") as f:
                    f.write(line.decode()) 

        result_check(pass_flag)
        remove_directory(wget_dir)

    except subprocess.CalledProcessError as e:
        print("Command failed with return code", e.returncode)
        print(e.output.decode())
        with open(logfile, "a") as f:
            f.write("\n\r")
            f.write("testing URL in " + " " + url_to_use + " failed with error")
        remove_directory(wget_dir)


def ip_ver_test(ipv):
    print("IP version testing started wait a moment please...\n")
    with open(logfile, "a") as f:
                f.write("IP version testing started\n")
    urltest_list = ["", "v6.testmyipv6.com", "ds.testmyipv6.com", "testmyipv6.com"]
    ip_type = ["", "ipv6", "ipv4v6", "ipv4"]
    # Check if the directory already exists
    ipv_dir = current_path + "/ip_ver_test/"
    if not os.path.exists(ipv_dir):
        # Create the new directory
        os.mkdir(ipv_dir)
    # run command and capture output
    url_to_use = urltest_list[ipv]  # 1 = ipv6, 2 = ipv4v6, 3 = ipv4
    get_page = "wget -P " + ipv_dir + " " + url_to_use
    try:
        output = subprocess.check_output(get_page, stderr=subprocess.STDOUT, shell=True)
        # Split the output into a list of lines
        lines = output.splitlines(keepends=True)
        pass_flag = 0 # reset flag to Fail

        for line in lines:
            decoded_line = line.decode("utf-8")
            if "connected" in decoded_line :
                print(line)
                pass_flag = 1 # 1 means Pass

                #  write output to a file
                with open(logfile, "a") as f:
                    f.write(line.decode()) 

        result_check(pass_flag)
        remove_directory(ipv_dir)


    except subprocess.CalledProcessError as e:
        print("Command failed with return code", e.returncode)
        print(e.output.decode())
        with open(logfile, "a") as f:
            f.write("\n\r")
            f.write("testing URL in " + geturl + " failed with error")


def icmp_test(ipv):
    ip_type = ["", "ping -c 10 ", "ping6 -c 10 "]
    print("Testing ICMP 10 times, please wait a moment...")
    

    try:
        # Run command and capture output
        geturl = set_url()
        output = subprocess.check_output(ip_type[ipv] + geturl, shell=True)
        with open(logfile, "a") as f:
            f.write("testing ICMP 10 times to: " + geturl + "\n")
        
        # Split the output into a list of lines
        lines = output.splitlines(keepends=True)
        pass_flag = 0 # reset flag to Fail

        for line in lines:
            # print(line)
            decoded_line = line.decode("utf-8")
            if "10 received" in decoded_line :
                print(line)
                pass_flag = 1 # 1 means Pass

                #  write output to a file
                with open(logfile, "a") as f:
                    f.write(line.decode()) 


    except subprocess.CalledProcessError as e:
        print("Command failed with return code", e.returncode)
        print(e.output.decode())
        with open(logfile, "a") as f:
            f.write("\n\r")
            f.write("testing ICMP in " + ip_type[ipv] + " failed with error")

    result_check(pass_flag)


def clean_files():
    subprocess.run("rm -f Conn_test*", shell= True, text=True)
    print("Logs Cleaned")


# Define the command-line arguments
parser = argparse.ArgumentParser(description='Run specific functions')
parser.add_argument('--t', action='store_true', help='Adds a Time stamp')
parser.add_argument('--st', action='store_true', help='calls the Speed test')
parser.add_argument('--dns', action='store_true', help='Solve an URL to IPv4 and IPv6')
parser.add_argument('--dl', action='store_true', help='download a Webpage from internet')
parser.add_argument('--ipv', type=int, metavar='INPUT_ARG', help='DL with specific IPv: 1 = ipv6, 2 = ipv4v6, 3 = ipv4')
parser.add_argument('--ping', type=int, metavar='INPUT_ARG', help='1 = ping, 2 = ping6')
parser.add_argument('--ins', action='store_true', help='install dependencies (Needs internet)')
parser.add_argument('--clean', action='store_true', help='Remove the log files')


def main ():

    # Parse the arguments
    args = parser.parse_args()

    # Show help message if no arguments were passed
    if not any(vars(args).values()):
        print("Example of use: sudo python connectivity_check.py --t --dns --ping 0\n")
        parser.print_help()


    # Call the selected functions
    if args.t:
        add_time()

    if args.st:
        test_speed()

    if args.dns:
        get_dns_test()

    if args.dl:
        download_test()

    if args.ipv:
        ip_ver_test(args.ipv)

    if args.ping:
        icmp_test(args.ping)

    if args.ins:
        install_dependencies()

    if args.clean:
        clean_files()


main()

# get_time()
# test_speed()
# get_dns_test()
# download_test()
# ip_ver_test(1)
# icmp_test(1)
# install_dependencies()
