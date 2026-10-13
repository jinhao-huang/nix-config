{ incomingEnabled, sshEnabled }:
{
  version = "alpha0";
  locked = true;
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
