# syntax=docker/dockerfile:1

FROM python:3.10-slim

WORKDIR /app


# Install dependencies
COPY thoughtsapp-rh26/python-report/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY thoughtsapp-rh26/python-report/app.py .

# Expose Streamlit port
EXPOSE 8501

# Set environment variables for Streamlit
ENV STREAMLIT_SERVER_PORT=8501
ENV STREAMLIT_SERVER_HEADLESS=true

# Run the dashboard
CMD ["streamlit", "run", "app.py"]
