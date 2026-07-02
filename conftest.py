# conftest.py
def pytest_addoption(parser):
    parser.addoption("--app", default=None, help="Path to the APK/IPA")
    parser.addoption("--platform", default="android", choices=["android", "ios"], help="android or ios")
    parser.addoption("--device", default=None, help="Device ID from adb devices")
    parser.addoption("--udid", default=None, help="iOS UDID")