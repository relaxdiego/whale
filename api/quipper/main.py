from fastapi import (
    Depends,
    FastAPI,
)
from sqlalchemy.orm import Session

from quipper import (
    models,
    schemas,
    services,
)
from quipper.database import (
    SessionLocal,
    engine,
)

# Create the tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI()


# https://fastapi.tiangolo.com/tutorial/dependencies/dependencies-with-yield
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.get("/healthz", status_code=200)
def get_health():
    return "healthy"


@app.post("/messages/", status_code=201)
def post_message(message: schemas.MessageCreate,
                 db: Session = Depends(get_db)):
    services.create_message(db=db, message=message)


@app.get("/conversations/{conversation_id}",
         response_model=schemas.Conversation)
def get_conversation(conversation_id: str,
                     db: Session = Depends(get_db)):
    return services.get_conversation(db=db,
                                     conversation_id=conversation_id)
