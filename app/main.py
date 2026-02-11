from fastapi import FastAPI, Request, Form
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from itsdangerous import URLSafeSerializer, BadSignature
import os

APP_NAME = "fastapi_login"
SECRET_KEY = os.environ.get("APP_SECRET_KEY", "change-me-in-prod")  # set via systemd env
COOKIE_NAME = "session"

# Demo credentials (replace with real auth later)
DEMO_USER = os.environ.get("APP_DEMO_USER", "admin")
DEMO_PASS = os.environ.get("APP_DEMO_PASS", "admin")

serializer = URLSafeSerializer(SECRET_KEY, salt=APP_NAME)

app = FastAPI()
templates = Jinja2Templates(directory=os.path.join(os.path.dirname(__file__), "templates"))


def set_session(response: RedirectResponse, username: str) -> None:
    token = serializer.dumps({"u": username})
    response.set_cookie(
        COOKIE_NAME,
        token,
        httponly=True,
        samesite="lax",
        secure=False,  # set True when behind HTTPS
        max_age=3600,
    )


def get_user(request: Request) -> str | None:
    token = request.cookies.get(COOKIE_NAME)
    if not token:
        return None
    try:
        data = serializer.loads(token)
        return data.get("u")
    except BadSignature:
        return None


@app.get("/login", response_class=HTMLResponse)
async def login_get(request: Request, error: str | None = None):
    return templates.TemplateResponse("login.html", {"request": request, "error": error})


@app.post("/login")
async def login_post(username: str = Form(...), password: str = Form(...)):
    if username == DEMO_USER and password == DEMO_PASS:
        resp = RedirectResponse(url="/", status_code=303)
        set_session(resp, username)
        return resp
    return RedirectResponse(url="/login?error=Invalid%20credentials", status_code=303)


@app.get("/logout")
async def logout():
    resp = RedirectResponse(url="/login", status_code=303)
    resp.delete_cookie(COOKIE_NAME)
    return resp


@app.get("/", response_class=HTMLResponse)
async def home(request: Request):
    user = get_user(request)
    if not user:
        return RedirectResponse(url="/login", status_code=303)
    return templates.TemplateResponse("home.html", {"request": request, "user": user})


@app.get("/healthz")
async def healthz():
    return {"ok": True}
