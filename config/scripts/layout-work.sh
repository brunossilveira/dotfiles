#!/bin/bash

# Layout: Browser (2/6) | Terminal (3/6) | Obsidian (1/6)
# All in horizontal tiles on workspace 5

# Switch to workspace 5
aerospace workspace 5

# Wait a moment for workspace switch
sleep 0.2

# Switch to horizontal tiles layout
aerospace layout tiles horizontal

# Launch applications in order: Browser, Alacritty, Obsidian
open -a "Google Chrome" || open -a "Arc" || open -a "Safari"
sleep 0.5
open -a "Alacritty" || open -a "Terminal"
sleep 0.5
open -a "Obsidian"

# Wait for windows to appear and be tiled
sleep 1.5

# Now resize to get proportions: Browser 2/6, Terminal 3/6, Obsidian 1/6
# Focus on Obsidian and make it smaller (1/6 of screen)
aerospace focus --window-id $(aerospace list-windows --workspace 5 | grep -i obsidian | head -1 | awk '{print $1}')
aerospace resize smart -200
aerospace resize smart -100

# Focus on Terminal and make it larger (3/6 of screen, which is 50%)
aerospace focus --window-id $(aerospace list-windows --workspace 5 | grep -i alacritty | head -1 | awk '{print $1}')
aerospace resize smart +150
aerospace resize smart +100

# Browser will automatically take remaining space (2/6)
