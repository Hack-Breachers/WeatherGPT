from app.database.database_postgres import PostgresSessionLocal


def get_postgres_db():
    db = PostgresSessionLocal()

    try:
        yield db
    finally:
        db.close()