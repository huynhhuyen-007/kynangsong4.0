from youtube_transcript_api import YouTubeTranscriptApi
import json
import sys

# Ensure UTF-8 output encoding for Vietnamese
sys.stdout.reconfigure(encoding='utf-8')

try:
    transcript = YouTubeTranscriptApi.get_transcript('Pp3uV0ZWoq0', languages=['vi', 'en'])
    res = ' '.join([t['text'] for t in transcript])
    print(res)
except Exception as e:
    print('Error:', e)
