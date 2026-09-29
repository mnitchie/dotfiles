c = get_config()  #noqa

c.InteractiveShellApp.extensions = ['autoreload']
c.InteractiveShellApp.exec_lines = [
    '%autoreload 2',
    'YELLOW = "\\033[33m"',
    'RESET = "\\033[0m"',
    'print("Autoreload enabled")',
    'print("Helpful commands:")',
    'print(f"\\t{YELLOW}?{RESET}: Introduction and overview of IPython features")',
    'print(f"\\t{YELLOW}%quickref{RESET}: Quick reference guide")',
    'print(f"\\t{YELLOW}object?{RESET}: Details about `object`")',
    'print(f"\\t{YELLOW}object??{RESET}: Verbose details about `object`")',
]
c.TerminalIPythonApp.display_banner = False
