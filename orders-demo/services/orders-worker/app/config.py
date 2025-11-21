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
    group: str
    username: Optional[str]
    password: Optional[str]

    @classmethod
    def from_env(cls) -> "KafkaConfig":
        return cls(
            brokers=os.getenv("KAFKA_BROKERS", "kafka:9092"),
            topic=os.getenv("KAFKA_TOPIC", "orders"),
            group=os.getenv("KAFKA_GROUP", "orders-worker"),
            username=os.getenv("KAFKA_USERNAME"),
            password=os.getenv("KAFKA_PASSWORD"),
        )


@dataclass
class EventHubConfig:
    fully_qualified_namespace: Optional[str]
    event_hub_name: Optional[str]
    consumer_group: str
    storage_account: Optional[str]
    client_id: Optional[str]

    @classmethod
    def from_env(cls) -> "EventHubConfig":
        return cls(
            fully_qualified_namespace=os.getenv("EVENTHUB_NAMESPACE"),
            event_hub_name=os.getenv("EVENTHUB_NAME"),
            consumer_group=os.getenv("EVENTHUB_CONSUMER_GROUP", "orders-worker"),
            storage_account=os.getenv("STORAGE_ACCOUNT"),
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
class WorkerConfig:
    backend_mode: BackendMode
    poll_interval: float
    kafka: KafkaConfig
    eventhub: EventHubConfig
    observability: ObservabilityConfig

    @classmethod
    def from_env(cls) -> "WorkerConfig":
        backend_mode = os.getenv("BACKEND_MODE", "kafka").lower()
        if backend_mode not in ("kafka", "eventhub"):
            backend_mode = "kafka"

        poll_interval_str = os.getenv("POLL_INTERVAL", "0.1")
        try:
            poll_interval = float(poll_interval_str)
        except ValueError:
            poll_interval = 0.1

        return cls(
            backend_mode=backend_mode,  # type: ignore[arg-type]
            poll_interval=poll_interval,
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
def get_config() -> WorkerConfig:
    """Return the cached worker configuration."""
    return WorkerConfig.from_env()
