let g:plugin_path = expand('<sfile>:p:h')

autocmd Filetype codereview syn match diffAdded "|[0-9 ]\+| +.*"
autocmd Filetype codereview syn match diffRemoved "|[0-9 ]\+| -.*"

autocmd Filetype codereviewcomment nnoremap <silent> <buffer> <CR> :python send_comment()<CR>
autocmd Filetype codereviewsidebar nnoremap <silent> <buffer> <CR> :python select_file()<CR>
autocmd Filetype codereview nnoremap <silent> <buffer> s :python open_file_selector(test_client.pr.diff.keys())<CR>
autocmd Filetype codereview nnoremap <silent> <buffer> <S-C> :python comment_on_thing_under_cursor()<CR>
autocmd Filetype codereview nnoremap <silent> <buffer> <S-E> :python edit_thing_under_cursor()<CR>
autocmd Filetype codereview nnoremap <silent> <buffer> <S-D> :python delete_thing_under_cursor()<CR>

python << EOF
import vim
import os

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
     thing_under_cursor = test_client.pr.line_to_obj.get(vim.current.window.cursor[0]-1,None)
     if not thing_under_cursor:
          return
     if hasattr(thing_under_cursor, 'reply'):
          vim.command('sp')
          vim.command('enew')
          b = vim.current.buffer
          b.options['bufhidden'] = 'delete'
          #b.options['swapfile'] = 0
          vim.command('set filetype=codereviewcomment')
          test_client.pr._active_comment = thing_under_cursor
          test_client.pr._send_comment = thing_under_cursor.reply

def edit_thing_under_cursor():
     thing_under_cursor = test_client.pr.line_to_obj.get(vim.current.window.cursor[0]-1,None)
     if not thing_under_cursor:
          return
     if hasattr(thing_under_cursor, 'edit'):
          vim.command('sp')
          vim.command('enew')
          b = vim.current.buffer
          b.options['bufhidden'] = 'delete'
          vim.command('set filetype=codereviewcomment')
          lines = thing_under_cursor.text.split('\n')
          b[0] = lines[0]
          if len(lines) > 1:
               for line in lines[1:]:
                    b.append(line)
          test_client.pr._active_comment = thing_under_cursor
          test_client.pr._send_comment = thing_under_cursor.edit

def delete_thing_under_cursor():
     thing_under_cursor = test_client.pr.line_to_obj.get(vim.current.window.cursor[0]-1,None)
     if not thing_under_cursor:
          return
     if hasattr(thing_under_cursor, 'delete'):
          thing_under_cursor.delete()
          load_pull_request()

def send_comment():
     b = vim.current.buffer
     comment_text = '\n'.join(b)
     test_client.pr._send_comment(comment_text)
     vim.command('close!')
     load_pull_request()

def load_pull_request():
     vim.command('enew')
     code_review.get_file_lines(test_client.pr, vim.current.buffer)
     vim.current.buffer.name = test_client.pr.title
     yummy_buffer(vim.current.buffer)
     vim.command('set filetype=codereview')

EOF
python load_pull_request()
