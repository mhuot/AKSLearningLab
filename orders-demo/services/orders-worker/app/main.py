import asyncio
import random


async def process_event(event_id: int) -> None:
    """Placeholder event handler that simulates work."""
    await asyncio.sleep(0.1)
    print(f"processed event {event_id}")


async def consume_loop() -> None:
    """Simple loop that fakes pulling messages from Kafka/Event Hubs."""
    event_id = 0
    while True:
        await process_event(event_id)
        event_id += 1
        await asyncio.sleep(random.uniform(0.05, 0.2))


def main() -> None:
    asyncio.run(consume_loop())


if __name__ == "__main__":
    main()
