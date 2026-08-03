# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "open3"
require "tmpdir"

class UpdatePsycheBuildCaskTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  SCRIPT = File.join(ROOT, "scripts/update-psyche-build-cask.rb")
  RELEASE_FIXTURE = File.join(__dir__, "fixtures/psyche-build-v0.0.1-release.json")
  CHECKSUM_FIXTURE = File.join(__dir__, "fixtures/psyche-build-v0.0.1-SHA256SUMS")
  CI_WORKFLOW = File.join(ROOT, ".github/workflows/ci.yml")
  UPDATE_WORKFLOW = File.join(ROOT, ".github/workflows/update-psyche-build-cask.yml")
  TAG = "v0.0.1"

  EXPECTED_CASK = <<~RUBY
    # frozen_string_literal: true

    cask "psyche-build" do
      arch arm: "aarch64", intel: "x86_64"

      version "0.0.1"
      sha256 arm:   "1111111111111111111111111111111111111111111111111111111111111111",
             intel: "2222222222222222222222222222222222222222222222222222222222222222"

      url "https://github.com/OpenCoven/psyche-build/releases/download/v\#{version}/Psyche-Build-v\#{version}-\#{arch}.dmg"
      name "Psyche Build"
      desc "Desktop app for building and managing OpenCoven psyche projects"
      homepage "https://github.com/OpenCoven/psyche-build"

      depends_on macos: :sonoma

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

  def test_requires_requested_tag_with_offline_fixtures
    with_files do |release, checksums, output|
      result = run_updater(tag: nil, release: release, checksums: checksums, output: output)
      assert_failure result, /--tag is required with fixture inputs/
      refute File.exist?(output)
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

  def test_requires_exactly_the_expected_dmg_assets
    cases = {
      "missing" => lambda do |json|
        json["assets"].reject! { |asset| asset["name"].end_with?("x86_64.dmg") }
      end,
      "duplicate" => lambda do |json|
        json["assets"] << json["assets"].find { |asset| asset["name"].end_with?("aarch64.dmg") }.dup
      end,
      "unexpected" => lambda do |json|
        json["assets"] << {
          "name" => "Psyche-Build-v0.0.1-universal.dmg",
          "browser_download_url" => "https://github.com/OpenCoven/psyche-build/releases/download/v0.0.1/Psyche-Build-v0.0.1-universal.dmg",
          "state" => "uploaded",
          "size" => 1,
        }
      end,
    }

    cases.each do |label, change|
      with_files(release_change: change) do |release, checksums, output|
        result = run_updater(release: release, checksums: checksums, output: output)
        assert_failure result, /exactly.*DMG assets/i, label
        refute File.exist?(output)
      end
    end
  end

  def test_requires_one_uploaded_nonempty_checksum_asset
    cases = {
      "missing" => ->(json) { json["assets"].reject! { |asset| asset["name"] == "SHA256SUMS" } },
      "duplicate" => lambda do |json|
        json["assets"] << json["assets"].find { |asset| asset["name"] == "SHA256SUMS" }.dup
      end,
      "uploading" => lambda do |json|
        json["assets"].find { |asset| asset["name"] == "SHA256SUMS" }["state"] = "new"
      end,
      "empty" => lambda do |json|
        json["assets"].find { |asset| asset["name"] == "SHA256SUMS" }["size"] = 0
      end,
    }

    cases.each do |label, change|
      with_files(release_change: change) do |release, checksums, output|
        result = run_updater(release: release, checksums: checksums, output: output)
        assert_failure result, /SHA256SUMS.*uploaded/i, label
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

  def test_ci_launches_the_exact_app_path_and_always_cleans_up
    workflow = File.binread(CI_WORKFLOW)

    assert_includes workflow, 'open -n "/Applications/Psyche Build.app"'
    refute_includes workflow, 'open -na "/Applications/Psyche Build.app"'
    assert_match(/- name: Clean up Psyche Build\n\s+if: always\(\)/, workflow)
  end

  def test_update_workflow_handles_new_and_existing_bot_branches_safely
    workflow = File.binread(UPDATE_WORKFLOW)

    assert_includes workflow, "git ls-files --error-unmatch Casks/psyche-build.rb"
    assert_includes workflow, "git ls-remote --exit-code --heads origin"
    assert_includes workflow, '--force-with-lease="refs/heads/$BRANCH:$remote_sha"'
    assert_includes workflow, 'git push origin "HEAD:refs/heads/$BRANCH"'
    refute_match(/git fetch .*\|\| true/, workflow)
    refute_match(/git push .*HEAD:main/, workflow)
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

  def with_files(release_change: nil, checksum_contents: nil)
    Dir.mktmpdir do |dir|
      release = File.join(dir, "release.json")
      checksums = File.join(dir, "SHA256SUMS")
      output = File.join(dir, "psyche-build.rb")

      json = JSON.parse(File.binread(RELEASE_FIXTURE))
      release_change&.call(json)
      File.binwrite(release, JSON.pretty_generate(json))
      File.binwrite(checksums, checksum_contents || File.binread(CHECKSUM_FIXTURE))
      yield release, checksums, output
    end
  end

  def assert_success(result)
    assert result.status.success?, "expected success, got #{result.status.exitstatus}: #{result.stderr}"
  end

  def assert_failure(result, message, label = nil)
    refute result.status.success?, "expected failure#{" for #{label}" if label}"
    assert_match message, result.stderr, "unexpected error#{" for #{label}" if label}"
  end
end
