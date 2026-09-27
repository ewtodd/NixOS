{
  annotations = {
    list = [ ];
  };
  editable = true;
  fiscalYearStartMonth = 0;
  graphTooltip = 0;
  links = [ ];
  liveNow = false;
  panels = [
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
        h = 4;
        w = 6;
        x = 0;
        y = 0;
      };
      id = 1;
      options = {
        colorMode = "value";
        graphMode = "area";
        justifyMode = "auto";
        orientation = "auto";
        reduceOptions = {
          calcs = [
            "lastNotNull"
          ];
          fields = "";
          values = false;
        };
        textMode = "auto";
      };
      pluginVersion = "11.0.0";
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "sum(f2b_jail_banned_current)";
          refId = "A";
        }
      ];
      title = "Currently banned (fail2ban)";
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
                color = "blue";
                value = null;
              }
            ];
          };
          unit = "short";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 4;
        w = 6;
        x = 6;
        y = 0;
      };
      id = 2;
      options = {
        colorMode = "value";
        graphMode = "area";
        justifyMode = "auto";
        orientation = "auto";
        reduceOptions = {
          calcs = [
            "lastNotNull"
          ];
          fields = "";
          values = false;
        };
        textMode = "auto";
      };
      pluginVersion = "11.0.0";
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "sum(endlessh_client_open_count)";
          refId = "A";
        }
      ];
      title = "Bots currently trapped (endlessh)";
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
          decimals = 0;
          thresholds = {
            mode = "absolute";
            steps = [
              {
                color = "purple";
                value = null;
              }
            ];
          };
          unit = "short";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 4;
        w = 6;
        x = 12;
        y = 0;
      };
      id = 3;
      options = {
        colorMode = "value";
        graphMode = "area";
        justifyMode = "auto";
        orientation = "auto";
        reduceOptions = {
          calcs = [
            "lastNotNull"
          ];
          fields = "";
          values = false;
        };
        textMode = "auto";
      };
      pluginVersion = "11.0.0";
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "sum(increase(endlessh_client_open_count_total[$__range]))";
          refId = "A";
        }
      ];
      title = "Bots trapped (selected range)";
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
            ];
          };
          unit = "s";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 4;
        w = 6;
        x = 18;
        y = 0;
      };
      id = 4;
      options = {
        colorMode = "value";
        graphMode = "area";
        justifyMode = "auto";
        orientation = "auto";
        reduceOptions = {
          calcs = [
            "lastNotNull"
          ];
          fields = "";
          values = false;
        };
        textMode = "auto";
      };
      pluginVersion = "11.0.0";
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "sum(increase(endlessh_trapped_time_seconds_total[$__range]))";
          refId = "A";
        }
      ];
      title = "Bot time wasted (selected range)";
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
            mode = "palette-classic";
          };
          custom = {
            axisCenteredZero = false;
            axisColorMode = "text";
            axisLabel = "";
            axisPlacement = "auto";
            drawStyle = "line";
            fillOpacity = 15;
            gradientMode = "none";
            lineInterpolation = "linear";
            lineWidth = 1;
            pointSize = 5;
            scaleDistribution = {
              type = "linear";
            };
            showPoints = "never";
            spanNulls = false;
            stacking = {
              group = "A";
              mode = "none";
            };
          };
          unit = "short";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 9;
        w = 12;
        x = 0;
        y = 4;
      };
      id = 5;
      options = {
        legend = {
          calcs = [
            "lastNotNull"
            "max"
          ];
          displayMode = "table";
          placement = "bottom";
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
          expr = "f2b_jail_banned_current";
          legendFormat = "{{jail}}";
          refId = "A";
        }
      ];
      title = "Banned IPs over time (fail2ban, by jail)";
      type = "timeseries";
    }
    {
      datasource = {
        type = "prometheus";
        uid = "prometheus";
      };
      fieldConfig = {
        defaults = {
          color = {
            mode = "palette-classic";
          };
          custom = {
            axisCenteredZero = false;
            axisColorMode = "text";
            axisLabel = "";
            axisPlacement = "auto";
            drawStyle = "line";
            fillOpacity = 15;
            gradientMode = "none";
            lineInterpolation = "linear";
            lineWidth = 1;
            pointSize = 5;
            scaleDistribution = {
              type = "linear";
            };
            showPoints = "never";
            spanNulls = false;
            stacking = {
              group = "A";
              mode = "none";
            };
          };
          unit = "short";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 9;
        w = 12;
        x = 12;
        y = 4;
      };
      id = 6;
      options = {
        legend = {
          calcs = [
            "lastNotNull"
          ];
          displayMode = "list";
          placement = "bottom";
          showLegend = true;
        };
        tooltip = {
          mode = "single";
          sort = "none";
        };
      };
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "sum(rate(f2b_jail_banned_total[$__rate_interval])) * 3600";
          legendFormat = "bans/hr";
          refId = "A";
        }
      ];
      title = "New bans / hour (fail2ban)";
      type = "timeseries";
    }
    {
      datasource = {
        type = "prometheus";
        uid = "prometheus";
      };
      fieldConfig = {
        defaults = {
          color = {
            mode = "palette-classic";
          };
          custom = {
            axisCenteredZero = false;
            axisColorMode = "text";
            axisLabel = "";
            axisPlacement = "auto";
            drawStyle = "line";
            fillOpacity = 20;
            gradientMode = "none";
            lineInterpolation = "linear";
            lineWidth = 1;
            pointSize = 5;
            scaleDistribution = {
              type = "linear";
            };
            showPoints = "never";
            spanNulls = false;
            stacking = {
              group = "A";
              mode = "none";
            };
          };
          unit = "short";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 9;
        w = 12;
        x = 0;
        y = 13;
      };
      id = 7;
      options = {
        legend = {
          calcs = [
            "lastNotNull"
          ];
          displayMode = "list";
          placement = "bottom";
          showLegend = true;
        };
        tooltip = {
          mode = "single";
          sort = "none";
        };
      };
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "sum(rate(endlessh_client_open_count_total[$__rate_interval])) * 3600";
          legendFormat = "trapped/hr";
          refId = "A";
        }
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "sum(endlessh_client_open_count)";
          legendFormat = "currently trapped";
          refId = "B";
        }
      ];
      title = "Bots trapped per hour (endlessh)";
      type = "timeseries";
    }
    {
      datasource = {
        type = "prometheus";
        uid = "prometheus";
      };
      fieldConfig = {
        defaults = {
          color = {
            mode = "palette-classic";
          };
          custom = {
            axisCenteredZero = false;
            axisColorMode = "text";
            axisLabel = "seconds wasted per hour";
            axisPlacement = "auto";
            drawStyle = "line";
            fillOpacity = 25;
            gradientMode = "none";
            lineInterpolation = "linear";
            lineWidth = 1;
            pointSize = 5;
            scaleDistribution = {
              type = "linear";
            };
            showPoints = "never";
            spanNulls = false;
            stacking = {
              group = "A";
              mode = "none";
            };
          };
          unit = "s";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 9;
        w = 12;
        x = 12;
        y = 13;
      };
      id = 8;
      options = {
        legend = {
          calcs = [
            "lastNotNull"
          ];
          displayMode = "list";
          placement = "bottom";
          showLegend = true;
        };
        tooltip = {
          mode = "single";
          sort = "none";
        };
      };
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "sum(rate(endlessh_trapped_time_seconds_total[$__rate_interval])) * 3600";
          legendFormat = "wasted/hr";
          refId = "A";
        }
      ];
      title = "Bot time wasted per hour (endlessh)";
      type = "timeseries";
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
                color = "blue";
                value = null;
              }
            ];
          };
          unit = "short";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 4;
        w = 6;
        x = 0;
        y = 22;
      };
      id = 9;
      options = {
        colorMode = "value";
        graphMode = "area";
        justifyMode = "auto";
        orientation = "auto";
        reduceOptions = {
          calcs = [
            "lastNotNull"
          ];
          fields = "";
          values = false;
        };
        textMode = "auto";
      };
      pluginVersion = "11.0.0";
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "sum(http_tarpit_active_connections)";
          refId = "A";
        }
      ];
      title = "HTTP bots currently trapped";
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
                color = "blue";
                value = null;
              }
            ];
          };
          unit = "short";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 4;
        w = 6;
        x = 6;
        y = 22;
      };
      id = 10;
      options = {
        colorMode = "value";
        graphMode = "area";
        justifyMode = "auto";
        orientation = "auto";
        reduceOptions = {
          calcs = [
            "lastNotNull"
          ];
          fields = "";
          values = false;
        };
        textMode = "auto";
      };
      pluginVersion = "11.0.0";
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "sum(increase(http_tarpit_connections_total[$__range]))";
          refId = "A";
        }
      ];
      title = "HTTP bots trapped (selected range)";
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
                color = "blue";
                value = null;
              }
            ];
          };
          unit = "s";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 4;
        w = 6;
        x = 12;
        y = 22;
      };
      id = 11;
      options = {
        colorMode = "value";
        graphMode = "area";
        justifyMode = "auto";
        orientation = "auto";
        reduceOptions = {
          calcs = [
            "lastNotNull"
          ];
          fields = "";
          values = false;
        };
        textMode = "auto";
      };
      pluginVersion = "11.0.0";
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "sum(increase(http_tarpit_wasted_seconds_total[$__range]))";
          refId = "A";
        }
      ];
      title = "HTTP bot time wasted (selected range)";
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
                color = "blue";
                value = null;
              }
            ];
          };
          unit = "bytes";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 4;
        w = 6;
        x = 18;
        y = 22;
      };
      id = 12;
      options = {
        colorMode = "value";
        graphMode = "area";
        justifyMode = "auto";
        orientation = "auto";
        reduceOptions = {
          calcs = [
            "lastNotNull"
          ];
          fields = "";
          values = false;
        };
        textMode = "auto";
      };
      pluginVersion = "11.0.0";
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "sum(increase(http_tarpit_bytes_sent_total[$__range]))";
          refId = "A";
        }
      ];
      title = "HTTP bytes dripped (selected range)";
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
            mode = "palette-classic";
          };
          custom = {
            axisCenteredZero = false;
            axisColorMode = "text";
            axisLabel = "bots per hour";
            axisPlacement = "auto";
            drawStyle = "line";
            fillOpacity = 25;
            gradientMode = "none";
            lineInterpolation = "linear";
            lineWidth = 1;
            pointSize = 5;
            scaleDistribution = {
              type = "linear";
            };
            showPoints = "auto";
            spanNulls = true;
            stacking = {
              group = "A";
              mode = "none";
            };
          };
          unit = "short";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 9;
        w = 12;
        x = 0;
        y = 26;
      };
      id = 13;
      options = {
        legend = {
          calcs = [
            "lastNotNull"
          ];
          displayMode = "list";
          placement = "bottom";
          showLegend = true;
        };
        tooltip = {
          mode = "single";
          sort = "none";
        };
      };
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "sum by (source) (rate(http_tarpit_connections_total[$__rate_interval])) * 3600";
          legendFormat = "{{source}} trapped/hr";
          refId = "A";
        }
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "sum by (source) (http_tarpit_active_connections)";
          legendFormat = "{{source}} active";
          refId = "B";
        }
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "sum by (source) (rate(http_tarpit_rejected_total[$__rate_interval])) * 3600";
          legendFormat = "{{source}} rejected/hr";
          refId = "C";
        }
      ];
      title = "HTTP bots trapped per hour";
      type = "timeseries";
    }
    {
      datasource = {
        type = "prometheus";
        uid = "prometheus";
      };
      fieldConfig = {
        defaults = {
          color = {
            mode = "palette-classic";
          };
          custom = {
            axisCenteredZero = false;
            axisColorMode = "text";
            axisLabel = "seconds wasted per hour";
            axisPlacement = "auto";
            drawStyle = "line";
            fillOpacity = 25;
            gradientMode = "none";
            lineInterpolation = "linear";
            lineWidth = 1;
            pointSize = 5;
            scaleDistribution = {
              type = "linear";
            };
            showPoints = "auto";
            spanNulls = true;
            stacking = {
              group = "A";
              mode = "none";
            };
          };
          unit = "s";
        };
        overrides = [ ];
      };
      gridPos = {
        h = 9;
        w = 12;
        x = 12;
        y = 26;
      };
      id = 14;
      options = {
        legend = {
          calcs = [
            "lastNotNull"
          ];
          displayMode = "list";
          placement = "bottom";
          showLegend = true;
        };
        tooltip = {
          mode = "single";
          sort = "none";
        };
      };
      targets = [
        {
          datasource = {
            type = "prometheus";
            uid = "prometheus";
          };
          expr = "sum(rate(http_tarpit_wasted_seconds_total[$__rate_interval])) * 3600";
          legendFormat = "wasted/hr";
          refId = "A";
        }
      ];
      title = "HTTP time wasted per hour";
      type = "timeseries";
    }
  ];
  refresh = "30s";
  schemaVersion = 39;
  tags = [
    "security"
    "bots"
  ];
  templating = {
    list = [ ];
  };
  time = {
    from = "now-6h";
    to = "now";
  };
  timepicker = { };
  timezone = "";
  title = "Bot Defense";
  uid = "bot-defense";
  version = 2;
  weekStart = "";
}
