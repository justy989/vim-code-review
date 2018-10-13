from collections import defaultdict

bar = '-' * 100

def print_comment(comment, appendable, indent=0):
    appendable.append('{}| {}: {}'.format(' '*indent, comment.author.display_name, comment.text))
    appendable.append('{}|{}'.format(' '*indent, bar[indent+1:]))
    for child_comment in comment.comments:
        print_comment(child_comment, appendable, indent+4)

def get_file_lines(pr, appendable):
    appendable[0] = bar
    for filename in sorted(pr.diff.keys()):
        diff = pr.diff[filename]
        appendable.append(filename)
        appendable.append(bar)

        comments = list(pr.comments(path=filename))
        line_comments = defaultdict(list)
        for comment in comments:
            if 'line' not in comment.anchor:
                print_comment(comment, appendable)
            else:
                line_comments[comment.anchor['line']].append(comment)

        lines_with_comments = sorted(line_comments.keys())
        comment_index = 0
        for hunk in diff.hunks:
            for segment in hunk.segments:
                for line in segment.lines:
                    if comment_index < len(lines_with_comments) and lines_with_comments[comment_index] < line.destination:
                        for comment in line_comments[lines_with_comments[comment_index]]:
                            indent = 0
                            appendable.append('{}|{}'.format(' '*indent, bar[indent+1:]))
                            print_comment(comment, appendable)
                        comment_index += 1
                    appendable.append('|{:4}| {} {}'.format(line.destination, {'ADDED': '+', 'REMOVED': '-', 'CONTEXT': ' '}[segment.type], line))
            appendable.append(bar)
