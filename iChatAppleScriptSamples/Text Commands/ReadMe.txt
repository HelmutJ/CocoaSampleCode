Text commands.applescript

This script demonstrates a "Message Sent" AppleScript for use with iChat. When this script is installed, messages sent using iChat will be processed. If the outgoing message matches certain strings, an appropriate AppleScript command is run.
	
To install this script:

1. Copy this script into ~/Library/Scripts/iChat

2. In iChat Preferences, go to Alerts

3. Choose "Message Sent" for "Event"

4. Check "Run AppleScript" checkbox

5. Select "Text commands.applescript" from the "Run AppleScript" dropdown
	
The script will run every time you send a message in a chat.
	
Available commands:
	
/away <status message> - Set status to away and set status message to specified string.
			
/available <status message> - Set status to available and set status message to specified string.
			
/audio - Start an audio chat with the person you're chatting with.
		
/video - Start a video chat with the person you're chatting with.
