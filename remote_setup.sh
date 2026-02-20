#!/bin/bash
PROJECT_ID="data-processing-487312"
ZONE="us-central1-a"

WORKERS=("worker-1" "worker-2" "worker-3")
MASTER="master"

# Worker Setup
for WORKER in "${WORKERS[@]}"; do
  echo "Setting up $WORKER..."
  gcloud compute ssh $WORKER --zone $ZONE --project $PROJECT_ID --command "
    mkdir -p ~/app
    echo 'flask
requests
google-cloud-storage' > ~/app/requirements.txt
    
    cat <<EOF > ~/app/worker.py
from flask import Flask, request, jsonify
from collections import Counter
import re

app = Flask(__name__)

@app.route('/map', methods=['POST'])
def map_task():
    data = request.get_json()
    if not data or 'text' not in data:
        return jsonify({\"error\": \"Missing text in request\"}), 400
        
    text = data.get('text', '')
    words = re.findall(r'\w+', text.lower())
    counts = Counter(words)
    return jsonify(dict(counts))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

    cd ~/app
    python3 -m venv venv
    ./venv/bin/pip install -r requirements.txt
    nohup ./venv/bin/python3 worker.py > worker.log 2>&1 &
  " --quiet
done

# Master Setup
echo "Setting up $MASTER..."
# Get internal IPs for workers
W1_IP=$(gcloud compute instances describe worker-1 --zone $ZONE --project $PROJECT_ID --format='get(networkInterfaces[0].networkIP)')
W2_IP=$(gcloud compute instances describe worker-2 --zone $ZONE --project $PROJECT_ID --format='get(networkInterfaces[0].networkIP)')
W3_IP=$(gcloud compute instances describe worker-3 --zone $ZONE --project $PROJECT_ID --format='get(networkInterfaces[0].networkIP)')

WORKER_URLS="http://$W1_IP:5000,http://$W2_IP:5000,http://$W3_IP:5000"
BUCKET_NAME="$PROJECT_ID-mapreduce-bucket"

gcloud compute ssh $MASTER --zone $ZONE --project $PROJECT_ID --command "
    mkdir -p ~/app
    echo 'flask
requests
google-cloud-storage' > ~/app/requirements.txt
    
    cat <<EOF > ~/app/master.py
from flask import Flask, jsonify
import requests
from google.cloud import storage
from collections import Counter
import os

app = Flask(__name__)

BUCKET_NAME = os.environ.get('BUCKET_NAME')
INPUT_FILE = os.environ.get('INPUT_FILE', 'archivo.txt')
WORKER_URLS = os.environ.get('WORKER_URLS', '').split(',')

@app.route('/run', methods=['GET'])
def run_mapreduce():
    if not BUCKET_NAME:
        return jsonify({\"error\": \"BUCKET_NAME not set\"}), 500
    
    try:
        storage_client = storage.Client()
        bucket = storage_client.bucket(BUCKET_NAME)
        blob = bucket.blob(INPUT_FILE)
        content = blob.download_as_text()
    except Exception as e:
        return jsonify({\"error\": f\"Failed to download: {str(e)}\"}), 500

    lines = [line for line in content.splitlines() if line.strip()]
    n_workers = len([w for w in WORKER_URLS if w.strip()])
    if n_workers == 0:
        return jsonify({\"error\": \"No workers\"}), 500
        
    chunk_size = max(1, len(lines) // n_workers)
    chunks = [lines[i:i + chunk_size] for i in range(0, len(lines), chunk_size)]
    if len(chunks) > n_workers:
        extra = chunks[n_workers:]
        chunks = chunks[:n_workers]
        for ec in extra: chunks[-1].extend(ec)

    partial_results = []
    for i, worker_url in enumerate(WORKER_URLS):
        if i >= len(chunks): break
        try:
            target_url = worker_url if worker_url.startswith('http') else f'http://{worker_url}:5000'
            response = requests.post(f'{target_url}/map', json={'text': '\n'.join(chunks[i])}, timeout=60)
            if response.status_code == 200: partial_results.append(response.json())
        except Exception as e:
            print(f'Worker {worker_url} failed: {e}')

    total_counts = Counter()
    for res in partial_results: total_counts.update(res)
    return jsonify({'status': 'success', 'top_20': total_counts.most_common(20)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

    cd ~/app
    python3 -m venv venv
    ./venv/bin/pip install -r requirements.txt
    export BUCKET_NAME=$BUCKET_NAME
    export WORKER_URLS=$WORKER_URLS
    nohup ./venv/bin/python3 master.py > master.log 2>&1 &
" --quiet
