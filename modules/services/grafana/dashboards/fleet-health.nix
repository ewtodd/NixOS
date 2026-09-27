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
      title = "Fleet overview";
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
          custom = {
            align = "left";
            cellOptions = {
              type = "auto";
            };
            filterable = false;
          };
          thresholds = {
            mode = "absolute";
            steps = [
              {
                color = "text";
                value = null;
              }
            ];
          };
        };
        overrides = [
          {
            matcher = {
              id = "byName";
              options = "Host";
            };
            properties = [
              {
                id = "custom.width";
                value = 220;
              }
            ];
          }
          {
            matcher = {
              id = "byName";
              options = "Status";
            };
            properties = [
              {
                id = "custom.width";
                value = 140;
              }
              {
                id = "custom.align";
                value = "center";
              }
              {
                id = "custom.cellOptions";
                value = {
                  mode = "basic";
                  type = "color-background";
                };
              }
              {
                id = "mappings";
                value = [
                  {
                    options = {
                      "0" = {
                        color = "red";
                        index = 0;
                        text = "DOWN";
                      };
                      "1" = {
                        color = "green";
                        index = 1;
                        text = "UP";
                      };
                    };
                    type = "value";
                  }
                  {
                    options = {
                      match = "null";
                      result = {
                        color = "red";
                        index = 2;
                        text = "NO DATA";
                      };
                    };
                    type = "special";
                  }
                ];
              }
            ];
          }
          {
            matcher = {
              id = "byName";
              options = "Uptime";
            };
            properties = [
              {
                id = "unit";
                value = "s";
              }
              {
                id = "decimals";
                value = 1;
              }
              {
                id = "mappings";
                value = [
                  {
                    options = {
                      match = "null";
                      result = {
                        color = "text";
                        index = 0;
                        text = "—";
                      };
                    };
                    type = "special";
                  }
                ];
              }
              {
                id = "custom.cellOptions";
                value = {
                  type = "color-text";
                };
              }
              {
                id = "color";
                value = {
                  mode = "thresholds";
                };
              }
              {
                id = "thresholds";
                value = {
                  mode = "absolute";
                  steps = [
                    {
                      color = "orange";
                      value = null;
                    }
                    {
                      color = "text";
                      value = 900;
                    }
                  ];
                };
              }
            ];
          }
        ];
      };
      gridPos = {
        h = 9;
        w = 24;
        x = 0;
        y = 1;
      };
      id = 2;
      options = {
        cellHeight = "md";
        footer = {
          countRows = false;
          fields = "";
          reducer = [
            "sum"
          ];
          show = false;
        };
        showHeader = true;
        sortBy = [
          {
            desc = false;
            displayName = "Status";
          }
        ];
      };
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "max by (instance) (up{job=\"node\",instance=~\"$instance\"})";
          format = "table";
          instant = true;
          refId = "A";
        }
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "max by (instance) (node_time_seconds{instance=~\"$instance\"} - node_boot_time_seconds)";
          format = "table";
          instant = true;
          refId = "B";
        }
      ];
      title = "Host status & uptime";
      transformations = [
        {
          id = "joinByField";
          options = {
            byField = "instance";
            mode = "outer";
          };
        }
        {
          id = "filterFieldsByName";
          options = {
            exclude = {
              pattern = "^Time.*";
            };
          };
        }
        {
          id = "organize";
          options = {
            excludeByName = { };
            indexByName = {
              "Value #A" = 1;
              "Value #B" = 2;
              instance = 0;
            };
            renameByName = {
              Value = "Status";
              "Value #A" = "Status";
              "Value #B" = "Uptime";
              "Value 1" = "Uptime";
              instance = "Host";
            };
          };
        }
      ];
      type = "table";
    }
    {
      collapsed = false;
      gridPos = {
        h = 1;
        w = 24;
        x = 0;
        y = 10;
      };
      id = 4;
      panels = [ ];
      title = "Resource trends";
      type = "row";
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
          max = 100;
          min = 0;
          unit = "percent";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 9;
        w = 12;
        x = 0;
        y = 11;
      };
      id = 5;
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
          expr = "100 - avg by (instance) (rate(node_cpu_seconds_total{instance=~\"$instance\",mode=\"idle\"}[5m]) * 100)";
          legendFormat = "{{instance}}";
          refId = "A";
        }
      ];
      title = "CPU % busy";
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
          max = 100;
          min = 0;
          unit = "percent";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 9;
        w = 12;
        x = 12;
        y = 11;
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
          expr = "100 * (1 - node_memory_MemAvailable_bytes{instance=~\"$instance\"} / node_memory_MemTotal_bytes{instance=~\"$instance\"})";
          legendFormat = "{{instance}}";
          refId = "A";
        }
      ];
      title = "Memory % used";
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
          max = 100;
          min = 0;
          unit = "percent";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 9;
        w = 12;
        x = 0;
        y = 20;
      };
      id = 7;
      options = {
        legend = {
          calcs = [
            "lastNotNull"
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
          expr = "100 - node_filesystem_avail_bytes{instance=~\"$instance\",mountpoint=\"/\",fstype!=\"tmpfs\"} / node_filesystem_size_bytes{instance=~\"$instance\",mountpoint=\"/\",fstype!=\"tmpfs\"} * 100";
          legendFormat = "{{instance}}";
          refId = "A";
        }
      ];
      title = "Root filesystem % used";
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
          unit = "Bps";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 9;
        w = 12;
        x = 12;
        y = 20;
      };
      id = 8;
      options = {
        legend = {
          calcs = [
            "lastNotNull"
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
          expr = "sum by (instance) (rate(node_network_receive_bytes_total{instance=~\"$instance\",device!=\"lo\"}[5m]))";
          legendFormat = "{{instance}} rx";
          refId = "A";
        }
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "-sum by (instance) (rate(node_network_transmit_bytes_total{instance=~\"$instance\",device!=\"lo\"}[5m]))";
          legendFormat = "{{instance}} tx";
          refId = "B";
        }
      ];
      title = "Network I/O (rx +, tx -)";
      type = "timeseries";
    }
    {
      collapsed = false;
      gridPos = {
        h = 1;
        w = 24;
        x = 0;
        y = 29;
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
        y = 30;
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
        y = 30;
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
        y = 30;
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
        y = 30;
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
        y = 30;
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
        y = 30;
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
        y = 36;
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
        y = 36;
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
        y = 45;
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
        y = 45;
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
    "node"
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
  title = "Fleet health";
  uid = "fleet-health";
  version = 3;
}
