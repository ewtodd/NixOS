# Pre-run script of the son-of-anton review job. Prints the newest run's report
# once and clears its PENDING marker; with nothing pending it prints the line
# that keeps the job from waking the agent.
state=${1:?state directory}

latest=
if [ -d "$state/runs" ]; then
  latest=$(find "$state/runs" -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1)
fi
if [ -z "$latest" ] || [ ! -e "$latest/PENDING" ]; then
  echo '{"wakeAgent": false}'
  exit 0
fi

rm -f "$latest/PENDING"
cat "$latest/report.md"
