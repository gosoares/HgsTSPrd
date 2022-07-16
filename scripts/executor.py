import argparse
import concurrent.futures
import subprocess
from os import cpu_count, getloadavg
from os.path import exists
import time

from tsprd_data import *

TIME_LIMIT = int(10 * 60 * (1976.0 / 1201.0))


def tsprd_execute(output_folder: str, n_threads: int):
    save_git_commit_hash(output_folder)
    instances = get_instances_execs()

    with concurrent.futures.ThreadPoolExecutor(max_workers=n_threads) as executor:
        total_elements = len(instances)
        current_element = 0
        start_time = time.time()
        print(" Executed  |   Time   |  Load   | Last Instance")
        for iset, name, beta, exec_id in executor.map(lambda i: execute_instance(*i, output_folder), instances):
            total_cores = cpu_count()
            current_element += 1
            current_time = time.time() - start_time
            instance_name = "{}/{}_{} {}".format(iset, name, beta, exec_id)

            print("\r {:4d}/{:4d} | {:02d}:{:02d}:{:02d} | {:2.2f}/{:<2d} | {}".format(current_element, total_elements, int(current_time / 3600), int(
                current_time / 60 % 60), int(current_time % 60), getloadavg()[0], total_cores, instance_name, end="   ", flush=True))


def save_git_commit_hash(output_folder: str):
    subprocess.run(["mkdir -p {}".format(output_folder)], stdout=subprocess.DEVNULL, shell=True)
    git_hash = subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode('ascii').strip()
    print(git_hash, file=open("{}/git-commit.hash".format(output_folder), 'w'))


def execute_instance(iset, _, name, beta, exec_id, output_folder):
    instance = "{}/{}_{}".format(iset, name, beta)
    instance_file = "../instances/{}.dat".format(instance)
    output_file = "{}/{}_{}.txt".format(output_folder, instance, exec_id)

    if not exists(output_file):  # skip if it was already executed and saved
        command = "julia executor.jl {} -o {} -t {}".format(instance_file, output_file, TIME_LIMIT)
        process = subprocess.run([command], stdout=subprocess.DEVNULL, shell=True)

        if process.returncode != 0:
            print(instance, file=open("{}/errors.txt".format(output_folder), 'a'))
            raise Exception("Error while running {}".format(instance))

    return iset, name, beta, exec_id


def main():
    parser = argparse.ArgumentParser(description='Run all instances of TSPrd.')
    parser.add_argument("output_folder", action="store",
                        type=str, help="Which folder to save the output files.")
    parser.add_argument("n_threads", action="store", type=int, nargs="?",
                        default=10, help="Maximum number of threads to execute concurrently.")
    args = parser.parse_args()
    tsprd_execute(args.output_folder, args.n_threads)


if __name__ == "__main__":
    main()
