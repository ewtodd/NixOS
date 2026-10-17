# GPU dashboard. Two sources:
#   - AMD GPUs: node_exporter's hwmon collector (already enabled fleet-wide).
#     amdgpu exposes temp1/2/3 = edge/junction/mem plus fan RPM and PPT power;
#     the human-readable sensor names come from node_hwmon_sensor_label, joined
#     back onto the value series. Chips are identified by PCI address (the
#     `pci` label, extracted from the sanitized hwmon chip path).
#   - WireView Pro II power monitor on e-desktop (moved here from fleet-health).
{
  annotations = {
    list = [ ];
  };
  editable = true;
  panels = [
    {
      collapsed = false;
      gridPos = {
        h = 1;
        w = 24;
        x = 0;
        y = 0;
      };
      id = 1;
      panels = [ ];
      title = "AMD GPUs (hwmon)";
      type = "row";
    }
    {
      datasource = {
        type = "prometheus";
        uid = "prometheus";
      };
      fieldConfig = {
        defaults = {
          color = {
            mode = "thresholds";
          };
          thresholds = {
            mode = "absolute";
            steps = [
              {
                color = "green";
                value = null;
              }
              {
                color = "yellow";
                value = 80;
              }
              {
                color = "red";
                value = 95;
              }
            ];
          };
          unit = "celsius";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 6;
        w = 6;
        x = 0;
        y = 1;
      };
      id = 2;
      options = {
        colorMode = "background";
        graphMode = "area";
        reduceOptions = {
          calcs = [
            "lastNotNull"
          ];
          fields = "";
          values = false;
        };
        textMode = "value";
      };
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "max(node_hwmon_temp_celsius{instance=~\"$instance\"} * on (instance, chip, sensor) group_left (label) node_hwmon_sensor_label{instance=~\"$instance\", label=\"edge\"})";
          instant = true;
          legendFormat = "edge";
          refId = "A";
        }
      ];
      title = "Max edge temp";
      type = "stat";
    }
    {
      datasource = {
        type = "prometheus";
        uid = "prometheus";
      };
      fieldConfig = {
        defaults = {
          color = {
            mode = "thresholds";
          };
          thresholds = {
            mode = "absolute";
            steps = [
              {
                color = "green";
                value = null;
              }
              {
                color = "yellow";
                value = 90;
              }
              {
                color = "red";
                value = 100;
              }
            ];
          };
          unit = "celsius";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 6;
        w = 6;
        x = 6;
        y = 1;
      };
      id = 3;
      options = {
        colorMode = "background";
        graphMode = "area";
        reduceOptions = {
          calcs = [
            "lastNotNull"
          ];
          fields = "";
          values = false;
        };
        textMode = "value";
      };
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "max(node_hwmon_temp_celsius{instance=~\"$instance\"} * on (instance, chip, sensor) group_left (label) node_hwmon_sensor_label{instance=~\"$instance\", label=\"junction\"})";
          instant = true;
          legendFormat = "junction";
          refId = "A";
        }
      ];
      title = "Max junction temp";
      type = "stat";
    }
    {
      datasource = {
        type = "prometheus";
        uid = "prometheus";
      };
      fieldConfig = {
        defaults = {
          color = {
            mode = "thresholds";
          };
          thresholds = {
            mode = "absolute";
            steps = [
              {
                color = "green";
                value = null;
              }
              {
                color = "yellow";
                value = 90;
              }
              {
                color = "red";
                value = 100;
              }
            ];
          };
          unit = "celsius";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 6;
        w = 6;
        x = 12;
        y = 1;
      };
      id = 4;
      options = {
        colorMode = "background";
        graphMode = "area";
        reduceOptions = {
          calcs = [
            "lastNotNull"
          ];
          fields = "";
          values = false;
        };
        textMode = "value";
      };
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "max(node_hwmon_temp_celsius{instance=~\"$instance\"} * on (instance, chip, sensor) group_left (label) node_hwmon_sensor_label{instance=~\"$instance\", label=\"mem\"})";
          instant = true;
          legendFormat = "mem";
          refId = "A";
        }
      ];
      title = "Max memory temp";
      type = "stat";
    }
    {
      datasource = {
        type = "prometheus";
        uid = "prometheus";
      };
      fieldConfig = {
        defaults = {
          color = {
            fixedColor = "text";
            mode = "fixed";
          };
          unit = "watt";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 6;
        w = 6;
        x = 18;
        y = 1;
      };
      id = 5;
      options = {
        colorMode = "none";
        graphMode = "area";
        reduceOptions = {
          calcs = [
            "lastNotNull"
          ];
          fields = "";
          values = false;
        };
        textMode = "value";
      };
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "sum(node_hwmon_power_average_watt{instance=~\"$instance\"} * on (instance, chip, sensor) group_left (label) node_hwmon_sensor_label{instance=~\"$instance\", label=\"PPT\"})";
          instant = true;
          legendFormat = "GPU W";
          refId = "A";
        }
      ];
      title = "GPU power draw";
      type = "stat";
    }
    {
      datasource = {
        type = "prometheus";
        uid = "prometheus";
      };
      fieldConfig = {
        defaults = {
          custom = {
            drawStyle = "line";
            fillOpacity = 10;
            lineWidth = 1;
            thresholdsStyle = {
              mode = "dashed";
            };
          };
          thresholds = {
            mode = "absolute";
            steps = [
              {
                color = "green";
                value = null;
              }
              {
                color = "yellow";
                value = 80;
              }
              {
                color = "red";
                value = 100;
              }
            ];
          };
          unit = "celsius";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 9;
        w = 12;
        x = 0;
        y = 7;
      };
      id = 6;
      options = {
        legend = {
          calcs = [
            "lastNotNull"
            "max"
          ];
          displayMode = "table";
          placement = "right";
          showLegend = true;
        };
        tooltip = {
          mode = "multi";
          sort = "desc";
        };
      };
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "label_replace(node_hwmon_temp_celsius{instance=~\"$instance\"} * on (instance, chip, sensor) group_left (label) node_hwmon_sensor_label{instance=~\"$instance\", label=~\"edge|junction|mem\"}, \"pci\", \"$1\", \"chip\", \".*:([0-9a-f]{2}:[0-9a-f]{2})_[0-9]$\")";
          legendFormat = "{{instance}} {{pci}} {{label}}";
          refId = "A";
        }
      ];
      title = "Temperatures (edge / junction / mem)";
      type = "timeseries";
    }
    {
      datasource = {
        type = "prometheus";
        uid = "prometheus";
      };
      fieldConfig = {
        defaults = {
          custom = {
            drawStyle = "line";
            fillOpacity = 10;
            lineWidth = 1;
          };
          unit = "watt";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 9;
        w = 6;
        x = 12;
        y = 7;
      };
      id = 7;
      options = {
        legend = {
          calcs = [
            "lastNotNull"
            "max"
          ];
          displayMode = "table";
          placement = "right";
          showLegend = true;
        };
        tooltip = {
          mode = "multi";
          sort = "desc";
        };
      };
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "label_replace(node_hwmon_power_average_watt{instance=~\"$instance\"} * on (instance, chip, sensor) group_left (label) node_hwmon_sensor_label{instance=~\"$instance\", label=\"PPT\"}, \"pci\", \"$1\", \"chip\", \".*:([0-9a-f]{2}:[0-9a-f]{2})_[0-9]$\")";
          legendFormat = "{{instance}} {{pci}}";
          refId = "A";
        }
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "label_replace(node_hwmon_power_cap_watt{instance=~\"$instance\"} * on (instance, chip) group_left () node_hwmon_chip_names{chip_name=\"amdgpu\"}, \"pci\", \"$1\", \"chip\", \".*:([0-9a-f]{2}:[0-9a-f]{2})_[0-9]$\")";
          hide = false;
          legendFormat = "{{instance}} {{pci}} cap";
          refId = "B";
        }
      ];
      title = "Board power (PPT)";
      type = "timeseries";
    }
    {
      datasource = {
        type = "prometheus";
        uid = "prometheus";
      };
      fieldConfig = {
        defaults = {
          custom = {
            drawStyle = "line";
            fillOpacity = 10;
            lineWidth = 1;
          };
          unit = "rpm";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 9;
        w = 6;
        x = 18;
        y = 7;
      };
      id = 8;
      options = {
        legend = {
          calcs = [
            "lastNotNull"
            "max"
          ];
          displayMode = "table";
          placement = "right";
          showLegend = true;
        };
        tooltip = {
          mode = "multi";
          sort = "desc";
        };
      };
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "label_replace(node_hwmon_fan_rpm{instance=~\"$instance\"} * on (instance, chip) group_left () node_hwmon_chip_names{chip_name=\"amdgpu\"}, \"pci\", \"$1\", \"chip\", \".*:([0-9a-f]{2}:[0-9a-f]{2})_[0-9]$\")";
          legendFormat = "{{instance}} {{pci}}";
          refId = "A";
        }
      ];
      title = "Fan speed";
      type = "timeseries";
    }
    {
      collapsed = false;
      gridPos = {
        h = 1;
        w = 24;
        x = 0;
        y = 16;
      };
      id = 9;
      panels = [ ];
      title = "WireView — e-desktop";
      type = "row";
    }
    {
      datasource = {
        type = "prometheus";
        uid = "prometheus";
      };
      fieldConfig = {
        defaults = {
          color = {
            mode = "thresholds";
          };
          thresholds = {
            mode = "absolute";
            steps = [
              {
                color = "green";
                value = null;
              }
              {
                color = "yellow";
                value = 500;
              }
              {
                color = "red";
                value = 580;
              }
            ];
          };
          unit = "watt";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 6;
        w = 4;
        x = 0;
        y = 17;
      };
      id = 10;
      options = {
        colorMode = "background";
        graphMode = "area";
        reduceOptions = {
          calcs = [
            "lastNotNull"
          ];
          fields = "";
          values = false;
        };
        textMode = "value";
      };
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "wireview_total_power_w";
          instant = true;
          legendFormat = "W";
          refId = "A";
        }
      ];
      title = "Total power";
      type = "stat";
    }
    {
      datasource = {
        type = "prometheus";
        uid = "prometheus";
      };
      fieldConfig = {
        defaults = {
          color = {
            mode = "thresholds";
          };
          thresholds = {
            mode = "absolute";
            steps = [
              {
                color = "green";
                value = null;
              }
              {
                color = "yellow";
                value = 42;
              }
              {
                color = "red";
                value = 48;
              }
            ];
          };
          unit = "ampere";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 6;
        w = 4;
        x = 4;
        y = 17;
      };
      id = 11;
      options = {
        colorMode = "background";
        graphMode = "area";
        reduceOptions = {
          calcs = [
            "lastNotNull"
          ];
          fields = "";
          values = false;
        };
        textMode = "value";
      };
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "wireview_total_current_a";
          instant = true;
          legendFormat = "A";
          refId = "A";
        }
      ];
      title = "Total current";
      type = "stat";
    }
    {
      datasource = {
        type = "prometheus";
        uid = "prometheus";
      };
      fieldConfig = {
        defaults = {
          color = {
            mode = "thresholds";
          };
          thresholds = {
            mode = "absolute";
            steps = [
              {
                color = "green";
                value = null;
              }
              {
                color = "yellow";
                value = 80;
              }
              {
                color = "red";
                value = 90;
              }
            ];
          };
          unit = "celsius";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 6;
        w = 4;
        x = 8;
        y = 17;
      };
      id = 12;
      options = {
        colorMode = "background";
        graphMode = "area";
        reduceOptions = {
          calcs = [
            "lastNotNull"
          ];
          fields = "";
          values = false;
        };
        textMode = "value";
      };
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "max(wireview_temperature_c)";
          instant = true;
          legendFormat = "°C";
          refId = "A";
        }
      ];
      title = "Max temperature";
      type = "stat";
    }
    {
      datasource = {
        type = "prometheus";
        uid = "prometheus";
      };
      fieldConfig = {
        defaults = {
          color = {
            mode = "thresholds";
          };
          mappings = [
            {
              options = {
                "0" = {
                  index = 0;
                  text = "OK";
                };
              };
              type = "value";
            }
          ];
          thresholds = {
            mode = "absolute";
            steps = [
              {
                color = "green";
                value = null;
              }
              {
                color = "red";
                value = 1;
              }
            ];
          };
          unit = "short";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 6;
        w = 4;
        x = 12;
        y = 17;
      };
      id = 13;
      options = {
        colorMode = "background";
        graphMode = "none";
        reduceOptions = {
          calcs = [
            "lastNotNull"
          ];
          fields = "";
          values = false;
        };
        textMode = "value";
      };
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "sum(wireview_fault_status)";
          instant = true;
          legendFormat = "faults";
          refId = "A";
        }
      ];
      title = "Faults";
      type = "stat";
    }
    {
      datasource = {
        type = "prometheus";
        uid = "prometheus";
      };
      fieldConfig = {
        defaults = {
          color = {
            mode = "thresholds";
          };
          max = 100;
          min = 0;
          thresholds = {
            mode = "absolute";
            steps = [
              {
                color = "green";
                value = null;
              }
              {
                color = "yellow";
                value = 70;
              }
              {
                color = "red";
                value = 90;
              }
            ];
          };
          unit = "percent";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 6;
        w = 4;
        x = 16;
        y = 17;
      };
      id = 14;
      options = {
        colorMode = "background";
        graphMode = "area";
        reduceOptions = {
          calcs = [
            "lastNotNull"
          ];
          fields = "";
          values = false;
        };
        textMode = "value";
      };
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "wireview_fan_duty";
          instant = true;
          legendFormat = "%";
          refId = "A";
        }
      ];
      title = "Fan duty";
      type = "stat";
    }
    {
      datasource = {
        type = "prometheus";
        uid = "prometheus";
      };
      fieldConfig = {
        defaults = {
          color = {
            fixedColor = "text";
            mode = "fixed";
          };
          unit = "watt";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 6;
        w = 4;
        x = 20;
        y = 17;
      };
      id = 15;
      options = {
        colorMode = "none";
        graphMode = "none";
        reduceOptions = {
          calcs = [
            "lastNotNull"
          ];
          fields = "";
          values = false;
        };
        textMode = "value";
      };
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "wireview_psu_capability_w";
          instant = true;
          legendFormat = "W";
          refId = "A";
        }
      ];
      title = "PSU capability";
      type = "stat";
    }
    {
      datasource = {
        type = "prometheus";
        uid = "prometheus";
      };
      fieldConfig = {
        defaults = {
          custom = {
            drawStyle = "line";
            fillOpacity = 10;
            lineStyle = {
              fill = "dash";
            };
            lineWidth = 1;
          };
          unit = "watt";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 9;
        w = 12;
        x = 0;
        y = 23;
      };
      id = 16;
      options = {
        legend = {
          calcs = [
            "lastNotNull"
            "max"
          ];
          displayMode = "table";
          placement = "right";
          showLegend = true;
        };
        tooltip = {
          mode = "multi";
          sort = "desc";
        };
      };
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "wireview_total_power_w";
          legendFormat = "total";
          refId = "A";
        }
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "wireview_psu_capability_w";
          hide = false;
          legendFormat = "PSU cap";
          refId = "B";
        }
      ];
      title = "Power";
      type = "timeseries";
    }
    {
      datasource = {
        type = "prometheus";
        uid = "prometheus";
      };
      fieldConfig = {
        defaults = {
          custom = {
            drawStyle = "line";
            fillOpacity = 10;
            lineWidth = 1;
          };
          unit = "ampere";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 9;
        w = 12;
        x = 12;
        y = 23;
      };
      id = 17;
      options = {
        legend = {
          calcs = [
            "lastNotNull"
            "max"
          ];
          displayMode = "table";
          placement = "right";
          showLegend = true;
        };
        tooltip = {
          mode = "multi";
          sort = "desc";
        };
      };
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "wireview_current_a";
          legendFormat = "pin {{pin}}";
          refId = "A";
        }
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "wireview_total_current_a";
          legendFormat = "total";
          refId = "B";
        }
      ];
      title = "Current per pin";
      type = "timeseries";
    }
    {
      datasource = {
        type = "prometheus";
        uid = "prometheus";
      };
      fieldConfig = {
        defaults = {
          custom = {
            drawStyle = "line";
            fillOpacity = 10;
            lineWidth = 1;
          };
          unit = "volt";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 9;
        w = 12;
        x = 0;
        y = 32;
      };
      id = 18;
      options = {
        legend = {
          calcs = [
            "lastNotNull"
            "min"
            "max"
          ];
          displayMode = "table";
          placement = "right";
          showLegend = true;
        };
        tooltip = {
          mode = "multi";
          sort = "desc";
        };
      };
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "wireview_voltage_v";
          legendFormat = "pin {{pin}}";
          refId = "A";
        }
      ];
      title = "Voltage per pin";
      type = "timeseries";
    }
    {
      datasource = {
        type = "prometheus";
        uid = "prometheus";
      };
      fieldConfig = {
        defaults = {
          custom = {
            drawStyle = "line";
            fillOpacity = 10;
            lineWidth = 1;
          };
          thresholds = {
            mode = "absolute";
            steps = [
              {
                color = "green";
                value = null;
              }
              {
                color = "yellow";
                value = 80;
              }
              {
                color = "red";
                value = 85;
              }
            ];
          };
          unit = "celsius";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 9;
        w = 12;
        x = 12;
        y = 32;
      };
      id = 19;
      options = {
        legend = {
          calcs = [
            "lastNotNull"
            "max"
          ];
          displayMode = "table";
          placement = "right";
          showLegend = true;
        };
        tooltip = {
          mode = "multi";
          sort = "desc";
        };
      };
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "wireview_temperature_c";
          legendFormat = "{{sensor}}";
          refId = "A";
        }
      ];
      title = "Temperature";
      type = "timeseries";
    }
  ];
  refresh = "30s";
  schemaVersion = 39;
  tags = [
    "nixos"
    "gpu"
  ];
  templating = {
    list = [
      {
        allValue = ".*";
        current = {
          text = "All";
          value = "$__all";
        };
        datasource = {
          type = "prometheus";
          uid = "prometheus";
        };
        includeAll = true;
        label = "Host";
        multi = true;
        name = "instance";
        query = "label_values(up{job=\"node\"}, instance)";
        refresh = 2;
        sort = 1;
        type = "query";
      }
    ];
  };
  time = {
    from = "now-6h";
    to = "now";
  };
  timepicker = {
    refresh_intervals = [
      "30s"
      "1m"
      "5m"
      "15m"
      "1h"
    ];
  };
  timezone = "browser";
  title = "GPUs";
  uid = "gpus";
  version = 1;
}
