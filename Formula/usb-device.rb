class UsbDevice < Formula
  desc "CLI tool for managing named USB devices on macOS"
  homepage "https://github.com/m-mcgowan/usb-device"
  url "https://github.com/m-mcgowan/usb-device/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "3c3d9828a7fb85ce7366e7018ad6f4bbd974ec10bd0e396a6989fcc87e268915"
  license "MIT"
  version "0.1.0"

  depends_on "uhubctl"
  depends_on "jq"
  depends_on "python@3"

  resource "pyserial" do
    url "https://github.com/m-mcgowan/usb-device/archive/refs/tags/v0.1.0.tar.gz"
    sha256 "3c3d9828a7fb85ce7366e7018ad6f4bbd974ec10bd0e396a6989fcc87e268915"
  end

  def install
    # Create Python venv with pyserial
    venv = libexec/"venv"
    system Formula["python@3"].opt_bin/"python3", "-m", "venv", venv
    venv_pip = venv/"bin/pip"
    resource("pyserial").stage do
      system venv_pip, "install", "."
    end

    # Install all scripts and support files to libexec
    libexec.install "usb-device", "serial-monitor", "hub-agent"
    libexec.install "hub_agent.py", "serial_monitor.py", "iokit_usb.py"
    libexec.install "VERSION", "LICENSE", "README.md", "DESIGN.md"
    libexec.install "devices.conf.example"
    libexec.install "setup.sh", "install.sh"
    (libexec/"types.d").install Dir["types.d/*"]

    # Patch Python scripts to use venv python
    inreplace libexec/"serial-monitor", '#!/bin/bash', "#!/bin/bash\n# Homebrew venv python"
    inreplace libexec/"hub-agent", '#!/bin/bash', "#!/bin/bash\n# Homebrew venv python"

    # Create wrapper scripts that set SCRIPT_DIR and use venv python
    (bin/"usb-device").write_env_script libexec/"usb-device", PATH: "#{venv}/bin:#{Formula["uhubctl"].opt_bin}:${PATH}"
    (bin/"serial-monitor").write_env_script libexec/"serial-monitor", PATH: "#{venv}/bin:${PATH}"
    (bin/"hub-agent").write_env_script libexec/"hub-agent", PATH: "#{venv}/bin:${PATH}"
  end

  def post_install
    # Create config directory if it doesn't exist
    config_dir = Pathname.new("#{Dir.home}/.config/usb-devices")
    config_dir.mkpath
    (config_dir/"types.d").mkpath

    unless (config_dir/"devices.conf").exist?
      cp libexec/"devices.conf.example", config_dir/"devices.conf"
    end

    unless (config_dir/"locations.json").exist?
      (config_dir/"locations.json").write("{}")
    end
  end

  test do
    assert_match "usb-device #{version}", shell_output("#{bin}/usb-device version")
  end
end
