package com.redhat.demos.evaluation.service;

import dev.langchain4j.data.embedding.Embedding;
import dev.langchain4j.data.segment.TextSegment;
import dev.langchain4j.model.embedding.EmbeddingModel;
import dev.langchain4j.model.output.Response;
import io.quarkus.logging.Log;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.faulttolerance.Retry;

import java.util.UUID;

/**
 * Service for generating vector embeddings from text using Langchain4j.
 */
@ApplicationScoped
public class EmbeddingService {

    @Inject
    EmbeddingModel embeddingModel;

    /**
     * Generates a vector embedding for the given text.
     * Implements retry logic with 2 attempts and exponential backoff.
     *
     * @param text the text to embed
     * @return float array representing the embedding vector
     * @throws RuntimeException if embedding generation fails after retries
     */
    @Retry(maxRetries = 2, delay = 1000, maxDuration = 10000, jitter = 200)
    public float[] generateEmbedding(String text) {
        String correlationId = UUID.randomUUID().toString();

        Log.infof("[%s] Generating embedding for text of length %d", correlationId, text.length());

        try {
            Response<Embedding> response = embeddingModel.embed(TextSegment.from(text));

            if (response == null || response.content() == null) {
                Log.errorf("[%s] Embedding model returned null response", correlationId);
                throw new RuntimeException("Embedding model returned null response");
            }

            float[] vector = response.content().vector();

            Log.infof("[%s] Successfully generated embedding with dimension %d", correlationId, vector.length);

            return vector;

        } catch (Exception e) {
            Log.errorf(e, "[%s] Failed to generate embedding", correlationId);
            throw new RuntimeException("Failed to generate embedding: " + e.getMessage(), e);
        }
    }
}
