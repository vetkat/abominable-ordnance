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
