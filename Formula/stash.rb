class Stash < Formula
  desc "Bidirectionally sync Markdown files with Apple Notes"
  homepage "https://github.com/shakedlokits/stash"
  url "https://github.com/shakedlokits/stash/releases/download/v0.2.0/stash"
  sha256 "b27ec3eaf9428a363673f1f57c3ee2aa4b83e72b396622a5452fd750699b245f"
  license "GPL-3.0-or-later"

  depends_on "pandoc"
  depends_on "bash"
  depends_on :macos

  def install
    bin.install "stash" => "stash.bin"

    (bin/"stash").write <<~EOS
      #!/bin/bash
      exec "#{Formula["bash"].opt_bin}/bash" "#{bin}/stash.bin" "$@"
    EOS
    chmod 0755, bin/"stash"
  end

  test do
    assert_match "stash", shell_output("#{bin}/stash --help")
  end
end
