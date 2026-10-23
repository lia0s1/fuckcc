
class Fuckcc < Formula
  desc "Process-local Claude Code locale camouflage + free offline prompt translation (macOS)"
  homepage "https://github.com/lia0s1/fuckcc"
  url "https://github.com/lia0s1/fuckcc/archive/refs/tags/v4.4.2.tar.gz"
  sha256 "41ea5f3bc34f43c599e1c2037f1a44cb0d64a8715049de8bcc89a4ae5cb26707"
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
