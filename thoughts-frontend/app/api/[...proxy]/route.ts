// Proxy all /api/* requests to the backend
// This allows frontend to make requests to /api/thoughts/random which get proxied to backend/thoughts/random

import { NextRequest, NextResponse } from 'next/server';

const BACKEND_URL = process.env.API_BACKEND_URL || 'http://localhost:8080';

export async function GET(
  request: NextRequest,
  context: { params: Promise<{ proxy: string[] }> }
) {
  const params = await context.params;
  return proxyRequest(request, params.proxy, 'GET');
}

export async function POST(
  request: NextRequest,
  context: { params: Promise<{ proxy: string[] }> }
) {
  const params = await context.params;
  return proxyRequest(request, params.proxy, 'POST');
}

export async function PUT(
  request: NextRequest,
  context: { params: Promise<{ proxy: string[] }> }
) {
  const params = await context.params;
  return proxyRequest(request, params.proxy, 'PUT');
}

export async function DELETE(
  request: NextRequest,
  context: { params: Promise<{ proxy: string[] }> }
) {
  const params = await context.params;
  return proxyRequest(request, params.proxy, 'DELETE');
}

export async function OPTIONS(request: NextRequest) {
  return new NextResponse(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  });
}

async function proxyRequest(
  request: NextRequest,
  pathSegments: string[],
  method: string
) {
  const path = pathSegments.join('/');
  const url = new URL(request.url);
  const targetUrl = `${BACKEND_URL}/${path}${url.search}`;

  console.log(`Proxying ${method} /api/${path} -> ${targetUrl}`);

  try {
    const headers: Record<string, string> = {};
    request.headers.forEach((value, key) => {
      // Skip host, connection, and content-length headers (will be set automatically)
      const lowerKey = key.toLowerCase();
      if (!['host', 'connection', 'content-length'].includes(lowerKey)) {
        headers[key] = value;
      }
    });

    const options: RequestInit = {
      method,
      headers,
    };

    // Add body for POST/PUT requests
    if (method === 'POST' || method === 'PUT') {
      try {
        const contentType = request.headers.get('content-type');
        if (contentType && contentType.includes('application/json')) {
          const body = await request.text();
          if (body && body.length > 0) {
            options.body = body;
          }
        }
      } catch (error) {
        // No body or error reading body - continue without it
        console.log('No body for request:', error);
      }
    }

    const response = await fetch(targetUrl, options);
    const data = await response.text();

    return new NextResponse(data, {
      status: response.status,
      headers: {
        'Content-Type': response.headers.get('Content-Type') || 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      },
    });
  } catch (error) {
    console.error(`Proxy error for ${targetUrl}:`, error);
    return NextResponse.json(
      { error: 'Failed to proxy request to backend' },
      { status: 502 }
    );
  }
}
