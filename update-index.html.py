"""Update index.html with new get params."""

import re

from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter, FileType

# This regexp is used so that the static file editor can bump version numbers
# in the given file.
src_regexp = 'src="([^?]+)[?]([0-9]+)["]'

parser = ArgumentParser(formatter_class=ArgumentDefaultsHelpFormatter)

parser.add_argument(
    'filename', nargs='?', default='index.html', type=FileType('r'),
    help='The file to modify.'
)


def repl(m):
    """Used with re.sub."""
    filename, i = m.groups()
    i = int(i)
    new = i + 1
    print('Bumping %s: %d -> %d.' % (filename, i, new))
    return 'src="%s?%d"' % (filename, new)


if __name__ == '__main__':
    args = parser.parse_args()
    f = args.filename
    code = f.read()
    f.close()
    code = re.sub(src_regexp, repl, code)
    with open(f.name, 'w') as f:
        f.write(code)
