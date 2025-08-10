#!/bin/bash

API_URL="https://ahamai-api.officialprakashkrsingh.workers.dev/v1/chat/completions"
API_KEY="ahamaibyprakash25"

models=(
  "gpt-4o"
  "gpt-4o-mini"
  "perplexed"
  "felo"
  "gpt-4.1-nano"
  "gpt-4.1-mini"
  "deepseek-chat"
  "deepseek-reasoner"
  "claude-3.5-haiku"
  "gemini-2.0-flash"
  "gemini-2.5-flash-proxy"
  "grok-3-mini"
  "deepseek-r1"
  "claude-sonnet-4"
  "claude-opus-4"
  "grok-4"
  "kimi-k2-instruct"
)

echo "🔬 Testing all API models..."
echo "========================================="

for model in "${models[@]}"; do
  echo "Testing: $model"
  
  response=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d "{
      \"model\": \"$model\",
      \"messages\": [{\"role\": \"user\", \"content\": \"Hi! Say just 'Hello from $model'\"}],
      \"stream\": false,
      \"max_tokens\": 20
    }" \
    --max-time 15)
  
  if echo "$response" | grep -q '"choices"'; then
    content=$(echo "$response" | grep -o '"content":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo "✅ $model: $content"
  else
    error=$(echo "$response" | grep -o '"error":[^}]*}' | head -1)
    echo "❌ $model: $error"
  fi
  echo "---"
done

echo "========================================="
echo "🏁 Model testing complete!"
