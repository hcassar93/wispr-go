# Audio Recorder with AI Transcription

https://www.loom.com/share/df6b56a88eed42e1add615915aec72bb


> Built by GitHub Copilot

A Hammerspoon-based audio recording tool that automatically transcribes recordings using OpenAI's Whisper API and processes them with configurable AI prompts.

## Features

- 🎙️ Audio recording with customizable microphone selection
- 🤖 Automatic transcription using OpenAI Whisper
- 📝 AI-powered transcript processing with configurable prompts
- 📋 Auto-paste transcripts to focused applications
- 🎛️ Menu bar interface for easy access
- ⌨️ Keyboard shortcut (Cmd+Option+R) to toggle recording

## Installation

### Step 0: Clone the Repository

First, clone this repository to your local machine:

```bash
git clone <repository-url>
cd wispr-go
```

*Note: Replace `<repository-url>` with the actual URL of this repository.*

### Step 1: Install Homebrew

If you don't have Homebrew installed, run this command in Terminal:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Step 2: Install Hammerspoon

```bash
brew install hammerspoon
```

### Step 3: Install FFmpeg

```bash
brew install ffmpeg
```

### Step 4: Add to Hammerspoon Configuration

1. Open Hammerspoon and go to the menu bar → Hammerspoon → Open Config
2. This will open your `~/.hammerspoon/init.lua` file
3. Add this line to import the audio recorder (adjust the path to where you cloned the repository):

```lua
dofile("/path/to/your/cloned/wispr-go/init.lua")
```

**Examples of common paths:**
- If you cloned to your home directory: `dofile("~/wispr-go/init.lua")`
- If you cloned to your Desktop: `dofile("~/Desktop/wispr-go/init.lua")`
- If you cloned to a Code folder: `dofile("~/Code/wispr-go/init.lua")`

*Important: Replace the path with the actual location where you cloned the repository in Step 0.*

### Step 5: Configure OpenAI API Key

1. Get an OpenAI API key from [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys)

2. Add your API key to the `.env` file in the project directory:

   Open the `.env` file in your cloned repository folder and replace the placeholder with your actual API key:

   ```
   OPENAI_API_KEY=sk-your-actual-api-key-here
   ```

   *Note: Replace `sk-your-actual-api-key-here` with your actual OpenAI API key from step 1.*

3. Verify setup by checking the `.env` file:
   ```bash
   cat .env
   ```

4. **Test in Hammerspoon**: After setup, reload Hammerspoon config and check the console (menu bar → Hammerspoon → Console) for debug messages.

### Step 6: Set Up Prompts (Optional)

Create a `prompts.json` file in the same directory as `init.lua` to define custom AI processing prompts:

```json
{
    "prompts": [
        {
            "role": "Engineer", 
            "content": "You are an expert in software development. Take the following instructions from your manager and format them into clear and concise instructions for an AI coding agent. Ensure that all necessary details are included and instructions don't repeat themselves. Synthesize a best practice prompt for an AI agent."
        },
        {
            "role": "SDR",
            "content": "You are an outbound sales development representative. Take the following instructions and return a clear and concise message. Keep it short and to the point. A casual and fun tone is perfect."
        }
    ]
}
```

## Usage

### Recording Audio

1. **Keyboard Shortcut**: Press `Cmd+Option+R` to start/stop recording
2. **Menu Bar**: Click the 🎙️ icon in your menu bar and select "Start Recording"

### Selecting Microphone

1. Click the 🎙️ icon in the menu bar
2. Choose your preferred microphone from the list

### Using AI Prompts

1. Click the 🎙️ icon in the menu bar
2. Select a prompt from the "Prompt:" section
3. When you record, the transcript will be processed according to the selected prompt

### File Organization

Recordings are saved to `~/Desktop/Recordings/` with the following structure:

```
~/Desktop/Recordings/recording_2025-07-15_14-30-25/
├── recording_2025-07-15_14-30-25.m4a     # Audio file
└── recording_2025-07-15_14-30-25.txt     # Transcript (after processing)
```

## Troubleshooting

### "FFmpeg not found" Error

Make sure FFmpeg is installed and accessible:

```bash
which ffmpeg
```

If not found, reinstall with Homebrew:

```bash
brew install ffmpeg
```

### "Transcription failed" or "OpenAI API key not configured" Error

1. Check that your `.env` file contains your OpenAI API key:
   ```bash
   cat .env
   ```

2. Ensure the `.env` file is in the same directory as `init.lua`

3. Verify your API key format in the `.env` file:
   ```
   OPENAI_API_KEY=sk-proj-your-actual-key-here
   ```
   (No quotes needed around the key)

4. Check Hammerspoon Console for debug messages:
   - Menu bar → Hammerspoon → Console
   - Look for "API KEY DEBUG" messages

5. Ensure you have sufficient credits in your OpenAI account

6. Check your internet connection

### Prompts Not Loading

1. Verify `prompts.json` is in the same directory as `init.lua`
2. Check the JSON syntax is valid
3. Reload prompts from the menu bar: 🎙️ → "Reload Prompts"

### Hammerspoon Issues

If Hammerspoon doesn't load the script:

1. Open Hammerspoon Console (menu bar → Hammerspoon → Console)
2. Check for error messages
3. Reload configuration: menu bar → Hammerspoon → Reload Config

## Requirements

- macOS (tested on macOS 12+)
- Homebrew
- Hammerspoon
- FFmpeg
- OpenAI API key (configured in `.env` file)
- Internet connection (for API calls)

## Privacy Note

This tool sends your audio recordings to OpenAI's servers for transcription and processing. Please ensure you're comfortable with this before recording sensitive content.
