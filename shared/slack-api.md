Formatting text
	https://api.slack.com/reference/surfaces/formatting#special-mentions
	
API message builder
	https://app.slack.com/block-kit-builder/

Tutorial I used to wire this up
	https://www.cloudsavvyit.com/289/how-to-send-a-message-to-slack-from-a-bash-script/
	
Tool I used to remove whitespace from the JSON
	https://codebeautify.org/remove-extra-spaces

App config for my Slack workspace
	https://api.slack.com/apps/A02QZBBESJH/incoming-webhooks?

EXAMPLES
	curl -X POST -H 'Content-type: application/json' --data '{"text":"Hello, World!"}' https://hooks.slack.com/services/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
	
	curl -X POST -H 'Content-type: application/json' --data "{\"text\": \"<@UT8HYKMQW>\n*TEST*\nThis is my test message\n\`\`\`code box\`\`\`\"}" https://hooks.slack.com/services/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


# @here (or <!here>) doesn't seem to work, which is understandable
# Use <@user-id> instead. I noticed this URL when hovering over my name in the web UI:
	https://crandellworkspace.slack.com/team/UT8HYKMQW

# Testing showed that I can @mention myself using <@UT8HYKMQW>

# escape double quotes inside the message payload for shell expansion to work

# Use \n for newline


App ID				A02QZPFG2A2
Client ID			926610666566.2849797546342
Client Secret		0f4b52df4d8ad5e2a86b5f1d67b6208e
Signing Secret		810f6899f65cc8b64198010a226d7239
Verification Token	6pblY7MtbzbpqwCt9UBxHInA
Bot User OAuth Token	xoxb-926610666566-2869287787905-e4l4rKUOQCMmZB9mK3lIDidO