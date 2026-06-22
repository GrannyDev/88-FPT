import subprocess
from datetime import datetime

scripts = [
    "int/mobilenetv2_int4.py",
    "int/mobilenetv2_int5.py",
    "int/mobilenetv2_int6.py",
    "int/mobilenetv2_int7.py",
    "rscm/mobilenetv2_rscm4.py",
    "rscm/mobilenetv2_rscm5.py",
    "rscm/mobilenetv2_rscm6.py",
    "rscm/mobilenetv2_rscm7.py",
]

log_file = f"run_{datetime.now():%Y%m%d_%H%M%S}.log"

with open(log_file, "w", buffering=1) as log:
    for script in scripts:
        header = f"\n{'='*60}\nRunning: {script}\n{'='*60}\n"

        print(header, end="")
        log.write(header)

        process = subprocess.Popen(
            ["python3", script],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )

        for line in process.stdout:
            print(line, end="")  # terminal
            log.write(line)      # log file

        process.wait()

        footer = f"\nFinished: {script} (exit code {process.returncode})\n"
        print(footer)
        log.write(footer)

        if process.returncode != 0:
            error = f"ERROR: {script} failed. Stopping.\n"
            print(error)
            log.write(error)
            break

print(f"Log saved to {log_file}")
