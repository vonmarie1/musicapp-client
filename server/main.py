from fastapi import FastAPI
from models.base import Base
from database import engine
from routes import auth
import firebase_admin
from dotenv import load_dotenv
import pathlib


basedir = pathlib.Path(__file__).parents[1]
load_dotenv(basedir / ".env")

app = FastAPI()

app.include_router(auth.router, prefix='/auth')
firebase_admin.initialize_app()
Base.metadata.create_all(engine)