from flask import Flask, jsonify
import requests
from google.cloud import storage
from collections import Counter
import os

app = Flask(__name__)

# Configurable items via environment variables
BUCKET_NAME = os.environ.get('BUCKET_NAME')
INPUT_FILE = os.environ.get('INPUT_FILE', 'archivo.txt')
WORKER_URLS = os.environ.get('WORKER_URLS', '').split(',')

@app.route('/run', methods=['GET'])
def run_mapreduce():
    if not BUCKET_NAME:
        return jsonify({"error": "BUCKET_NAME not set"}), 500
    
    # 1. Download data from GCS
    try:
        storage_client = storage.Client()
        bucket = storage_client.bucket(BUCKET_NAME)
        blob = bucket.blob(INPUT_FILE)
        content = blob.download_as_text()
    except Exception as e:
        return jsonify({"error": f"Failed to download file from GCS: {str(e)}"}), 500

    # 2. Split data for workers
    lines = content.splitlines()
    # Filter empty lines
    lines = [line for line in lines if line.strip()]
    
    n_workers = len([w for w in WORKER_URLS if w.strip()])
    if n_workers == 0:
        return jsonify({"error": "No workers configured. Set WORKER_URLS environment variable."}), 500
        
    chunk_size = max(1, len(lines) // n_workers)
    chunks = [lines[i:i + chunk_size] for i in range(0, len(lines), chunk_size)]
    
    # If we have more chunks than workers, merge the last ones
    if len(chunks) > n_workers:
        extra_chunks = chunks[n_workers:]
        chunks = chunks[:n_workers]
        for ec in extra_chunks:
            chunks[-1].extend(ec)

    # 3. Map Phase: Send chunks to workers
    partial_results = []
    active_workers = [w.strip() for w in WORKER_URLS if w.strip()]
    
    for i, worker_url in enumerate(active_workers):
        if i >= len(chunks): break
        
        payload = {"text": "\n".join(chunks[i])}
        try:
            # Construct the full URL if only IP/Host provided
            target_url = worker_url if worker_url.startswith('http') else f"http://{worker_url}:5000"
            response = requests.post(f"{target_url}/map", json=payload, timeout=60)
            if response.status_code == 200:
                partial_results.append(response.json())
            else:
                print(f"Worker {target_url} returned status {response.status_code}")
        except Exception as e:
            print(f"Worker {worker_url} failed: {e}")

    # 4. Reduce Phase: Aggregate results
    total_counts = Counter()
    for res in partial_results:
        total_counts.update(res)

    top_20 = total_counts.most_common(20)
    
    return jsonify({
        "status": "success",
        "workers_involved": len(partial_results),
        "total_keys": len(total_counts),
        "top_20": top_20
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
