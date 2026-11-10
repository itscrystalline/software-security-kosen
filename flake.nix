{
  description = "Software Security 2 — course toolchain (labs, live-quiz platform, security scanners)";
  inputs = {
    # Reproducible toolchain for everything in this repo that is *not* a
    # deliberately vulnerable container image. Enter with `nix develop` (or let
    # direnv do it via .envrc).
    #
    # Linux only on purpose: Week 11 needs ptrace, ELF linking flags (-no-pie,
    # -z execstack) and `setarch -R`, none of which exist on macOS/Windows.
    # Windows/macOS students follow Lab 0 in labs/week01-threat-modeling/README.md
    # (Docker Desktop) and run this flake inside WSL2 if they want it locally.
    #
    # Host-side prerequisites this flake cannot provide:
    #   - a Docker daemon (the flake ships the CLI + Compose plugin, not dockerd)
    #   - Burp Suite Community or OWASP ZAP (GUI; Burp is proprietary, ZAP is not
    #     packaged in nixpkgs — install either from the vendor)
    #   - WireGuard kernel support/root for docs/arena-vpn-guide.md

    # Stable, not unstable: semgrep-core 1.180.0 (unstable, Oct 2026) fails to build
    # — patchelf assertion in fixupPhase, Hydra can't build it either
    # (NixOS/nixpkgs#579107). nixos-26.05 ships semgrep 1.161.0 with cache coverage.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    omp.url = "github:bjin/oh-my-pi.nix";
  };

  nixConfig = {
    substituters = ["https://cache.nixos.org" "https://oh-my-pi.cachix.org"];
    extra-trusted-public-keys = "oh-my-pi.cachix.org-1:FRLFzcZnCIB2GfSpDkgHsl8uGa1zDrx1F+bBlVIy7Wo=";
  };

  outputs = {
    self,
    nixpkgs,
    omp,
  }: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
  in {
    devShells = forAllSystems (
      pkgs: let
        # Mirrors labs/live-quiz/requirements.txt plus what the test suite and
        # the Week 11 exploit/fuzz scripts import. nixpkgs flask is 3.1.2 while
        # the requirements pin allows >=3.1.3; if a version-sensitive bug shows
        # up, use the pip path CI uses:
        #   python -m venv .venv && .venv/bin/pip install -r labs/live-quiz/requirements.txt pytest
        python = pkgs.python312.withPackages (
          ps:
            with ps; [
              bcrypt
              cryptography
              defusedcsv
              eventlet
              flask
              flask-socketio
              markupsafe
              pip
              pwntools
              pycryptodome
              pytest
              requests

              # documents — worksheets/exams authored or generated as .docx
              # (slides/pptx is already .pptx in this repo)
              mammoth
              openpyxl
              python-docx
              python-pptx
            ]
        );
      in {
        default = pkgs.mkShell {
          name = "software-security-2";

          packages = [
            # --- core ---
            python
            pkgs.git
            pkgs.gh
            pkgs.curl
            pkgs.jq
            pkgs.yq-go
            pkgs.gnumake
            pkgs.openssl

            # --- C / memory safety (Week 2 fuzzing, Week 11 exploitation) ---
            pkgs.gcc
            pkgs.clang # ships the libFuzzer runtime
            pkgs.llvm
            pkgs.binutils
            pkgs.gdb
            pkgs.aflplusplus
            pkgs.checksec
            pkgs.rustc
            pkgs.cargo

            # --- web / API testing (Weeks 4, 5, 6, 10) ---
            pkgs.ffuf
            pkgs.mitmproxy # scriptable proxy fallback for Burp/ZAP
            pkgs.nikto
            pkgs.nmap
            pkgs.sqlmap

            # --- crypto (Week 3) ---
            pkgs.hashcat
            pkgs.john

            # --- supply chain + DevSecOps (Weeks 12, 15) ---
            pkgs.semgrep
            pkgs.gitleaks
            pkgs.trivy
            pkgs.cosign
            pkgs.syft
            pkgs.grype

            # --- documents (.docx worksheets/exams, .pptx slides) ---
            pkgs.pandoc # markdown <-> docx
            pkgs.libreoffice-fresh # soffice --convert-to pdf/docx (headless editing/rendering)
            pkgs.poppler-utils # pdftotext/qpdf for verifying rendered output

            # --- containers / orchestration (Weeks 13, 15) ---
            pkgs.docker-client
            pkgs.docker-compose
            pkgs.kubectl
            pkgs.kind

            # omp
            omp.packages.${pkgs.stdenv.hostPlatform.system}.oh-my-pi
          ];
        };
      }
    );
  };
}
