#!/usr/bin/python3

'''
A set of classes for performing a specific test within a git repo.
Base classes can be created for performing tool-specific tests.
Several generic test classes are included that could be used in any
type of repository.
'''

import subprocess
import os
import sys
from enum import Enum
from git import Repo
import datetime

#########################################################3
# Base repo test classes
#########################################################3

class result_type(Enum):
    SUCCESS = 1
    WARNING = 2
    ERROR = 3

class repo_test_result():
    """ Class for indicating the result of a repo test
    """

    def __init__(self, test, result = result_type.SUCCESS, msg = None):
        self.test = test
        self.result = result
        self.msg = msg

class repo_test():
    """ Class for performing a test on files within a repository.
    Each instance of this class represents a _single_ test with a single
    executable. Multiple tests can be performed by creating multiple instances
    of this test class.
    This is intended as a super class for custom test modules.
    """

    def __init__(self, abort_on_error=True, process_output_filename = None):
        """ Initialize the test module with a repo object """
        self.abort_on_error = abort_on_error
        self.process_output_filename = process_output_filename
        # List of files that should be deleted after the test is done (i.e., log files)
        self.files_to_delete = []  

    def module_name(self):
        """ returns a string indicating the name of the module. Used for logging. """
        return "BASE MODULE"

    def perform_test(self, repo_test_suite):
        """ This function should be overridden by a subclass. It performs the test using
        the repo_test_suite object to obtain test-specific information. """ 
        return False
    
    def success_result(self, msg=None):
        return repo_test_result(self, result_type.SUCCESS, msg)

    def warning_result(self, msg=None):
        return repo_test_result(self, result_type.WARNING, msg)

    def error_result(self, msg=None):
        return repo_test_result(self, result_type.ERROR, msg)

    def execute_command(self, repo_test_suite, proc_cmd, process_output_filename = None ):
        """ Completes a sub-process command. and print to a file and stdout.
        Args:
            proc_cmd -- The string command to be executed.
            proc_wd -- The directory in which the command should be executed. Note that the execution directory
                can be anywhere and not necessarily within the repository. If this is None, the self.working_path
                will be used.
            print_to_stdout -- If True, the output of the command will be printed to stdout.
            print_message -- If True, messages will be printed to stdout about the command being executed.
            process_output_filepath -- The file path to which the output of the command should be written.
                This can be None if no output file is wanted.
        Returns: the sub-process return code
        """
        
        fp = None
        if repo_test_suite.log_dir is not None and process_output_filename is not None:
            if not os.path.exists(self.repo_test_suite.log_dir):
                os.makedirs(self.repo_test_suite.log_dir)
            process_output_filepath = self.log_dir + '/' + process_output_filename
            fp = open(process_output_filepath, "w")
            if not fp:
                repo_test_suite.print_error("Error opening file for writing:", process_output_filepath)
                return -1
            repo_test_suite.print("Writing output to:", process_output_filepath)
            self.files_to_delete.append(process_output_filepath)
        cmd_str = " ".join(proc_cmd)
        message = "Executing the following command in directory:"+str(repo_test_suite.working_path)+":"+str(cmd_str)
        repo_test_suite.print(message)
        if fp:
            fp.write(message+"\n")
        # Execute command		
        proc = subprocess.Popen(
            proc_cmd,
            cwd=repo_test_suite.working_path,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            universal_newlines=True,
        )
        for line in proc.stdout:
            if repo_test_suite.print_to_stdout:
                sys.stdout.write(line)
            if fp:
                fp.write(line)
                fp.flush()
        # Wait until process is donetest
        proc.communicate()
        return proc.returncode

    def cleanup(self):
        """ Cleanup any files that were created by the test. """
        for file in self.files_to_delete:
            if os.path.exists(file):
                os.remove(file) 

#########################################################3
# Generic, non-repo test classes
#########################################################3

class file_exists_test(repo_test):
    ''' Checks to see if files exist in a repo directory
    '''

    def __init__(self, repo_file_list, abort_on_error=True):
        '''  '''
        super().__init__(abort_on_error)
        self.repo_file_list = repo_file_list

    def module_name(self):
        name_str = "Files Exist: "
        for repo_file in self.repo_file_list:
            name_str += f'{repo_file}, '
        return name_str[:-2] # Remove the last two characters (', ')

    def perform_test(self, repo_test_suite):
        return_val = True
        for repo_file in self.repo_file_list:
            file_path = repo_test_suite.working_path / repo_file
            if not os.path.exists(file_path):
                repo_test_suite.print_error(f'File does not exist: {file_path}')
                return_val = False
            repo_test_suite.print(f'File exists: {file_path}')
        if return_val:
            return self.success_result()
        return self.error_result()

class make_test(repo_test):
    ''' Executes a makefile rule in the repository.
    '''

    def __init__(self, make_rule, generate_output_file = True, make_output_filename=None,
                 abort_on_error=True):
        ''' make_rule is the string makefile rule that is executed. '''
        if generate_output_file and make_output_filename is None:
            # default makefile output filename
            make_output_filename = "make_" + make_rule.replace(" ", "_") + '.log'
        super().__init__(abort_on_error=abort_on_error, process_output_filename=make_output_filename)
        self.make_rule = make_rule

    def module_name(self):
        return f"Makefile: 'make {self.make_rule}'"

    def perform_test(self, repo_test_suite):
        cmd = ["make", self.make_rule]
        return_val = self.execute_command(repo_test_suite, cmd)
        if return_val != 0:
            return self.error_result()
        return self.success_result()

#########################################################3
# Git repo test classes
#########################################################3

class check_for_untracked_files(repo_test):
    ''' This tests the repo for any untracked files in the repository.
    '''
    def __init__(self, ignore_ok = True):
        '''  '''
        super().__init__()
        self.ignore_ok = ignore_ok

    def module_name(self):
        return "Check for untracked GIT files"

    def perform_test(self, repo_test_suite):
        # TODO: look into using repo.untracked_files instead of git command

        untracked_files = repo_test_suite.repo.git.ls_files("--others", "--exclude-standard")
        if untracked_files:
            repo_test_suite.print_error('Untracked files found in repository:')
            files = untracked_files.splitlines()
            for file in files:
                repo_test_suite.print_error(f'  {file}')
            # return False
            return self.warning_result()
        repo_test_suite.print('No untracked files found in repository')
        # return True
        return self.success_result()

class check_for_tag(repo_test):
    ''' This tests to see if the given tag exists in the repository.
    '''
    def __init__(self, tag_name):
        '''  '''
        super().__init__()
        self.tag_name = tag_name

    def module_name(self):
        return f"Check for tag \'{self.tag_name}\'"

    def perform_test(self, repo_test_suite):
        if self.tag_name in repo_test_suite.repo.tags:
            commit = repo_test_suite.repo.tags[self.tag_name].commit
            commit_date = datetime.datetime.fromtimestamp(commit.committed_date).strftime('%Y-%m-%d %H:%M:%S')
            repo_test_suite.print(f'Tag \'{self.tag_name}\' found in repository (commit date: {commit_date})')
            return self.success_result()
        repo_test_suite.print_error(f'Tag {self.tag_name} not found in repository')
        return self.warning_result()

class check_for_max_repo_files(repo_test):
    ''' Check to see if the repository has more than a given number of files.
    '''
    def __init__(self, max_dir_files):
        '''  '''
        super().__init__()
        self.max_dir_files = max_dir_files

    def module_name(self):
        return "Check for max tracked repo files"

    def perform_test(self, repo_test_suite):
        tracked_files = repo_test_suite.repo.git.ls_files(repo_test_suite.relative_repo_path).split('\n')
        n_tracked_files = len(tracked_files)
        repo_test_suite.print(f"{n_tracked_files} Tracked git files in {repo_test_suite.relative_repo_path}")
        if n_tracked_files > self.max_dir_files:
            repo_test_suite.print_error(f"  Too many tracked files")
            return self.warning_result()
        return self.success_result()

class check_for_ignored_files(repo_test):
    ''' Checks to see if there are any ignored files in the repo directory.
    The intent is to make sure that these ignore files are removed through a clean
    operation. Returns true if there are no ignored files in the directory.
    '''
    def __init__(self, check_path = None):
        '''  '''
        super().__init__()
        self.check_path = check_path

    def module_name(self):
        return "Check for ignored GIT files"

    def perform_test(self, repo_test_suite):
        if self.check_path is None:
            self.check_path = repo_test_suite.working_path
        # TODO: look into using repo.untracked_files instead of git command
        repo_test_suite.print(f'Checking for ignored files at {self.check_path}')
        ignored_files = repo_test_suite.repo.git.ls_files(self.check_path, "--others", "--ignored", "--exclude-standard")
        if ignored_files:
            repo_test_suite.print_error('Ignored files found in repository:')
            files = ignored_files.splitlines()
            for file in files:
                repo_test_suite.print_error(f'  {file}')
            # return False
            return self.warning_result()
        repo_test_suite.print('No ignored files found in repository')
        # return True
        return self.success_result()

class check_for_uncommitted_files(repo_test):
    ''' Checks for uncommitted files in the repo directory.
    '''

    def __init__(self):
        '''  '''
        super().__init__()

    def module_name(self):
        return "Check for uncommitted git files"

    def perform_test(self, repo_test_suite):
        uncommitted_changes = repo_test_suite.repo.index.diff(None)
        modified_files = [item.a_path for item in uncommitted_changes if item.change_type == 'M']
        if modified_files:
            repo_test_suite.print_error('Uncommitted files found in repository:')
            for file in modified_files:
                repo_test_suite.print_error(f'  {file}')
            # return False
            return self.warning_result()
        repo_test_suite.print('No uncommitted files found in repository')
        # return True
        return self.success_result()

class check_number_of_files(repo_test):
    ''' Counts the number of files in the repo directory.
    '''

    def __init__(self, max_files=sys.maxsize):
        '''  '''
        super().__init__()
        self.max_files = max_files

    def module_name(self):
        return "Count files in repo dir"

    def perform_test(self, repo_test_suite):
        uncommitted_files = repo_test_suite.repo.git.status("--suno")
        if uncommitted_files:
            repo_test_suite.print_error(f'Uncommitted files found in repository:')
            files = uncommitted_files.splitlines()
            for file in files:
                repo_test_suite.print_error(f'  {file}')
            # return False
            return self.warning_result()
        repo_test_suite.print(f'No uncommitted files found in repository')
        # return True
        return self.success_result()

class list_git_commits(repo_test):
    ''' Prints the commits of the given directory in the repo.
    '''
    def __init__(self, check_path = None):
        '''  '''
        super().__init__()
        self.check_path = check_path

    def module_name(self):
        return "List Git Commits"

    def perform_test(self, repo_test_suite):
        if self.check_path is None:
            self.check_path = repo_test_suite.working_path
        relative_path = self.check_path.relative_to(repo_test_suite.repo_root_path)
        repo_test_suite.print(f'Checking for commits at {relative_path}')
        commits = list(repo_test_suite.repo.iter_commits(paths=relative_path))
        for commit in commits:
            commit_hash = commit.hexsha[:7]
            commit_message = commit.message.strip()
            commit_date = commit.committed_datetime.strftime('%Y-%m-%d %H:%M:%S')
            print(f"{commit_hash} - {commit_date} - {commit_message}")
        # return True
        return self.success_result()

class check_remote_updates(repo_test):
    ''' Checks to see if the repository has the latest commites from a remote.
    '''
    def __init__(self, remote_name, use_date_of_current_commit = False):
        '''  '''
        super().__init__()
        self.remote_name = remote_name
        self.use_date_of_current_commit = use_date_of_current_commit

    def module_name(self):
        return "Check for updates from remote:" + self.remote_name

    def perform_test(self, repo_test_suite):
        # Get the current branch, commit, and commit date from the local repo
        current_branch = repo_test_suite.repo.active_branch
        local_commit = repo_test_suite.repo.commit(current_branch)
        local_commit_date = datetime.datetime.fromtimestamp(local_commit.committed_date)
        print(f"current branch:{current_branch}, commit hash {local_commit.hexsha[:7]} commit date {local_commit_date}" )
        # Get the remote
        remote = repo_test_suite.repo.remote(name = self.remote_name)
        if remote is None:
            repo_test_suite.print_error(f"Remote {self.remote_name} not found")
            return self.error_result()
        # Fetch from the remote and get remote commit
        remote.fetch()
        # Find the commit from the remote that is the closest to the search limit date
        # but not past the lsearch limit date. This is done so that checks against old tagged
        # commits during grading are not penalized for future commits to the remote.
        if self.use_date_of_current_commit:
            search_limit_date = local_commit_date
        else:
            search_limit_date = datetime.datetime.now()
        remote_commits = list(repo_test_suite.repo.iter_commits(f"{self.remote_name}/{current_branch}"))
        latest_remote_commit = None
        print(f"search limit date {search_limit_date}")
        for commit in remote_commits:
            remote_commit_date = datetime.datetime.fromtimestamp(commit.committed_date)
            if remote_commit_date <= search_limit_date:
                if latest_remote_commit is None:
                    latest_remote_commit = remote_commit_date
                else:
                    if remote_commit_date > latest_remote_commit:
                        latest_remote_commit = remote_commit_date
        print(f"Latest remote commit date {latest_remote_commit}")
        # git config --global alias.tm "commit --no-commit --no-ff"

        if latest_remote_commit > local_commit_date:
            repo_test_suite.print_error(f"Git Remote \'{self.remote_name}\' has some newer commits that are not integarated into the local repository")
            return self.warning_result()

        return self.success_result()
