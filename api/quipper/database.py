from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Normally this should be a production grade database but for the
# interest of time, we will use SQLite for demo purposes
SQLALCHEMY_DATABASE_URL = "sqlite:///./quipper.db"

# Pysqlite’s default behavior is to prohibit the usage of a single
# connection in more than one thread. This is originally intended
# to work with older versions of SQLite that did not support
# multithreaded operation under various circumstances. In particular,
# older SQLite versions did not allow a :memory: database to be used
# in multiple threads under any circumstances.
#
# Pysqlite does include a now-undocumented flag known as
# check_same_thread which will disable this check, however
# note that pysqlite connections are still not safe to use in
# concurrently in multiple threads.
# Reference: https://docs.sqlalchemy.org/en/14/dialects/sqlite.html
#
# Having said all that, using this flag should be safe for this demo.
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)

SessionLocal = sessionmaker(autocommit=False,
                            autoflush=False,
                            bind=engine)

Base = declarative_base()
