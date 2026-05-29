#!/usr/bin/env bash
# Build the thoughts-evaluation image using podman
# Two-step approach: 1) Build JAR locally, 2) Package in container
# NOTE: pom.xml enforces Java 21 - build will fail if not using Java 21

set -e

# Set Java 21 for build
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
export PATH="$JAVA_HOME/bin:$PATH"

echo "Step 1: Building uber-jar locally..."
echo "Java version: $(java -version 2>&1 | head -1)"
./mvnw clean package -DskipTests -Dquarkus.package.jar.type=uber-jar

echo ""
echo "Step 2: Building container image..."
podman build \
  --platform linux/amd64 \
  -t thoughtsapp/evaluation:latest \
  -f ContainerFile.runtime \
  .

# Tag the image for container registry
podman tag thoughtsapp/evaluation:latest quay.io/redhat_na_ssa/thoughtsapp-evaluation:latest

echo ""
echo "Build complete!"
podman push quay.io/redhat_na_ssa/thoughtsapp-evaluation:latest
