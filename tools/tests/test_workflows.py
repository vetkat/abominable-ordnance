"""Static checks on the workflows and the Makefile, for rules that only fail on GitHub."""
import pathlib

import yaml

from tools import pr_checks

ROOT = pathlib.Path(__file__).resolve().parents[2]


def read(name):
    return (ROOT / ".github/workflows" / name).read_text(encoding="utf-8")


def makefile():
    return (ROOT / "Makefile").read_text(encoding="utf-8")


def test_make_fast_leaves_out_the_gate_tests():
    text = makefile()
    assert 'python3 -m pytest -m "not gates"' in text
    assert "python3 -m pytest -m gates" in text
    assert "\ncheck: fast gates ingame\n" in text


def test_lua_and_gates_depend_on_the_api_folder():
    text = makefile()
    assert "\nlua: $(API)/stamp\n" in text
    assert "\ngates: $(API)/stamp\n" in text


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


def test_lua_job_installs_luals_and_runs_the_gate_tests():
    text = read("check.yml")
    lua_job = text[text.index("\n  lua:\n"):text.index("\n  tools:\n")]
    assert "lua-language-server-3.19.2-linux-x64.tar.gz" in lua_job
    assert "sha256sum -c" in lua_job
    assert "path: .factorio-api" in lua_job
    assert "touch .factorio-api/stamp" in lua_job
    assert "run: npm ci" in lua_job
    # Ubuntu's own Python refuses pip install, so the job sets up Python.
    assert "uses: actions/setup-python@v7" in lua_job
    assert "make gates" in lua_job


def test_check_can_be_called_by_the_release():
    assert "workflow_call:" in read("check.yml")
def test_release_calls_check_and_does_not_publish_to_the_portal():
    text = read("release.yml")
    assert "uses: ./.github/workflows/check.yml" in text
    assert "mods.factorio.com" not in text and "secrets." not in text


def test_release_checks_that_the_tag_is_on_main():
    assert "merge-base --is-ancestor" in read("release.yml")


def test_weekly_checks_links_only():
    text = read("weekly.yml")
    assert "links:" in text and "schedule:" in text
    assert "factorio_version" not in text and "factorio-version:" not in text


def version_jobs():
    data = yaml.safe_load(read("factorio-version.yml"))
    return data, data["jobs"]


def step_runs(job):
    return "\n".join(step.get("run", "") for step in job["steps"])


def test_factorio_version_runs_daily_and_moves_the_pin():
    data, jobs = version_jobs()
    assert data[True]["schedule"] == [{"cron": "17 6 * * *"}]
    runs = step_runs(jobs["bump"])
    assert "python3 -m tools.factorio_version" in runs
    assert 'gh pr merge "$pr" --auto --squash' in runs


def test_only_the_keepalive_job_can_enable_workflows():
    data, jobs = version_jobs()
    assert "permissions" not in data or data["permissions"] == {}
    assert jobs["keepalive"]["permissions"] == {"actions": "write"}
    assert jobs["bump"]["permissions"] == {"contents": "read"}
    runs = step_runs(jobs["keepalive"])
    assert "for file in factorio-version.yml weekly.yml; do" in runs
    assert "actions/workflows/$file/enable" in runs


def test_the_app_token_is_made_only_for_a_new_version_and_never_stored():
    _, jobs = version_jobs()
    steps = jobs["bump"]["steps"]
    checkout = next(s for s in steps if s.get("uses", "").startswith("actions/checkout"))
    assert checkout["with"]["persist-credentials"] is False
    app = next(s for s in steps if s.get("uses", "").startswith("actions/create-github-app-token"))
    assert app["if"] == "steps.pin.outputs.version"
    assert app["with"]["permission-contents"] == "write"
    assert app["with"]["permission-pull-requests"] == "write"
    pr = steps[-1]
    assert pr["if"] == "steps.pin.outputs.version"
    assert pr["env"]["GH_TOKEN"] == "${{ steps.app.outputs.token }}"


def test_untrusted_values_reach_the_shell_through_env_only():
    _, jobs = version_jobs()
    for job in jobs.values():
        for step in job["steps"]:
            assert "${{" not in step.get("run", ""), step


def test_the_bot_pr_reuses_one_branch_from_this_repository():
    runs = step_runs(version_jobs()[1]["bump"])
    assert 'branch="ci/factorio-version"' in runs
    assert 'git push --force origin "$branch"' in runs
    assert "isCrossRepository" in runs


def test_the_bot_pr_body_passes_the_pr_check():
    runs = step_runs(version_jobs()[1]["bump"])
    body = runs[runs.index("<<BODY"):runs.index("\nBODY")]
    assert pr_checks.review_problems(body, [], "ao-bot[bot]") == []
    assert pr_checks.title_problems("ci: test Factorio 2.1.25") == []


def test_push_runs_check_on_main_only():
    # A push run on a PR branch would report a second all-checks that
    # skips the pr job, and could hide a failing PR check.
    assert 'push:\n    branches: [main]\n' in read("check.yml")


def test_check_cancels_superseded_pr_runs_only():
    text = read("check.yml")
    assert "concurrency:" in text
    assert "cancel-in-progress: ${{ github.event_name == 'pull_request' }}" in text
