# Lab toolbox (Docker-first)

Most labs run as their own containers (`docker compose up`). A few weeks need a **Linux
dev/attacker shell** with tools that don't run cleanly on a Windows/macOS host:

- **Week 2 (fuzzing intro)** and **Week 11 (memory safety):** `clang` + **libFuzzer** + ASan
  (+ `gdb`, `rustc`, `pwntools` in Week 11). Apple clang ships no libFuzzer runtime, `gdb` is
  painful on macOS, and Rust/pwntools aren't assumed to be on your host, so use this container.
- **Weeks 4 / 10 (optional recon):** `nmap`, `sqlmap`.

This replaces the full Kali VM for those weeks. (A VM is still a fine optional fallback if your
host can't run Docker.)

## Build (once, from the repo root)
```bash
docker build -t softsec-toolbox labs/toolbox
```

## Run (from the week's folder, which is mounted at /work)
Week 2 needs no extra flags:
```bash
cd labs/week02-sdlc-tooling
docker run -it --rm -v "$PWD":/work -w /work softsec-toolbox
# inside the container:
clang -g -fsanitize=address,fuzzer harness.c -o fuzz && mkdir -p corpus && printf 'FUZ' > corpus/seed && ./fuzz corpus
# -> ERROR: AddressSanitizer: heap-buffer-overflow ... harness.c:23:21
```

Week 11 adds `--cap-add=SYS_PTRACE` + relaxed seccomp so `gdb` and ASan work:
```bash
cd labs/week11-memory-safety-exploitation
docker run -it --rm --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
    -v "$PWD":/work -w /work softsec-toolbox
# inside: clang -g -fsanitize=address,fuzzer fuzz_harness.c -o fuzz && ./fuzz
```

**Identity stamp:** take it in a terminal on your laptop, not in this container. Inside the
container `whoami` prints `root` and `date` prints UTC, which identifies nobody.

On Windows, run these from WSL (Ubuntu) rather than Git Bash.

Includes: clang 19 + libFuzzer/ASan, gdb, rustc (stable, via rustup) + cargo, Python 3 with
pwntools pre-installed, nmap, sqlmap, git, curl.
