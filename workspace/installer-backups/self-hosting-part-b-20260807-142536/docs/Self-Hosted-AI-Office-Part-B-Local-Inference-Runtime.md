# Self-Hosted AI Office Part B — Local Inference Runtime

Part B installs and activates the first real local inference runtime.

Default runtime:

- Provider: Ollama
- Endpoint: `http://127.0.0.1:11434`
- Initial model: `qwen2.5:3b`
- Binding expectation: localhost only

The runtime includes:

- Ollama discovery/install
- Runtime startup
- Model download
- Model inventory synchronization
- Provider health checks
- Direct local inference
- Inference result records
- AI Office provider/model registration
- End-to-end local generation validation

The default 3B model is intentionally modest for the first certification run. Larger or
specialized models can be added after local inference is proven stable.
