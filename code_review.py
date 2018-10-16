from collections import defaultdict
import textwrap

bar = '-' * 120

line_to_obj = {}
file_lines = []
hunk_lines = []

def append_line(appendable, line, obj):
    global line_to_obj
    line_to_obj[len(appendable)] = obj
    appendable.append(line)

def print_comment(comment, appendable, indent=0):
    text = ''
    for line in '{}: {}'.format(comment.author.display_name, comment.text).split('\n'):
         text += '{}\n'.format('\n'.join(textwrap.wrap(line, len(bar)-(indent+2))))
    for line in text.rstrip().split('\n'):
         append_line(appendable, ' '*indent + '| ' + line, comment)
    append_line(appendable, '{}|{}'.format(' '*indent, bar[indent+1:]), comment)
    for child_comment in comment.comments:
        print_comment(child_comment, appendable, indent+4)

def view_file_diff(pr, filename, appendable):
   diff = pr.diff[filename]
   file_lines.append((len(appendable)-1,filename))
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
       hunk_lines.append(len(appendable)-1)
       for segment in hunk.segments:
           for line in segment.lines:
               if comment_index < len(lines_with_comments) and lines_with_comments[comment_index] < line.destination:
                   for comment in line_comments[lines_with_comments[comment_index]]:
                       indent = 0
                       append_line(appendable, '{}|{}'.format(' '*indent, bar[indent+1:]), comment)
                       print_comment(comment, appendable)
                   comment_index += 1
               append_line(appendable, '{:4}| {} {}'.format(line.destination, {'ADDED': '+', 'REMOVED': '-', 'CONTEXT': ' '}[segment.type], line), line)
       appendable.append(bar)

def reset_trackers():
    global line_to_obj
    global file_lines
    global hunk_lines
    line_to_obj = {}
    file_lines = []
    hunk_lines = []

def view_file_diffs(pr, appendable):
    reset_trackers()
    appendable[0] = bar
    for filename in sorted(pr.diff.keys()):
        view_file_diff(pr, filename, appendable)
