let g:plugin_path = expand('<sfile>:p:h')

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
     vim.command('nnoremap <silent> <buffer> <CR> :python select_file()<CR>')
     vim.command('set syntax=python') # hack

     b = vim.current.buffer
     b.name = 'File Selector'
     b[0] = '# Select a file to view:'

     window_width = len(b[0])

     for file in sorted(files):
          selection_indicator = '>' if selected_file == file else ' '
          line = '{} {}'.format(selection_indicator, file)
          window_width = max(window_width, len(line))
          b.append(line)

     vim.command('vertical resize {}'.format(window_width))

     # move the cursor to the start of the file list
     vim.current.window.cursor = (2, 0)


def select_file():
     file = vim.current.line.strip()
     global selected_file
     selected_file = file
     vim.command('close')

vim.command('enew')
code_review.get_file_lines(test_client.pr, vim.current.buffer)
vim.current.buffer.name = test_client.pr.title
yummy_buffer(vim.current.buffer)

EOF

" python open_file_selector(['foo/bar.txt', 'foo/bazz/zop.txt', 'foo/baaaaaaaaaaaaaaaaat.txt'])

