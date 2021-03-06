#!/usr/bin/python
from scenarios.jazz_generic_details import get_stack_generic_details

from scenarios import stack_with_bb_jenkins as option1
from scenarios import stack_with_bb_dockerized_jenkins as option2
from scenarios import stack_with_dockerized_gitlab_jenkins as option3

# Global Variables
OPTIONS = {
    1: ["\t1: Stack with existing Bitbucket and Jenkins", option1],
    2: ["\t2: Stack with existing Bitbucket and Jenkins in container", option2],
    3: ["\t3: Stack with Gitlab and Jenkins in container", option3]
}


def is_valid_scenario(option):
    return (option in OPTIONS)


def print_stack_options():
    for key, value in OPTIONS.iteritems():
        option_string = value[0]
        print(option_string)


def execute(key, git_branch_name):
    if not is_valid_scenario(key):
        return
    parameter_list = get_stack_generic_details(git_branch_name)
    OPTIONS[key][1].start(parameter_list)
