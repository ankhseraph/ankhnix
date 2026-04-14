{ ... }:

{
  programs.git = {
    enable = true;
    settings.user = {
      name = "ankhseraph";
      email = "git@ankhseraph.com";
    };
  };
}
