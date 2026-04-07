{ ... }:

{
  programs.git = {
    enable = true;
    settings.user = {
      name = "ankhseraph";
      email = "homeserver@ankhseraph.git";
    };
  };
}
