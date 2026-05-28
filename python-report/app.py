import streamlit as st
import requests
from datetime import datetime
import matplotlib.pyplot as plt
from collections import Counter

API_BASE = "http://localhost:8080"  # Adjust if backend runs elsewhere

@st.cache_data(ttl=60)
def fetch_all_thoughts():
    try:
        resp = requests.get(f"{API_BASE}/thoughts?page=0&size=10000")
        resp.raise_for_status()
        return resp.json()
    except Exception as e:
        st.error(f"Error fetching thoughts: {e}")
        return []

st.set_page_config(page_title="Thoughts Dashboard", layout="wide")
# Inject custom CSS for a polished look
st.markdown(
    """
    <style>
    body {
        background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
        margin: 0;
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    }
    .stApp {
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    }
    .stMetric {
        background: #ffffff;
        border-radius: 8px;
        padding: 12px 16px;
        box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        text-align: center;
        font-size: 1.1rem;
    }
    .stDataFrame, .stTable {
        background: #ffffff;
        border-radius: 8px;
        padding: 12px;
        box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        overflow-x: auto;
    }
    .stTable table {
        width: 100%;
        border-collapse: collapse;
    }
    .stTable th, .stTable td {
        padding: 8px 12px;
        border-bottom: 1px solid #e0e0e0;
        text-align: left;
    }
    .stTable th {
        background: #f0f0f0;
        font-weight: 600;
    }
    .stButton button {
        background: #4a90e2;
        color: #fff;
        border: none;
        border-radius: 4px;
        padding: 8px 16px;
        cursor: pointer;
        transition: background 0.2s ease;
    }
    .stButton button:hover {
        background: #357ab8;
    }
    .stCaption {
        color: #666;
        font-size: 0.9rem;
        text-align: center;
        margin-top: 20px;
    }
    </style>
    """,
    unsafe_allow_html=True
)
st.title("Thoughts Dashboard")

thoughts = fetch_all_thoughts()

# Compute stats
total_thoughts = len(thoughts)
up_votes = sum(t.get("thumbsUp", 0) for t in thoughts)
down_votes = sum(t.get("thumbsDown", 0) for t in thoughts)
status_counts = {
    "APPROVED": 0,
    "REJECTED": 0,
    "IN_REVIEW": 0,
}
for t in thoughts:
    status_counts[t.get("status", "")] += 1
print(status_counts)


# Recent activity
recent = sorted(thoughts, key=lambda t: t.get("updatedAt", ""), reverse=True)[:5]

# Layout
col1, col2, col3 = st.columns(3)
with col1:
    st.metric(label="Total Thoughts", value=total_thoughts)
with col2:
    st.metric(label="Total Thumbs Up", value=up_votes)
with col3:
    st.metric(label="Total Thumbs Down", value=down_votes)

st.subheader("Status Overview")
status_df = st.dataframe(
    {
        "Status": list(status_counts.keys()),
        "Count": list(status_counts.values()),
    },
    hide_index=True,
)
# Bar chart of status distribution
st.bar_chart(status_counts)
# Votes distribution chart
st.subheader("Votes Distribution")
st.bar_chart({"Thumbs Up": up_votes, "Thumbs Down": down_votes})
# Daily activity line chart
st.subheader("Thoughts Over Time")
date_counts = Counter([t.get("updatedAt", "")[:10] for t in thoughts])
st.line_chart(date_counts)

st.subheader("Recent Activity")
if recent:
    recent_table = []
    for t in recent:
        recent_table.append(
            {
                "Content": t.get("content", "")[:50] + ("…" if len(t.get("content", "")) > 50 else ""),
                "Author": t.get("author", ""),
                "Status": t.get("status", ""),
                "Updated": datetime.fromisoformat(t.get("updatedAt", "")).strftime("%b %d, %Y"),
            }
        )
    st.table(recent_table)
else:
    st.write("No thoughts yet.")

# Instructions
st.caption("Run with `streamlit run app.py` in the python-report directory.")
