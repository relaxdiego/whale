from datetime import datetime
from uuid import uuid1
from unittest import mock

from fastapi.testclient import TestClient

from quipper.main import app
from quipper.schemas import (
    Conversation,
    Message,
    MessageCreate,
)


client = TestClient(app)


def test_post_message__it_submits_successfully():
    message = {
        "sender": f"someone-{uuid1()}",
        "conversation_id": str(uuid1()),
        "message": f"{uuid1()}mike mike mike, guess what day it is!"
    }

    with mock.patch('quipper.main.services'):
        response = client.post("/messages/", json=message)

    assert response.status_code == 201


def test_post_message__it_calls_the_create_message_service():
    message = {
        "sender": f"someone-{uuid1()}",
        "conversation_id": str(uuid1()),
        "message": f"{uuid1()}mike mike mike, guess what day it is!"
    }

    with mock.patch('quipper.main.services') as mock_services:
        client.post("/messages/", json=message)

    assert mock_services.create_message.call_count == 1
    assert mock_services.create_message.call_args[1]['message'] == \
        MessageCreate(**message)


def test_get_conversation__it_returns_the_conversation():
    conversation_id = str(uuid1())
    conversation = Conversation(
        id=conversation_id,
        messages=[
            Message(
                sender=str(uuid1()),
                message=str(uuid1()),
                created_at=datetime.utcnow()
            ),
            Message(
                sender=str(uuid1()),
                message=str(uuid1()),
                created_at=datetime.utcnow()
            )
        ]
    )

    with mock.patch('quipper.main.services') as mock_services:
        mock_services.get_conversation.return_value = conversation

        response = \
            client.get(f"/conversations/{conversation_id}")

    assert mock_services.get_conversation.call_count == 1
    assert mock_services.get_conversation.call_args[1]['conversation_id'] == \
        conversation_id

    assert Conversation(**response.json()) == conversation.dict()
