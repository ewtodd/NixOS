{ inputs, ... }:
let unstable = import inputs.unstable { system = "x86_64-linux"; };
in {
  services.hyprsunset = {
    enable = true;
    package = unstable.hypridle;
    transitions = {
      sunrise = {
        calendar = "*-*-* 06:00:00";
        requests = [[ "temperature" "6500" ]];
      };
      sunset = {
        calendar = "*-*-* 19:00:00";
        requests = [[ "temperature" "4750" ]];
      };
    };
  };
}
