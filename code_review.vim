let g:plugin_path = expand('<sfile>:p:h')

autocmd Filetype codereview,codereviewhunk syn match diffAdded "|[0-9 ]\+| +.*"
autocmd Filetype codereview,codereviewhunk syn match diffRemoved "|[0-9 ]\+| -.*"
autocmd Filetype codereviewpullrequests syn match diffAdded "(+)[^,]*"
autocmd Filetype codereviewpullrequests syn match diffChange "(\\)[^,]*"

autocmd Filetype codereviewpullrequests nnoremap <silent> <buffer> <CR> :python select_pull_request()<CR>
autocmd Filetype codereviewpullrequests nnoremap <silent> <buffer> j :python select_next_pull_request()<CR>
autocmd Filetype codereviewpullrequests nnoremap <silent> <buffer> k :python select_prev_pull_request()<CR>
autocmd Filetype codereviewcomment nnoremap <silent> <buffer> <CR> :python send_comment()<CR>
autocmd Filetype codereviewsidebar nnoremap <silent> <buffer> <CR> :python select_file()<CR>
autocmd Filetype codereview,codereviewhunk nnoremap <silent> <buffer> s :python open_file_selector(test_client.pr.diff.keys())<CR>
autocmd Filetype codereview,codereviewhunk nnoremap <silent> <buffer> <S-C> :python comment_on_thing_under_cursor()<CR>
autocmd Filetype codereview,codereviewhunk nnoremap <silent> <buffer> <S-E> :python edit_thing_under_cursor()<CR>
autocmd Filetype codereview,codereviewhunk nnoremap <silent> <buffer> <S-D> :python delete_thing_under_cursor()<CR>
autocmd Filetype codereview,codereviewhunk nnoremap <silent> <buffer> <S-V> :python view_dashboard()<CR>
autocmd Filetype codereview,codereviewhunk nnoremap <silent> <buffer> <S-M> :python comment_on_file_under_cursor()<CR>
autocmd Filetype codereview nnoremap <silent> <buffer> j :python next_hunk()<CR>
autocmd Filetype codereview nnoremap <silent> <buffer> k :python prev_hunk()<CR>

autocmd Filetype codereview nnoremap <silent> <buffer> <CR> :set filetype=codereviewhunk<CR>

autocmd Filetype codereviewhunk nnoremap <silent> <buffer> j gj
autocmd Filetype codereviewhunk nnoremap <silent> <buffer> k gk
autocmd Filetype codereviewhunk nnoremap <silent> <buffer> <Esc> :set filetype=codereview<CR>

python << EOF
import vim
import os
import textwrap
import bisect

# Get the Vim variable to Python
plugin_path = vim.eval("g:plugin_path")
# Get the absolute path to the lib directory
python_module_path = os.path.abspath('%s' % (plugin_path))
# Append it to the system paths
sys.path.append(python_module_path)

# import whatever you want that's in the same directory as automation.vim here
import code_review
import test_client

selected_file = None

def yummy_buffer(b):
     # set this buffer up to disappear without a trace when it goes away
     b.options['buftype']    = 'nowrite'
     b.options['bufhidden']  = 'delete'
     b.options['swapfile']   = 0
     b.options['modifiable'] = 0 # prevent users from modifying the buffer
     b.options['readonly']   = 1 # readonly appears to be just for show, but I like it
     vim.command('set nonumber')
     vim.command('set norelativenumber')

def open_file_selector(files):
     global selected_file

     vim.command('vnew')

     b = vim.current.buffer
     b.name = 'File Selector'

     window_width = len(b[0])

     for file in sorted(files):
          selection_indicator = '>' if selected_file == file else ' '
          line = '{} {}'.format(selection_indicator, file)
          window_width = max(window_width, len(line))
          b.append(line)

     vim.command('vertical resize {}'.format(window_width))
     yummy_buffer(b)
     vim.command('set filetype=codereviewsidebar')

     # move the cursor to the start of the file list
     vim.current.window.cursor = (2, 0)

def select_file():
     file = vim.current.line[1:].strip()
     global selected_file
     selected_file = file
     vim.command('close')

     the_yummiest_buffer = None
     for buffer in vim.buffers:
          if test_client.pr.title in buffer.name :
               the_yummiest_buffer = buffer
               break

     if not the_yummiest_buffer:
          return

     # TODO: obvious problems
     for index, line in enumerate(the_yummiest_buffer):
          if selected_file in line:
               vim.current.window.cursor = (index + 1, 1)
               break
     vim.command("call feedkeys ('zt')")

def comment_on_thing_under_cursor():
     thing_under_cursor = code_review.line_to_obj.get(vim.current.window.cursor[0]-1,None)
     if not thing_under_cursor:
          return
     if hasattr(thing_under_cursor, 'reply'):
          open_comment_buffer(thing_under_cursor.reply)
     elif hasattr(thing_under_cursor, 'destination'):
          file_under_cursor = find_file_under_cursor()
          if not file_under_cursor:
               return
          def comment_on_file_line(text):
               anchor = {'line' : thing_under_cursor.destination, 'lineType' : 'CONTEXT'}
               test_client.pr.comment(text, path=file_under_cursor, anchor=anchor)
          open_comment_buffer(comment_on_file_line)

def edit_thing_under_cursor():
     thing_under_cursor = code_review.line_to_obj.get(vim.current.window.cursor[0]-1,None)
     if not thing_under_cursor:
          return
     if hasattr(thing_under_cursor, 'edit'):
          b = open_comment_buffer(thing_under_cursor.edit)
          lines = thing_under_cursor.text.split('\n')
          b[0] = lines[0]
          if len(lines) > 1:
               for line in lines[1:]:
                    b.append(line)
          test_client.pr._active_comment = thing_under_cursor

def delete_thing_under_cursor():
     thing_under_cursor = code_review.line_to_obj.get(vim.current.window.cursor[0]-1,None)
     if not thing_under_cursor:
          return
     if hasattr(thing_under_cursor, 'delete'):
          thing_under_cursor.delete()
          reload_pull_request()

def send_comment():
     b = vim.current.buffer
     comment_text = '\n'.join(b)
     test_client.pr._send_comment(comment_text)
     vim.command('close!')
     reload_pull_request()

def load_pull_request():
     vim.command('enew')
     code_review.get_file_lines(test_client.pr, vim.current.buffer)
     vim.current.buffer.name = test_client.pr.title
     yummy_buffer(vim.current.buffer)
     vim.command('set filetype=codereview')

def reload_pull_request():
     saved_cursor = vim.current.window.cursor
     load_pull_request()
     try:
          vim.current.window.cursor = saved_cursor
     except:
          pass

def pull_request_format(pr):
     lines = []
     spaces_betwixt = len(code_review.bar) - (len(pr.title) + len(pr.author.user.display_name))
     if spaces_betwixt < 2:
          spaces_betwixt = 2
     title_line = pr.title + (' ' * spaces_betwixt) + pr.author.user.display_name
     lines.append(title_line)
     lines.append(pr.links.self)
     lines.append('')
     for desc_line in pr.description.split('\n'):
          desc_lines = textwrap.wrap(desc_line, len(code_review.bar))
          lines.extend(desc_lines)
     lines.append('')

     review_status_dct = {
          'APPROVED'   : '(+) ',
          'NEEDS_WORK' : '(\) ',
          'UNAPPROVED' : '',
     }

     reviewer_line = ''
     for reviewer in pr.reviewers.values():
          reviewer_line += '{}{}, '.format(review_status_dct[reviewer.status], reviewer.user.display_name)
     lines.append(reviewer_line.rstrip(', '))
     lines.append(code_review.bar)
     return lines

line_to_pr = []

def view_dashboard():
     global line_to_pr
     line_to_pr = []
     vim.command('enew')
     b = vim.current.buffer
     b.name = 'Pull Request Dashboard'
     b[0] = code_review.bar
     for pr in test_client.bitbucket.dashboard(state='OPEN'):
          lines = pull_request_format(pr)
          for line in lines:
               line_to_pr.append(pr)
               b.append(line.rstrip())

     yummy_buffer(vim.current.buffer)
     vim.command('set filetype=codereviewpullrequests')

def select_pull_request():
     global line_to_pr
     if vim.current.window.cursor[0] >= len(line_to_pr) or vim.current.window.cursor[0] < 0:
          return
     test_client.pr = line_to_pr[vim.current.window.cursor[0] - 1]
     load_pull_request()

def find_file_under_cursor():
     selected_index = vim.current.window.cursor[0]-1
     prev_file = code_review.file_lines[0][1] if code_review.file_lines else None
     for file_line in code_review.file_lines:
          if file_line[0] > selected_index:
               return prev_file
          prev_file = file_line[1]

     return prev_file

def open_comment_buffer(send_comment):
     vim.command('sp')
     vim.command('enew')
     b = vim.current.buffer
     b.options['bufhidden'] = 'delete'
     #b.options['swapfile'] = 0
     vim.command('set filetype=codereviewcomment')
     test_client.pr._send_comment = send_comment
     return b

def comment_on_file_under_cursor():
     file_under_cursor = find_file_under_cursor()
     if not file_under_cursor:
          return
     def comment_on_file(text):
          test_client.pr.comment(text, path=file_under_cursor)
     open_comment_buffer(comment_on_file)

def select_prev_pull_request():
     for i in range(vim.current.window.cursor[0] - 3, -1, -1):
          line = vim.current.buffer[i]
          if line == code_review.bar:
               vim.current.window.cursor = (i + 2, 1)
               break;
     vim.command("call feedkeys ('zz')")

def select_next_pull_request():
     for i in range(vim.current.window.cursor[0], len(vim.current.buffer) - 2):
          line = vim.current.buffer[i]
          if line == code_review.bar:
               vim.current.window.cursor = (i + 2, 1)
               break;
     vim.command("call feedkeys ('zz')")

def prev_hunk():
     new_index = bisect.bisect_left(code_review.hunk_lines, vim.current.window.cursor[0] - 2)
     if new_index <= 0:
          return
     vim.current.window.cursor = (code_review.hunk_lines[new_index - 1] + 2, 1)
     vim.command("call feedkeys ('zz')")

def next_hunk():
     new_index = bisect.bisect_right(code_review.hunk_lines, vim.current.window.cursor[0] - 1)
     if new_index >= len(code_review.hunk_lines):
          return
     vim.current.window.cursor = (code_review.hunk_lines[new_index] + 2, 1)
     vim.command("call feedkeys ('zz')")

EOF
python view_dashboard()
