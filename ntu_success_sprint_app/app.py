from flask import Flask, request, jsonify
from youtube_transcript_api import YouTubeTranscriptApi, TranscriptsDisabled, NoTranscriptFound

app = Flask(__name__)

@app.route('/transcript', methods=['GET'])
def get_transcript():
    video_id = request.args.get('videoId')
    if not video_id:
        return jsonify({'error': 'Missing videoId parameter'}), 400

    try:
        transcript = YouTubeTranscriptApi.get_transcript(video_id)
        text_only = " ".join([entry['text'] for entry in transcript])
        return jsonify({'transcript': text_only}), 200
    except TranscriptsDisabled:
        return jsonify({'error': 'Transcripts are disabled for this video.'}), 403
    except NoTranscriptFound:
        return jsonify({'error': 'No transcript found for this video.'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)