from fastapi import FastAPI

app = FastAPI(title="CareerLens API")


@app.get("/")
def root():
    return {"message": "CareerLens backend is running"}