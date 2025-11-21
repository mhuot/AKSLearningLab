from fastapi import FastAPI, status
from pydantic import BaseModel

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
def create_order(order: OrderCreate) -> PublishResult:
    """Placeholder endpoint that pretends to publish to Kafka/Event Hub."""
    fake_order_id = "order-0001"
    # This is where the real publisher abstraction will emit to Kafka or Event Hubs.
    return PublishResult(order_id=fake_order_id, status="queued")
