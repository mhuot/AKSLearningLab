from __future__ import annotations

from dataclasses import dataclass
from functools import lru_cache
from typing import Literal, Optional
import os


BackendMode = Literal["kafka", "eventhub"]


@dataclass
class KafkaConfig:
    brokers: str
    topic: str
    username: Optional[str]
    password: Optional[str]

    @classmethod
    def from_env(cls) -> "KafkaConfig":
        return cls(
            brokers=os.getenv("KAFKA_BROKERS", "kafka:9092"),
            topic=os.getenv("KAFKA_TOPIC", "orders"),
            username=os.getenv("KAFKA_USERNAME"),
            password=os.getenv("KAFKA_PASSWORD"),
        )


@dataclass
class EventHubConfig:
    fully_qualified_namespace: Optional[str]
    event_hub_name: Optional[str]
    client_id: Optional[str]

    @classmethod
    def from_env(cls) -> "EventHubConfig":
        return cls(
            fully_qualified_namespace=os.getenv("EVENTHUB_NAMESPACE"),
            event_hub_name=os.getenv("EVENTHUB_NAME"),
            client_id=os.getenv("EVENTHUB_CLIENT_ID"),
        )


@dataclass
class ObservabilityConfig:
    otlp_endpoint: Optional[str]
    resource_attributes: Optional[str]

    @classmethod
    def from_env(cls) -> "ObservabilityConfig":
        return cls(
            otlp_endpoint=os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT"),
            resource_attributes=os.getenv("OTEL_RESOURCE_ATTRIBUTES"),
        )


@dataclass
class ApiConfig:
    api_key: str
    backend_mode: BackendMode
    kafka: KafkaConfig
    eventhub: EventHubConfig
    observability: ObservabilityConfig

    @classmethod
    def from_env(cls) -> "ApiConfig":
        backend_mode = os.getenv("BACKEND_MODE", "kafka").lower()
        if backend_mode not in ("kafka", "eventhub"):
            backend_mode = "kafka"

        return cls(
            api_key=os.getenv("API_KEY", "super-secret-key"),
            backend_mode=backend_mode,  # type: ignore[arg-type]
            kafka=KafkaConfig.from_env(),
            eventhub=EventHubConfig.from_env(),
            observability=ObservabilityConfig.from_env(),
        )

    @property
    def uses_eventhub(self) -> bool:
        return self.backend_mode == "eventhub"

    @property
    def uses_kafka(self) -> bool:
        return self.backend_mode == "kafka"


@lru_cache(maxsize=1)
def get_config() -> ApiConfig:
    """Return the cached API configuration."""
    return ApiConfig.from_env()
