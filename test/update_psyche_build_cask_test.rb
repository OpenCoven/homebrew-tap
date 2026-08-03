# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "open3"
require "psych"
require "tmpdir"

class UpdatePsycheBuildCaskTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  SCRIPT = File.join(ROOT, "scripts/update-psyche-build-cask.rb")
  RELEASE_FIXTURE = File.join(__dir__, "fixtures/psyche-build-v0.0.1-release.json")
  CHECKSUM_FIXTURE = File.join(__dir__, "fixtures/psyche-build-v0.0.1-SHA256SUMS")
  CI_WORKFLOW = File.join(ROOT, ".github/workflows/ci.yml")
  UPDATE_WORKFLOW = File.join(ROOT, ".github/workflows/update-psyche-build-cask.yml")
  TAG = "v0.0.1"
  API_LATEST = "https://api.github.com/repos/OpenCoven/psyche-build/releases/latest"
  API_TAG = "https://api.github.com/repos/OpenCoven/psyche-build/releases/tags/v0.0.1"
  DOWNLOAD_ROOT = "https://github.com/OpenCoven/psyche-build/releases/download/v0.0.1"

  EXPECTED_CASK = <<~RUBY
    # frozen_string_literal: true

    cask "psyche-build" do
      arch arm: "aarch64", intel: "x86_64"

      version "0.0.1"
      sha256 arm:   "1111111111111111111111111111111111111111111111111111111111111111",
             intel: "2222222222222222222222222222222222222222222222222222222222222222"

      url "https://github.com/OpenCoven/psyche-build/releases/download/v\#{version}/Psyche-Build-v\#{version}-\#{arch}.dmg"
      name "Psyche Build"
      desc "Multiagent coding harness for parallel agent lanes"
      homepage "https://github.com/OpenCoven/psyche-build"

      depends_on macos: :monterey

      app "Psyche Build.app"

      zap trash: [
        "~/Library/Application Support/dev.opencoven.psyche",
        "~/Library/Caches/dev.opencoven.psyche",
        "~/Library/Preferences/dev.opencoven.psyche.plist",
        "~/Library/Saved Application State/dev.opencoven.psyche.savedState",
        "~/Library/WebKit/dev.opencoven.psyche",
      ]
    end
  RUBY

  def test_renders_complete_fixture_byte_for_byte_deterministically
    with_files do |release, checksums, output|
      first = run_updater(release: release, checksums: checksums, output: output)
      assert_success first
      assert_equal EXPECTED_CASK, File.binread(output)

      File.binwrite(output, "stale\n")
      second = run_updater(release: release, checksums: checksums, output: output)
      assert_success second
      assert_equal EXPECTED_CASK, File.binread(output)
    end
  end

  def test_rejects_non_stable_tags
    ["0.0.1", "v0.0", "v0.0.1-rc.1", "v0.0.1+build", "latest", "v01.0.1"].each do |tag|
      with_files do |release, checksums, output|
        result = run_updater(tag: tag, release: release, checksums: checksums, output: output)
        assert_failure result, /stable vMAJOR\.MINOR\.PATCH/, tag
        refute File.exist?(output)
      end
    end
  end

  def test_infers_release_tag_with_offline_fixtures
    with_files do |release, checksums, output|
      result = run_updater(tag: nil, release: release, checksums: checksums, output: output)
      assert_success result
      assert_equal EXPECTED_CASK, File.binread(output)
    end
  end

  def test_rejects_release_tag_mismatch
    with_files(release_change: ->(json) { json["tag_name"] = "v0.0.2" }) do |release, checksums, output|
      result = run_updater(release: release, checksums: checksums, output: output)
      assert_failure result, /release tag.*does not match/i
      refute File.exist?(output)
    end
  end

  def test_rejects_draft_prerelease_and_unpublished_releases
    {
      "draft" => ->(json) { json["draft"] = true },
      "prerelease" => ->(json) { json["prerelease"] = true },
      "published" => ->(json) { json["published_at"] = nil },
    }.each do |label, change|
      with_files(release_change: change) do |release, checksums, output|
        result = run_updater(release: release, checksums: checksums, output: output)
        assert_failure result, /published stable release/i, label
        refute File.exist?(output)
      end
    end
  end

  def test_requires_exactly_three_expected_release_assets
    cases = {
      "missing" => lambda do |json|
        json["assets"].reject! { |asset| asset["name"].end_with?("x86_64.dmg") }
      end,
      "duplicate" => lambda do |json|
        json["assets"] << json["assets"].find { |asset| asset["name"].end_with?("aarch64.dmg") }.dup
      end,
      "unexpected DMG" => lambda do |json|
        json["assets"] << {
          "name" => "Psyche-Build-v0.0.1-universal.dmg",
          "browser_download_url" => "https://github.com/OpenCoven/psyche-build/releases/download/v0.0.1/Psyche-Build-v0.0.1-universal.dmg",
          "state" => "uploaded",
          "size" => 1,
        }
      end,
      "extra non-DMG" => lambda do |json|
        json["assets"] << {
          "name" => "release-notes.txt",
          "browser_download_url" => "https://github.com/OpenCoven/psyche-build/releases/download/v0.0.1/release-notes.txt",
          "state" => "uploaded",
          "size" => 1,
        }
      end,
      "malformed non-object" => ->(json) { json["assets"][0] = "not-an-asset-object" },
      "malformed object" => ->(json) { json["assets"][0] = {} },
    }

    cases.each do |label, change|
      with_files(release_change: change) do |release, checksums, output|
        result = run_updater(release: release, checksums: checksums, output: output)
        assert_failure result, /exactly.*three.*assets/i, label
        refute File.exist?(output)
      end
    end
  end

  def test_requires_exact_lowercase_sha256_digest_for_each_dmg
    cases = {
      "missing" => ->(asset) { asset.delete("digest") },
      "malformed" => ->(asset) { asset["digest"] = "sha256:not-a-hash" },
      "unsupported" => ->(asset) { asset["digest"] = "sha512:#{"1" * 64}" },
      "uppercase algorithm" => ->(asset) { asset["digest"] = "SHA256:#{"1" * 64}" },
      "uppercase hash" => ->(asset) { asset["digest"] = "sha256:#{"A" * 64}" },
      "non-string" => ->(asset) { asset["digest"] = 123 },
    }

    cases.each do |label, change|
      with_files(release_change: lambda { |json|
        change.call(json["assets"].find { |asset| asset["name"].end_with?("aarch64.dmg") })
      }) do |release, checksums, output|
        result = run_updater(release: release, checksums: checksums, output: output)
        assert_failure result, /digest/i, label
        refute File.exist?(output)
      end
    end
  end

  def test_rejects_syntactically_valid_checksum_that_does_not_match_asset_digest
    wrong_checksums = File.binread(CHECKSUM_FIXTURE).sub("1" * 64, "3" * 64)
    with_files(checksum_contents: wrong_checksums) do |release, checksums, output|
      result = run_updater(release: release, checksums: checksums, output: output)
      assert_failure result, /checksum.*does not match.*digest/i
      refute File.exist?(output)
    end
  end

  def test_requires_one_uploaded_nonempty_checksum_asset
    cases = {
      "missing" => [
        ->(json) { json["assets"].reject! { |asset| asset["name"] == "SHA256SUMS" } },
        /exactly three expected assets/i,
      ],
      "duplicate" => [
        lambda do |json|
          json["assets"] << json["assets"].find { |asset| asset["name"] == "SHA256SUMS" }.dup
        end,
        /exactly three expected assets/i,
      ],
      "uploading" => [
        lambda do |json|
          json["assets"].find { |asset| asset["name"] == "SHA256SUMS" }["state"] = "new"
        end,
        /fully uploaded/i,
      ],
      "empty" => [
        lambda do |json|
          json["assets"].find { |asset| asset["name"] == "SHA256SUMS" }["size"] = 0
        end,
        /fully uploaded/i,
      ],
    }

    cases.each do |label, (change, message)|
      with_files(release_change: change) do |release, checksums, output|
        result = run_updater(release: release, checksums: checksums, output: output)
        assert_failure result, message, label
        refute File.exist?(output)
      end
    end
  end

  def test_rejects_partial_dmg_uploads
    [
      ->(asset) { asset["state"] = "new" },
      ->(asset) { asset["size"] = 0 },
    ].each do |change|
      with_files(release_change: lambda { |json|
        change.call(json["assets"].find { |asset| asset["name"].end_with?("aarch64.dmg") })
      }) do |release, checksums, output|
        result = run_updater(release: release, checksums: checksums, output: output)
        assert_failure result, /fully uploaded/i
        refute File.exist?(output)
      end
    end
  end

  def test_rejects_wrong_or_insecure_asset_urls
    [
      "http://github.com/OpenCoven/psyche-build/releases/download/v0.0.1/Psyche-Build-v0.0.1-aarch64.dmg",
      "https://example.com/Psyche-Build-v0.0.1-aarch64.dmg",
      "https://github.com/OpenCoven/psyche-build/releases/download/v0.0.2/Psyche-Build-v0.0.1-aarch64.dmg",
    ].each do |url|
      with_files(release_change: lambda { |json|
        json["assets"].find { |asset| asset["name"].end_with?("aarch64.dmg") }["browser_download_url"] = url
      }) do |release, checksums, output|
        result = run_updater(release: release, checksums: checksums, output: output)
        assert_failure result, /unexpected download URL/i, url
        refute File.exist?(output)
      end
    end

    with_files(release_change: lambda { |json|
      json["assets"].find { |asset| asset["name"] == "SHA256SUMS" }["browser_download_url"] =
        "https://example.com/SHA256SUMS"
    }) do |release, checksums, output|
      result = run_updater(release: release, checksums: checksums, output: output)
      assert_failure result, /unexpected download URL/i, "SHA256SUMS"
      refute File.exist?(output)
    end
  end

  def test_rejects_missing_duplicate_malformed_or_mismatched_checksums
    valid = File.binread(CHECKSUM_FIXTURE)
    cases = {
      "missing" => valid.lines.first,
      "duplicate" => valid + valid.lines.first,
      "malformed" => "not-a-checksum Psyche-Build-v0.0.1-aarch64.dmg\n#{valid.lines.last}",
      "uppercase" => valid.sub("1" * 64, "A" * 64),
      "wrong filename" => valid.sub("aarch64.dmg", "arm64.dmg"),
      "unexpected entry" => valid + ("3" * 64) + "  notes.txt\n",
    }

    cases.each do |label, contents|
      with_files(checksum_contents: contents) do |release, checksums, output|
        result = run_updater(release: release, checksums: checksums, output: output)
        assert_failure result, /checksum/i, label
        refute File.exist?(output)
      end
    end
  end

  def test_does_not_mutate_existing_output_on_any_failure
    with_files(release_change: ->(json) { json["draft"] = true }) do |release, checksums, output|
      File.binwrite(output, "keep me\n")
      result = run_updater(release: release, checksums: checksums, output: output)
      assert_failure result, /published stable release/i
      assert_equal "keep me\n", File.binread(output)
    end
  end

  def test_rejects_malformed_release_json_and_field_types_without_mutating_output
    cases = {
      "invalid JSON" => ["{not-json", /JSON|unexpected token/i],
      "top-level array" => ["[]", /release JSON must be an object/i],
      "non-string tag" => [JSON.generate(JSON.parse(File.binread(RELEASE_FIXTURE)).merge("tag_name" => 1)), /release tag/i],
      "non-array assets" => [JSON.generate(JSON.parse(File.binread(RELEASE_FIXTURE)).merge("assets" => {})), /assets must be an array/i],
      "non-boolean draft" => [JSON.generate(JSON.parse(File.binread(RELEASE_FIXTURE)).merge("draft" => "false")), /published stable release/i],
      "non-string published_at" => [JSON.generate(JSON.parse(File.binread(RELEASE_FIXTURE)).merge("published_at" => 1)), /published stable release/i],
    }

    cases.each do |label, (release_contents, message)|
      with_files(release_contents: release_contents) do |release, checksums, output|
        File.binwrite(output, "preserve\n")
        result = run_updater(release: release, checksums: checksums, output: output)
        assert_failure result, message, label
        assert_equal "preserve\n", File.binread(output), label
      end
    end
  end

  def test_live_latest_uses_ordered_authenticated_api_and_unauthenticated_asset_requests
    sentinel = "ghs_DO_NOT_LEAK_THIS_SENTINEL"
    with_fake_curl(token: sentinel) do |environment, log, output|
      result = run_live_updater(environment, output: output)
      assert_success result
      assert_equal EXPECTED_CASK, File.binread(output)

      requests = fake_curl_requests(log)
      assert_equal [
        API_LATEST,
        "#{DOWNLOAD_ROOT}/SHA256SUMS",
        "#{DOWNLOAD_ROOT}/Psyche-Build-v0.0.1-aarch64.dmg",
        "#{DOWNLOAD_ROOT}/Psyche-Build-v0.0.1-x86_64.dmg",
      ], requests.map { |request| request.fetch(:url) }
      assert_equal [true, false, false, false], requests.map { |request| request.fetch(:authenticated) }
      requests.each do |request|
        assert_includes request.fetch(:arguments), "--fail-with-body"
        assert_includes request.fetch(:arguments), "--silent"
        assert_includes request.fetch(:arguments), "--show-error"
        assert_includes request.fetch(:arguments), "--location"
      end
      assert_includes requests.first.fetch(:arguments), "--config -"

      refute_includes File.binread(log), sentinel
      refute_includes result.stdout, sentinel
      refute_includes result.stderr, sentinel
    end
  end

  def test_live_explicit_tag_uses_tag_endpoint_without_api_auth_when_token_is_absent
    with_fake_curl(token: nil) do |environment, log, output|
      result = run_live_updater(environment, tag: TAG, output: output)
      assert_success result
      requests = fake_curl_requests(log)
      assert_equal API_TAG, requests.first.fetch(:url)
      refute requests.first.fetch(:authenticated)
      assert_equal EXPECTED_CASK, File.binread(output)
    end
  end

  def test_live_non_200_dmg_preserves_existing_output
    with_fake_curl(mode: "non_200_arm") do |environment, _log, output|
      File.binwrite(output, "preserve\n")
      result = run_live_updater(environment, output: output)
      assert_failure result, /did not resolve HTTP 200.*503/i
      assert_equal "preserve\n", File.binread(output)
    end
  end

  def test_live_curl_failure_preserves_output_and_omits_token_from_diagnostics
    sentinel = "ghs_DO_NOT_LEAK_THIS_SENTINEL"
    with_fake_curl(mode: "fail_checksums", token: sentinel) do |environment, log, output|
      File.binwrite(output, "preserve\n")
      result = run_live_updater(environment, output: output)
      assert_failure result, /curl failed.*SHA256SUMS/i
      assert_equal "preserve\n", File.binread(output)
      refute_includes File.binread(log), sentinel
      refute_includes result.stdout, sentinel
      refute_includes result.stderr, sentinel
    end
  end

  def test_live_missing_curl_preserves_existing_output
    Dir.mktmpdir do |dir|
      File.symlink("/usr/bin/uname", File.join(dir, "uname"))
      output = File.join(dir, "psyche-build.rb")
      File.binwrite(output, "preserve\n")
      result = run_live_updater({ "PATH" => dir }, output: output)
      assert_failure result, /curl is required/i
      assert_equal "preserve\n", File.binread(output)
    end
  end

  def test_ci_verifies_installed_app_trust_before_launch_and_always_cleans_up
    workflow = File.binread(CI_WORKFLOW)

    app = '"/Applications/Psyche Build.app"'
    codesign = "codesign --verify --deep --strict #{app}"
    gatekeeper = "spctl --assess --type execute #{app}"
    stapler = "xcrun stapler validate #{app}"
    launch = "open -n #{app}"
    assert_includes workflow, codesign
    assert_includes workflow, gatekeeper
    assert_includes workflow, stapler
    assert_includes workflow, launch
    assert_operator workflow.index(codesign), :<, workflow.index(launch)
    assert_operator workflow.index(gatekeeper), :<, workflow.index(launch)
    assert_operator workflow.index(stapler), :<, workflow.index(launch)
    refute_includes workflow, 'open -na "/Applications/Psyche Build.app"'
    assert_match(/- name: Clean up Psyche Build\n\s+if: always\(\)/, workflow)
  end

  def test_ci_proves_normal_uninstall_and_every_zap_path
    workflow = File.binread(CI_WORKFLOW)
    paths = [
      "$HOME/Library/Application Support/dev.opencoven.psyche",
      "$HOME/Library/Caches/dev.opencoven.psyche",
      "$HOME/Library/Preferences/dev.opencoven.psyche.plist",
      "$HOME/Library/Saved Application State/dev.opencoven.psyche.savedState",
      "$HOME/Library/WebKit/dev.opencoven.psyche",
    ]

    assert_match(/brew uninstall --cask psyche-build\n\s+test ! -e "\/Applications\/Psyche Build\.app"/, workflow)
    paths.each { |path| assert_includes workflow, path }
    assert_includes workflow, 'test ! -e "$path"'
    assert_includes workflow, "brew uninstall --cask --zap psyche-build"
    assert_includes workflow, "brew uninstall --cask --zap --force psyche-build"
  end

  def test_workflows_parse_structurally_and_every_run_block_has_bash_syntax
    {
      CI_WORKFLOW => {
        "updater-tests" => ["Ruby syntax", "Updater tests"],
        "test" => ["Install and launch Psyche Build", "Reinstall and zap Psyche Build", "Clean up Psyche Build"],
      },
      UPDATE_WORKFLOW => {
        "update" => ["Resolve requested tag", "Render Cask from published release", "Push bot branch"],
      },
    }.each do |path, jobs|
      parsed = parse_workflow(path)
      jobs.each do |job_name, expected_steps|
        steps = parsed.fetch("jobs").fetch(job_name).fetch("steps")
        names = steps.map { |step| step["name"] }.compact
        expected_steps.each { |name| assert_includes names, name }
      end

      workflow_steps(parsed).each do |step|
        next unless step["run"]

        _stdout, stderr, status = Open3.capture3("bash", "-n", stdin_data: step.fetch("run"))
        assert status.success?, "#{path} step #{step['name'].inspect} has invalid Bash: #{stderr}"
      end

      workflow_steps(parsed).map { |step| step["uses"] }.compact.each do |uses|
        assert_match(/@[0-9a-f]{40}\z/, uses)
      end
    end
  end

  def test_resolve_tag_step_accepts_empty_or_stable_tags_without_environment_injection
    step = workflow_steps(parse_workflow(UPDATE_WORKFLOW)).find { |candidate| candidate["name"] == "Resolve requested tag" }
    refute_nil step

    { "" => "REQUESTED_TAG=\n", "v0.0.1" => "REQUESTED_TAG=v0.0.1\n" }.each do |tag, expected|
      Dir.mktmpdir do |dir|
        environment_file = File.join(dir, "github-env")
        result = run_bash_step(step.fetch("run"), "DISPATCH_TAG" => tag, "INPUT_TAG" => "", "GITHUB_ENV" => environment_file)
        assert_success result
        assert_equal expected, File.binread(environment_file)
      end
    end

    ["0.0.1", "v0.0.1-rc.1", "v01.0.1", "v0.0.1\nINJECTED=true", "v0.0.1\rINJECTED=true"].each do |tag|
      Dir.mktmpdir do |dir|
        environment_file = File.join(dir, "github-env")
        File.binwrite(environment_file, "preserve=true\n")
        result = run_bash_step(step.fetch("run"), "DISPATCH_TAG" => tag, "INPUT_TAG" => "", "GITHUB_ENV" => environment_file)
        assert_failure result, /stable vMAJOR\.MINOR\.PATCH/i, tag.inspect
        assert_equal "preserve=true\n", File.binread(environment_file)
      end
    end
  end

  def test_update_workflow_handles_new_and_existing_bot_branches_safely
    workflow = File.binread(UPDATE_WORKFLOW)

    assert_includes workflow, "git ls-files --error-unmatch Casks/psyche-build.rb"
    assert_includes workflow, "git ls-remote --exit-code --heads origin"
    assert_includes workflow, '--force-with-lease="refs/heads/$BRANCH:$remote_sha"'
    assert_includes workflow, '--force-with-lease="refs/heads/$BRANCH:"'
    refute_match(/git fetch .*\|\| true/, workflow)
    refute_match(/git push .*HEAD:main/, workflow)
  end

  def test_git_leases_reject_creation_races_and_allow_exact_updates
    Dir.mktmpdir do |dir|
      remote = File.join(dir, "remote.git")
      worker = File.join(dir, "worker")
      racer = File.join(dir, "racer")
      branch = "refs/heads/automation/psyche-build-v0.0.1"

      assert_git_success git("init", "--bare", remote)
      assert_git_success git("init", worker)
      configure_git(worker)
      File.binwrite(File.join(worker, "cask"), "first\n")
      assert_git_success git("-C", worker, "add", "cask")
      assert_git_success git("-C", worker, "commit", "-m", "first")
      assert_git_success git("-C", worker, "push", "--force-with-lease=#{branch}:", remote, "HEAD:#{branch}")

      assert_git_success git("clone", remote, racer)
      configure_git(racer)
      assert_git_success git("-C", racer, "switch", "--detach", "origin/automation/psyche-build-v0.0.1")
      File.binwrite(File.join(racer, "cask"), "racing update\n")
      assert_git_success git("-C", racer, "commit", "-am", "race")
      assert_git_success git("-C", racer, "push", remote, "HEAD:#{branch}")

      File.binwrite(File.join(worker, "cask"), "intended update\n")
      assert_git_success git("-C", worker, "commit", "-am", "update")
      race_result = git("-C", worker, "push", "--force-with-lease=#{branch}:", remote, "HEAD:#{branch}")
      refute race_result.status.success?, "empty-expectation lease must reject a creation race"

      remote_sha = git("ls-remote", remote, branch).stdout.split.first
      assert_match(/\A[0-9a-f]{40}\z/, remote_sha)
      assert_git_success git(
        "-C", worker, "push", "--force-with-lease=#{branch}:#{remote_sha}", remote, "HEAD:#{branch}"
      )
    end
  end

  private

  Result = Struct.new(:stdout, :stderr, :status, keyword_init: true)

  def run_updater(tag: TAG, release:, checksums:, output:)
    arguments = [
      RbConfig.ruby,
      SCRIPT,
      "--release-json", release,
      "--checksums", checksums,
      "--output", output,
    ]
    arguments.concat(["--tag", tag]) if tag
    stdout, stderr, status = Open3.capture3(*arguments)
    Result.new(stdout: stdout, stderr: stderr, status: status)
  end

  def run_live_updater(environment, tag: nil, output:)
    arguments = [RbConfig.ruby, SCRIPT, "--output", output]
    arguments.concat(["--tag", tag]) if tag
    stdout, stderr, status = Open3.capture3(environment, *arguments)
    Result.new(stdout: stdout, stderr: stderr, status: status)
  end

  def with_files(release_change: nil, release_contents: nil, checksum_contents: nil)
    Dir.mktmpdir do |dir|
      release = File.join(dir, "release.json")
      checksums = File.join(dir, "SHA256SUMS")
      output = File.join(dir, "psyche-build.rb")

      json = JSON.parse(File.binread(RELEASE_FIXTURE))
      release_change&.call(json)
      File.binwrite(release, release_contents || JSON.pretty_generate(json))
      File.binwrite(checksums, checksum_contents || File.binread(CHECKSUM_FIXTURE))
      yield release, checksums, output
    end
  end

  def with_fake_curl(mode: "success", token: nil)
    Dir.mktmpdir do |dir|
      bin = File.join(dir, "bin")
      Dir.mkdir(bin)
      curl = File.join(bin, "curl")
      log = File.join(dir, "curl.log")
      output = File.join(dir, "psyche-build.rb")
      File.binwrite(curl, fake_curl_script)
      File.chmod(0o700, curl)
      File.symlink("/usr/bin/uname", File.join(bin, "uname"))

      environment = {
        "PATH" => bin,
        "FAKE_CURL_LOG" => log,
        "FAKE_CURL_MODE" => mode,
        "FAKE_RELEASE_JSON" => RELEASE_FIXTURE,
        "FAKE_CHECKSUMS" => CHECKSUM_FIXTURE,
        "GITHUB_TOKEN" => token,
      }
      yield environment, log, output
    end
  end

  def fake_curl_script
    <<~'BASH'
      #!/bin/bash
      set -euo pipefail

      config="$(/bin/cat)"
      url="${!#}"
      authenticated=false
      if [[ -n "$config" ]]; then
        expected="header = \"Authorization: Bearer ${GITHUB_TOKEN:-}\""
        if [[ -z "${GITHUB_TOKEN:-}" || "$config" != "$expected" ]]; then
          echo "invalid auth config" >&2
          exit 90
        fi
        authenticated=true
      fi
      if [[ "$url" != https://api.github.com/* && "$authenticated" == true ]]; then
        echo "auth supplied to non-API request" >&2
        exit 91
      fi

      {
        printf '%s\t%s\t' "$url" "$authenticated"
        printf '%q ' "$@"
        printf '\n'
      } >> "$FAKE_CURL_LOG"

      case "${FAKE_CURL_MODE:-success}:$url" in
        fail_api:https://api.github.com/*)
          echo "simulated curl API failure" >&2
          exit 22
          ;;
        fail_checksums:*\/SHA256SUMS)
          echo "simulated curl checksum failure ${GITHUB_TOKEN:-}" >&2
          exit 22
          ;;
        non_200_arm:*aarch64.dmg)
          printf '503'
          exit 0
          ;;
      esac

      case "$url" in
        https://api.github.com/repos/OpenCoven/psyche-build/releases/latest|https://api.github.com/repos/OpenCoven/psyche-build/releases/tags/v0.0.1)
          /bin/cat "$FAKE_RELEASE_JSON"
          ;;
        https://github.com/OpenCoven/psyche-build/releases/download/v0.0.1/SHA256SUMS)
          /bin/cat "$FAKE_CHECKSUMS"
          ;;
        https://github.com/OpenCoven/psyche-build/releases/download/v0.0.1/Psyche-Build-v0.0.1-aarch64.dmg|https://github.com/OpenCoven/psyche-build/releases/download/v0.0.1/Psyche-Build-v0.0.1-x86_64.dmg)
          printf '200'
          ;;
        *)
          echo "unexpected URL" >&2
          exit 92
          ;;
      esac
    BASH
  end

  def fake_curl_requests(log)
    File.readlines(log).map do |line|
      url, authenticated, arguments = line.chomp.split("\t", 3)
      { url: url, authenticated: authenticated == "true", arguments: arguments }
    end
  end

  def parse_workflow(path)
    Psych.safe_load(
      File.binread(path),
      permitted_classes: [],
      permitted_symbols: [],
      aliases: true,
    )
  end

  def workflow_steps(parsed)
    parsed.fetch("jobs").values.flat_map { |job| job.fetch("steps") }
  end

  def run_bash_step(script, environment)
    stdout, stderr, status = Open3.capture3(environment, "bash", "--noprofile", "--norc", "-euo", "pipefail", "-c", script)
    Result.new(stdout: stdout, stderr: stderr, status: status)
  end

  def assert_success(result)
    assert result.status.success?, "expected success, got #{result.status.exitstatus}: #{result.stderr}"
  end

  def assert_failure(result, message, label = nil)
    refute result.status.success?, "expected failure#{" for #{label}" if label}"
    assert_match message, result.stderr, "unexpected error#{" for #{label}" if label}"
  end

  def git(*arguments)
    stdout, stderr, status = Open3.capture3("git", *arguments)
    Result.new(stdout: stdout, stderr: stderr, status: status)
  end

  def configure_git(repository)
    assert_git_success git("-C", repository, "config", "user.name", "Updater Test")
    assert_git_success git("-C", repository, "config", "user.email", "updater@example.invalid")
  end

  def assert_git_success(result)
    assert result.status.success?, "git failed: #{result.stderr}"
  end
end
