#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"
require "optparse"
require "tempfile"
require "uri"

class PsycheBuildCaskUpdater
  class Error < StandardError; end

  REPOSITORY = "OpenCoven/psyche-build"
  DOWNLOAD_ROOT = "https://github.com/#{REPOSITORY}/releases/download"
  API_ROOT = "https://api.github.com/repos/#{REPOSITORY}/releases"
  STABLE_TAG = /\Av(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\z/.freeze
  ARCHITECTURES = %w[aarch64 x86_64].freeze

  def initialize(tag:, release_json_path:, checksums_path:, output_path:)
    @requested_tag = tag
    @release_json_path = release_json_path
    @checksums_path = checksums_path
    @output_path = output_path
  end

  def run
    validate_fixture_options!
    validate_tag!(@requested_tag) if @requested_tag

    release = JSON.parse(release_json)
    tag = @requested_tag || release["tag_name"]
    validate_tag!(tag)
    validate_release!(release, tag)

    version = tag.delete_prefix("v")
    names = expected_names(version)
    asset_digests = validate_assets!(release.fetch("assets"), tag, names)

    sums = parse_checksums(checksums(tag), names.values)
    sums.each do |name, checksum|
      next if checksum == asset_digests.fetch(name)

      raise Error, "checksum for #{name} does not match its release asset digest"
    end
    verify_downloads!(tag, names) unless fixture_mode?
    write_atomically(render(version, sums))

    puts "rendered #{@output_path} for #{tag}"
    true
  rescue Error, JSON::ParserError, KeyError, TypeError => e
    warn "error: #{e.message}"
    false
  end

  private

  def fixture_mode?
    !@release_json_path.nil?
  end

  def validate_fixture_options!
    if @release_json_path.nil? != @checksums_path.nil?
      raise Error, "--release-json and --checksums must be provided together"
    end
  end

  def validate_tag!(tag)
    return if tag.is_a?(String) && STABLE_TAG.match?(tag)

    raise Error, "tag '#{tag}' is not a stable vMAJOR.MINOR.PATCH release tag"
  end

  def release_json
    return File.binread(@release_json_path) if fixture_mode?

    endpoint = if @requested_tag
                 "#{API_ROOT}/tags/#{URI.encode_www_form_component(@requested_tag)}"
               else
                 "#{API_ROOT}/latest"
               end
    curl(endpoint, api: true)
  rescue Errno::ENOENT, Errno::EACCES => e
    raise Error, "cannot read release JSON: #{e.message}"
  end

  def validate_release!(release, tag)
    raise Error, "release JSON must be an object" unless release.is_a?(Hash)
    unless release["tag_name"] == tag
      raise Error, "release tag #{release['tag_name'].inspect} does not match requested tag #{tag.inspect}"
    end
    unless release["draft"] == false && release["prerelease"] == false &&
           release["published_at"].is_a?(String) && !release["published_at"].empty?
      raise Error, "release must be a non-draft, non-prerelease published stable release"
    end
    raise Error, "release assets must be an array" unless release["assets"].is_a?(Array)
  end

  def expected_names(version)
    ARCHITECTURES.to_h do |arch|
      [arch, "Psyche-Build-v#{version}-#{arch}.dmg"]
    end
  end

  def validate_assets!(assets, tag, names)
    expected_asset_names = names.values + ["SHA256SUMS"]
    unless assets.length == 3 &&
           assets.all? { |asset| asset.is_a?(Hash) && asset["name"].is_a?(String) } &&
           assets.map { |asset| asset["name"] }.sort == expected_asset_names.sort
      raise Error, "release must contain exactly three expected assets"
    end

    unless assets.all? { |asset| fully_uploaded?(asset) }
      raise Error, "release assets must be fully uploaded and nonempty"
    end

    expected_urls = names.values.to_h do |name|
      [name, "#{DOWNLOAD_ROOT}/#{tag}/#{name}"]
    end
    expected_urls["SHA256SUMS"] = "#{DOWNLOAD_ROOT}/#{tag}/SHA256SUMS"
    assets.each do |asset|
      next if asset["browser_download_url"] == expected_urls.fetch(asset["name"])

      raise Error, "unexpected download URL for #{asset['name']}"
    end

    names.values.to_h do |name|
      asset = assets.find { |candidate| candidate["name"] == name }
      digest = asset["digest"]
      match = /\Asha256:([0-9a-f]{64})\z/.match(digest) if digest.is_a?(String)
      raise Error, "invalid release asset digest for #{name}" unless match

      [name, match[1]]
    end
  end

  def fully_uploaded?(asset)
    asset["state"] == "uploaded" && asset["size"].is_a?(Integer) && asset["size"].positive?
  end

  def checksums(tag)
    return File.binread(@checksums_path) if fixture_mode?

    curl("#{DOWNLOAD_ROOT}/#{tag}/SHA256SUMS")
  rescue Errno::ENOENT, Errno::EACCES => e
    raise Error, "cannot read checksums: #{e.message}"
  end

  def parse_checksums(contents, expected_names)
    lines = contents.each_line.map(&:chomp)
    entries = lines.map do |line|
      match = /\A([0-9a-f]{64})  ([^\s]+)\z/.match(line)
      raise Error, "malformed checksum line: #{line.inspect}" unless match

      [match[2], match[1]]
    end

    unless entries.length == expected_names.length && entries.map(&:first).sort == expected_names.sort
      raise Error, "checksum entries must contain exactly the two expected DMG filenames"
    end
    raise Error, "duplicate checksum entries are not allowed" unless entries.map(&:first).uniq.length == entries.length

    entries.to_h
  end

  def verify_downloads!(tag, names)
    names.each_value do |name|
      url = "#{DOWNLOAD_ROOT}/#{tag}/#{name}"
      status = curl(url, output: File::NULL, write_out: "%{http_code}")
      raise Error, "#{url} did not resolve HTTP 200 (got #{status.inspect})" unless status == "200"
    end
  end

  def curl(url, api: false, output: nil, write_out: nil)
    command = ["curl", "--fail-with-body", "--silent", "--show-error", "--location"]
    command.concat(["--header", "Accept: application/vnd.github+json"]) if api
    token = ENV["GITHUB_TOKEN"]
    command.concat(["--header", "Authorization: Bearer #{token}"]) if api && token && !token.empty?
    command.concat(["--output", output]) if output
    command.concat(["--write-out", write_out]) if write_out
    command << url

    stdout, stderr, status = Open3.capture3(*command)
    raise Error, "curl failed for #{url}: #{stderr.strip}" unless status.success?

    stdout
  rescue Errno::ENOENT
    raise Error, "curl is required for live updates"
  end

  def render(version, sums)
    <<~RUBY
      # frozen_string_literal: true

      cask "psyche-build" do
        arch arm: "aarch64", intel: "x86_64"

        version "#{version}"
        sha256 arm:   "#{sums.fetch("Psyche-Build-v#{version}-aarch64.dmg")}",
               intel: "#{sums.fetch("Psyche-Build-v#{version}-x86_64.dmg")}"

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
  end

  def write_atomically(contents)
    directory = File.dirname(@output_path)
    Tempfile.create(["psyche-build", ".rb"], directory) do |temporary|
      temporary.binmode
      temporary.write(contents)
      temporary.flush
      temporary.fsync
      File.chmod(0o644, temporary.path)
      File.rename(temporary.path, @output_path)
    end
  rescue SystemCallError => e
    raise Error, "cannot write #{@output_path}: #{e.message}"
  end
end

options = {
  tag: nil,
  release_json_path: nil,
  checksums_path: nil,
  output_path: File.expand_path("../Casks/psyche-build.rb", __dir__),
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: update-psyche-build-cask.rb [options]"
  opts.on("--tag TAG", "Stable release tag (vMAJOR.MINOR.PATCH)") { |tag| options[:tag] = tag }
  opts.on("--release-json PATH", "Read release metadata from PATH (offline)") do |path|
    options[:release_json_path] = path
  end
  opts.on("--checksums PATH", "Read SHA256SUMS from PATH (offline)") { |path| options[:checksums_path] = path }
  opts.on("--output PATH", "Write the rendered Cask to PATH") { |path| options[:output_path] = path }
end

begin
  parser.parse!
  raise OptionParser::InvalidOption, ARGV.join(" ") unless ARGV.empty?
rescue OptionParser::ParseError => e
  warn "error: #{e.message}"
  warn parser
  exit 2
end

updater = PsycheBuildCaskUpdater.new(**options)
exit(updater.run ? 0 : 1)
