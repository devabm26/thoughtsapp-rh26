# Thoughts Dashboard

This repository contains a lightweight **Python + Streamlit** dashboard that visualises the state of thoughts in the backend service.

## Prerequisites

* Python 3.10+ (recommended)
* The backend service must be running and reachable at `http://localhost:8080`. If the backend is hosted elsewhere, update the `API_BASE` constant in `app.py`.

## Setup

```bash
# Create a virtual environment (optional but recommended)
python -m venv .venv
source .venv/bin/activate   # On Windows use `.venv\Scripts\activate`

# Install dependencies
pip install -r requirements.txt
```

## Run the dashboard

```bash
streamlit run app.py
```

## Build and run with Podman

```bash
# Build the container image
podman build -t thoughts-dashboard .

# Run the container, exposing port 8501
podman run -d --name thoughts-dashboard -p 8501:8501 thoughts-dashboard
```

The dashboard will be accessible at `http://localhost:8501`. Ensure the backend service is reachable from within the container (e.g., expose the backend port or use host networking).

The dashboard will open in your default browser at `http://localhost:8501`. It displays:

1. **Total Thoughts** – number of thoughts stored.
2. **Total Thumbs Up / Down** – aggregate vote counts.
3. **Status Overview** – counts per status (APPROVED, REJECTED, IN_REVIEW).
4. **Recent Activity** – a table of the five most recently updated thoughts.

## Verify connectivity

If the dashboard shows *No thoughts yet* or errors, ensure:

* The backend is running (`mvnw quarkus:dev` in `thoughtsapp-rh26/thoughts-backend`).
* The API endpoint `http://localhost:8080/thoughts` is reachable (try `curl http://localhost:8080/thoughts`).
* The `API_BASE` in `app.py` matches the backend host/port.

Once the backend responds with data, the dashboard will populate automatically.
