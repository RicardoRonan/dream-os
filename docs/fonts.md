# Fonts

Dream OS uses **SF Pro Text** for the interface and **SF Mono** for the terminal
and code. Both are Apple-licensed and cannot be redistributed or auto-installed,
so they must be installed manually.

## SF Pro Text (already present)

Installed at `~/.local/share/fonts/SF-Pro/`. This is what COSMIC uses for the UI
font (`~/.config/cosmic/com.system76.CosmicTk/v1/interface_font`).

## SF Mono (manual)

1. Download **SF Mono** from Apple's developer fonts page
   (<https://developer.apple.com/fonts/>), or extract it from the "SF Mono"
   folder of the "Fonts for Apple Platforms" disk image.
2. Install to the user font dir and refresh the cache:

   ```bash
   mkdir -p ~/.local/share/fonts/SF-Mono
   cp /path/to/SFMono-Regular.otf /path/to/SFMono-Bold.otf ~/.local/share/fonts/SF-Mono/
   fc-cache -f
   fc-list | grep -i 'SF Mono'   # verify
   ```

3. Point COSMIC's monospace font at it:

   ```bash
   cat > ~/.config/cosmic/com.system76.CosmicTk/v1/monospace_font <<'EOF'
   (
       family: "SF Mono",
       weight: Normal,
       stretch: Normal,
       style: Normal,
   )
   EOF
   ```

## Fallback

If you skip SF Mono, **JetBrains Mono Nerd Font** is already installed and is a
solid terminal font (it also ships prompt and tool glyphs).
