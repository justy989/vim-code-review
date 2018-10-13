#!/usr/bin/python3

import sys

ansi_colors={'{black}'  : "\033[0;30m" , '{dgray}'   : "\033[1;30m" ,
             '{red}'    : "\033[0;31m" , '{lred}'    : "\033[1;31m" ,
             '{green}'  : "\033[0;32m" , '{lgreen}'  : "\033[1;32m" ,
             '{orange}' : "\033[0;33m" , '{yellow}'  : "\033[1;33m" ,
             '{blue}'   : "\033[0;34m" , '{lblue}'   : "\033[1;34m" ,
             '{magenta}' : "\033[0;35m" , '{lmagenta}' : "\033[1;35m" ,
             '{cyan}'   : "\033[0;36m" , '{lcyan}'   : "\033[1;36m" ,
             '{lgray}'  : "\033[0;37m" , '{white}'   : "\033[1;37m" ,
             '{nc}'     : "\033[0m"}
def main():
    if len(sys.argv) != 2:
        print('usage: %s [filepath]' % (sys.argv[0]))
        return 1

    f = open(sys.argv[1])

    for line in f:
        line = line.replace('\n', '')
        for color in ansi_colors:
            line = line.replace(color, ansi_colors[color])
        print(line)

main()
