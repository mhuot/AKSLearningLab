from fastapi import Depends, FastAPI, status
from pydantic import BaseModel

from .config import ApiConfig, get_config

app = FastAPI(title="Orders API", version="0.1.0")


class OrderCreate(BaseModel):
    customer_id: str
    items: list[str]
    total_amount: float
    channel: str = "web"


class PublishResult(BaseModel):
    order_id: str
    status: str


@app.get("/healthz", status_code=status.HTTP_200_OK)
def health() -> dict[str, str]:
    """Basic liveness probe endpoint."""
    return {"status": "ok"}


@app.post("/orders", response_model=PublishResult, status_code=status.HTTP_202_ACCEPTED)
def create_order(order: OrderCreate, config: ApiConfig = Depends(get_config)) -> PublishResult:
    """Placeholder endpoint that pretends to publish to Kafka/Event Hub."""
    fake_order_id = "order-0001"
    target_backend = "event hub" if config.uses_eventhub else "kafka"
    # This is where the real publisher abstraction will emit to Kafka or Event Hubs based on config.
    return PublishResult(order_id=fake_order_id, status=f"queued:{target_backend}")
