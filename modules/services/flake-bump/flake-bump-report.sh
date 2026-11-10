# Pre-run script of the son-of-anton review job. Prints the newest run's report
# once and clears its PENDING marker; with nothing pending it prints the line
# that keeps the job from waking the agent.
state=${1:?state directory}

latest=$(find "$state/runs" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -n 1)
if [ -z "$latest" ] || [ ! -e "$latest/PENDING" ]; then
  echo '{"wakeAgent": false}'
  exit 0
fi

rm -f "$latest/PENDING"
cat "$latest/report.md"
