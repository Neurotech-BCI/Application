PID=$(lsof -t -i:5000)
if [ -n "$PID" ]; then
    kill -9 $PID
else
    echo "No process found on port 5000"
fi
dart run testserver.dart