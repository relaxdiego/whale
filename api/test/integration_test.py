from uuid import uuid1

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

from quipper.main import (
    app,
    get_db
)
from quipper import (
    models,
    schemas,
)


SQLALCHEMY_DATABASE_URL = "sqlite:///./quipper-integration-test.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)

SessionLocal = sessionmaker(autocommit=False,
                            autoflush=False,
                            bind=engine)

Base = declarative_base()


def db_for_testing():
    models.Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
        models.Base.metadata.drop_all(bind=engine)


client = TestClient(app)

app.dependency_overrides[get_db] = db_for_testing


def test_post_message__it_submits_successfully():
    message = {
        "sender": f"someone-{uuid1()}",
        "conversation_id": str(uuid1()),
        "message": f"{uuid1()}mike mike mike, guess what day it is!"
    }

    response = client.post("/messages/", json=message)

    assert response.status_code == 201


def test_get_conversation__it_returns_the_conversation():
    conversation_id = str(uuid1())
    messages = [
        schemas.MessageCreate(
            conversation_id=conversation_id,
            sender=str(uuid1()),
            message=str(uuid1()),
        ),
        schemas.MessageCreate(
            conversation_id=conversation_id,
            sender=str(uuid1()),
            message=str(uuid1()),
        )
    ]

    for message in messages:
        response = client.post("/messages/", json=message.dict())
        assert response.status_code == 201

    response = client.get(f"/conversations/{conversation_id}")

    conversation = schemas.Conversation(**response.json())

    assert conversation.id == conversation_id
    for i, message in enumerate(conversation.messages):
        assert message.sender == messages[i].sender
        assert message.message == messages[i].message
