-- Audio Recording Automation for Hammerspoon
-- Triggered by Cmd+Option+R

local audioRecorder = {}
audioRecorder.isRecording = false
audioRecorder.recordingTask = nil
audioRecorder.recordingFile = nil

-- Configuration
local recordingDirectory = os.getenv("HOME") .. "/Desktop/Recordings"
local defaultFormat = "m4a"  -- Can be changed to "wav", "aiff", etc.
local audioDevice = ":1"  -- Default: MacBook Pro Microphone
local currentMicName = "MacBook Pro Microphone"  -- Display name for current mic
local availableDevices = {}  -- Cache of available devices
local selectedPromptIndex = nil  -- Track which prompt is selected
local prompts = {}  -- Prompts loaded from JSON file

-- OpenAI API Configuration
-- Load API key from .env file in the project directory
local function getApiKey()
    -- Get the directory where this script is located
    local scriptPath = debug.getinfo(1, "S").source:sub(2)  -- Remove the '@' prefix
    local scriptDir = scriptPath:match("(.*/)")
    local envFile = scriptDir .. ".env"
    
    local file = io.open(envFile, "r")
    if file then
        for line in file:lines() do
            -- Look for OPENAI_API_KEY=value pattern
            local key = line:match("^OPENAI_API_KEY=(.+)$")
            if key and key ~= "" and key ~= "your_openai_api_key_here" then
                file:close()
                return key:gsub("%s+", "") -- Remove any whitespace
            end
        end
        file:close()
    end
    
    return "YOUR_API_KEY_HERE"
end

local OPENAI_API_KEY = getApiKey()

-- Debug: Print the API key status at startup
print("=== API KEY DEBUG ===")
local scriptPath = debug.getinfo(1, "S").source:sub(2)
local scriptDir = scriptPath:match("(.*/)")
local envFile = scriptDir .. ".env"
print("Looking for .env file at:", envFile)

local envFileHandle = io.open(envFile, "r")
if envFileHandle then
    print(".env file found")
    envFileHandle:close()
else
    print(".env file not found - please create one with your OpenAI API key")
end

print("Final OPENAI_API_KEY value:", OPENAI_API_KEY == "YOUR_API_KEY_HERE" and "NOT CONFIGURED" or "CONFIGURED")
if OPENAI_API_KEY ~= "YOUR_API_KEY_HERE" then
    print("Using API key starting with:", string.sub(OPENAI_API_KEY, 1, 10) .. "...")
end
print("=====================")

-- Transcribe audio file using OpenAI Whisper API
function audioRecorder.transcribeAudio(audioFilePath)
    if OPENAI_API_KEY == "YOUR_API_KEY_HERE" then
        print("OpenAI API key not configured - skipping transcription")
        return
    end
    
    print("Starting transcription for: " .. audioFilePath)
    hs.alert.show("🤖 Transcribing...", 1)
    
    -- Generate transcript filename in the same directory as the audio file
    local audioDir = audioFilePath:match("(.*/)")
    local audioBasename = audioFilePath:match("([^/]+)$"):gsub("%.%w+$", "")
    local transcriptFile = audioDir .. audioBasename .. ".txt"
    
    -- Build curl command for OpenAI Whisper API
    local curlCmd = string.format([[
        curl -s -X POST "https://api.openai.com/v1/audio/transcriptions" \
        -H "Authorization: Bearer %s" \
        -H "Content-Type: multipart/form-data" \
        -F "file=@%s" \
        -F "model=whisper-1" \
        -F "response_format=text" \
        -o "%s"
    ]], OPENAI_API_KEY, audioFilePath, transcriptFile)
    
    -- Execute transcription
    local task = hs.task.new("/bin/sh", function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            print("Transcription completed: " .. transcriptFile)
            
            -- Read the transcript file and copy to clipboard
            local file = io.open(transcriptFile, "r")
            if file then
                local transcript = file:read("*all")
                file:close()
                
                -- Apply selected prompt to enhance the transcript if one is selected
                if selectedPromptIndex and prompts[selectedPromptIndex] then
                    print("🤖 AI PROCESSING TRIGGERED")
                    print("Selected prompt index: " .. selectedPromptIndex)
                    print("Selected prompt: " .. prompts[selectedPromptIndex].content)
                    print("Original transcript length: " .. string.len(transcript))
                    
                    local processedTranscript = audioRecorder.applyPromptToTranscript(transcript, selectedPromptIndex)
                    
                    if processedTranscript and processedTranscript ~= transcript then
                        print("✅ AI processing changed the transcript")
                        print("Original vs Processed length: " .. string.len(transcript) .. " -> " .. string.len(processedTranscript))
                        transcript = processedTranscript
                        print("🎯 Using AI-processed transcript")
                    else
                        print("⚠️ AI processing returned same/empty result")
                        print("Processed result: " .. tostring(processedTranscript))
                        print("🔄 Using original transcript")
                    end
                else
                    if not selectedPromptIndex then
                        print("ℹ️ No prompt selected - using original transcript")
                    elseif not prompts[selectedPromptIndex] then
                        print("❌ Selected prompt index invalid: " .. tostring(selectedPromptIndex))
                    else
                        print("❌ Unknown issue with prompt selection")
                    end
                end
                
                -- Copy to clipboard
                hs.pasteboard.setContents(transcript)
                print("Transcript copied to clipboard")
                
                -- Auto-paste if there's a focused text input
                local focusedApp = hs.application.frontmostApplication()
                if focusedApp then
                    -- Small delay to ensure clipboard is ready
                    hs.timer.doAfter(0.1, function()
                        -- Simulate Cmd+V to paste
                        hs.eventtap.keyStroke({"cmd"}, "v")
                        print("Auto-pasted transcript to focused input")
                    end)
                    hs.alert.show("📝 Transcript saved & auto-pasted", 1)
                else
                    hs.alert.show("📝 Transcript saved & copied", 1)
                end
            else
                print("Could not read transcript file")
                hs.alert.show("📝 Transcript saved", 1)
            end
        else
            print("Transcription failed - Exit code: " .. tostring(exitCode))
            if stdErr and stdErr ~= "" then
                print("Error: " .. stdErr)
            end
            hs.alert.show("❌ Transcription failed", 1)
        end
    end, {"-c", curlCmd})
    
    task:start()
end

-- Create recordings directory if it doesn't exist
function audioRecorder.ensureRecordingDirectory()
    local task = hs.task.new("/bin/mkdir", nil, {"-p", recordingDirectory})
    task:start()
    task:waitUntilExit()
end

-- Generate session directory and filename with timestamp
function audioRecorder.generateFilename()
    local timestamp = os.date("%Y-%m-%d_%H-%M-%S")
    local sessionDir = recordingDirectory .. "/recording_" .. timestamp
    
    -- Create the session directory
    local task = hs.task.new("/bin/mkdir", nil, {"-p", sessionDir})
    task:start()
    task:waitUntilExit()
    
    return sessionDir .. "/recording_" .. timestamp .. "." .. defaultFormat
end

-- Check if ffmpeg is available
function audioRecorder.checkRecordingTool()
    -- Check common locations for ffmpeg
    local possiblePaths = {
        "/opt/homebrew/bin/ffmpeg",  -- ARM Homebrew
        "/usr/local/bin/ffmpeg",     -- Intel Homebrew
        "/usr/local/homebrew/bin/ffmpeg"  -- Custom Homebrew location
    }
    
    for _, path in ipairs(possiblePaths) do
        local file = io.open(path, "r")
        if file then
            file:close()
            return path, "ffmpeg"
        end
    end
    
    -- Fallback: try which command with full PATH
    local ffmpegPath = hs.execute("PATH=/opt/homebrew/bin:/usr/local/bin:/usr/local/homebrew/bin:$PATH which ffmpeg"):gsub("%s+", "")
    if ffmpegPath and ffmpegPath ~= "" then
        return ffmpegPath, "ffmpeg"
    end
    
    return nil, nil
end

-- Start recording
function audioRecorder.startRecording()
    if audioRecorder.isRecording then
        hs.alert.show("Already recording!", 1)
        return
    end
    
    local toolPath, toolType = audioRecorder.checkRecordingTool()
    if not toolPath then
        hs.alert.show("FFmpeg not found!", 2)
        return
    end
    
    audioRecorder.ensureRecordingDirectory()
    audioRecorder.recordingFile = audioRecorder.generateFilename()
    
    -- Build the complete command as a string
    local cmd = string.format('"%s" -f avfoundation -i %s -c:a aac -b:a 128k -ac 2 -ar 44100 -y "%s"', 
                             toolPath, audioDevice, audioRecorder.recordingFile)
    
    print("Executing: " .. cmd)
    
    audioRecorder.recordingTask = hs.task.new("/bin/sh", function(exitCode, stdOut, stdErr)
        print("Recording finished - Exit code: " .. tostring(exitCode))
        if stdErr and stdErr ~= "" then
            print("Error: " .. stdErr)
        end
        
        -- Check if file was actually created (exit code can be non-zero due to signal termination)
        local file = io.open(audioRecorder.recordingFile, "r")
        local fileExists = file ~= nil
        if file then file:close() end
        
        if fileExists then
            hs.alert.show("🔴 Saved", 1)
            -- Automatically start transcription
            audioRecorder.transcribeAudio(audioRecorder.recordingFile)
        else
            hs.alert.show("❌ Failed", 1)
        end
        audioRecorder.isRecording = false
        audioRecorder.recordingTask = nil
    end, {"-c", cmd})
    
    if audioRecorder.recordingTask:start() then
        audioRecorder.isRecording = true
        hs.alert.show("🔴 Recording", 1)
    else
        hs.alert.show("❌ Failed", 1)
    end
end

-- Stop recording
function audioRecorder.stopRecording()
    if not audioRecorder.isRecording or not audioRecorder.recordingTask then
        hs.alert.show("Not recording", 1)
        return
    end
    
    audioRecorder.recordingTask:terminate()
    hs.alert.show("🛑 Stopped", 1)
end

-- Toggle recording (start if stopped, stop if started)
function audioRecorder.toggleRecording()
    if audioRecorder.isRecording then
        audioRecorder.stopRecording()
    else
        audioRecorder.startRecording()
    end
end

-- Get available audio devices from FFmpeg
function audioRecorder.getAudioDevices()
    local toolPath = audioRecorder.checkRecordingTool()
    if not toolPath then
        return {}
    end
    
    local output = hs.execute(toolPath .. ' -f avfoundation -list_devices true -i "" 2>&1')
    local devices = {}
    
    -- Parse the output to extract audio devices
    local inAudioSection = false
    for line in output:gmatch("[^\r\n]+") do
        if line:match("AVFoundation audio devices:") then
            inAudioSection = true
        elseif inAudioSection and line:match("%[AVFoundation") and line:match("%]") then
            local deviceNum, deviceName = line:match("%[(%d+)%] (.+)")
            if deviceNum and deviceName then
                table.insert(devices, {
                    id = ":" .. deviceNum,
                    name = deviceName
                })
            end
        elseif inAudioSection and not line:match("%[AVFoundation") then
            break
        end
    end
    
    return devices
end

-- Initialize devices at startup
function audioRecorder.initializeDevices()
    availableDevices = audioRecorder.getAudioDevices()
    print("Found " .. #availableDevices .. " audio devices:")
    for i, device in ipairs(availableDevices) do
        print("  " .. device.id .. " - " .. device.name)
    end
end

-- Set audio device
function audioRecorder.setAudioDevice(deviceId, deviceName)
    audioDevice = deviceId
    currentMicName = deviceName
    hs.alert.show("Microphone set to: " .. deviceName, 1)
    audioRecorder.updateMenubar()
end

-- Prompts functionality

-- Load prompts from JSON file
function audioRecorder.loadPrompts()
    -- Get the directory where this script is located
    local scriptPath = debug.getinfo(1, "S").source:sub(2)  -- Remove the '@' prefix
    local scriptDir = scriptPath:match("(.*/)")
    local promptsFile = scriptDir .. "prompts.json"
    
    print("Looking for prompts file at: " .. promptsFile)
    
    local file = io.open(promptsFile, "r")
    if not file then
        print("Prompts file not found: " .. promptsFile)
        -- Try alternative path - current working directory
        local altPromptsFile = "prompts.json"
        file = io.open(altPromptsFile, "r")
        if file then
            promptsFile = altPromptsFile
            print("Found prompts file at: " .. promptsFile)
        else
            return
        end
    end
    
    local content = file:read("*all")
    file:close()
    
    print("Prompts file content: " .. content)
    
    -- Improved JSON parsing for the prompts structure
    local success, data = pcall(function()
        local promptsList = {}
        
        -- Find the start of the prompts array
        local promptsStart = content:find('"prompts"%s*:%s*%[')
        if not promptsStart then 
            print("Could not find 'prompts' array in JSON")
            return nil 
        end
        
        -- Extract the content starting from the prompts array
        local promptsSection = content:sub(promptsStart)
        
        -- Pattern to match complete prompt objects, handling nested quotes properly
        -- This captures everything between { and } for each prompt object
        local promptObjectPattern = '(%b{})'
        
        for promptObj in promptsSection:gmatch(promptObjectPattern) do
            -- Extract role and content from each prompt object
            local role = promptObj:match('"role"%s*:%s*"([^"]*)"')
            
            -- For content, we need to handle the fact that it might contain escaped quotes
            -- Find the content field and extract everything between the quotes
            local contentStart = promptObj:find('"content"%s*:%s*"')
            if contentStart and role then
                -- Find the content string - start after the opening quote
                local contentQuoteStart = promptObj:find('"', contentStart + promptObj:match('"content"%s*:%s*'):len())
                if contentQuoteStart then
                    -- Find the closing quote, being careful about escaped quotes
                    local contentEnd = contentQuoteStart + 1
                    local found = false
                    while contentEnd <= #promptObj and not found do
                        if promptObj:sub(contentEnd, contentEnd) == '"' then
                            -- Check if it's escaped
                            local backslashCount = 0
                            local checkPos = contentEnd - 1
                            while checkPos > 0 and promptObj:sub(checkPos, checkPos) == '\\' do
                                backslashCount = backslashCount + 1
                                checkPos = checkPos - 1
                            end
                            -- If even number of backslashes (or zero), the quote is not escaped
                            if backslashCount % 2 == 0 then
                                found = true
                            else
                                contentEnd = contentEnd + 1
                            end
                        else
                            contentEnd = contentEnd + 1
                        end
                    end
                    
                    if found then
                        local content = promptObj:sub(contentQuoteStart + 1, contentEnd - 1)
                        -- Unescape any escaped quotes
                        content = content:gsub('\\"', '"')
                        
                        print("Found prompt - Role: " .. role .. ", Content: " .. content:sub(1, 50) .. "...")
                        table.insert(promptsList, {
                            role = role,
                            content = content
                        })
                    end
                end
            end
        end
        
        print("Total prompts found: " .. #promptsList)
        return promptsList
    end)
    
    if success and data then
        prompts = data
        print("Loaded " .. #prompts .. " prompts from " .. promptsFile)
        for i, prompt in ipairs(prompts) do
            print("  " .. i .. ". [" .. prompt.role .. "] " .. prompt.content:sub(1, 50) .. "...")
        end
    else
        print("Failed to parse prompts file")
    end
end

-- Apply prompt to transcript
function audioRecorder.applyPromptToTranscript(transcript, promptIndex)
    print("=== AI PROCESSING START ===")
    print("Function called with promptIndex: " .. tostring(promptIndex))
    print("Transcript length: " .. string.len(transcript))
    print("Transcript preview: " .. transcript:sub(1, 100) .. "...")
    
    if not prompts or #prompts == 0 then
        print("ERROR: No prompts loaded")
        return transcript
    end
    
    local prompt = prompts[promptIndex or 1]
    if not prompt then
        print("ERROR: Invalid prompt index: " .. tostring(promptIndex))
        return transcript
    end
    
    print("Selected prompt: [" .. prompt.role .. "] " .. prompt.content)
    
    if OPENAI_API_KEY == "YOUR_API_KEY_HERE" then
        print("ERROR: OpenAI API key not configured - just prepending prompt")
        return prompt.content .. "\n\n" .. transcript
    end
    
    print("✅ API key configured, proceeding with AI processing...")
    print("Using model: gpt-4o-mini")
    hs.alert.show("🤖 Processing with AI...", 2)
    
    -- Create a temporary file for the enhanced transcript
    local tempFile = os.tmpname() .. ".txt"
    print("Temp file for AI response: " .. tempFile)
    
    -- Build the JSON payload for the chat completion
    local messages = string.format([[{
        "model": "gpt-4o-mini",
        "messages": [
            {
                "role": "system",
                "content": "You are a helpful assistant. Process the user's transcript according to their instructions. Return ONLY the processed result without any additional commentary or explanation."
            },
            {
                "role": "user",
                "content": "Instructions: %s\n\nTranscript to process: %s\n\nPlease apply the instructions to the transcript and return only the final processed result:"
            }
        ],
        "temperature": 0.7,
        "max_tokens": 4000
    }]], prompt.content:gsub('"', '\\"'):gsub('\n', '\\n'), transcript:gsub('"', '\\"'):gsub('\n', '\\n'))
    
    print("📝 JSON payload length: " .. string.len(messages))
    print("📝 JSON payload preview:")
    print(messages:sub(1, 300) .. "...")
    
    -- Create a temp file for the JSON payload
    local jsonFile = os.tmpname() .. ".json"
    print("JSON payload file: " .. jsonFile)
    
    local jsonFileHandle = io.open(jsonFile, "w")
    if jsonFileHandle then
        jsonFileHandle:write(messages)
        jsonFileHandle:close()
        print("✅ JSON payload written to file")
        
        -- Verify the file was written
        local verifyHandle = io.open(jsonFile, "r")
        if verifyHandle then
            local written = verifyHandle:read("*all")
            verifyHandle:close()
            print("📄 Verified JSON file size: " .. string.len(written) .. " bytes")
        end
    else
        print("❌ ERROR: Could not create JSON payload file")
        return transcript
    end
    
    -- Build curl command for OpenAI Chat Completions API
    local curlCmd = string.format([[
        curl -s -X POST "https://api.openai.com/v1/chat/completions" \
        -H "Authorization: Bearer %s" \
        -H "Content-Type: application/json" \
        -d @"%s" \
        > "%s.raw" && cat "%s.raw" | jq -r '.choices[0].message.content // empty' > "%s"
    ]], OPENAI_API_KEY, jsonFile, tempFile, tempFile, tempFile)
    
    print("🌐 Executing curl command:")
    print("API Endpoint: https://api.openai.com/v1/chat/completions")
    print("JSON file: " .. jsonFile)
    print("Output file: " .. tempFile)
    print("Raw output file: " .. tempFile .. ".raw")
    print("Full command: " .. curlCmd)
    
    -- Execute the API call synchronously
    print("⏳ Making API call to OpenAI...")
    local result = os.execute(curlCmd)
    print("📡 API call completed with result: " .. tostring(result))
    
    -- Clean up JSON file
    os.remove(jsonFile)
    print("🗑️  Cleaned up JSON file")
    
    -- In Lua, os.execute returns true for success, not 0
    if result == true then
        print("✅ API call successful, reading response...")
        
        -- First, let's see what the raw API response was
        local rawFile = io.open(tempFile .. ".raw", "r")
        if rawFile then
            local rawResponse = rawFile:read("*all")
            rawFile:close()
            print("🔍 Raw API response length: " .. string.len(rawResponse))
            print("🔍 Raw API response: " .. rawResponse:sub(1, 500) .. (string.len(rawResponse) > 500 and "..." or ""))
            os.remove(tempFile .. ".raw") -- Clean up raw file
        else
            print("❌ Could not read raw API response file")
        end
        
        -- Read the enhanced transcript
        local file = io.open(tempFile, "r")
        if file then
            local enhancedTranscript = file:read("*all")
            file:close()
            print("📖 Read response from file, length: " .. string.len(enhancedTranscript))
            print("📄 Processed response: '" .. enhancedTranscript .. "'")
            
            os.remove(tempFile) -- Clean up temp file
            print("🗑️  Cleaned up temp file")
            
            if enhancedTranscript and enhancedTranscript:trim() ~= "" and enhancedTranscript ~= "null" then
                print("🎉 AI processing successful!")
                print("📝 Original transcript (first 100 chars): " .. transcript:sub(1, 100) .. "...")
                print("🤖 AI processed result (first 100 chars): " .. enhancedTranscript:sub(1, 100) .. "...")
                print("📊 Character count - Original: " .. string.len(transcript) .. ", Processed: " .. string.len(enhancedTranscript:trim()))
                hs.alert.show("✅ AI processing complete", 1)
                print("=== AI PROCESSING SUCCESS ===")
                return enhancedTranscript:trim()
            else
                print("❌ AI returned empty/null response")
                print("📄 Processed response was: '" .. tostring(enhancedTranscript) .. "'")
                hs.alert.show("⚠️ AI processing failed, using basic mode", 2)
                print("=== AI PROCESSING FAILED (EMPTY RESPONSE) ===")
                return prompt.content .. "\n\n" .. transcript
            end
        else
            print("❌ Could not read AI response file: " .. tempFile)
            hs.alert.show("⚠️ AI processing failed, using basic mode", 2)
            print("=== AI PROCESSING FAILED (FILE READ ERROR) ===")
            return prompt.content .. "\n\n" .. transcript
        end
    else
        print("❌ OpenAI API call failed with result: " .. tostring(result))
        hs.alert.show("⚠️ AI processing failed, using basic mode", 2)
        os.remove(tempFile) -- Clean up temp file even on failure
        print("=== AI PROCESSING FAILED (API ERROR) ===")
        return prompt.content .. "\n\n" .. transcript
    end
end

-- Helper function to trim whitespace
function string:trim()
    return self:match("^%s*(.-)%s*$")
end

-- Bind keyboard shortcut (Cmd+Option+R)
hs.hotkey.bind({"cmd", "alt"}, "r", function()
    audioRecorder.toggleRecording()
end)

-- Optional: Add menu bar item for easy access
local menubar = hs.menubar.new()

-- Update menubar function
function audioRecorder.updateMenubar()
    if not menubar then return end
    
    -- Build main menu
    local mainMenu = {
        {title = "🔴 Start Recording", fn = audioRecorder.startRecording},
        {title = "⏹️ Stop Recording", fn = audioRecorder.stopRecording},
        {title = "-"},
        {title = "🎙️ Microphone:", disabled = true},
    }
    
    -- Add microphone options directly to main menu
    for _, device in ipairs(availableDevices) do
        local isSelected = device.id == audioDevice
        table.insert(mainMenu, {
            title = (isSelected and "✓ " or "   ") .. device.name,
            fn = function()
                audioRecorder.setAudioDevice(device.id, device.name)
            end
        })
    end
    
    -- Add separator and prompt section
    table.insert(mainMenu, {title = "-"})
    table.insert(mainMenu, {title = "📝 Prompt:", disabled = true})
    
    -- Add "No Prompt" option with same select style
    table.insert(mainMenu, {
        title = (selectedPromptIndex == nil and "✓ " or "   ") .. "No Prompt",
        fn = function()
            selectedPromptIndex = nil
            audioRecorder.updateMenubar()
            hs.alert.show("No prompt selected", 1)
        end
    })
    
    -- Add all prompts directly to main menu with same select style
    if prompts and #prompts > 0 then
        for i, prompt in ipairs(prompts) do
            local isSelected = selectedPromptIndex == i
            local promptTitle = prompt.role
            table.insert(mainMenu, {
                title = (isSelected and "✓ " or "   ") .. promptTitle,
                fn = function()
                    selectedPromptIndex = i
                    audioRecorder.updateMenubar()
                    hs.alert.show("Selected prompt: " .. prompt.role, 2)
                end
            })
        end
    end
    
    -- Add remaining menu items
    table.insert(mainMenu, {title = "-"})
    table.insert(mainMenu, {title = "📁 Open Recordings Folder", fn = function()
        hs.execute("open " .. recordingDirectory)
    end})
    table.insert(mainMenu, {title = "-"})
    table.insert(mainMenu, {title = "🔄 Refresh Devices", fn = function()
        audioRecorder.initializeDevices()
        audioRecorder.updateMenubar()
        hs.alert.show("Audio devices refreshed", 1)
    end})
    table.insert(mainMenu, {title = "🔄 Reload Prompts", fn = function()
        audioRecorder.loadPrompts()
        audioRecorder.updateMenubar()
        hs.alert.show("Prompts reloaded", 1)
    end})
    table.insert(mainMenu, {title = "-"})
    table.insert(mainMenu, {title = "🗑️ Delete All Sessions", fn = function()
        audioRecorder.deleteAllSessions()
    end})
    
    menubar:setMenu(mainMenu)
end

if menubar then
    menubar:setTitle("🎙️")
    -- Initialize devices and menubar
    audioRecorder.initializeDevices()
    audioRecorder.loadPrompts()  -- Load prompts from JSON file
    audioRecorder.updateMenubar()
end

-- Notification when Hammerspoon loads
hs.alert.show("Audio Recorder loaded! Press Cmd+Option+R to toggle recording", 2)

print("Hammerspoon Audio Recorder initialized")
print("Recordings will be saved to: " .. recordingDirectory)
print("Keyboard shortcut: Cmd+Option+R")

-- Delete all recording sessions with confirmation
function audioRecorder.deleteAllSessions()
    -- Show confirmation dialog
    local buttonPressed = hs.dialog.blockAlert(
        "Delete All Sessions", 
        "Are you sure you want to delete ALL recorded sessions?\n\nThis action cannot be undone and will permanently remove:\n• All audio recordings\n• All transcripts\n• All screenshots\n• All session folders",
        "Delete All",
        "Cancel"
    )
    
    if buttonPressed == "Delete All" then
        print("User confirmed deletion of all sessions")
        hs.alert.show("🗑️ Deleting all sessions...", 2)
        
        -- Delete the entire recordings directory
        local deleteCmd = string.format('rm -rf "%s"', recordingDirectory)
        local success = os.execute(deleteCmd)
        
        if success then
            -- Recreate the empty recordings directory
            audioRecorder.ensureRecordingDirectory()
            hs.alert.show("✅ All sessions deleted", 2)
            print("Successfully deleted all recording sessions")
        else
            hs.alert.show("❌ Failed to delete sessions", 2)
            print("Failed to delete recording sessions")
        end
    else
        print("User cancelled session deletion")
        hs.alert.show("Deletion cancelled", 1)
    end
end