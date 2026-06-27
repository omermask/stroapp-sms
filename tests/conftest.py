import pytest


def pytest_configure(config):
    # Enable auto mode for async tests
    config.option.asyncio_mode = "auto"


@pytest.fixture(scope="function")
async def client():
    from tests.test_comprehensive import TestClient
    c = TestClient()
    await c.bootstrap()
    yield c
    await c.close()
