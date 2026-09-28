def _python_startup():
    import sys

    if sys.version_info < (3, 13):

        def _interactivehook():
            try:
                import atexit
                import os
                import readline
                import rlcompleter
            except ImportError:
                return

            readline.set_completer(rlcompleter.Completer(locals()).complete)
            readline_doc = getattr(readline, '__doc__', '') or ''
            if 'libedit' in readline_doc:
                readline.parse_and_bind('bind ^I rl_complete')
            else:
                readline.parse_and_bind('tab: complete')

            hist = os.environ.get('PYTHON_HISTORY')
            if hist:
                histfile = hist
            else:
                state = os.environ.get('XDG_STATE_HOME')
                if state:
                    histfile = os.path.join(state, 'python', 'history')
                else:
                    histfile = os.path.expanduser('~/.local/state/python/history')

            histdir = os.path.dirname(histfile)
            if histdir:
                os.makedirs(histdir, exist_ok=True)
            try:
                readline.read_history_file(histfile)
            except OSError:
                pass
            readline.set_history_length(10000)
            atexit.register(readline.write_history_file, histfile)

        sys.__interactivehook__ = _interactivehook

    import pprint

    return pprint.pprint


try:
    pp = _python_startup()
except Exception:
    pass

try:
    del _python_startup
except NameError:
    pass
