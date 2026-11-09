{
  incomingEnabled,
  sshEnabled,
  serveEnabled,
}:
{
  version = "alpha0";
  # The runtime mapping API is unavailable while preferences are locked.
  locked = !serveEnabled;
  enabled = true;
  acceptDNS = false;
  acceptRoutes = false;
  runSSHServer = sshEnabled;
  runWebClient = false;
  shieldsUp = !incomingEnabled;
  exitNode = "";
  advertiseRoutes = [ ];
  autoUpdate = {
    check = false;
    apply = false;
  };
}
