from pathlib import Path
import subprocess as sp
import sys

def main(args):
    home = str(Path.home())
    filename=home+"/dotfiles/dot_setup.sh"
    print(filename)
    sp.call(args)
    with open('{}'.format(filename), 'a') as f:
        f.write(' '.join(args) + "\n")
    pass

if __name__ == "__main__":
    main(sys.argv[1:])
    pass

