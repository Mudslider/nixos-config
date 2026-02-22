# ── Audio (PipeWire) ─────────────────────────────────────────────
{ ... }:
{
  # Disable PulseAudio (PipeWire replaces it)
  services.pulseaudio.enable = false;

  # Enable real-time scheduling for audio
  security.rtkit.enable = true;

  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;       # PulseAudio compatibility
    # jack.enable     = true;       # uncomment for JACK apps
  };
}
