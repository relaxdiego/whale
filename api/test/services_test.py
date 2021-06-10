from datetime import datetime
from unittest import mock
from uuid import uuid1

from quipper import (
    models,
    schemas,
)
from quipper import services


def test_create_message__it_calls_the_database_layer():
    message = schemas.MessageCreate(
        conversation_id=str(uuid1()),
        sender=str(uuid1()),
        message=str(uuid1()),
    )

    with mock.patch('quipper.services.Session') as mock_db:
        services.create_message(mock_db, message)

    assert mock_db.add.call_count == 1
    assert isinstance(mock_db.add.call_args.args[0],
                      models.Message)

    model = mock_db.add.call_args.args[0]
    for key, val in message.dict().items():
        assert getattr(model, key) == val

    assert mock_db.commit.call_count == 1


def test_get_conversation__it_returns_a_conversation_object():
    conversation_id = str(uuid1())
    messages = [
        schemas.Message(
            sender=str(uuid1()),
            message=str(uuid1()),
            created_at=datetime.utcnow()
        ),
        schemas.Message(
            sender=str(uuid1()),
            message=str(uuid1()),
            created_at=datetime.utcnow()
        )
    ]
    messages_orm_models = [models.Message(**m.dict()) for m in messages]

    with mock.patch('quipper.services.Session') as mock_db:
        mock_db.query.return_value. \
            filter.return_value. \
            all.return_value = messages_orm_models

        conversation = \
            services.get_conversation(mock_db, conversation_id)

    assert conversation == \
        schemas.Conversation(
            id=conversation_id,
            messages=messages
        )
