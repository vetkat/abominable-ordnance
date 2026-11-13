"""Static checks on the workflows, for rules that only fail on GitHub."""
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]


def read(name):
    return (ROOT / ".github/workflows" / name).read_text(encoding="utf-8")


def test_check_uses_no_secrets():
    assert "secrets." not in read("check.yml")


def test_pr_checks_run_again_when_title_or_labels_change():
    assert ("types: [opened, synchronize, reopened, edited, labeled, unlabeled]"
            in read("check.yml"))


def test_all_checks_needs_every_job():
    text = read("check.yml")
    assert "needs: [text, lua, tools, ingame, pr]" in text


def test_each_gate_job_calls_its_make_target():
    text = read("check.yml")
    for target in ["make text", "make lua", "make tools", "make ingame"]:
        assert target in text


def test_check_can_be_called_by_the_release():
    assert "workflow_call:" in read("check.yml")
def test_release_calls_check_and_does_not_publish_to_the_portal():
    text = read("release.yml")
    assert "uses: ./.github/workflows/check.yml" in text
    assert "mods.factorio.com" not in text and "secrets." not in text


def test_release_checks_that_the_tag_is_on_main():
    assert "merge-base --is-ancestor" in read("release.yml")


def test_weekly_has_links_and_factorio_version_jobs():
    text = read("weekly.yml")
    assert "links:" in text and "factorio-version:" in text
    assert "schedule:" in text


def test_push_runs_check_on_main_only():
    # A push run on a PR branch would report a second all-checks that
    # skips the pr job, and could hide a failing PR check.
    assert 'push:\n    branches: [main]\n' in read("check.yml")


def test_check_cancels_superseded_pr_runs_only():
    text = read("check.yml")
    assert "concurrency:" in text
    assert "cancel-in-progress: ${{ github.event_name == 'pull_request' }}" in text
