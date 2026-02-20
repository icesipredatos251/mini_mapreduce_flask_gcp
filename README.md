# Mini-MapReduce on GCP with Flask

This project implements a distributed word count system using a Master-Worker architecture on Google Compute Engine, with input data stored in Google Cloud Storage.

## Prerequisites
- GCP Account
- `gcloud` CLI installed and authenticated (`gcloud auth login`)
- `terraform` installed

## 1. Deploy Infrastructure

Run the deployment script with your GCP Project ID:
```bash
chmod +x deploy.sh cleanup.sh
./deploy.sh <YOUR_PROJECT_ID>
```

Alternatively, manually:
```bash
cd terraform
terraform init
terraform apply -var="project=<YOUR_PROJECT_ID>"
```

## 2. Prepare Input Data

Create a sample text file and upload it to the newly created bucket:
```bash
echo "hola mundo mapreduce flask python hola gcp google cloud" > archivo.txt
gsutil cp archivo.txt gs://<YOUR_PROJECT_ID>-mapreduce-bucket/
```

## 3. Deploy and Run Application

### Step A: Start Workers
For each worker (1, 2, and 3), SSH into the instance and start the worker app:
```bash
# Repeat for worker-1, worker-2, worker-3
gcloud compute ssh worker-1 --zone us-central1-a

# Inside VM:
git clone <YOUR_REPO_URL> mapreduce
cd mapreduce/app
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
python3 worker.py &
exit
```

### Step B: Start Master
SSH into the master instance and start the orchestrator:
```bash
gcloud compute ssh master --zone us-central1-a

# Inside VM:
git clone <YOUR_REPO_URL> mapreduce
cd mapreduce/app
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt

# Set environment variables
export BUCKET_NAME=<YOUR_PROJECT_ID>-mapreduce-bucket
export WORKER_URLS=http://<WORKER1_IP>:5000,http://<WORKER2_IP>:5000,http://<WORKER3_IP>:5000

python3 master.py &
exit
```

## 4. Execute MapReduce JOB

Trigger the process from your local machine:
```bash
curl http://<MASTER_IP>:5000/run
```

Expected response:
```json
{
  "status": "success",
  "total_keys": 8,
  "workers_involved": 3,
  "top_20": [["hola", 2], ["mundo", 1], ...]
}
```

## 5. Stop Infrastructure

To avoid ongoing costs, destroy the infrastructure:
```bash
./cleanup.sh <YOUR_PROJECT_ID>
```
# mini_mapreduce_flask_gcp
