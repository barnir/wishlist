@echo off
echo 🏷️ Creating Git tag for release...

set /p version="Enter version (e.g., v1.0.0): "
set /p message="Enter release message: "

git tag -a %version% -m "%message%"
git push origin %version%

echo ✅ Tag %version% created and pushed!