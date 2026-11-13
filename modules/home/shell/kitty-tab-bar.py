# A persistent status marker for kitty's tab titles, used as `{custom}` in tab_title_template
# (modules/home/shell/kitty.nix). kitty calls draw_title(data) for every tab title and puts the result in.
#
# kitty's own {tab.program_status} cannot do this. It draws nothing for `idle`, and it drops a `done` record as
# soon as the window is focused or a key is pressed, after which a coding agent that has finished and waits for
# the next prompt looks the same as a shell. Claude Code sends `done` once at the end of a turn and never
# repeats it, so after that the tab would stay plain. Here a window with an agent running in it and nothing to
# report is "ready", which makes the marker persistent.
import os

from kitty.fast_data_types import get_boss

# state: (glyph, palette colour index), least urgent first. Palette indexes follow the terminal's theme.
STATES = {
    'ready': ('✳', 8),  # waiting for the next prompt: dim, a calm resting state
    'working': ('◐', 3),
    'done': ('✓', 2),  # finished while unseen; kitty drops it once the window is focused or a key pressed
    'error': ('✗', 1),
    'blocked': ('▲', 1),  # needs the user: permission, a question, sign-in
}
URGENCY = list(STATES)
AGENTS = {'claude'}


def agent_running(window):
    # needs shell integration: it knows the command that was started and whether the shell is back at its prompt
    if window.at_prompt:
        return False
    words = (window.last_cmd_cmdline or '').split(None, 1)
    return bool(words) and os.path.basename(words[0]) in AGENTS


def window_state(window):
    """What the program in this window reports, 'ready' for an idle agent, None for a plain window."""
    status = window.program_status
    record = status.most_urgent()
    if record is not None and record.state.value != 'idle':
        return record.state.value
    if record is not None or agent_running(window):
        return 'ready'
    return None


def draw_title(data):
    try:
        tab = get_boss().tab_for_id(data['tab_id'])
        states = [s for s in map(window_state, tab or ()) if s]
        if not states:
            return ''
        best = max(states, key=URGENCY.index)
        glyph, colour = STATES[best]
        count = states.count(best)
        fg = data['fmt'].fg
        return f'{getattr(fg, f"color{colour}")}{glyph}{count if count > 1 else ""}{fg.tab} '
    except Exception:
        # never let a bug here take the whole tab title down with it
        return ''
