class Hister < Formula
  desc "Personal search engine over your browsing history and local files"
  homepage "https://hister.org/"
  version "0.16.0"
  license "AGPL-3.0-or-later"

  livecheck do
    url :stable
    strategy :github_latest
  end

  # Upstream ships prebuilt binaries; building from source needs Go 1.26, npm
  # and a C compiler for the CGO deps, so we install the release artefact.
  on_macos do
    on_arm do
      url "https://github.com/asciimoo/hister/releases/download/v0.16.0/hister_0.16.0_darwin_arm64"
      sha256 "c99a90063a7e5a3fb4e392195bc33a901c14bebee04641ff294d1d019bf31f7e"
    end
    on_intel do
      url "https://github.com/asciimoo/hister/releases/download/v0.16.0/hister_0.16.0_darwin_amd64"
      sha256 "131c3b1503463da35c444b735bdc51a3e5a679248cabdfd9b9ede7418ed4fc03"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/asciimoo/hister/releases/download/v0.16.0/hister_0.16.0_linux_arm64"
      sha256 "78ed5fa53105ef801d3f8e2ba497ea703097df0f34430275522f0183cefaa7cd"
    end
    on_intel do
      url "https://github.com/asciimoo/hister/releases/download/v0.16.0/hister_0.16.0_linux_amd64"
      sha256 "77a840569710cd8245676d5a55c0c210be00b329630362fcf51fe675dc086406"
    end
  end

  def install
    bin.install Dir["hister_*"].first => "hister"
    # The release artefact is a bare binary, not an archive, so it arrives 0644.
    chmod 0755, bin/"hister"
    generate_completions_from_executable(bin/"hister", "completion")
  end

  # Mirrors upstream's launchd agent (nix/darwin.nix): `hister listen`, restarted
  # unless it exits cleanly. Upstream also sets KeepAlive/Crashed, but Homebrew's
  # plist writer is an if/elsif over the keep_alive keys and emits only the first
  # match — and SuccessfulExit:false subsumes Crashed anyway, since launchd counts
  # a crash as an unsuccessful exit.
  #
  # No working_dir on purpose: --config defaults to the *relative* path
  # "config.yml", so leaving the working directory at launchd's default keeps
  # lookup on hister's documented search paths rather than picking up whatever
  # config.yml happens to sit in the current directory.
  service do
    run [opt_bin/"hister", "listen"]
    keep_alive successful_exit: false
    run_type :immediate
    log_path var/"log/hister.log"
    error_log_path var/"log/hister.log"
  end

  def caveats
    <<~EOS
      The web UI listens on http://127.0.0.1:4433 once the service is running:
        brew services start hister

      No config file is needed for a personal setup; data lands in
        #{Dir.home}/Library/Application Support/hister
      To customise (listen address, indexed directories, embeddings endpoint):
        hister create-config "#{Dir.home}/Library/Preferences/hister/config.yml"

      Indexing pages you visit needs the browser extension:
        https://hister.org/docs/browser-extension
      Or seed the index from existing browser history:
        hister import-browser
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/hister --version")

    port = free_port
    config = testpath/"config.yml"
    (testpath/"data").mkpath
    config.write <<~YAML
      server:
        address: 127.0.0.1:#{port}
      app:
        directory: #{testpath}/data
    YAML

    pid = spawn bin/"hister", "listen", "--config", config
    begin
      sleep 5
      assert_match "<html", shell_output("curl -sL http://127.0.0.1:#{port}/")
    ensure
      Process.kill "TERM", pid
      Process.wait pid
    end
  end
end
