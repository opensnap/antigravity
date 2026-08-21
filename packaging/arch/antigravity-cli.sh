# Antigravity CLI - Shell Profile
# Adds agy to PATH if not already there

if [ -d "/usr/bin" ] && [[ ":${PATH}:" != *":/usr/bin:"* ]]; then
    export PATH="/usr/bin:${PATH}"
fi
