let
  datasource = {
    type = "prometheus";
    uid = "prometheus";
  };

  sel = "{key=~\"$key\"}";

  # Takes { id, title, unit, expr, gridPos }; returns a stat panel showing the query's value at the end of
  # the picked range.
  stat =
    {
      id,
      title,
      unit,
      expr,
      gridPos,
    }:
    {
      inherit
        id
        title
        gridPos
        datasource
        ;
      type = "stat";
      fieldConfig = {
        defaults = {
          inherit unit;
          color = {
            mode = "fixed";
            fixedColor = "blue";
          };
        };
        overrides = [ ];
      };
      options = {
        colorMode = "value";
        graphMode = "none";
        justifyMode = "auto";
        orientation = "auto";
        textMode = "auto";
        reduceOptions = {
          calcs = [ "lastNotNull" ];
          fields = "";
          values = false;
        };
      };
      targets = [
        {
          inherit datasource expr;
          instant = true;
          refId = "A";
        }
      ];
    };

  # Takes { id, title, unit, targets, gridPos } and optionally bars = true; each target is { expr, legend }
  # with an optional query step (interval). Returns a time series panel; bars are stacked, lines are not.
  series =
    {
      id,
      title,
      unit,
      targets,
      gridPos,
      bars ? false,
    }:
    {
      inherit
        id
        title
        gridPos
        datasource
        ;
      type = "timeseries";
      fieldConfig = {
        defaults = {
          inherit unit;
          min = 0;
          custom = {
            drawStyle = if bars then "bars" else "line";
            fillOpacity = if bars then 80 else 10;
            lineWidth = 1;
            stacking.mode = if bars then "normal" else "none";
          };
        };
        overrides = [ ];
      };
      options = {
        legend = {
          calcs = [
            "mean"
            "max"
            "sum"
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
      targets = builtins.genList (
        i:
        let
          t = builtins.elemAt targets i;
        in
        {
          inherit datasource;
          inherit (t) expr;
          legendFormat = t.legend;
          refId = builtins.substring i 1 "ABCDEFGH";
        }
        // (if t ? interval then { inherit (t) interval; } else { })
      ) (builtins.length targets);
    };

  # PromQL over a maitred counter, limited to the picked keys: its total increase over the picked range,
  # its per-second rate summed by the labels `by`, and its daily increase summed by them.
  overRange = metric: "sum(increase(${metric}${sel}[$__range]))";
  rateBy = by: metric: "sum by (${by}) (rate(${metric}${sel}[$__rate_interval]))";
  perDayBy = by: metric: "sum by (${by}) (increase(${metric}${sel}[1d]))";
in
{
  annotations.list = [ ];
  editable = true;
  panels = [
    (stat {
      id = 1;
      title = "Generated tokens";
      unit = "short";
      expr = overRange "maitred_completion_tokens_total";
      gridPos = {
        h = 4;
        w = 4;
        x = 0;
        y = 0;
      };
    })
    (stat {
      id = 2;
      title = "Prompt tokens";
      unit = "short";
      expr = overRange "maitred_prompt_tokens_total";
      gridPos = {
        h = 4;
        w = 4;
        x = 4;
        y = 0;
      };
    })
    (stat {
      id = 3;
      title = "Prompt tokens read from cache";
      unit = "percentunit";
      expr = "${overRange "maitred_cached_tokens_total"} / ${overRange "maitred_prompt_tokens_total"}";
      gridPos = {
        h = 4;
        w = 4;
        x = 8;
        y = 0;
      };
    })
    (stat {
      id = 4;
      title = "Requests";
      unit = "short";
      expr = overRange "maitred_requests_total";
      gridPos = {
        h = 4;
        w = 4;
        x = 12;
        y = 0;
      };
    })
    (stat {
      id = 5;
      title = "Failed or abandoned requests";
      unit = "short";
      expr = overRange "maitred_request_failures_total";
      gridPos = {
        h = 4;
        w = 4;
        x = 16;
        y = 0;
      };
    })
    (stat {
      id = 6;
      title = "In flight now";
      unit = "short";
      expr = "sum(maitred_requests_in_flight${sel})";
      gridPos = {
        h = 4;
        w = 4;
        x = 20;
        y = 0;
      };
    })
    (series {
      id = 7;
      title = "Generated tokens/s by model";
      unit = "short";
      targets = [
        {
          expr = rateBy "model" "maitred_completion_tokens_total";
          legend = "{{model}}";
        }
      ];
      gridPos = {
        h = 9;
        w = 12;
        x = 0;
        y = 4;
      };
    })
    (series {
      id = 8;
      title = "Prefilled (uncached) prompt tokens/s by model";
      unit = "short";
      targets = [
        {
          expr = "${rateBy "model" "maitred_prompt_tokens_total"} - ${rateBy "model" "maitred_cached_tokens_total"}";
          legend = "{{model}}";
        }
      ];
      gridPos = {
        h = 9;
        w = 12;
        x = 12;
        y = 4;
      };
    })
    (series {
      id = 9;
      title = "Generated tokens per day by model";
      unit = "short";
      bars = true;
      targets = [
        {
          expr = perDayBy "model" "maitred_completion_tokens_total";
          legend = "{{model}}";
          interval = "1d";
        }
      ];
      gridPos = {
        h = 9;
        w = 12;
        x = 0;
        y = 13;
      };
    })
    (series {
      id = 10;
      title = "Generated tokens per day by key";
      unit = "short";
      bars = true;
      targets = [
        {
          expr = perDayBy "key" "maitred_completion_tokens_total";
          legend = "{{key}}";
          interval = "1d";
        }
      ];
      gridPos = {
        h = 9;
        w = 12;
        x = 12;
        y = 13;
      };
    })
    (series {
      id = 11;
      title = "Requests/min by key";
      unit = "short";
      targets = [
        {
          expr = "60 * ${rateBy "key" "maitred_requests_total"}";
          legend = "{{key}}";
        }
      ];
      gridPos = {
        h = 9;
        w = 12;
        x = 0;
        y = 22;
      };
    })
    (series {
      id = 12;
      title = "Failed or abandoned requests/min by key and model";
      unit = "short";
      targets = [
        {
          expr = "60 * ${rateBy "key, model" "maitred_request_failures_total"}";
          legend = "{{key}} {{model}}";
        }
      ];
      gridPos = {
        h = 9;
        w = 12;
        x = 12;
        y = 22;
      };
    })
    (series {
      id = 13;
      title = "Requests in flight by key";
      unit = "short";
      targets = [
        {
          expr = "sum by (key) (maitred_requests_in_flight${sel})";
          legend = "{{key}}";
        }
      ];
      gridPos = {
        h = 9;
        w = 12;
        x = 0;
        y = 31;
      };
    })
    (series {
      id = 14;
      title = "Prompt tokens read from cache, by model";
      unit = "percentunit";
      targets = [
        {
          expr = "${rateBy "model" "maitred_cached_tokens_total"} / ${rateBy "model" "maitred_prompt_tokens_total"}";
          legend = "{{model}}";
        }
      ];
      gridPos = {
        h = 9;
        w = 12;
        x = 12;
        y = 31;
      };
    })
  ];
  refresh = "1m";
  schemaVersion = 39;
  tags = [
    "nixos"
    "llm"
  ];
  templating.list = [
    {
      allValue = ".*";
      current = {
        text = "All";
        value = "$__all";
      };
      inherit datasource;
      includeAll = true;
      label = "Key";
      multi = true;
      name = "key";
      query = "label_values(maitred_requests_total, key)";
      refresh = 2;
      sort = 1;
      type = "query";
    }
  ];
  time = {
    from = "now-7d";
    to = "now";
  };
  timepicker.refresh_intervals = [
    "1m"
    "5m"
    "15m"
    "1h"
  ];
  timezone = "browser";
  title = "LLM usage";
  uid = "llm-usage";
  version = 1;
}
