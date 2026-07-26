class Hister < Formula
  desc "Personal search engine over your browsing history and local files"
  homepage "https://hister.org/"
  url "https://github.com/asciimoo/hister/archive/refs/tags/v0.16.0.tar.gz"
  sha256 "fd7373b2bfa6fbec4fe622a8f611c661399b1a5ad38cdc2351ab2feb8fca36b1"
  license "AGPL-3.0-or-later"
  head "https://github.com/asciimoo/hister.git", branch: "master"

  depends_on "go" => :build
  depends_on "node" => :build

  def install
    # Equivalent of `go generate`, which shells out to webui/build.sh: the web UI
    # is not committed, but server/static/static.go does `go:embed all:app/*`, so
    # the Go build fails unless the frontend is built and copied into place first.
    system "npm", "ci", "--include=optional"
    system "npm", "run", "build", "-w", "@hister/app"
    (buildpath/"server/static/app").install Dir[buildpath/"webui/app/build/*"]

    system "go", "build", *std_go_args(ldflags: "-s -w"), "-tags", "netgo,osusergo"

    generate_completions_from_executable(bin/"hister", "completion")
  end

  service do
    run [opt_bin/"hister", "listen"]
    keep_alive successful_exit: false
    run_type :immediate
    log_path var/"log/hister.log"
    error_log_path var/"log/hister.log"
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
