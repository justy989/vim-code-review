
bar = '-' * 100

def get_file_lines(pr, appendable):
    appendable[0] = bar
    for filename in sorted(pr.diff.keys()):
        diff = pr.diff[filename]
        appendable.append(filename)
        appendable.append(bar)
        for hunk in diff.hunks:
            for segment in hunk.segments:
                for line in segment.lines:
                    appendable.append('|{:4}| {} {}'.format(line.destination, {'ADDED': '+', 'REMOVED': '-', 'CONTEXT': ' '}[segment.type], line))
            appendable.append(bar)
