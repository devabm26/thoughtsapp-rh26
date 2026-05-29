// API client service for backend communication

import { Thought } from './types';

// Get base URL from environment variable
// Use relative /api/* URLs which Next.js will proxy to the backend
// In production, /api/* is rewritten to the backend URL configured in API_BACKEND_URL env var
const API_BASE_URL = '/api';

// Custom error class for API errors
export class ApiError extends Error {
  constructor(
    message: string,
    public status?: number,
    public details?: unknown
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

// Error handling wrapper for API calls
async function handleResponse<T>(response: Response): Promise<T> {
  if (!response.ok) {
    let errorMessage = `API error: ${response.status} ${response.statusText}`;
    let errorDetails;

    try {
      errorDetails = await response.json();
      errorMessage = errorDetails.message || errorMessage;
    } catch {
      // If response body is not JSON, use status text
    }

    throw new ApiError(errorMessage, response.status, errorDetails);
  }

  // Handle 204 No Content responses
  if (response.status === 204) {
    return {} as T;
  }

  return response.json();
}

// API client service
export const apiClient = {
  // Fetch a random thought
  async getRandomThought(): Promise<Thought> {
    const response = await fetch(`${API_BASE_URL}/thoughts/random`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    return handleResponse<Thought>(response);
  },

  // Submit thumbs up rating for a thought
  async thumbsUpThought(id: string): Promise<Thought> {
    const response = await fetch(`${API_BASE_URL}/thoughts/thumbsup/${id}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    return handleResponse<Thought>(response);
  },

  // Submit thumbs down rating for a thought
  async thumbsDownThought(id: string): Promise<Thought> {
    const response = await fetch(`${API_BASE_URL}/thoughts/thumbsdown/${id}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    return handleResponse<Thought>(response);
  },

  // Create a new thought
  async createThought(data: { content: string; author: string; authorBio: string }): Promise<Thought> {
    const response = await fetch(`${API_BASE_URL}/thoughts`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    });

    return handleResponse<Thought>(response);
  },
};
