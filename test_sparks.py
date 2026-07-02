import os
import time
import pytest
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.options.ios import XCUITestOptions
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.common.actions.action_builder import ActionBuilder
from selenium.webdriver.common.actions.pointer_input import PointerInput
from selenium.webdriver.common.actions import interaction


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

APPIUM_SERVER = "http://127.0.0.1:4723/wd/hub"

ANDROID_CAPS = {
    "platformName": "Android",
    "appium:automationName": "UIAutomator2",   # capital UI to match server
    "appium:app": "",
    "appium:deviceName": "",
    "appium:appPackage": "com.whispr.app",
    "appium:appActivity": ".MainActivity",
    "appium:noReset": True,
    "appium:autoGrantPermissions": True,
    "appium:newCommandTimeout": 120,
}

IOS_CAPS = {
    "platformName": "iOS",
    "appium:automationName": "XCUITest",
    "appium:app": "",
    "appium:deviceName": "",
    "appium:udid": "auto",
    "appium:bundleId": "com.whispr.app",
    "appium:noReset": True,
    "appium:newCommandTimeout": 120,
}

DEFAULT_TIMEOUT = 15
VIDEO_PLAY_TIMEOUT = 20
SWIPE_DISTANCE_PX = 800


# ---------------------------------------------------------------------------
# Page Object
# ---------------------------------------------------------------------------

class SparksFeedPage:
    print(driver.page_source)
    SPARKS_SCREEN_LABEL  = "SparksScreen"
    VIDEO_PLAYER_LABEL   = "SparkVideoPlayer"
    LIKE_BUTTON_LABEL    = "LikeButton"
    LIKE_COUNT_LABEL     = "LikeCount"
    COMMENT_BUTTON_LABEL = "CommentButton"
    SHARE_BUTTON_LABEL   = "ShareButton"
    MORE_BUTTON_LABEL    = "MoreButton"
    BACK_BUTTON_LABEL    = "BackButton"
    PLAY_PAUSE_LABEL     = "PlayPauseOverlay"
    HEART_BURST_LABEL    = "HeartBurst"
    EMPTY_STATE_LABEL    = "EmptySparksState"
    ERROR_STATE_LABEL    = "SparksErrorState"
    RETRY_BUTTON_LABEL   = "RetryButton"
    REPORT_MENU_LABEL    = "ReportReelOption"
    AUTHOR_LABEL         = "SparkAuthorName"
    COMMUNITY_LABEL      = "SparkCommunityTag"
    LOADING_INDICATOR    = "CircularProgressIndicator"

    def __init__(self, driver, platform="android"):
        self.driver = driver
        self.platform = platform
        self.wait = WebDriverWait(driver, DEFAULT_TIMEOUT)
        self.size = driver.get_window_size()

    def _by_label(self, label):
        return (AppiumBy.ACCESSIBILITY_ID, label)

    def _find(self, label, timeout=DEFAULT_TIMEOUT):
        return WebDriverWait(self.driver, timeout).until(
            EC.presence_of_element_located(self._by_label(label))
        )

    def _find_visible(self, label, timeout=DEFAULT_TIMEOUT):
        return WebDriverWait(self.driver, timeout).until(
            EC.visibility_of_element_located(self._by_label(label))
        )

    def _is_present(self, label, timeout=3):
        try:
            WebDriverWait(self.driver, timeout).until(
                EC.presence_of_element_located(self._by_label(label))
            )
            return True
        except TimeoutException:
            return False

    def navigate_to_sparks(self):
        sparks_tab = self._find("SparksTab")
        sparks_tab.click()
        self._find(self.SPARKS_SCREEN_LABEL)

    def go_back(self):
        self._find(self.BACK_BUTTON_LABEL).click()

    def assert_feed_loaded(self, timeout=DEFAULT_TIMEOUT):
        WebDriverWait(self.driver, timeout).until(
            EC.invisibility_of_element_located(self._by_label(self.LOADING_INDICATOR))
        )
        assert self._is_present(self.VIDEO_PLAYER_LABEL, timeout=5), (
            "Expected a video player on screen after feed loaded"
        )

    def assert_empty_state(self):
        self._find_visible(self.EMPTY_STATE_LABEL)

    def assert_error_state(self):
        self._find_visible(self.ERROR_STATE_LABEL)

    def swipe_to_next_reel(self):
        start_x = self.size["width"] // 2
        start_y = self.size["height"] * 3 // 4
        end_y = start_y - SWIPE_DISTANCE_PX
        self.driver.swipe(start_x, start_y, start_x, end_y, duration=300)

    def swipe_to_previous_reel(self):
        start_x = self.size["width"] // 2
        start_y = self.size["height"] // 4
        end_y = start_y + SWIPE_DISTANCE_PX
        self.driver.swipe(start_x, start_y, start_x, end_y, duration=300)

    def wait_for_video_playing(self, timeout=VIDEO_PLAY_TIMEOUT):
        WebDriverWait(self.driver, timeout).until(
            EC.invisibility_of_element_located(self._by_label(self.PLAY_PAUSE_LABEL))
        )

    def tap_to_pause(self):
        video = self._find(self.VIDEO_PLAYER_LABEL)
        video.click()
        time.sleep(0.3)

    def tap_to_play(self):
        video = self._find(self.VIDEO_PLAYER_LABEL)
        video.click()
        time.sleep(0.3)

    def assert_video_paused(self):
        self._find_visible(self.PLAY_PAUSE_LABEL, timeout=5)

    def assert_video_playing(self):
        WebDriverWait(self.driver, 5).until(
            EC.invisibility_of_element_located(self._by_label(self.PLAY_PAUSE_LABEL))
        )

    def get_like_count(self):
        el = self._find(self.LIKE_COUNT_LABEL)
        text = el.text.strip()
        try:
            return int(text)
        except ValueError:
            return 0

    def tap_like(self):
        self._find(self.LIKE_BUTTON_LABEL).click()
        time.sleep(0.3)

    def double_tap_for_like(self):
        video = self._find(self.VIDEO_PLAYER_LABEL)
        loc = video.location
        size = video.size
        center_x = loc["x"] + size["width"] // 2
        center_y = loc["y"] + size["height"] // 2
        finger = PointerInput(interaction.POINTER_TOUCH, "finger")
        actions = ActionBuilder(self.driver, mouse=finger)
        actions.pointer_action.move_to_location(center_x, center_y)
        actions.pointer_action.pointer_down()
        actions.pointer_action.pause(0.05)
        actions.pointer_action.pointer_up()
        actions.pointer_action.pause(0.1)
        actions.pointer_action.pointer_down()
        actions.pointer_action.pause(0.05)
        actions.pointer_action.pointer_up()
        actions.perform()
        time.sleep(0.2)

    def assert_heart_burst_visible(self):
        self._find_visible(self.HEART_BURST_LABEL, timeout=2)

    def assert_heart_burst_gone(self, timeout=2):
        WebDriverWait(self.driver, timeout).until(
            EC.invisibility_of_element_located(self._by_label(self.HEART_BURST_LABEL))
        )

    def tap_comments(self):
        self._find(self.COMMENT_BUTTON_LABEL).click()

    def tap_share(self):
        self._find(self.SHARE_BUTTON_LABEL).click()

    def dismiss_share_sheet(self):
        if self.platform == "android":
            self.driver.back()
        else:
            self.driver.tap([(50, 50)])

    def open_context_menu(self):
        self._find(self.MORE_BUTTON_LABEL).click()
        time.sleep(0.3)

    def tap_report(self):
        self._find(self.REPORT_MENU_LABEL).click()

    def dismiss_context_menu(self):
        if self.platform == "android":
            self.driver.back()
        else:
            self.driver.tap([(50, 50)])

    def pull_to_refresh(self):
        start_x = self.size["width"] // 2
        start_y = self.size["height"] // 4
        end_y = start_y + 600
        self.driver.swipe(start_x, start_y, start_x, end_y, duration=800)
        time.sleep(1)
        try:
            WebDriverWait(self.driver, 8).until(
                EC.invisibility_of_element_located(self._by_label(self.LOADING_INDICATOR))
            )
        except TimeoutException:
            pass

    def tap_retry(self):
        self._find(self.RETRY_BUTTON_LABEL).click()


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture(scope="module")
def driver(request):
    platform = request.config.getoption("--platform")
    app      = request.config.getoption("--app")
    device   = request.config.getoption("--device")
    udid     = request.config.getoption("--udid")

    if platform == "android":
        options = UiAutomator2Options()
        options.platform_name = "Android"
        options.device_name = device or "emulator-5554"
        options.udid = device
        options.app = app
        options.app_package = "com.example.whispr"
        options.app_activity = ".MainActivity"
        options.no_reset = False
        options.auto_grant_permissions = True
        options.new_command_timeout = 120
    else:
        options = XCUITestOptions()
        options.platform_name = "iOS"
        options.device_name = device or "iPhone 15"
        options.udid = udid or "auto"
        options.app = app
        options.bundle_id = "com.whispr.app"
        options.no_reset = True
        options.new_command_timeout = 120

    d = webdriver.Remote(APPIUM_SERVER, options=options)
    d.implicitly_wait(0)
    yield d
    d.quit()

@pytest.fixture
def sparks(driver, request):
    platform = request.config.getoption("--platform")
    page = SparksFeedPage(driver, platform)
    page.navigate_to_sparks()
    yield page
    if hasattr(request.node, "rep_call") and request.node.rep_call.failed:
        os.makedirs("screenshots", exist_ok=True)
        name = request.node.name.replace(" ", "_")
        driver.save_screenshot("screenshots/FAIL_{}.png".format(name))


@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    rep = outcome.get_result()
    setattr(item, "rep_" + rep.when, rep)


# ---------------------------------------------------------------------------
# Tests — Feed Loading
# ---------------------------------------------------------------------------

class TestSparksFeedLoading:

    def test_feed_loads_and_shows_video(self, sparks):
        """Feed loads and at least one video card is visible."""
        sparks.assert_feed_loaded()

    def test_first_reel_auto_plays(self, sparks):
        """First video should be playing automatically on load."""
        sparks.assert_feed_loaded()
        sparks.assert_video_playing()

    def test_author_and_community_visible(self, sparks):
        """Author name and community tag are visible in the caption overlay."""
        sparks.assert_feed_loaded()
        author_visible = sparks._is_present(SparksFeedPage.AUTHOR_LABEL, timeout=5)
        community_visible = sparks._is_present(SparksFeedPage.COMMUNITY_LABEL, timeout=5)
        assert author_visible, "Author name should be visible in caption overlay"
        assert community_visible, "Community tag should be visible in caption overlay"


# ---------------------------------------------------------------------------
# Tests — Scroll and Preload
# ---------------------------------------------------------------------------

class TestSparkScrollAndPreload:

    def test_scroll_to_next_reel(self, sparks):
        """Swiping up shows the next reel."""
        sparks.assert_feed_loaded()
        sparks.swipe_to_next_reel()
        time.sleep(0.5)
        video_visible = sparks._is_present(SparksFeedPage.VIDEO_PLAYER_LABEL, timeout=5)
        assert video_visible, "Video player should still be visible after scrolling to next reel"

    def test_next_reel_plays_without_spinner(self, sparks):
        """
        After preload has had 3s, scrolling to next reel should NOT show
        a loading spinner within the first 500ms — the preload cache is working.
        """
        sparks.assert_feed_loaded()
        time.sleep(3)
        sparks.swipe_to_next_reel()
        spinner_appeared = False
        deadline = time.time() + 0.5
        while time.time() < deadline:
            if sparks._is_present(SparksFeedPage.LOADING_INDICATOR, timeout=0.1):
                spinner_appeared = True
                break
        assert not spinner_appeared, (
            "Loading spinner appeared after scrolling to preloaded reel — "
            "preload cache is not working correctly"
        )

    def test_next_reel_starts_playing(self, sparks):
        """Second reel should auto-play within VIDEO_PLAY_TIMEOUT seconds."""
        sparks.assert_feed_loaded()
        sparks.swipe_to_next_reel()
        try:
            sparks.wait_for_video_playing(timeout=VIDEO_PLAY_TIMEOUT)
        except TimeoutException:
            pytest.fail("Second reel did not start playing within {}s".format(VIDEO_PLAY_TIMEOUT))

    def test_swipe_back_to_previous_reel(self, sparks):
        """Swiping down returns to the previous reel."""
        sparks.assert_feed_loaded()
        sparks.swipe_to_next_reel()
        time.sleep(1)
        sparks.swipe_to_previous_reel()
        time.sleep(0.5)
        video_visible = sparks._is_present(SparksFeedPage.VIDEO_PLAYER_LABEL, timeout=5)
        assert video_visible, "Video player should be visible after returning to previous reel"

    def test_scroll_multiple_reels_no_crash(self, sparks):
        """Scrolling through 3 reels quickly should not crash or show a blank screen."""
        sparks.assert_feed_loaded()
        for _ in range(3):
            sparks.swipe_to_next_reel()
            time.sleep(0.4)
        video_visible = sparks._is_present(SparksFeedPage.VIDEO_PLAYER_LABEL, timeout=5)
        assert video_visible, "Video player missing after scrolling through 3 reels"


# ---------------------------------------------------------------------------
# Tests — Play / Pause
# ---------------------------------------------------------------------------

class TestSparksPlayPause:

    def test_single_tap_pauses_video(self, sparks):
        """Single tap on playing video should pause it."""
        sparks.assert_feed_loaded()
        sparks.assert_video_playing()
        sparks.tap_to_pause()
        sparks.assert_video_paused()

    def test_single_tap_resumes_video(self, sparks):
        """Single tap on paused video should resume it."""
        sparks.assert_feed_loaded()
        sparks.tap_to_pause()
        sparks.assert_video_paused()
        sparks.tap_to_play()
        sparks.assert_video_playing()


# ---------------------------------------------------------------------------
# Tests — Like / Unlike
# ---------------------------------------------------------------------------

class TestSparksLike:

    def test_like_increments_count(self, sparks):
        """Tapping like should increment the count by 1 immediately."""
        sparks.assert_feed_loaded()
        count_before = sparks.get_like_count()
        sparks.tap_like()
        count_after = sparks.get_like_count()
        assert count_after == count_before + 1, (
            "Like count should be {}, got {}".format(count_before + 1, count_after)
        )

    def test_unlike_decrements_count(self, sparks):
        """Tapping like on an already-liked reel should decrement the count."""
        sparks.assert_feed_loaded()
        sparks.tap_like()
        count_liked = sparks.get_like_count()
        sparks.tap_like()
        count_unliked = sparks.get_like_count()
        assert count_unliked == count_liked - 1, (
            "Like count should decrease to {}, got {}".format(count_liked - 1, count_unliked)
        )

    def test_double_tap_triggers_heart_burst_and_like(self, sparks):
        """Double-tap should show heart burst animation and increment like count."""
        sparks.assert_feed_loaded()
        count_before = sparks.get_like_count()
        sparks.double_tap_for_like()
        sparks.assert_heart_burst_visible()
        sparks.assert_heart_burst_gone(timeout=2)
        count_after = sparks.get_like_count()
        assert count_after == count_before + 1, "Double-tap should increment like count"

    def test_double_tap_already_liked_no_duplicate(self, sparks):
        """Double-tap on an already-liked reel should not increment count again."""
        sparks.assert_feed_loaded()
        sparks.tap_like()
        count_after_like = sparks.get_like_count()
        sparks.double_tap_for_like()
        sparks.assert_heart_burst_visible()
        sparks.assert_heart_burst_gone(timeout=2)
        count_final = sparks.get_like_count()
        assert count_final == count_after_like, (
            "Double-tap on already-liked reel should not increment count again"
        )


# ---------------------------------------------------------------------------
# Tests — Comments
# ---------------------------------------------------------------------------

class TestSparksComments:

    def test_tap_comments_navigates_to_post(self, sparks):
        """Tapping comment button should navigate to the post detail screen."""
        sparks.assert_feed_loaded()
        sparks.tap_comments()
        page = SparksFeedPage(sparks.driver, sparks.platform)
        on_post_screen = page._is_present("PostDetailScreen", timeout=DEFAULT_TIMEOUT)
        assert on_post_screen, "Should navigate to post detail screen on comment tap"
        sparks.go_back()
        sparks.assert_feed_loaded()


# ---------------------------------------------------------------------------
# Tests — Share
# ---------------------------------------------------------------------------

class TestSparksShare:

    def test_share_opens_system_sheet(self, sparks):
        """Tapping share should open the OS share sheet."""
        sparks.assert_feed_loaded()
        sparks.tap_share()
        time.sleep(1.5)
        if sparks.platform == "android":
            share_visible = (
                sparks._is_present("ShareWith", timeout=5) or
                sparks._is_present("android:id/resolver_list", timeout=2)
            )
        else:
            share_visible = (
                sparks._is_present("Copy", timeout=5) or
                sparks._is_present("AirDrop", timeout=2)
            )
        assert share_visible, "System share sheet did not appear"
        sparks.dismiss_share_sheet()


# ---------------------------------------------------------------------------
# Tests — Context Menu / Report
# ---------------------------------------------------------------------------

class TestSparksContextMenu:

    def test_more_button_opens_context_menu(self, sparks):
        """Tapping the more button should show a Report option in the bottom sheet."""
        sparks.assert_feed_loaded()
        sparks.open_context_menu()
        report_visible = sparks._is_present(SparksFeedPage.REPORT_MENU_LABEL, timeout=5)
        assert report_visible, "Report reel option should appear in context menu"
        sparks.dismiss_context_menu()

    def test_report_opens_report_sheet(self, sparks):
        """Tapping Report reel should open the report sheet."""
        sparks.assert_feed_loaded()
        sparks.open_context_menu()
        sparks.tap_report()
        report_sheet_visible = sparks._is_present("ReportSheet", timeout=DEFAULT_TIMEOUT)
        assert report_sheet_visible, "Report sheet should appear after tapping Report reel"
        sparks.driver.back()


# ---------------------------------------------------------------------------
# Tests — Empty and Error States
# ---------------------------------------------------------------------------

class TestSparksEmptyAndError:

    def test_empty_state_shown_when_no_reels(self, driver, request):
        """Empty state widget should show when there are no video posts."""
        platform = request.config.getoption("--platform")
        page = SparksFeedPage(driver, platform)
        page.navigate_to_sparks()
        try:
            page.assert_empty_state()
        except TimeoutException:
            pytest.skip(
                "Empty state test skipped — database is not empty. "
                "Run against an empty-posts test environment."
            )

    def test_retry_button_leaves_error_state(self, sparks):
        """Tapping Retry should leave the error state."""
        if not sparks._is_present(SparksFeedPage.ERROR_STATE_LABEL, timeout=3):
            pytest.skip("Error state not present — skipping retry test")
        sparks.tap_retry()
        time.sleep(1)
        still_error = sparks._is_present(SparksFeedPage.ERROR_STATE_LABEL, timeout=3)
        assert not still_error, "App should leave error state after tapping Retry"


# ---------------------------------------------------------------------------
# Tests — Pull to Refresh
# ---------------------------------------------------------------------------

class TestSparksPullToRefresh:

    def test_pull_to_refresh_reloads_feed(self, sparks):
        """Pull to refresh should reload the feed and still show content."""
        sparks.assert_feed_loaded()
        sparks.pull_to_refresh()
        sparks.assert_feed_loaded()

    def test_live_stream_keeps_feed_current(self, sparks):
        """Feed should remain functional after 5s (live Firestore stream active)."""
        sparks.assert_feed_loaded()
        time.sleep(5)
        sparks.assert_feed_loaded()


# ---------------------------------------------------------------------------
# Tests — Back Navigation
# ---------------------------------------------------------------------------

class TestSparksBackNavigation:

    def test_back_button_exits_sparks_screen(self, sparks):
        """Back button should navigate away from the Sparks screen."""
        sparks.assert_feed_loaded()
        sparks.go_back()
        time.sleep(0.5)
        still_on_sparks = sparks._is_present(SparksFeedPage.SPARKS_SCREEN_LABEL, timeout=3)
        assert not still_on_sparks, "Sparks screen should not be visible after pressing Back"

    def test_return_to_sparks_resets_feed(self, sparks):
        """Re-entering Sparks after leaving should start fresh from the first reel."""
        sparks.assert_feed_loaded()
        sparks.swipe_to_next_reel()
        time.sleep(0.5)
        sparks.swipe_to_next_reel()
        time.sleep(0.5)
        sparks.go_back()
        time.sleep(0.5)
        page = SparksFeedPage(sparks.driver, sparks.platform)
        page.navigate_to_sparks()
        page.assert_feed_loaded()
        page.assert_video_playing()


# ---------------------------------------------------------------------------
# Semantics labels needed in your Flutter code
# ---------------------------------------------------------------------------
#
# Add Semantics(label: '...', child: ...) wrappers to these widgets:
#
# reel_card.dart:
#   SparkVideoPlayer   -> wrap FittedBox(child: VideoPlayer(...))
#   LikeButton         -> wrap the like _ReelActionButton
#   LikeCount          -> wrap the like count Text widget
#   CommentButton      -> wrap the comment _ReelActionButton
#   ShareButton        -> wrap the share _ReelActionButton
#   MoreButton         -> wrap the more _ReelActionButton
#   PlayPauseOverlay   -> wrap the pause indicator Container
#   HeartBurst         -> wrap the AnimatedOpacity heart icon
#   SparkAuthorName    -> wrap the author pseudonym Text
#   SparkCommunityTag  -> wrap the community tag Container
#
# reels_screen.dart:
#   SparksScreen       -> wrap the Scaffold
#   EmptySparksState   -> wrap the _EmptyReels Column
#   SparksErrorState   -> wrap the _ReelsErrorState Column
#   RetryButton        -> wrap the retry GestureDetector
#   BackButton         -> wrap the back GestureDetector
#   SparksTab          -> wrap the bottom nav Sparks tab item