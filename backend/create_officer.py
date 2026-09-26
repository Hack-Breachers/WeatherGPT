from app.database.database_postgres import PostgresSessionLocal
from app.database.officer_model import Officer
from argon2 import PasswordHasher


password_hasher = PasswordHasher()


def create_officer():
    username = input("Enter officer username: ").strip()
    password = input("Enter officer password: ")

    if not username or not password:
        print("Username and password cannot be empty.")
        return

    db = PostgresSessionLocal()

    try:
        existing_officer = (
            db.query(Officer)
            .filter(Officer.username == username)
            .first()
        )

        if existing_officer:
            print("An officer with this username already exists.")
            return

        password_hash = password_hasher.hash(password)

        officer = Officer(
            username=username,
            password_hash=password_hash
        )

        db.add(officer)
        db.commit()
        db.refresh(officer)

        print("Officer created successfully.")
        print(f"Officer ID: {officer.id}")
        print(f"Username: {officer.username}")

    finally:
        db.close()


if __name__ == "__main__":
    create_officer()