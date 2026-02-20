from flask import Flask, request, jsonify
from collections import Counter
import re

app = Flask(__name__)

@app.route('/map', methods=['POST'])
def map_task():
    data = request.get_json()
    if not data or 'text' not in data:
        return jsonify({"error": "Missing text in request"}), 400
        
    text = data.get('text', '')
    
    # Tokenize and clean text
    words = re.findall(r'\w+', text.lower())
    counts = Counter(words)
    
    return jsonify(dict(counts))

if __name__ == '__main__':
    # Listen on all interfaces on port 5000
    app.run(host='0.0.0.0', port=5000)
