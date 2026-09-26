from app.database.init_postgres import init_postgres


if __name__ == "__main__":
    init_postgres()
    print("PostgreSQL connection successful.")
    print("PostgreSQL tables created successfully.")