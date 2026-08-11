
class Fuckcc < Formula
  desc "Process-local Claude Code locale camouflage + free offline prompt translation (macOS)"
  homepage "https://github.com/lia0s1/fuckcc"
  url "https://github.com/lia0s1/fuckcc/archive/refs/tags/v4.4.2.tar.gz"
  sha256 "66c03600eec4a1405c9b48e4d0eefa206b4e8162af476ae5d893c0eaed97302e"
  license "MIT"
  version "4.4.2"
  head "https://github.com/lia0s1/fuckcc.git", branch: "main"

  depends_on "python@3.12"
  depends_on "node"
  depends_on :macos

  def install
    libexec.install Dir["*"]

    (bin/"fuckcc").write <<~EOS
      set -euo pipefail
      export FUCKCC_PREFIX="#{libexec}"
      export FUCKCC_HOME="${FUCKCC_HOME:-${HOME}/.fuckcc}"
      exec bash "#{libexec}/fuckcc" "$@"
    EOS
    chmod 0755, bin/"fuckcc"
  end

  def caveats
    <<~EOS
      First-time setup:
        fuckcc install
        fuckcc hide 3
        fuckcc translate-setup
        fuckcc translate-daemon-start

      Optional control panel:
        cd $(brew --prefix)/opt/fuckcc/libexec && ./ui/build_app.sh

      Ensure ~/.local/bin or Homebrew bin is on your PATH.
    EOS
  end

  test do
    assert_match "fuckcc", shell_output("#{bin}/fuckcc version")
  end
end
