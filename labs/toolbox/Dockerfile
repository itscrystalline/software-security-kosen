# Software Security — lab toolbox (Docker-first; replaces the full Kali VM)
#
# A small Linux container with the dev/attacker tools that don't run cleanly on a
# Windows/macOS host: clang + libFuzzer + ASan, gdb, rustc, and recon tools. Used in
# Week 2 (fuzzing intro), Week 11 (memory-safety exploitation) and for optional
# recon in Weeks 4/10.
#
# Build:
#   docker build -t softsec-toolbox labs/toolbox
# Run (ptrace caps + relaxed seccomp so gdb/ASan work; mount your lab dir):
#   docker run -it --rm --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
#       -v "$PWD":/work -w /work softsec-toolbox
#
# silkeh/clang ships a working libFuzzer runtime (Apple clang does not), so
# `clang -fsanitize=address,fuzzer harness.c -o fuzz && ./fuzz` works here.
FROM silkeh/clang:19

RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc make \
        gdb \
        python3 python3-pip \
        nmap sqlmap \
        curl git vim less ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# rustc (Week 11 Task 4: safe.rs) — rustup rather than the apt package so the
# same Dockerfile gets a current, non-stale toolchain on both amd64 and arm64.
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
        | sh -s -- -y --profile minimal --default-toolchain stable \
    && rustc --version && cargo --version

# pwntools (Week 11 Task 2: exploit_skeleton.py) — installed here so no one
# builds the exploit without the offset/cyclic helpers pwntools provides.
RUN pip3 install --no-cache-dir --break-system-packages pwntools

WORKDIR /work
CMD ["/bin/bash"]
