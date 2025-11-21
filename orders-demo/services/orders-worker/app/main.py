import asyncio
import random
from typing import Final

from .config import WorkerConfig, get_config


async def process_event(event_id: int, config: WorkerConfig) -> None:
    """Placeholder event handler that simulates work using the configured backend."""
    await asyncio.sleep(random.uniform(0.05, 0.15))
    destination = (
        config.eventhub.event_hub_name or "eventhub"
        if config.uses_eventhub
        else config.kafka.topic
    )
    print(f"processed event {event_id} via {destination}")


async def consume_loop(config: WorkerConfig) -> None:
    """Simple loop that fakes pulling messages from Kafka/Event Hubs."""
    event_id = 0
    backend_label: Final[str] = "Event Hubs" if config.uses_eventhub else "Kafka"
    print(
        f"starting worker with backend={backend_label}, "
        f"poll_interval={config.poll_interval}s"
    )
    while True:
        await process_event(event_id, config)
        event_id += 1
        await asyncio.sleep(config.poll_interval)


def main() -> None:
    config = get_config()
    asyncio.run(consume_loop(config))


if __name__ == "__main__":
    main()
