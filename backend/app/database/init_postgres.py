from app.database.database_postgres import PostgresBase, postgres_engine

# Import the models so SQLAlchemy knows about them
from app.database.rescue_member_model import RescueMember
from app.database.otp_model import OTPVerification
from app.database.officer_model import Officer


def init_postgres():
    PostgresBase.metadata.create_all(bind=postgres_engine)

if __name__ == "__main__":
    init_postgres()