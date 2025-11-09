from handler import handler


def test_handler_returns_200():
    resp = handler({}, {})
    assert resp.get("statusCode") == 200
    assert "Hello from example lambda" in resp.get("body")
