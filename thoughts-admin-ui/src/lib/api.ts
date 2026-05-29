// Use relative URLs that nginx will proxy to the actual backend services
// In production, nginx proxies /api -> thoughts-backend:8080 and /evaluation-api -> thoughts-evaluation:8088
export const API_BASE_URL = "/api";
export const EVALUATION_API_BASE_URL = "/evaluation-api";

export interface Thought {
  id: string;
  content: string;
  thumbsUp: number;
  thumbsDown: number;
  status: "APPROVED" | "REJECTED" | "IN_REVIEW";
  author: string;
  authorBio: string;
  createdAt: string;
  updatedAt: string;
}

export interface CreateThoughtInput {
  content: string;
  author: string;
  authorBio: string;
}

async function handleResponse<T>(res: Response): Promise<T> {
  if (!res.ok) {
    const text = await res.text().catch(() => "Unknown error");
    throw new Error(`API Error ${res.status}: ${text}`);
  }
  if (res.status === 204) return undefined as T;
  return res.json();
}

export async function fetchThoughts(page = 0, size = 20): Promise<Thought[]> {
  const res = await fetch(`${API_BASE_URL}/thoughts?page=${page}&size=${size}`);
  return handleResponse<Thought[]>(res);
}

export async function fetchAllThoughts(): Promise<Thought[]> {
  const res = await fetch(`${API_BASE_URL}/thoughts?page=0&size=10000`);
  return handleResponse<Thought[]>(res);
}

export async function fetchThought(id: string): Promise<Thought> {
  const res = await fetch(`${API_BASE_URL}/thoughts/${id}`);
  return handleResponse<Thought>(res);
}

export async function createThought(data: CreateThoughtInput): Promise<Thought> {
  const res = await fetch(`${API_BASE_URL}/thoughts`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
  });
  return handleResponse<Thought>(res);
}

export async function updateThought(id: string, data: Partial<Thought>): Promise<Thought> {
  const res = await fetch(`${API_BASE_URL}/thoughts/${id}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
  });
  return handleResponse<Thought>(res);
}

export async function deleteThought(id: string): Promise<void> {
  const res = await fetch(`${API_BASE_URL}/thoughts/${id}`, { method: "DELETE" });
  return handleResponse<void>(res);
}

export async function thumbsUp(id: string): Promise<Thought> {
  const res = await fetch(`${API_BASE_URL}/thoughts/thumbsup/${id}`, { method: "POST" });
  return handleResponse<Thought>(res);
}

export async function thumbsDown(id: string): Promise<Thought> {
  const res = await fetch(`${API_BASE_URL}/thoughts/thumbsdown/${id}`, { method: "POST" });
  return handleResponse<Thought>(res);
}

export interface VectorStatus {
  totalVectors: number;
  positiveCount: number;
  negativeCount: number;
  initialized: boolean;
}

export interface VectorInitializationResult {
  vectorsCreated: number;
  positiveCount: number;
  negativeCount: number;
  message: string;
}

export async function fetchVectorStatus(): Promise<VectorStatus> {
  const res = await fetch(`${EVALUATION_API_BASE_URL}/vectors/status`);
  return handleResponse<VectorStatus>(res);
}

export async function initializeVectors(): Promise<VectorInitializationResult> {
  const res = await fetch(`${EVALUATION_API_BASE_URL}/vectors/initialize`, { method: "POST" });
  return handleResponse<VectorInitializationResult>(res);
}
