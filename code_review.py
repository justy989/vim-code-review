from collections import defaultdict
import textwrap

bar = '-' * 100

def append_line(pr, appendable, line, obj):
    pr.line_to_obj[len(appendable)] = obj
    appendable.append(line)

def print_comment(pr, comment, appendable, indent=0):
    text = ''
    for line in textwrap.wrap('{}: {}'.format(comment.author.display_name, comment.text), 100 - indent):
       text += '{}| {}\n'.format(' '*indent, line)
    for line in text.rstrip().split('\n'):
         append_line(pr, appendable, line, comment)
    append_line(pr, appendable, '{}|{}'.format(' '*indent, bar[indent+1:]), comment)
    for child_comment in comment.comments:
        print_comment(pr, child_comment, appendable, indent+4)

def get_file_lines(pr, appendable):
    pr.line_to_obj = {}
    appendable[0] = bar
    for filename in sorted(pr.diff.keys()):
        diff = pr.diff[filename]
        appendable.append(filename)
        appendable.append(bar)

        comments = list(pr.comments(path=filename))
        line_comments = defaultdict(list)
        for comment in comments:
            if 'line' not in comment.anchor:
                print_comment(pr, comment, appendable)
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
                            append_line(pr, appendable, '{}|{}'.format(' '*indent, bar[indent+1:]), comment)
                            print_comment(pr, comment, appendable)
                        comment_index += 1
                    append_line(pr, appendable, '|{:4}| {} {}'.format(line.destination, {'ADDED': '+', 'REMOVED': '-', 'CONTEXT': ' '}[segment.type], line), line)
            appendable.append(bar)
