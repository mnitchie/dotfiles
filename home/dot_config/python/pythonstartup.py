def _python_startup():
    import os
    import sys

    # 3.13+ reads PYTHON_HISTORY in the default hook and otherwise uses
    # ~/.python_history. Set the XDG path before that hook runs.
    if not os.environ.get('PYTHON_HISTORY'):
        state = os.environ.get('XDG_STATE_HOME') or os.path.expanduser('~/.local/state')
        os.environ['PYTHON_HISTORY'] = os.path.join(state, 'python', 'history')

    if sys.version_info < (3, 13):

        def _interactivehook():
            try:
                import atexit
                import os
                import readline
                import rlcompleter
            except ImportError:
                return

            readline.set_completer(rlcompleter.Completer().complete)
            readline_doc = getattr(readline, '__doc__', '') or ''
            if 'libedit' in readline_doc:
                readline.parse_and_bind('bind ^I rl_complete')
            else:
                readline.parse_and_bind('tab: complete')

            histfile = os.environ.get('PYTHON_HISTORY')
            if not histfile:
                state = os.environ.get('XDG_STATE_HOME')
                if not state:
                    state = os.path.expanduser('~/.local/state')
                histfile = os.path.join(state, 'python', 'history')

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
    else:
        histfile = os.environ.get('PYTHON_HISTORY') or ''
        histdir = os.path.dirname(histfile)
        if histdir:
            try:
                os.makedirs(histdir, exist_ok=True)
            except OSError:
                pass

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
