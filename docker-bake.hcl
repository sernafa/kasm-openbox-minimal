group "default" {
  targets = ["openbox-1_0_0"]
}

group "all" {
  targets = [
    "openbox-1_0_0",
    "openbox-systemd-1_0_0",
    "openbox-trixie-1_0_0",
    "openbox-trixie-systemd-1_0_0",
  ]
}

target "openbox-1_0_0" {
  context = "."
  dockerfile = "Dockerfile"
  tags = ["sernafa/kasm-openbox-minimal:1.0.0"]
  args = {
    KASMVNC_COMMIT_ID = "582662953c819ade9ed4b620a5646546d8d7de7b"
    KASMVNC_BRANCH = "release"
    KASMVNC_VER = "1.5.1"
    PROFILE_SYNC_V2_COMMIT_ID = "506ba7a13d810b214fe76cb91e94abc7c559d8d7"
    PROFILE_SYNC_V2_BRANCH = "release_2.1.1"
  }
  no-cache = true
  platforms = ["linux/amd64"]
}

target "openbox-systemd-1_0_0" {
  context = "."
  dockerfile = "Dockerfile.systemd"
  tags = ["sernafa/kasm-openbox-minimal:1.0.0-systemd"]
  args = {
    BASE_IMAGE = "antmelekhin/docker-systemd:ubuntu-24.04"
    KASMVNC_COMMIT_ID = "582662953c819ade9ed4b620a5646546d8d7de7b"
    KASMVNC_BRANCH = "release"
    KASMVNC_VER = "1.5.1"
    PROFILE_SYNC_V2_COMMIT_ID = "506ba7a13d810b214fe76cb91e94abc7c559d8d7"
    PROFILE_SYNC_V2_BRANCH = "release_2.1.1"
  }
  no-cache = true
  platforms = ["linux/amd64"]
}

target "openbox-trixie-1_0_0" {
  context = "."
  dockerfile = "Dockerfile"
  tags = ["sernafa/kasm-openbox-minimal:1.0.0-trixie"]
  args = {
    KASMVNC_COMMIT_ID = "582662953c819ade9ed4b620a5646546d8d7de7b"
    KASMVNC_BRANCH = "release"
    KASMVNC_VER = "1.5.1"
    PROFILE_SYNC_V2_COMMIT_ID = "506ba7a13d810b214fe76cb91e94abc7c559d8d7"
    PROFILE_SYNC_V2_BRANCH = "release_2.1.1"
    BASE_IMAGE = "debian:trixie-slim"
    DISTRO = "debian"
  }
  no-cache = true
  platforms = ["linux/amd64"]
}

target "openbox-trixie-systemd-1_0_0" {
  context = "."
  dockerfile = "Dockerfile.systemd"
  tags = ["sernafa/kasm-openbox-minimal:1.0.0-trixie-systemd"]
  args = {
    KASMVNC_COMMIT_ID = "582662953c819ade9ed4b620a5646546d8d7de7b"
    KASMVNC_BRANCH = "release"
    KASMVNC_VER = "1.5.1"
    PROFILE_SYNC_V2_COMMIT_ID = "506ba7a13d810b214fe76cb91e94abc7c559d8d7"
    PROFILE_SYNC_V2_BRANCH = "release_2.1.1"
    BASE_IMAGE = "debian:trixie-slim"
    DISTRO = "debian"
  }
  no-cache = true
  platforms = ["linux/amd64"]
}
