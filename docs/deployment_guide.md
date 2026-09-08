# Deployment Guide: New Wheels Sales Analytics Streamlit Application

This guide covers deploying the interactive **New Wheels Sales Analytics** dashboard locally, to **Streamlit Community Cloud**, or via **Docker** on modern cloud hosting (Render, Railway, GCP Cloud Run, AWS ECS).

---

## 1. Local Development & Testing

### Prerequisites
- Python 3.9+
- Git

### Installation & Launch
```bash
# 1. Clone repository
git clone https://github.com/Rupesh4113/New-Wheels-Sales-Analytics-Automotive-Transportation.git
cd New-Wheels-Sales-Analytics-Automotive-Transportation

# 2. Create and activate a virtual environment
python -m venv venv
# On Windows:
.\venv\Scripts\activate
# On macOS / Linux:
source venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Launch Streamlit
streamlit run app.py
```
The application will open automatically at `http://localhost:8501`.

---

## 2. Deploying to Streamlit Community Cloud (Free & 1-Click)

1. Push your repository to GitHub: `https://github.com/<your-username>/New-Wheels-Sales-Analytics-Automotive-Transportation`.
2. Sign in to [share.streamlit.io](https://share.streamlit.io/) with your GitHub account.
3. Click **"New app"**.
4. Select:
   - **Repository**: `your-username/New-Wheels-Sales-Analytics-Automotive-Transportation`
   - **Branch**: `main`
   - **Main file path**: `app.py`
5. Click **"Deploy"**.

> **Zero Database Setup Needed**: The application is built with a resilient hybrid data architecture. If a live MySQL 8 instance is not detected, it automatically loads and serves the clean transactional dataset from `data/raw/`, providing instant zero-latency deployment on Streamlit Cloud!

---

## 3. Containerized Deployment via Docker

### Build and Run Locally
```bash
# Build Docker image
docker build -t new-wheels-analytics .

# Run Docker container
docker run -d -p 8501:8501 --name new-wheels-app new-wheels-analytics
```
Visit `http://localhost:8501`.

### Deploy to Render / Railway / Cloud Run
- **Render**: Connect GitHub repo, select **Web Service**, choose **Docker** runtime, port `8501`.
- **Railway**: Click New Project -> Deploy from GitHub repo.
- **GCP Cloud Run**:
  ```bash
  gcloud builds submit --tag gcr.io/[PROJECT-ID]/new-wheels-app
  gcloud run deploy new-wheels-app --image gcr.io/[PROJECT-ID]/new-wheels-app --platform managed --allow-unauthenticated --port 8501
  ```

---

## 4. Connecting to Live MySQL Database (Optional)

If running in an environment with a live MySQL 8.0 server:
1. In `.streamlit/secrets.toml`:
   ```toml
   [mysql]
   host = "127.0.0.1"
   port = 3306
   user = "root"
   password = "your_password"
   database = "new_wheels_db"
   ```
2. The application will detect the database connection and query the live views directly.