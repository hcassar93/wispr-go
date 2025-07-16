# Audio Recorder with AI Transcription

[![Wispr-Go - Watch Video](https://cdn.loom.com/sessions/thumbnails/df6b56a88eed42e1add615915aec72bb-0f48e4236291bd4b-full-play.gif)](https://www.loom.com/share/df6b56a88eed42e1add615915aec72bb)

[Wispr-Go - Watch Video](https://www.loom.com/share/df6b56a88eed42e1add615915aec72bb)


> Built by GitHub Copilot

## Problems This Solves

### Native macOS Transcription Sucks
macOS's built-in transcription is painfully inaccurate and unreliable. **Whisper is way, way better** - it actually understands what you're saying and handles various accents, technical terms, and background noise like a champ.

### Beyond Basic Transcription 
Often I don't just want my voice transcribed - I want it **passed directly to a prompt for post-processing**. Whether that's formatting meeting notes, creating action items, writing code documentation, or generating emails from voice memos, raw transcription is just the starting point.

### Visual Context Missing
When explaining something on screen, **I want to attach a screenshot** to provide visual context alongside my voice. This is crucial for code reviews, design feedback, bug reports, or any workflow where what you're looking at matters as much as what you're saying.

### No Existing Solutions
Here's the kicker: **none of the major AI chat desktop applications or operating systems currently provide this**. They give you either basic transcription OR AI processing OR screenshots, but never all three integrated seamlessly.

### The Hack
So I hacked together this Hammerspoon plugin that does exactly what I need. **Please, someone build a SaaS that does all this natively.** In the meantime, I'm using this and it works beautifully.

## Features

- 🎙️ Audio recording with customizable microphone selection
- 🤖 Automatic transcription using OpenAI Whisper
- 📝 AI-powered transcript processing with configurable prompts
- 📋 Auto-paste transcripts to focused applications
- 🎛️ Menu bar interface for easy access
- ⌨️ Keyboard shortcut (Cmd+Option+R) to toggle recording
- 📸 **NEW:** Available screenshot capture during recording sessions
- 🔗 **NEW:** Path or Base64 screenshots included in responses
- 🖼️ **NEW:** Screenshots passed to AI prompts for enhanced context understanding

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

**📸 Screenshot Feature**: Screenshots are automatically captured during recording sessions and saved alongside your audio files.

### Selecting Microphone

1. Click the 🎙️ icon in the menu bar
2. Choose your preferred microphone from the list

### Using Screenshots with AI

Screenshots captured during recording are automatically:
- 🔗 **Encoded as base64** and included as local system links in responses
- 🤖 **Passed to AI prompts** for enhanced context understanding
- 📁 **Organized in folders** within your recording directory

This allows AI to provide more contextual responses by understanding both what you said and what was on your screen.

### Using AI Prompts

1. Click the 🎙️ icon in the menu bar
2. Select a prompt from the "Prompt:" section
3. When you record, the transcript will be processed according to the selected prompt

### File Organization

Recordings are saved to `~/Desktop/Recordings/` with the following structure:

```
~/Desktop/Recordings/recording_2025-07-15_14-30-25/
├── recording_2025-07-15_14-30-25.m4a     # Audio file
├── recording_2025-07-15_14-30-25.txt     # Transcript (after processing)
└── screenshots/                          # Screenshot captures (NEW)
    ├── screenshot_001.png
    ├── screenshot_002.png
    └── ...
```

## Screenshot Features 📸

### Automatic Screenshot Capture

During recording sessions, the application automatically captures screenshots at regular intervals to provide visual context alongside your audio recordings.

**Key Features:**
- 📸 **Periodic Screenshots**: Captures screen content during active recording sessions
- 🖼️ **Visual Context**: Screenshots provide additional context for AI processing
- 📁 **Organized Storage**: All screenshots are saved in a dedicated `screenshots/` folder within each recording directory

### Base64 Screenshot Integration

Screenshots are automatically encoded as base64 data and included in the system response as local file links.

**Benefits:**
- 🔗 **Local System Links**: Screenshots accessible as `file://` URLs for easy viewing
- 💾 **Embedded Data**: Base64 encoding ensures screenshots are preserved in responses
- 🔄 **Seamless Integration**: No external dependencies for screenshot viewing

### AI-Enhanced Screenshot Processing

Screenshots are automatically passed to your selected AI prompts for enhanced context understanding.

**How it works:**
- 🤖 **Multi-modal Processing**: AI prompts can analyze both audio transcripts and visual content
- 🧠 **Enhanced Context**: Screenshots help AI understand what you were working on during recording
- 📊 **Visual Analysis**: AI can describe, analyze, or reference visual elements from your screen
- 💡 **Smarter Responses**: Combined audio and visual context leads to more accurate and contextual AI responses

**Example Use Cases:**
- **Code Reviews**: AI can see your code while you explain issues
- **Design Feedback**: Visual context helps AI understand design critiques
- **Tutorial Creation**: Screenshots capture step-by-step processes alongside narration
- **Bug Reports**: Visual evidence combined with verbal descriptions

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

### Screenshot Issues

**Screenshots Not Capturing:**
1. Check macOS screen recording permissions for Hammerspoon:
   - System Preferences → Security & Privacy → Privacy → Screen Recording
   - Ensure Hammerspoon is enabled
2. Verify the `screenshots/` folder is being created in your recording directory
3. Check Hammerspoon Console for screenshot-related error messages

**Base64 Links Not Working:**
1. Ensure screenshots are being saved properly (check the `screenshots/` folder)
2. Verify file permissions allow reading of screenshot files
3. Check that the local file paths are correctly formatted

**AI Not Processing Screenshots:**
1. Confirm your selected AI prompt supports image processing
2. Check that screenshots are being passed correctly to the API
3. Verify your OpenAI API plan supports vision capabilities

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
- **Screen Recording Permission** for Hammerspoon (for screenshot features)

## Privacy Note

This tool sends your audio recordings and captured screenshots to OpenAI's servers for transcription and processing. Please ensure you're comfortable with this before recording sensitive content. Screenshots capture whatever is visible on your screen during recording sessions, so be mindful of any confidential information that may be displayed.
